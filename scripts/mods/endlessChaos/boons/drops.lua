-- Runs on: HOST. Rolls boon drops when enemies die in the Risk of Rats arena and spawns the pickup.
local mod = get_mod("endlessChaos")

local Drops = {}

-- Chance per tier, in 1/1000. Tiers are checked rarest first, and the first hit wins.
local LOOT_TABLES = {
	boss = {
		exotic = 1000,
	},
	special = {
		unique = 50,
		exotic = 10,
		rare = 100,
	},
	elite = {
		rare = 10,
		stats = 25,
	},
	trash = {
		stats = 10,
	},
}

local ROLL_ORDER = {
	"unique",
	"exotic",
	"rare",
	"stats",
}

local function loot_table_for(breed)
	if not breed or breed.critter or breed.race == "critter" then
		return nil
	end

	if breed.boss then
		return LOOT_TABLES.boss
	elseif breed.special then
		return LOOT_TABLES.special
	elseif breed.elite then
		return LOOT_TABLES.elite
	end

	return LOOT_TABLES.trash
end

function Drops.roll(breed)
	local loot_table = loot_table_for(breed)

	if not loot_table then
		return nil
	end

	for _, tier in ipairs(ROLL_ORDER) do
		local chance = loot_table[tier]

		if chance and math.random(1, 1000) <= chance then
			return tier
		end
	end

	return nil
end

function Drops.spawn(tier, position, rotation)
	local entity_manager = Managers.state.entity
	local pickup_system = entity_manager and entity_manager:system("pickup_system")

	if not pickup_system then
		return
	end

	local pickup_name = mod.Pickups.pickup_name(tier)
	local with_physics = true
	local spawn_type = "dropped"

	-- Async: makes sure the pickup's unit package is loaded (and synced to clients) first.
	pickup_system:spawn_pickup_async(pickup_name, position, rotation, with_physics, spawn_type)
end

local function on_ai_killed(killed_unit, death_data)
	-- ai_killed also fires on clients (husk deaths); only the host rolls and spawns.
	if not mod.Util.is_server() or not mod.Util.in_endless_arena() then
		return
	end

	-- A peer without a matching build would crash on an unknown pickup id.
	if not mod.Net.all_peers_ready() then
		return
	end

	local breed = death_data and death_data.breed or Unit.get_data(killed_unit, "breed")
	local tier = Drops.roll(breed)

	if tier then
		Drops.spawn(tier, Unit.local_position(killed_unit, 0), Unit.local_rotation(killed_unit, 0))
	end
end

function Drops.init()
	mod:hook_safe("GameModeManager", "ai_killed", function (self, killed_unit, killer_unit, death_data, killing_blow)
		on_ai_killed(killed_unit, death_data)
	end)
end

return Drops
