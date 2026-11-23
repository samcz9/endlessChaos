-- Runs on: ALL. Small shared helpers. No side effects at load.
local mod = get_mod("endlessChaos")

local Util = {}

Util.JOURNEY_NAME = "journey_endless_chaos"
Util.ARENA_LEVEL_KEY = "arena_endless_chaos"

-- True on the machine that owns the game session (lobby host / server).
-- Managers.player.is_server is set as soon as the lobby exists, so it also works in the inn.
function Util.is_server()
	local player_manager = Managers.player

	return player_manager ~= nil and player_manager.is_server == true
end

function Util.get_run_controller()
	local mechanism_manager = Managers.mechanism
	local mechanism = mechanism_manager and mechanism_manager:game_mechanism()

	if mechanism and mechanism.get_deus_run_controller then
		return mechanism:get_deus_run_controller()
	end

	return nil
end

-- True while a Risk of Rats run is active (map, arena, or loading between them).
function Util.is_endless_run()
	local run_controller = Util.get_run_controller()

	return run_controller ~= nil and run_controller:get_journey_name() == Util.JOURNEY_NAME
end

-- True only while inside the Risk of Rats arena level itself.
function Util.in_endless_arena()
	if not Util.is_endless_run() then
		return false
	end

	local level_transition_handler = Managers.level_transition_handler
	local level_key = level_transition_handler and level_transition_handler:get_current_level_key()

	return level_key ~= nil and string.find(level_key, Util.ARENA_LEVEL_KEY, 1, true) == 1
end

function Util.local_human_player()
	local player_manager = Managers.player

	return player_manager and player_manager:local_player()
end

-- Remote human players (no bots, not ourselves), keyed by peer_id.
function Util.remote_human_peers()
	local peers = {}
	local player_manager = Managers.player
	local human_players = player_manager and player_manager:human_players()

	if human_players then
		for _, player in pairs(human_players) do
			if player.remote and player.peer_id then
				peers[player.peer_id] = player
			end
		end
	end

	return peers
end

function Util.player_name(peer_id)
	local player_manager = Managers.player
	local player = player_manager and player_manager:player_from_peer_id(peer_id)

	return player and player:name() or tostring(peer_id)
end

-- Sends a normal chat message from the local player so every peer sees it, including
-- peers that do not have the mod. Falls back to a local echo.
function Util.broadcast_chat(message)
	local ok = pcall(function ()
		local localize, localization_parameters, localize_parameters = false, nil, false
		local recent_message_index, optional_message_target = nil, nil
		local irc = rawget(_G, "Irc")
		local party_message_type = irc and irc.PARTY_MSG

		Managers.chat:send_chat_message(1, 1, "[Risk of Rats] " .. message, localize, localization_parameters, localize_parameters, recent_message_index, optional_message_target, party_message_type)
	end)

	if not ok then
		mod:echo("%s", message)
	end
end

return Util
