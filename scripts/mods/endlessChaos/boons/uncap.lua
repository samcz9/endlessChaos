-- Runs on: ALL (deterministic). Adjusts how often boons can stack and which ones drops can roll.
--
-- Vanilla copies each template's max_amount into the runtime table DeusPowerUps[rarity][name]
-- when the settings load, so editing only DeusPowerUpTemplates afterwards does not affect rolls.
-- Caps are written to both tables; availability goes on DeusPowerUps.
local mod = get_mod("endlessChaos")

local Uncap = {}

Uncap.STATS_AVAILABILITY = "risk_of_rats_stats"

-- How many copies of each boon a player may own (vanilla max_amount is 1 or 2). Enforced by the
-- reroll in boons/grant.lua. Stats whose negative values add up past -100% stay below that:
-- 4 x -0.2 cooldown = -80%, 2 x -0.3 block cost = -60%.
-- Milestone 3 replaces these with real uncapping plus diminishing returns.
local MAX_AMOUNT = {
	attack_speed = 20,
	stamina = 10,
	push_block_arc = 2,
	crit_chance = 10,
	ability_cooldown_reduction = 4,
	crit_boost = 20,
	health = 10,
	block_cost = 2,
	movespeed = 40,
}

-- Stat boons that "stats" drops can roll (vanilla only grants these from map nodes).
local STAT_POWER_UPS = {
	"attack_speed",
	"stamina",
	"crit_chance",
	"push_block_arc",
	"ability_cooldown_reduction",
	"crit_boost",
	"health",
	"block_cost",
	"movespeed",
	"revive_speed",
	"fatigue_regen",
}

local function set_max_amounts()
	for name, max_amount in pairs(MAX_AMOUNT) do
		local found = false

		-- DeusRunController:reached_max_power_ups (used by grant.lua and the chest/shop UI)
		-- reads the template; the roll filter reads the runtime copy. Keep both in sync.
		local template = DeusPowerUpTemplates[name]

		if template then
			template.max_amount = max_amount
		end

		for _, power_ups in pairs(DeusPowerUps) do
			local power_up = power_ups[name]

			if power_up then
				power_up.max_amount = max_amount
				found = true
			end
		end

		if not found then
			mod:warning("max_amount: unknown power-up '%s'", name)
		end
	end
end

local function add_stats_availability()
	-- Add a key; never replace the vanilla table.
	DeusPowerUpAvailabilityTypes[Uncap.STATS_AVAILABILITY] = Uncap.STATS_AVAILABILITY

	local rare_power_ups = DeusPowerUps.rare

	for _, name in ipairs(STAT_POWER_UPS) do
		local power_up = rare_power_ups and rare_power_ups[name]

		if power_up then
			-- Copy before appending so vanilla's DeusPowerUpRarityPool entry stays untouched.
			local availability = table.clone(power_up.availability or {})

			if not table.contains(availability, Uncap.STATS_AVAILABILITY) then
				availability[#availability + 1] = Uncap.STATS_AVAILABILITY
			end

			power_up.availability = availability
		else
			mod:warning("stats availability: unknown rare power-up '%s'", name)
		end
	end
end

function Uncap.init()
	set_max_amounts()
	add_stats_availability()
end

return Uncap
