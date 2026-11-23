-- Runs on: ALL. The host checks that every human peer runs the same build of this mod.
--
-- The custom journey, arena level keys, and boon pickups all rely on NetworkLookup indices
-- (see core/lookups.lua). A peer without the mod, or with a different version or load order,
-- crashes as soon as one of those ids reaches it. This module turns that into a clear message:
--   * When VMF detects a peer that has this mod, the host sends "ec_hello" {version, fingerprint}
--     and the peer replies with its own values.
--   * Peers that never answer within HANDSHAKE_TIMEOUT are marked "missing" (no mod or no VMF).
--   * While any peer is not verified, a Risk of Rats run cannot be started (see journey.lua) and
--     the host spawns no boon drops.
local mod = get_mod("endlessChaos")

local Net = {}

local HANDSHAKE_TIMEOUT = 15
local HELLO_RESEND_INTERVAL = 3
local VERIFIED_GRACE_PERIOD = 120
local LOBBY_STATE_INTERVAL = 5

local STATUS_PENDING = "pending"
local STATUS_OK = "ok"
local STATUS_MISMATCH = "mismatch"
local STATUS_MISSING = "missing"

-- Host only: peer_id -> { status, since, reason, announced, last_hello }
-- "ok" entries survive level transitions (remote players are removed and re-added on every load).
local _peers = {}
local _last_lobby_state_broadcast = -math.huge
local _last_all_ready = nil

-- Client only: what the host last told us.
local _host_says_ready = false
local _host_reason = nil

local function now()
	return Managers.time and Managers.time:time("main") or os.clock()
end

local function version()
	return mod.VERSION
end

local function fingerprint()
	return mod.Lookups.fingerprint()
end

local function compare(remote_version, remote_fingerprint)
	if remote_version ~= version() then
		return false, string.format("version %s (host has %s)", tostring(remote_version), version())
	end

	if remote_fingerprint ~= fingerprint() then
		return false, "same version but different network ids (check mod load order)"
	end

	return true
end

-- Host only.
local function compute_all_ready()
	for peer_id, _ in pairs(mod.Util.remote_human_peers()) do
		local entry = _peers[peer_id]

		if not entry or entry.status ~= STATUS_OK then
			return false, entry and entry.reason or "waiting for handshake"
		end
	end

	return true
end

-- Host only.
local function broadcast_lobby_state()
	local all_ready, reason = compute_all_ready()

	mod:network_send("ec_lobby_state", "others", all_ready, reason or "")

	_last_lobby_state_broadcast = now()
end

-- Host only.
local function announce(peer_id, entry)
	if entry.announced then
		return
	end

	entry.announced = true

	local name = mod.Util.player_name(peer_id)

	if entry.status == STATUS_MISSING then
		mod.Util.broadcast_chat(string.format("%s does not have the Risk of Rats mod (v%s) enabled. Risk of Rats runs are blocked until everyone has it.", name, version()))
	elseif entry.status == STATUS_MISMATCH then
		mod.Util.broadcast_chat(string.format("%s has a different Risk of Rats build: %s. Risk of Rats runs are blocked until everyone matches.", name, tostring(entry.reason)))
	end
end

-- ##### RPCs ##################################################################################

-- host -> client
mod:network_register("ec_hello", function (sender, host_version, host_fingerprint)
	mod:network_send("ec_hello_reply", sender, version(), fingerprint())

	local ok, reason = compare(host_version, host_fingerprint)

	if not ok then
		mod:echo("[Risk of Rats] Your build does not match the host's: %s", reason)
	end
end)

-- client -> host
mod:network_register("ec_hello_reply", function (sender, peer_version, peer_fingerprint)
	if not mod.Util.is_server() then
		return
	end

	local ok, reason = compare(peer_version, peer_fingerprint)
	local entry = _peers[sender] or {}
	local new_status = ok and STATUS_OK or STATUS_MISMATCH

	-- Peers may reply more than once (unsolicited intro + answer to ec_hello); only announce
	-- when something actually changed.
	if entry.status ~= new_status or entry.reason ~= reason then
		entry.announced = false
	end

	entry.status = new_status
	entry.reason = reason
	entry.since = entry.since or now()
	_peers[sender] = entry

	if ok then
		mod:info("handshake ok with %s", tostring(sender))
	else
		announce(sender, entry)
	end

	broadcast_lobby_state()
end)

