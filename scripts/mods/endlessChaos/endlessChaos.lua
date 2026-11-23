-- Risk of Rats: endless, scaling Chaos Wastes mode on the Fortunes of War arena.
-- See docs/DESIGN.md. Every module states where it runs: HOST, OWNER, or ALL (deterministic).
local mod = get_mod("endlessChaos")

mod.VERSION = "0.1.0"

local BASE = "scripts/mods/endlessChaos/"

-- ##### Localization #########################################################################

local language_id = Application.user_setting("language_id")
local localizations = mod:dofile(BASE .. "endlessChaos_localization")

mod:hook("Localize", function (func, text_id, ...)
	local translations = localizations[text_id]

	if translations then
		return translations[language_id] or translations.en
	end

	return func(text_id, ...)
end)

-- ##### Modules ##############################################################################
-- Load order matters: NetworkLookup registrations happen during init and must run in the same
-- order on every peer (journey, then pickups).

mod.Util = mod:dofile(BASE .. "core/util")
mod.Lookups = mod:dofile(BASE .. "core/lookups")
mod.Net = mod:dofile(BASE .. "core/net")
mod.Pickups = mod:dofile(BASE .. "boons/pickups")
mod.Grant = mod:dofile(BASE .. "boons/grant")
mod.Uncap = mod:dofile(BASE .. "boons/uncap")
mod.Drops = mod:dofile(BASE .. "boons/drops")

local Journey = mod:dofile(BASE .. "journey/journey")
local plaza_blueprints = mod:dofile(BASE .. "journey/plaza_blueprints")

Journey.init(plaza_blueprints)
mod.Pickups.init()
mod.Uncap.init()
mod.Drops.init()

-- Enemy scaling was removed in milestone 1. It edited Breeds and hooked calculate_damage on every
-- peer, which desynced host and clients. Milestone 2 brings it back as host-only spawn buffs.

-- ##### VMF events ###########################################################################

mod.update = function (dt)
	mod.Net.update(dt)
end

mod.on_user_joined = function (player)
	mod.Net.on_user_joined(player)
end

mod.on_user_left = function (player)
	mod.Net.on_user_left(player)
end

mod.on_game_state_changed = function (status, state_name)
	mod.Net.on_game_state_changed(status, state_name)
end

-- ##### Commands #############################################################################

mod:command("ec_status", "Risk of Rats: show version, network fingerprint and each player's handshake status.", function ()
	mod.Net.print_status()
end)

mod:command("ec_givebuff", "Risk of Rats (debug): ec_givebuff <boon_name> <rarity>. Grants a specific boon to yourself.", function (name, rarity)
	if not name then
		mod:echo("Usage: /ec_givebuff <boon_name> <rarity>   e.g. /ec_givebuff attack_speed rare")

		return
	end

	mod.Grant.grant_specific_boon(name, rarity or "rare")
end)

mod:info("Risk of Rats v%s loaded (network fingerprint %s)", mod.VERSION, mod.Lookups.fingerprint())
