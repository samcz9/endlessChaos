local mod = get_mod("endlessChaos")
require("scripts/managers/game_mode/mechanisms/deus_generate_graph")
require("scripts/helpers/deus_gen_utils")
require("scripts/settings/dlcs/morris/deus_map_populate_settings")
require("scripts/managers/game_mode/mechanisms/deus_base_graph_generator")
require("scripts/managers/game_mode/mechanisms/deus_layout_base_graph")
require("scripts/managers/game_mode/mechanisms/deus_populate_graph")


local VERSION = "0.0.4v"
local base_graphs = require("scripts/settings/dlcs/morris/deus_map_baked_base_graphs")
local power_up_attribute_adjustments = mod:dofile("scripts/mods/endlessChaos/power_up_customizations")

local _language_id = Application.user_setting("language_id")
local localizations = mod:dofile("scripts/mods/endlessChaos/endlessChaos_localization")

mod._quick_localize = function (self, text_id)
    local mod_localization_table = localizations
    if mod_localization_table then
        local text_translations = mod_localization_table[text_id]
        if text_translations then
            return text_translations[_language_id] or text_translations["en"]
        end
    end
end

mod:hook("Localize", function(func, text_id)
    local str = mod:_quick_localize(text_id)
    if str then return str end
    return func(text_id)
end)

base_graphs.journey_endless_chaos = {
	[0] = {
		start = {
			layout_y = 0.4549130485552151,
			name = "start",
			type = "START",
			connected_to = 2,
			layout_x = 0,
			next = {
				[1.0] = "final",
			},
			prev = {}
		},
		final = {
			name = "final",
			type = "ARENA",
			layout_y = 0.4382208721337627,
			layout_x = 0.12872723028946012,
			prev = {
				"start",
			},
			next = {}
		},
	}
}

-- Your mod code goes here.
-- https://vmf-docs.verminti.de


-- important globals -- 
mod.difficulty = nil
mod.vanilla_breed_health = {}
mod.vanilla_breed_walk_speed = {}
mod.vanilla_breed_run_speed = {}
mod.vanilla_breed_stagger_resist = {}

mod.loot_tables = {}
mod.terror_event = mod:dofile("scripts/mods/endlessChaos/endlessChaosPlazaEvent")
mod.curses = {
	nurgle = {
		"curse_corrupted_flesh",
		"curse_rotten_miasma"
	},
	tzeentch = {
		"curse_change_of_tzeentch",
		"curse_bolt_of_change"
	},
	khorne = {
		"curse_skulls_of_fury",
		"curse_khorne_champions"
	},
	slaanesh = {
		"curse_empathy"
	}
}

local Breeds = Breeds
local Managers = Managers

local theme_packages_lookup = {
	wastes = "resource_packages/levels/dlcs/morris/wastes_common",
	tzeentch = "resource_packages/levels/dlcs/morris/tzeentch_common",
	nurgle = "resource_packages/levels/dlcs/morris/nurgle_common",
	slaanesh = "resource_packages/levels/dlcs/morris/slaanesh_common",
	khorne = "resource_packages/levels/dlcs/morris/khorne_common"
}

function mod:get_journey_name()
	return "journey_endless_chaos"
end