-- host -> clients
mod:network_register("ec_lobby_state", function (sender, all_ready, reason)
	_host_says_ready = all_ready == true
	_host_reason = reason ~= "" and reason or nil
end)

-- ##### VMF events (wired up in endlessChaos.lua) ##############################################

local function send_hello(peer_id, entry)
	entry.last_hello = now()

	mod:network_send("ec_hello", peer_id, version(), fingerprint())
end

-- Fires when VMF learns that `player` also runs this mod (on both host and clients).
function Net.on_user_joined(player)
	if not player or not player.peer_id then
		return
	end

	if not mod.Util.is_server() then
		-- VMF can register the two directions at different times, so the host's "ec_hello" may
		-- be dropped. Introduce ourselves as well; non-host receivers ignore the reply.
		mod:network_send("ec_hello_reply", player.peer_id, version(), fingerprint())

		return
	end

	local entry = _peers[player.peer_id] or {}

	if entry.status ~= STATUS_OK then
		entry.status = STATUS_PENDING
		entry.reason = nil
		entry.since = now()
		entry.announced = false
	end

	_peers[player.peer_id] = entry

	send_hello(player.peer_id, entry)
end

function Net.on_user_left(player)
	-- Nothing to do: Net.update prunes unverified peers that are gone, and verified peers are
	-- kept so a level transition doesn't trigger a new handshake.
end

function Net.update(dt)
	if not mod.Util.is_server() then
		return
	end

	local t = now()
	local remote_peers = mod.Util.remote_human_peers()

	-- Track peers VMF never reported (they don't have the mod, or have no VMF at all).
	for peer_id, _ in pairs(remote_peers) do
		local entry = _peers[peer_id]

		if not entry then
			entry = {
				status = STATUS_PENDING,
				since = t,
			}
			_peers[peer_id] = entry
		end

		if entry.status == STATUS_PENDING then
			if t - entry.since > HANDSHAKE_TIMEOUT then
				entry.status = STATUS_MISSING
				entry.reason = "no response (mod missing or disabled)"

				announce(peer_id, entry)
			elseif t - (entry.last_hello or -math.huge) > HELLO_RESEND_INTERVAL then
				-- VMF silently drops sends to peers it hasn't registered yet; keep trying.
				send_hello(peer_id, entry)
			end
		end
	end

	-- Forget peers that left. Verified peers get a grace period so a level transition (which
	-- removes and re-adds every remote player) doesn't force a new handshake, while a player who
	-- really left and comes back later (maybe with the mod disabled) is checked again.
	for peer_id, entry in pairs(_peers) do
		if remote_peers[peer_id] then
			entry.absent_since = nil
		elseif entry.status ~= STATUS_OK then
			_peers[peer_id] = nil
		else
			entry.absent_since = entry.absent_since or t

			if t - entry.absent_since > VERIFIED_GRACE_PERIOD then
				_peers[peer_id] = nil
			end
		end
	end

	local all_ready = compute_all_ready()

	if all_ready ~= _last_all_ready or t - _last_lobby_state_broadcast > LOBBY_STATE_INTERVAL then
		_last_all_ready = all_ready

		broadcast_lobby_state()
	end
end

function Net.on_game_state_changed(status, state_name)
	-- A new session (or leaving one) means a new set of peers.
	if state_name == "StateLoading" and status == "enter" then
		_host_says_ready = false
		_host_reason = nil
	end
end

-- ##### Queries ##############################################################################

-- Host: every remote human peer passed the handshake.
-- Client: the host told us everyone passed.
function Net.all_peers_ready()
	if mod.Util.is_server() then
		return compute_all_ready()
	end

	return _host_says_ready, _host_reason or "waiting for host"
end

function Net.print_status()
	mod:echo("Risk of Rats v%s, network fingerprint %s", version(), fingerprint())

	if not mod.Util.is_server() then
		local ready, reason = Net.all_peers_ready()

		mod:echo("Host reports lobby ready: %s%s", tostring(ready), reason and (" (" .. reason .. ")") or "")

		return
	end

	local any = false

	for peer_id, _ in pairs(mod.Util.remote_human_peers()) do
		local entry = _peers[peer_id]

		any = true

		mod:echo("  %s: %s%s", mod.Util.player_name(peer_id), entry and entry.status or STATUS_PENDING, entry and entry.reason and (" - " .. entry.reason) or "")
	end

	if not any then
		mod:echo("  (no other players)")
	end
end

return Net
