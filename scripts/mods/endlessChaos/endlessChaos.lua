-- Risk of Rats: endless, scaling Chaos Wastes mode on the Fortunes of War arena.
-- See docs/DESIGN.md. Every module states where it runs: HOST, OWNER, or ALL (deterministic).
local mod = get_mod("endlessChaos")

mod.VERSION = "0.2.0"

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
-- order on every peer (journey, then pickups, then enemy buff templates). Only append new
-- registrations at the end.

mod.Util = mod:dofile(BASE .. "core/util")
mod.Lookups = mod:dofile(BASE .. "core/lookups")
mod.Net = mod:dofile(BASE .. "core/net")
mod.Pickups = mod:dofile(BASE .. "boons/pickups")
mod.Grant = mod:dofile(BASE .. "boons/grant")
mod.Uncap = mod:dofile(BASE .. "boons/uncap")
mod.Drops = mod:dofile(BASE .. "boons/drops")
mod.Difficulty = mod:dofile(BASE .. "scaling/difficulty")
mod.EnemyScaling = mod:dofile(BASE .. "scaling/enemy_scaling")

local Journey = mod:dofile(BASE .. "journey/journey")
local plaza_blueprints = mod:dofile(BASE .. "journey/plaza_blueprints")

Journey.init(plaza_blueprints)
mod.Pickups.init()
mod.Uncap.init()
mod.Drops.init()
mod.Difficulty.init()
mod.EnemyScaling.init()

-- ##### VMF events ###########################################################################

mod.update = function (dt)
	mod.Net.update(dt)
	mod.Difficulty.update(dt)
end

mod.on_user_joined = function (player)
	mod.Net.on_user_joined(player)
end

mod.on_user_left = function (player)
	mod.Net.on_user_left(player)
end

mod.on_game_state_changed = function (status, state_name)
	mod.Net.on_game_state_changed(status, state_name)
	mod.Difficulty.on_game_state_changed(status, state_name)
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

mod:command("ec_scaling", "Risk of Rats: show the enemy scaling coefficient, health/damage multipliers and network health limits.", function ()
	mod.Difficulty.print_status()
end)

mod:command("ec_addtime", "Risk of Rats (debug, host): ec_addtime <minutes>. Moves the scaling clock forward (negative to go back).", function (minutes)
	if not mod.Util.is_server() then
		mod:echo("Only the host can change scaling.")

		return
	end

	local amount = tonumber(minutes)

	if not amount then
		mod:echo("Usage: /ec_addtime <minutes>   e.g. /ec_addtime 30")

		return
	end

	mod.Difficulty.add_minutes(amount)
	mod.Difficulty.print_status()
end)

mod:command("ec_setwave", "Risk of Rats (debug, host): ec_setwave <n>. Sets how many waves count as cleared for scaling.", function (waves)
	if not mod.Util.is_server() then
		mod:echo("Only the host can change scaling.")

		return
	end

	local amount = tonumber(waves)

	if not amount then
		mod:echo("Usage: /ec_setwave <n>   e.g. /ec_setwave 8")

		return
	end

	mod.Difficulty.set_waves_completed(amount)
	mod.Difficulty.print_status()
end)

mod:info("Risk of Rats v%s loaded (network fingerprint %s)", mod.VERSION, mod.Lookups.fingerprint())