mod:hook(DeusMechanism, "get_loading_tip", function (func, self)
	if self._deus_run_controller and self._deus_run_controller:get_journey_name() == mod:get_journey_name() then
		return "risk_of_rats_desc"
	end
	local loading_tips_file = DLCSettings.morris.loading_tips_file
	local loading_tips = local_require(loading_tips_file)
	local theme = self:get_current_node_theme()
	local themed_tips = loading_tips[theme] or loading_tips.general

	if self._state == MAP_STATE then
		themed_tips = loading_tips.general
	end

	local random_index = math.random(1, #themed_tips)
	local loading_tip = themed_tips[random_index]

	return loading_tip
end)


-- SYSTEM CLASS --
EndlessChaosMechanism = class(EndlessChaosMechanism)
EndlessChaosMechanism.name = "Risk of Rats"
EndlessChaosMechanism.init = function(self, run_controller, active_monsters, active_mutators, active_arena, difficulty, risk_of_rats_active, start_timer)
	self._run_controller = run_controller
	self._active_monsters = active_monsters
	self._active_mutators = active_mutators
	self._active_arena = active_arena
	self._difficulty = difficulty
	self._risk_of_rats_active = risk_of_rats_active
	self._start_timer = start_timer
end

function mod:create_journeys()
	NewJourneySettings = {}
	NewJourneySettings.journey_endless_chaos = {
		description = "journey_endless_chaos_desc",
		level_image = "morris_level_icon_04",
		display_name = "journey_endless_chaos_name",
		video_settings = {
			material_name = "video_default",
			resource = "video/area_videos/morris/area_video_morris"
		}
	}
	DeusJourneySettings = DeusJourneySettings
	if DeusJourneySettings[mod:get_journey_name()] then
		return
	end
	DeusJourneySettings.journey_endless_chaos = {
		description = "journey_endless_chaos_desc",
		level_image = "morris_level_icon_04",
		display_name = "journey_endless_chaos_name",
		video_settings = {
			material_name = "video_default",
			resource = "video/area_videos/morris/area_video_morris"
		}
	}
	local journey_index = #NetworkLookup.deus_journeys + 1
	NetworkLookup.deus_journeys[journey_index] = mod:get_journey_name()
	NetworkLookup.deus_journeys[mod:get_journey_name()] = journey_index

	for journey_name, settings in pairs(NewJourneySettings) do
		local default_settings = {
			player_aux_bus_name = "environment_reverb_outside",
			ambient_sound_event = "silent_default_world_sound",
			knocked_down_setting = "knocked_down",
			disable_percentage_completed = true,
			environment_state = "exterior",
			game_mode = "deus",
			unlockable = true,
			loading_bg_image = "loading_screen_1",
			load_no_enemies = true,
			no_terror_events = true,
			loading_ui_package_name = "morris/deus_loading_screen_1",
			conflict_settings = "disabled",
			level_name = "levels/honduras_dlcs/morris/map_scene/world",
			no_nav_mesh = true,
			source_aux_bus_name = "environment_reverb_outside_source",
			packages = {
				"resource_packages/levels/dlcs/morris/map"
			},
			level_particle_effects = {},
			level_screen_effects = {},
			locations = {}
		}

		table.merge(default_settings, settings)
		LevelSettings[journey_name] = default_settings
		local mission_index = #NetworkLookup.mission_ids + 1
		NetworkLookup.mission_ids[mission_index] = journey_name
		NetworkLookup.mission_ids[journey_name] = mission_index
	end
end

function mod:get_base_level_endless_chaos()
	return {
		display_name = "level_name_plaza",
		player_aux_bus_name = "environment_reverb_outside",
		environment_state = "exterior",
		ambient_sound_event = "silent_default_world_sound",
		check_no_spawn_volumes_for_special_spawning = true,
		loading_ui_package_name = "loading_screen_21",
		use_mini_patrols = false,
		boss_spawning_method = "hand_placed",
		default_surface_material = "stone",
		conflict_settings = "challenge_level",
		knocked_down_setting = "knocked_down",
		base_level_name = "arena_endless_chaos",
		source_aux_bus_name = "environment_reverb_outside_source",
		disable_twitch_game_mode = true,
		disable_percentage_completed = true,
		packages = {
			"resource_packages/levels/dlcs/holly/plaza",
			"resource_packages/dlcs/morris_ingame",
			"units/props/inn/deus/deus_chest_01"

		},
		level_particle_effects = {},
		level_screen_effects = {},
		pickup_settings = {
			default = {
				primary = {
					deus_weapon_chest = 0,
					grenades = 6,
					deus_soft_currency = 20,
					potions = 0,
					ammo = 7,
					deus_potions = 8,
					deus_cursed_chest = 0,
					healing = {
						first_aid_kit = 3,
						healing_draught = 3
					},
					level_events = {
						explosive_barrel = 2,
						lamp_oil = 2
					}
				},
				secondary = {
					ammo = 4,
					deus_potions = 10,
					potions = 0,
					grenades = 6,
					healing = 2
				}
			},
			normal = {
				primary = {
					deus_weapon_chest = 0,
					grenades = 9,
					deus_soft_currency = 20,
					potions = 0,
					ammo = 10,
					deus_potions = 10,
					deus_cursed_chest = 0,
					healing = {
						first_aid_kit = 4,
						healing_draught = 4
					},
					level_events = {
						explosive_barrel = 4,
						lamp_oil = 4
					}
				},
				secondary = {
					ammo = 6,
					deus_potions = 8,
					potions = 0,
					grenades = 9,
					healing = 3
				}
			}
		},
		loading_screen_wwise_events = {
			"nfl_loading_screen_plaza_01",
			"nfl_loading_screen_plaza_02"
		},
		locations = {
			"dlc1_2_location_survival_magnus_plaza",
			"dlc1_2_location_survival_magnus_tower",
			"dlc1_2_location_survival_magnus_wall",
			"dlc1_2_location_survival_magnus_market",
			"dlc1_2_location_survival_magnus_gate"
		},
		paths = {
			1
		},
		themes = {
			DEUS_THEME_TYPES.KHORNE,
			DEUS_THEME_TYPES.NURGLE,
			DEUS_THEME_TYPES.SLAANESH,
			DEUS_THEME_TYPES.TZEENTCH,
			DEUS_THEME_TYPES.WASTES
		}
	}
end

function mod:create_journey_level_settings()
	NewLevelSettings = {}
	NewLevelSettings.arena_endless_chaos = mod:get_base_level_endless_chaos()

	for level_key, settings in pairs(NewLevelSettings) do
		for _, theme_name in ipairs(settings.themes) do
			for _, path in ipairs(settings.paths) do
				local settings_clone = table.clone(settings)
				local permutation_name = theme_name .. "_path" .. path
				local permutation_key = level_key .. "_" .. permutation_name
				settings_clone.level_name = "levels/honduras_dlcs/holly/plaza/world"
				settings_clone.theme = theme_name
				settings_clone.display_name = level_key .. "_title"
				settings_clone.description_text = level_key .. "_desc"
				settings_clone.level_key = permutation_key
				mod.current_journey_level_name = permutation_key
				settings_clone.level_image = "level_icon_weaves"
				settings_clone.loading_ui_package_name = settings_clone.loading_ui_package_name or "morris/deus_loading_screen_1"
				settings_clone.music_won_state = settings_clone.music_won_state
				settings_clone.game_mode = "deus"
				settings_clone.mechanism = "deus"
				settings_clone.disable_percentage_completed = true
				settings_clone.allowed_locked_director_functions = {
					beastmen = true
				}
				settings_clone.disable_quickplay = true
				local base_level_name = settings.base_level_name
				local packages = settings_clone.packages
				packages[#packages + 1] = theme_packages_lookup[theme_name]
				LevelSettings[permutation_key] = settings_clone
				local level_setting_index = #NetworkLookup.level_keys + 1
				NetworkLookup.level_keys[level_setting_index] = permutation_key
				NetworkLookup.level_keys[permutation_key] = level_setting_index
				local mission_index = #NetworkLookup.mission_ids + 1
				NetworkLookup.mission_ids[mission_index] = permutation_key
				NetworkLookup.mission_ids[permutation_key] = mission_index
				TerrorEventBlueprints[permutation_key] = mod.terror_event
			end
		end
	end
end

function mod:create_journey_map_settings()
	local all_curses = {
		nurgle = {
			"curse_corrupted_flesh"
		},
		tzeentch = {
			"curse_change_of_tzeentch"
		},
		khorne = {
			"curse_skulls_of_fury",
			"curse_khorne_champions",
			"curse_blood_storm"
		},
		slaanesh = {
			"curse_empathy",
			"curse_abundance_of_life"
		}
	}
	local default_config = {
		CURSES_HOT_SPOT_MAX_RANGE = 0.3,
		CURSES_HOT_SPOTS_MAX_COUNT = 1,
		CURSES_HOT_SPOT_MIN_RANGE = 0.2,
		CURSES_MIN_PROGRESS = 0.35,
		CURSES_HOT_SPOTS_MIN_COUNT = 1,
		MINOR_MODIFIABLE_MIN_PROGRESS = -0.1,
		POWER_UP_LOOKAHEAD = 2,
		MINOR_MODIFIABLE_NODE_CHANCE = 1,
		AVAILABLE_GODS = {
			"nurgle",
			"tzeentch",
			"khorne",
			"slaanesh"
		},
		AVAILABLE_CURSES = {
			SIGNATURE = all_curses,
			TRAVEL = all_curses,
			ARENA = all_curses
		},
		CURSEABLE_NODE_TYPES = {
			"SIGNATURE",
			"TRAVEL"
		},
		MUTATORS = {
			SIGNATURE = {},
			TRAVEL = {},
			SHOP = {},
			ARENA = {},
			START = {}
		},
		AVAILABLE_MINOR_MODIFIERS = {
			{
				"deus_less_monsters",
				"deus_more_hordes"
			},
			{
				"deus_less_monsters",
				"deus_more_specials"
			},
			{
				"deus_less_monsters",
				"deus_more_roamers"
			},
			{
				"deus_less_monsters",
				"deus_more_elites"
			},
			{
				"deus_less_specials",
				"deus_more_hordes"
			},
			{
				"deus_less_specials",
				"deus_more_monsters"
			},
			{
				"deus_less_specials",
				"deus_more_roamers"
			},
			{
				"deus_less_specials",
				"deus_more_elites"
			},
			{
				"deus_less_hordes",
				"deus_more_specials"
			},
			{
				"deus_less_hordes",
				"deus_more_monsters"
			},
			{
				"deus_less_hordes",
				"deus_more_roamers"
			},
			{
				"deus_less_hordes",
				"deus_more_elites"
			},
			{
				"deus_less_roamers",
				"deus_more_specials"
			},
			{
				"deus_less_roamers",
				"deus_more_monsters"
			},
			{
				"deus_less_roamers",
				"deus_more_hordes"
			},
			{
				"deus_less_roamers",
				"deus_more_elites"
			},
			{
				"deus_less_elites",
				"deus_more_specials"
			},
			{
				"deus_less_elites",
				"deus_more_monsters"
			},
			{
				"deus_less_elites",
				"deus_more_hordes"
			},
			{
				"deus_less_elites",
				"deus_more_roamers"
			},
			{
				"increased_deus_potions"
			}
		},
		MINOR_MODIFIABLE_NODE_TYPES = {
			"SIGNATURE",
			"TRAVEL"
		},
		MINOR_MODIFIER_VALIDATORS = {
			"prevent_modifier_on_curse_abundance_of_life"
		},
		DEUS_CHEST_GRANTABLE_NODE_TYPES = {
			"SIGNATURE",
			"TRAVEL"
		},
		CONFLICT_DIRECTORS = {
			default = {
				"risk_of_rats"
			}
		},
		LEVEL_ALIAS = {
			sig_snare_wastes_path3 = "sig_snare_c_wastes_path1",
			sig_snare_wastes_path2 = "sig_snare_b_wastes_path1",
			sig_snare_nurgle_path1 = "sig_snare_a_nurgle_path1",
			sig_snare_wastes_path1 = "sig_snare_a_wastes_path1",
			sig_snare_nurgle_path5 = "sig_snare_e_nurgle_path1",
			sig_snare_khorne_path2 = "sig_snare_b_khorne_path1",
			sig_snare_slaanesh_path5 = "sig_snare_e_slaanesh_path1",
			sig_snare_tzeentch_path5 = "sig_snare_e_tzeentch_path1",
			sig_snare_nurgle_path3 = "sig_snare_c_nurgle_path1",
			sig_snare_slaanesh_path1 = "sig_snare_a_slaanesh_path1",
			sig_snare_nurgle_path4 = "sig_snare_d_nurgle_path1",
			sig_snare_khorne_path3 = "sig_snare_c_khorne_path1",
			sig_snare_slaanesh_path2 = "sig_snare_b_slaanesh_path1",
			sig_snare_tzeentch_path3 = "sig_snare_c_tzeentch_path1",
			sig_snare_nurgle_path2 = "sig_snare_b_nurgle_path1",
			sig_snare_slaanesh_path3 = "sig_snare_c_slaanesh_path1",
			sig_snare_slaanesh_path4 = "sig_snare_d_slaanesh_path1",
			sig_snare_khorne_path4 = "sig_snare_d_khorne_path1",
			sig_snare_wastes_path5 = "sig_snare_e_wastes_path1",
			sig_snare_tzeentch_path2 = "sig_snare_b_tzeentch_path1",
			sig_snare_khorne_path5 = "sig_snare_e_khorne_path1",
			sig_snare_tzeentch_path1 = "sig_snare_a_tzeentch_path1",
			sig_snare_tzeentch_path4 = "sig_snare_d_tzeentch_path1",
			sig_snare_wastes_path4 = "sig_snare_d_wastes_path1",
			sig_snare_khorne_path1 = "sig_snare_a_khorne_path1"
		},
		LEVEL_AVAILABILITY = {},
		LEVEL_VALIDATIONS = {
			SIGNATURE = {
				"prevent_same_level_choice"
			},
			TRAVEL = {
				"prevent_same_level_choice"
			},
			SHOP = {
				"prevent_same_level_choice"
			},
			ARENA = {},
			START = {}
		},
		LEVEL_SHUFFLERS = {
			"lower_priority_of_already_used_levels_on_path"
		},
		LABEL_OVERRIDES = {},
		TERROR_POWER_UPS = {
			{
				"attack_speed",
				"rare"
			},
			{
				"stamina",
				"rare"
			},
			{
				"crit_chance",
				"rare"
			},
			{
				"push_block_arc",
				"rare"
			},
			{
				"ability_cooldown_reduction",
				"rare"
			},
			{
				"crit_boost",
				"rare"
			},
			{
				"health",
				"rare"
			},
			{
				"block_cost",
				"rare"
			},
			{
				"fatigue_regen",
				"rare"
			},
			{
				"movespeed",
				"rare"
			}
		}
	}

	DEUS_MAP_POPULATE_SETTINGS = {
		journey_endless_chaos = table.clone(default_config)
	}

	DEUS_MAP_POPULATE_SETTINGS.journey_endless_chaos.LEVEL_AVAILABILITY = {
		TRAVEL = {},
		SIGNATURE = {},
		ARENA = {
			arena_endless_chaos = {
				themes = {
					DEUS_THEME_TYPES.KHORNE,
					DEUS_THEME_TYPES.SLAANESH,
					DEUS_THEME_TYPES.TZEENTCH,
					DEUS_THEME_TYPES.WASTES
				},
				paths = {1}
			}
		}
	}

end

function mod:ensure_init()
	new_journey_name = mod:get_journey_name()
	journey_created = false
	for _, journey_name in ipairs(AvailableJourneyOrder) do
		if journey_name == new_journey_name then
			journey_created = true
		end
	end
	if not journey_created then
		table.insert(AvailableJourneyOrder, new_journey_name)
	end
	mod:create_journeys()
	mod:create_journey_level_settings()
	mod:create_journey_map_settings()
	mod:update_power_up_attributes(power_up_attribute_adjustments)
	
	ConflictDirectors.risk_of_rats = {
		name = "risk_of_rats",
		debug_color = "orange",
		disabled = false,
		locked_func_name = "beastmen",
		intensity = IntensitySettings.disabled,
		pacing = PacingSettings.disabled,
		boss = BossSettings.disabled,
		specials = SpecialsSettings.disabled,
		roaming = RoamingSettings.disabled,
		pack_spawning = PackSpawningSettings.disabled,
		horde = HordeSettings.challenge_level,
		description = "risk_of_rats",
		factions = {
			"beastmen",
			"skaven",
			"chaos"
		},
		contained_breeds = {}
	}
	local difficulties = Difficulties
	for i = 1, #difficulties, 1 do
		local difficulty = difficulties[i]
		local difficulty_breeds = {}

		ConflictUtils.find_conflict_director_breeds(ConflictDirectors.risk_of_rats, difficulty, difficulty_breeds)

		ConflictDirectors.risk_of_rats.contained_breeds[difficulty] = difficulty_breeds
	end

	for breed_name, breed_data in pairs(Breeds) do
		local max_health = breed_data.max_health
		if max_health then
			mod.vanilla_breed_health[breed_name] = table.clone(max_health)
		end
		if breed_data.walk_speed and breed_data.walk_speed then
			mod.vanilla_breed_walk_speed[breed_name] = breed_data.walk_speed
			mod.vanilla_breed_run_speed[breed_name] = breed_data.run_speed
 		end
		if breed_data.stagger_resistance then
			mod.vanilla_breed_stagger_resist[breed_name] = breed_data.stagger_resistance
		end
	end
	mod.loot_tables = mod:dofile("scripts/mods/endlessChaos/endless_chaos_pickup_system")
	mod:echo(ConflictDirectors.risk_of_rats.name .. " version: " .. VERSION)

end

mod.active_level = false

mod:hook_safe(TerrorEventMixer, "start_event", function(event_name, data)
	if event_name == "plaza_wave_1" then
		mod.active_level = true
		current_difficulty, current_difficulty_tweak = Managers.state.difficulty:get_difficulty()
		mod.difficulty = current_difficulty
	end
end)

-- ENEMY SCALING STUFF --
mod.difficulty_tier = {
	easy = {
		scaling = 1.05,
		tweak = 0,
		time_interval = 1
	},
	normal = {
		scaling = 1.08,
		tweak = 1,
		time_interval = 1
	},
	hard = {
		scaling = 1.1,
		tweak = 2,
		time_interval = 1
	},
	harder = {
		scaling = 1.13,
		tweak = 3,
		time_interval = 1
	},
	hardest = {
		scaling = 1.13,
		tweak = 5,
		time_interval = 1
	},
	cataclysm = {
		scaling = 1.15,
		tweak = 7,
		time_interval = 1
	},
	cataclysm_2 = {
		scaling = 1.18,
		tweak = 9,
		time_interval = 1
	},
	cataclysm_3 = {
		scaling = 1.18,
		tweak = 10,
		time_interval = 1
	}

}

mod:hook_safe(StateIngame, "on_enter", function(func, self)
	if mod.active_level then
		if mod.vanilla_breed_health then
			for breed_name, max_health in pairs(mod.vanilla_breed_health) do
				Breeds[breed_name].max_health = max_health
			end
		end
		if mod.vanilla_breed_run_speed and mod.vanilla_breed_walk_speed then
			for breed_name, walk_speed in pairs(mod.vanilla_breed_walk_speed) do
				Breeds[breed_name].walk_speed = walk_speed
			end
			for breed_name, run_speed in pairs(mod.vanilla_breed_run_speed) do
				Breeds[breed_name].run_speed = run_speed
			end

		end
		if mod.vanilla_breed_stagger_resist then
			for breed_name, stagger_resistance in pairs(mod.vanilla_breed_stagger_resist) do
				Breeds[breed_name].stagger_resistance = stagger_resistance
			end
		end
		mod.active_level = false
		mod.interval = 30
		mod.last_interval = 0
	end
end)

mod.time_started = false
mod.interval = 30
mod.scaling = 1.0
mod.last_interval = 0

mod.update = function(dt)
	if mod.active_level then
		local t = Managers.time:time("game")
		if t and t - mod.last_interval >= mod.interval * mod.difficulty_tier[mod.difficulty].time_interval then
			-- Could do t here but i like a nice number
			mod.last_interval = mod.last_interval + mod.interval * mod.difficulty_tier[mod.difficulty].time_interval
			mod:scale_enemies_with_time()
			mod:perform_random_generation(t)
		end
	end
end

local function get_scaling() 
	if mod.difficulty then
		return mod.difficulty_tier[mod.difficulty].scaling
	end
	return 1.05
end

mod:hook(DamageUtils, "calculate_damage", function(func, damage_output, target_unit, attacker_unit, hit_zone_name,
	original_power_level, boost_curve, boost_damage_multiplier, is_critical_strike, damage_profile, target_index, backstab_multiplier, damage_source)
		local dmg = func(damage_output, target_unit, attacker_unit, hit_zone_name, original_power_level,
		boost_curve, boost_damage_multiplier, is_critical_strike, damage_profile, target_index, backstab_multiplier, damage_source)
		
		if target_unit then
			breed = AiUtils.unit_breed(target_unit)
			local target_is_hero = breed and breed.is_hero
			if target_is_hero and mod.active_level then
				mod:echo(dmg)
				dmg = dmg * (get_scaling())
				mod:echo("new dmg: ")
				mod:echo(dmg)
			end
		end
		
		return dmg
end)

local function networkify_value(value, clamp)
	amount = math.clamp(value, 0, clamp)
	local decimal = amount % 1
	local rounded_decimal = math.round(decimal * 4) * 0.25

	return math.floor(amount) + rounded_decimal
end

local function scale_breeds(scaling)
	for breed_name, breed_data in pairs(Breeds) do
		if breed_data.race ~= "critter" then
			local max_health = breed_data.max_health
			if max_health then
				for i, health in ipairs(max_health) do
					max_health[i] = networkify_value(health * scaling, 8100)
				end
			end
			
			local run_speed = breed_data.run_speed
			local walk_speed = breed_data.walk_speed
			if run_speed and walk_speed then
				breed_data.walk_speed = networkify_value(walk_speed * scaling, 6)
				breed_data.run_speed = networkify_value(run_speed * scaling, 10)
			end
			local stagger_resistance = breed_data.stagger_resistance
			if stagger_resistance and not breed_data.boss then
				stagger_resistance = networkify_value(stagger_resistance, 90)
			end
			
		end
	end
end

function mod:scale_enemies_with_time()
	scale_breeds(get_scaling())
	
end

function mod:perform_random_generation(timer)
	print(t)
end

mod:hook_safe(DeusRunController, "setup_run", function(self, run_seed, difficulty, journey_name, dominant_god, initial_own_soft_currency, telemetry_id)
	self._path_graph["final"]["run_progress"] = .9999999
end)

-- POWER UP STUFF --
local AllPickups = AllPickups
local ItemMasterList = ItemMasterList

function mod:update_power_up_attributes(power_ups)
	DeusPowerUpTemplates = DeusPowerUpTemplates or {}
	for power_up_name, power_up_settings in pairs(power_ups) do
		if DeusPowerUpTemplates[power_up_name] then
			for power_up_attribute, power_up_value in pairs(power_up_settings) do
				DeusPowerUpTemplates[power_up_attribute] = power_up_value
			end
		end
	end
end

function mod:add_pickup_template(pickup_name, pickup_data)
	local pickup_already_exists = rawget(AllPickups, pickup_name)
	local item_name = pickup_name
	AllPickups[pickup_name] = pickup_data
	local index = #NetworkLookup.pickup_names + 1
	NetworkLookup.pickup_names[index] = pickup_name
    NetworkLookup.pickup_names[pickup_name] = index

	-- Add item to ItemMasterList
	ItemMasterList[item_name] = item
			
	-- Add item to NetworkLookup
	local item_name_index = #NetworkLookup.item_names + 1
	NetworkLookup.item_names[item_name_index] = item_name
	NetworkLookup.item_names[item_name] = item_name_index
end

local total_rolls = 0
local drops = 0

local function rollLootDrop(percent)
	total_rolls = total_rolls + 1
	drop = percent >= math.random(1, 1000)
	if drop then
		drops = drops + 1
		mod:echo(drops .. "/" .. total_rolls .. " drops")
	end
	return drop
end

local function should_spawn_item(loot_table)
	local rolling = true
	local should_spawn = false
	local type = nil
	while rolling do
		for k, v in pairs(loot_table) do
			should_spawn = rollLootDrop(v)
			if should_spawn then
				type = k
				rolling = false
			end
		end
		rolling = false
	end
	if type then
		return type
	end
	return false
end

local function get_spawn_chance(breed)
	if not breed or breed.critter then
		return
	end
	if breed.boss then
		return should_spawn_item(mod.loot_tables.boss)
	elseif breed.special then
		return should_spawn_item(mod.loot_tables.exotic)
	elseif breed.elite then
		return should_spawn_item(mod.loot_tables.rare)
	else
		return should_spawn_item(mod.loot_tables.stats)
	end

	return false
end 

mod:hook_safe(DeathReactions.templates.ai_default.unit, "start", function(unit)
	if mod.active_level then
		mod:pcall(function()
			local breed_killed = Unit.get_data(unit, "breed")
			if Managers.player.is_server then
				local spawn_type = get_spawn_chance(breed_killed)
				if spawn_type then
					local pickup_name = "endless_chaos_buff_pickup_" .. spawn_type
					local pickup_settings = rawget(AllPickups, pickup_name)
					if not pickup_settings then
						return mod:echo("No pickup found for: " .. pickup_name)
					end
					local spawn_method = "rpc_spawn_pickup_with_physics"
					local position = Unit.local_position(unit, 0)
					local rotation = Unit.local_rotation(unit, 0)
					local v_zero = Vector3.zero()
					Managers.state.network.network_transmit:send_rpc_server(
						spawn_method,
						NetworkLookup.pickup_names[pickup_name],
						position,
						rotation,
						NetworkLookup.pickup_spawn_types['dropped']
					)
				end
			end
		end)
	end
end)

local function get_random_buff(_deus_run_controller, tier)
	local power_up = nil
	local current_node = _deus_run_controller:get_current_node()
	local res = ""
	for i = 1, 5 do
		res = res .. string.char(math.random(97, 122))
	end
	local seed = HashUtils.fnv32_hash(res .. "_" .. current_node.weapon_pickup_seed)

	if tier == "stats" then
		power_up = _deus_run_controller:generate_random_power_ups(1, DeusPowerUpAvailabilityTypes.risk_of_rats_stats, seed)
	else
		power_up = _deus_run_controller:generate_random_power_ups(1, DeusPowerUpAvailabilityTypes.cursed_chest, seed)
	end	

	if power_up then
		return power_up[1]
	end
end

local REAL_PLAYER_LOCAL_ID = 1

local function give_power_up(_deus_run_controller, power_up, player_unit)
	local run_controller = _deus_run_controller

	run_controller:add_power_ups({
		power_up
	}, REAL_PLAYER_LOCAL_ID)

	local buff_system = Managers.state.entity:system("buff_system")
	local talent_interface = Managers.backend:get_talents_interface()
	local deus_backend = Managers.backend:get_interface("deus")
	local own_peer_id = run_controller:get_own_peer_id()

	local profile_index, career_index = run_controller:get_player_profile(own_peer_id, REAL_PLAYER_LOCAL_ID)

	DeusPowerUpUtils.activate_deus_power_up(power_up, buff_system, talent_interface, deus_backend, run_controller, player_unit, profile_index, career_index)
end

function mod:apply_buff(tier, player)
	_deus_run_controller = Managers.mechanism:game_mechanism():get_deus_run_controller()
	player_unit = player.player_unit
	power_up = get_random_buff(_deus_run_controller, tier)
	if power_up then
		give_power_up(_deus_run_controller, power_up, player_unit)
		Managers.state.event:trigger("present_rewards", {
			{
				type = "deus_power_up",
				power_up = power_up
			}
		})
	end
end

local CMD_GIVEBUFF_HELP = [[ grants named_buff]]
local function give_specific_buff(buff_name, rarity)
	local power_up = DeusPowerUpUtils.generate_specific_power_up(buff_name, rarity)
	local mechanism = Managers.mechanism:game_mechanism()
	local deus_run_controller = mechanism:get_deus_run_controller()
	local local_player = Managers.player:local_player()
	local local_player_id = local_player:local_player_id()

	deus_run_controller:add_power_ups({
		power_up
	}, local_player_id)

	local buff_system = Managers.state.entity:system("buff_system")
	local talent_interface = Managers.backend:get_talents_interface()
	local deus_backend = Managers.backend:get_interface("deus")
	local local_player_unit = local_player.player_unit
	local profile_index = local_player:profile_index()
	local career_index = local_player:career_index()
	DeusPowerUpUtils.activate_deus_power_up(power_up, buff_system, talent_interface, deus_backend, deus_run_controller, local_player_unit, profile_index, career_index)
end
mod:command("givebuff", CMD_GIVEBUFF_HELP, function()
	give_specific_buff("deus_extra_shot", "unique")
end)

mod:ensure_init()


--[[
going to want this:

if is_server then
	debug_print("[TWITCH VOTE] Spawning chaos spawn")

	local breed = Breeds.chaos_spawn
	local spawn_amount = math.floor(1 * twitch_settings.spawn_amount_multiplier)

	for i = 1, spawn_amount, 1 do
		Managers.state.conflict:spawn_one(breed, nil, nil, {
			max_health_modifier = 0.85
		})
	end
end


stats.tier 

attack_speed
crit_chance
health
stamina_recovery
block_cost_reduction
movement_speed
stamina

resetting doesn't start scaling again
]]--