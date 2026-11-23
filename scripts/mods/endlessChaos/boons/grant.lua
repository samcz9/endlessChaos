-- Runs on: OWNER (the client whose player picked up the drop).
-- Rolls a random Deus power-up for the local player and adds it through the run controller.
--
-- DeusRunController:add_power_ups does everything in one call: stores the boon in the run state,
-- activates its buff/talent on the local player unit, sends rpc_deus_add_power_ups to the host,
-- and (present = true) shows the reward popup. Do NOT also call activate_deus_power_up, or the
-- buff gets applied twice. The host re-applies stored boons on respawn (DeusSpawning).
local mod = get_mod("endlessChaos")

local Grant = {}

local MAX_ROLL_ATTEMPTS = 10

-- tier -> { availability type, preferred rarity }
local TIER_SETTINGS = {
	stats = {
		availability = "risk_of_rats_stats",
		rarity = "rare",
	},
	rare = {
		availability = "cursed_chest",
		rarity = "rare",
	},
	exotic = {
		availability = "cursed_chest",
		rarity = "exotic",
	},
	unique = {
		availability = "cursed_chest",
		rarity = "unique",
	},
}

local function roll_power_up(run_controller, local_player_id, tier_settings)
	local peer_id = run_controller:get_own_peer_id()
	local node = run_controller:get_current_node()
	local node_seed = node and node.system_seeds and node.system_seeds.power_ups or 0
	local seed = HashUtils.fnv32_hash(tostring(math.random_seed()) .. "_" .. tostring(peer_id) .. "_" .. tostring(node_seed))
	local profile_index, career_index = run_controller:get_player_profile(peer_id, local_player_id)
	local profile = SPProfiles[profile_index]
	local career = profile and profile.careers[career_index]

	if not career then
		return nil
	end

	local existing_power_ups = run_controller:get_player_power_ups(peer_id, local_player_id)
	local difficulty = run_controller:get_run_difficulty()
	local run_progress = node and node.run_progress or 0
	local availability = DeusPowerUpAvailabilityTypes[tier_settings.availability] or tier_settings.availability

	-- With a forced rarity, vanilla fasserts when the whole pool is exhausted; fall back to an
	-- unforced roll (which returns nothing instead of erroring).
	local ok, _, power_ups = pcall(DeusPowerUpUtils.generate_random_power_ups, seed, 1, existing_power_ups, difficulty, run_progress, availability, career.name, tier_settings.rarity)

	if not ok or not power_ups or not power_ups[1] then
		_, power_ups = DeusPowerUpUtils.generate_random_power_ups(seed, 1, existing_power_ups, difficulty, run_progress, availability, career.name)
	end

	return power_ups and power_ups[1]
end

function Grant.grant_random_boon(tier)
	local run_controller = mod.Util.get_run_controller()
	local local_player = mod.Util.local_human_player()

	if not run_controller or not local_player then
		return
	end

	local tier_settings = TIER_SETTINGS[tier] or TIER_SETTINGS.stats
	local local_player_id = local_player:local_player_id()
	local peer_id = run_controller:get_own_peer_id()
	local power_up

	-- Vanilla's own max_amount filter counts from a set, so it only works for max_amount = 1.
	-- Reroll until we get a boon that isn't at its cap (reached_max_power_ups counts correctly).
	for _ = 1, MAX_ROLL_ATTEMPTS do
		local candidate = roll_power_up(run_controller, local_player_id, tier_settings)

		if not candidate then
			break
		end

		if not run_controller:reached_max_power_ups(peer_id, candidate.name) then
			power_up = candidate

			break
		end
	end

	if not power_up then
		mod:echo("[Risk of Rats] No boons left to roll for tier '%s'.", tostring(tier))

		return
	end

	local present = true

	run_controller:add_power_ups({
		power_up,
	}, local_player_id, present)
end

-- Debug helper: grants a specific boon to the local player. Validates input first so a typo
-- can't crash the game.
function Grant.grant_specific_boon(name, rarity)
	local run_controller = mod.Util.get_run_controller()
	local local_player = mod.Util.local_human_player()

	if not run_controller or not local_player then
		mod:echo("Not in a Chaos Wastes run.")

		return
	end

	local by_rarity = DeusPowerUps[rarity]

	if not by_rarity or not by_rarity[name] then
		mod:echo("Unknown boon '%s' with rarity '%s'.", tostring(name), tostring(rarity))

		return
	end

	local power_up = DeusPowerUpUtils.generate_specific_power_up(name, rarity)

	run_controller:add_power_ups({
		power_up,
	}, local_player:local_player_id(), true)
end

return Grant
