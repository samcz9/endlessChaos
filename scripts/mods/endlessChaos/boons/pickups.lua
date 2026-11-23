-- Runs on: ALL (deterministic registration) + OWNER (on_pick_up_func grant).
-- Boon drop pickups ("loot dice"). One pickup per tier.
--
-- Note on on_pick_up_func: the pickup interaction runs on EVERY peer (remote copies get
-- is_husk = true). The boon must only be granted on the machine of the human who picked it up,
-- otherwise every player gets a boon whenever anyone grabs a die.
local mod = get_mod("endlessChaos")

local Pickups = {}

Pickups.TIERS = {
	"stats",
	"rare",
	"exotic",
	"unique",
}

function Pickups.pickup_name(tier)
	return "endless_chaos_buff_pickup_" .. tier
end

local function can_spawn_func(params, is_debug_spawn)
	-- Never let random level pickup spawning (or anything else) place these outside our arena.
	return is_debug_spawn or mod.Util.in_endless_arena()
end

local function make_on_pick_up_func(tier)
	return function (world, interactor_unit, is_server, interactable_unit, is_husk)
		if is_husk then
			return
		end

		local owner = Managers.player:owner(interactor_unit)

		if not owner or owner.remote or owner.bot_player then
			return
		end

		mod.Grant.grant_random_boon(tier)
	end
end

local function make_pickup_settings(tier)
	local name = Pickups.pickup_name(tier)

	return {
		only_once = true,
		hide_on_pickup = true,
		disallow_bot_pickup = true,
		type = "custom_buff",
		pickup_sound_event = "hud_pickup_loot_die",
		debug_pickup_category = "special",
		spawn_weighting = 1e-06,
		unit_name = "units/props/dice_bowl/pup_loot_die",
		local_pickup_sound = true,
		item_name = name,
		hud_description = name .. "_hud_desc",
		can_spawn_func = can_spawn_func,
		on_pick_up_func = make_on_pick_up_func(tier),
	}
end

function Pickups.init()
	-- Only AllPickups (not the Pickups.<category> tables), so level pickup spawners never roll
	-- these as random loot. Registration order is the TIERS array: deterministic lookup indices.
	for _, tier in ipairs(Pickups.TIERS) do
		local name = Pickups.pickup_name(tier)

		AllPickups[name] = make_pickup_settings(tier)

		mod.Lookups.add("pickup_names", name)
	end
end

return Pickups
