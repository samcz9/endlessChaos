-- Runs on: HOST (authoritative). Clients only keep the last value the host broadcast, for display.
--
-- One number drives enemy scaling, RoR2 style:
--   coeff = (1 + time_factor[difficulty] * minutes_in_arena) * WAVE_FACTOR ^ waves_completed
-- enemy_scaling.lua turns it into health and damage multipliers for each spawned enemy.
local mod = get_mod("endlessChaos")

local Difficulty = {}

-- Coefficient growth per minute, by difficulty (Recruit ... Cataclysm 3). Tune here.
local TIME_FACTOR = {
	normal = 0.03,
	hard = 0.04,
	harder = 0.05,
	hardest = 0.06,
	cataclysm = 0.07,
	cataclysm_2 = 0.075,
	cataclysm_3 = 0.08,
}
local DEFAULT_TIME_FACTOR = 0.05

-- Extra multiplier for every plaza wave cleared.
local WAVE_FACTOR = 1.1

-- How much of the coefficient goes into each stat: mult = 1 + weight * (coeff - 1).
local HEALTH_WEIGHT = 1
local DAMAGE_WEIGHT = 0.5

-- Keeps the math finite (1.1 ^ n overflows to inf past ~7,400 waves, which would make enemies
-- immune through the damage_taken overflow).
local MAX_COEFFICIENT = 10000
local MAX_WAVES = 500

local BROADCAST_INTERVAL = 2

-- Host state, reset whenever a level loads.
local _arena_start_t = nil
local _bonus_minutes = 0
local _waves_completed = 0
local _last_broadcast_t = -math.huge

-- Client state: last values from the host.
local _client_view = nil

local function game_time()
	local time_manager = Managers.time

	return time_manager and time_manager:has_timer("game") and time_manager:time("game") or nil
end

local function time_factor()
	local difficulty_manager = Managers.state.difficulty
	local difficulty = difficulty_manager and difficulty_manager:get_difficulty()

	return TIME_FACTOR[difficulty] or DEFAULT_TIME_FACTOR
end

local function reset()
	_arena_start_t = nil
	_bonus_minutes = 0
	_waves_completed = 0
	_last_broadcast_t = -math.huge
	_client_view = nil
end

-- Host only. Minutes since the arena started, plus any debug offset.
function Difficulty.minutes()
	local t = game_time()

	if not _arena_start_t or not t then
		return _bonus_minutes
	end

	return math.max(t - _arena_start_t, 0) / 60 + _bonus_minutes
end

function Difficulty.waves_completed()
	return _waves_completed
end

-- Host only.
function Difficulty.coefficient()
	local coeff = (1 + time_factor() * Difficulty.minutes()) * WAVE_FACTOR ^ _waves_completed

	return math.min(coeff, MAX_COEFFICIENT)
end

function Difficulty.multipliers_for(coeff)
	local health_mult = 1 + HEALTH_WEIGHT * (coeff - 1)
	local damage_mult = 1 + DAMAGE_WEIGHT * (coeff - 1)

	return health_mult, damage_mult
end

-- Host only. Returns health_mult, damage_mult for an enemy spawning right now.
function Difficulty.multipliers()
	return Difficulty.multipliers_for(Difficulty.coefficient())
end

-- Debug: push the clock forward to test late-game scaling quickly.
function Difficulty.add_minutes(minutes)
	_bonus_minutes = math.max(_bonus_minutes + minutes, 0)
end

-- Debug: set the cleared-wave count directly.
function Difficulty.set_waves_completed(waves)
	_waves_completed = math.min(math.max(math.floor(waves), 0), MAX_WAVES)
end

-- ##### Network (display only) ###############################################################

mod:network_register("ec_coeff", function (sender, coeff, minutes, waves)
	if mod.Util.is_server() then
		return
	end

	_client_view = {
		coeff = coeff,
		minutes = minutes,
		waves = waves,
	}
end)

-- Client: what the host last reported, or nil.
function Difficulty.client_view()
	return _client_view
end

-- ##### Lifecycle ############################################################################

function Difficulty.update(dt)
	if not mod.Util.is_server() then
		return
	end

	if not mod.Util.in_endless_arena() then
		if _arena_start_t then
			reset()
		end

		return
	end

	local t = game_time()

	if not t then
		return
	end

	if not _arena_start_t then
		_arena_start_t = t
	end

	if t - _last_broadcast_t >= BROADCAST_INTERVAL then
		_last_broadcast_t = t

		mod:network_send("ec_coeff", "others", Difficulty.coefficient(), Difficulty.minutes(), _waves_completed)
	end
end

function Difficulty.on_game_state_changed(status, state_name)
	if state_name == "StateLoading" and status == "enter" then
		reset()
	end
end

function Difficulty.init()
	-- The plaza blueprints end every wave with a "wave_N_complete" flow event (run by the
	-- terror event on the host).
	mod:hook_safe("ConflictDirector", "level_flow_event", function (self, event_name)
		if not mod.Util.is_server() or not mod.Util.in_endless_arena() or type(event_name) ~= "string" then
			return
		end

		local wave = tonumber(string.match(event_name, "^wave_(%d+)_complete$"))

		if wave and wave > _waves_completed then
			_waves_completed = wave

			mod:info("wave %d complete, coefficient now %.2f", wave, Difficulty.coefficient())
		end
	end)
end

-- ##### Debug output #########################################################################

local function print_network_limits()
	local constants = rawget(_G, "NetworkConstants")

	if not constants then
		return
	end

	for _, name in ipairs({ "health", "damage", "damage_hotjoin_sync" }) do
		local info = constants[name]

		if info then
			mod:echo("  NetworkConstants.%s: %s .. %s", name, tostring(info.min), tostring(info.max))
		end
	end
end

function Difficulty.print_status()
	local coeff, minutes, waves

	if mod.Util.is_server() then
		if not mod.Util.in_endless_arena() then
			mod:echo("Not in the Risk of Rats arena; enemy scaling is inactive.")
			print_network_limits()

			return
		end

		coeff, minutes, waves = Difficulty.coefficient(), Difficulty.minutes(), _waves_completed
	else
		local view = _client_view

		if not view then
			mod:echo("No scaling data from the host yet.")
			print_network_limits()

			return
		end

		coeff, minutes, waves = view.coeff, view.minutes, view.waves
	end

	local health_mult, damage_mult = Difficulty.multipliers_for(coeff)

	mod:echo("Scaling: coefficient %.2f (%.1f min, %d waves) -> enemy health x%.2f, damage x%.2f", coeff, minutes, waves, health_mult, damage_mult)
	print_network_limits()
end

return Difficulty
