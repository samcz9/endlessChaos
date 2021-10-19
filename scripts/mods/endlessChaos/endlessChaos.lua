local mod = get_mod("endlessChaos")
require("scripts/managers/game_mode/mechanisms/deus_generate_graph")
require("scripts/helpers/deus_gen_utils")
require("scripts/settings/dlcs/morris/deus_map_populate_settings")
require("scripts/managers/game_mode/mechanisms/deus_base_graph_generator")
require("scripts/managers/game_mode/mechanisms/deus_layout_base_graph")
require("scripts/managers/game_mode/mechanisms/deus_populate_graph")

local base_graphs = require("scripts/settings/dlcs/morris/deus_map_baked_base_graphs")

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

mod.difficulty_tables = {}
mod.vanilla_breed_health = {}
mod.current_journey_level_name = nil

local Breeds = Breeds
local Managers = Managers
local MechanismManager = MechanismManager

local theme_packages_lookup = {
	wastes = "resource_packages/levels/dlcs/morris/wastes_common",
	tzeentch = "resource_packages/levels/dlcs/morris/tzeentch_common",
	nurgle = "resource_packages/levels/dlcs/morris/nurgle_common",
	slaanesh = "resource_packages/levels/dlcs/morris/slaanesh_common",
	khorne = "resource_packages/levels/dlcs/morris/khorne_common"
}

-- TIMER AND SCALING STUFF
mod.time_started = false
mod.interval = 60
mod.scaling = 1.0
mod.last_interval = 0
-- Default Difficulty
mod.difficulty_tier = "normal"

function mod:get_journey_name()
	return "journey_endless_chaos"
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
	-- can't figure out which way to add this
	DeusJourneySettings = DeusJourneySettings
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
				local mission_index = #NetworkLookup.mission_ids + 1
				NetworkLookup.mission_ids[mission_index] = permutation_key
				NetworkLookup.mission_ids[permutation_key] = mission_index
			end
		end
	end
end

function mod:create_journey_map_settings()
	local all_curses = {
		nurgle = {
			"curse_corrupted_flesh",
			"curse_rotten_miasma",
			"curse_skulking_sorcerer"
		},
		tzeentch = {
			"curse_change_of_tzeentch",
			"curse_bolt_of_change",
			"curse_egg_of_tzeentch"
		},
		khorne = {
			"curse_skulls_of_fury",
			"curse_khorne_champions",
			"curse_blood_storm"
		},
		slaanesh = {
			"curse_greed_pinata",
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
			ARENA = {
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
		},
		CURSEABLE_NODE_TYPES = {
			"SIGNATURE",
			"TRAVEL",
			"ARENA"
		},
		MUTATORS = {
			SIGNATURE = {},
			TRAVEL = {},
			SHOP = {},
			ARENA = {},
			START = {}
		},
		AVAILABLE_MINOR_MODIFIERS = {
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
				"deus_skaven_chaos",
				"deus_skaven_beastmen"
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
					DEUS_THEME_TYPES.NURGLE,
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
	mod:echo("ensuring config for endlessChaos")
	journey_name = mod:get_journey_name()
	table.insert(AvailableJourneyOrder, journey_name)
	mod:create_journeys()
	mod:create_journey_level_settings()
	mod:create_journey_map_settings()
	if next(mod.vanilla_breed_health) == nil then
		for breed_name, breed_data in pairs(Breeds) do
			local max_health = breed_data.max_health
			if max_health then
				mod.vanilla_breed_health[breed_name] = table.clone(max_health)
			end
		end
	end

	if next(mod.difficulty_tables) == nil then
		mod.difficulty_tables = mod:dofile("scripts/mods/endlessChaos/endlessChaos_difficulty_tables")
	end
end

mod.time_started = false
mod.interval = 60
mod.scaling = 1.0
mod.last_interval = 0
-- Default Difficulty
mod.difficulty_tier = {
	easy = {
		scaling = 1.0,
		tweak = 0
	},
	normal = {
		scaling = 1.0,
		tweak = 1
	},
	hard = {
		scaling = 1.0,
		tweak = 2
	},
	harder = {
		scaling = 1.0,
		tweak = 3
	},
	hardest = {
		scaling = 1.0,
		tweak = 5
	},
	cataclysm = {
		scaling = 1.0,
		tweak = 7
	},
	cataclysm_2 = {
		scaling = 1.0,
		tweak = 9
	},
	cataclysm_3 = {
		scaling = 1.0,
		tweak = 10
	}

}
mod.active_level = false

--[[ mod:hook_origin(NetworkState, "get_difficulty_tweak", function(self)
	local key = self._shared_state:get_key("difficulty_tweak")
	mod:echo("key 1")
	mod:echo(key)
	returned_key = self._shared_state:get_server(key)
	mod:echo("key 2")
	mod:echo(returned_key)
	return returned_key
end)

mod:hook(LevelTransitionHandler, "promote_next_level_data", function(func, self)
	mod:echo("next level data: difficulty_tweak")
	mod:echo(self._next_level_data.difficulty_tweak)
	return func(self)
end)

]]--
mod.counter = 0

mod:hook_origin(LevelTransitionHandler, "set_next_level", function(self, optional_level_key, optional_environment_variation_id, optional_level_seed, optional_mechanism, optional_game_mode, optional_conflict_director, optional_locked_director_functions, optional_difficulty, optional_difficulty_tweak, optional_extra_packages)
	local level_transition_type = "load_next_level"
	if optional_level_key == mod.current_journey_level_name then
		optional_difficulty_tweak = mod.difficulty_tier[optional_difficulty]["tweak"]
	end
	self:_set_next_level(level_transition_type, optional_level_key, optional_environment_variation_id, optional_level_seed, optional_mechanism, optional_game_mode, optional_conflict_director, optional_locked_director_functions, optional_difficulty, optional_difficulty_tweak, optional_extra_packages)
end)

mod:hook(DeusMechanism, "_transition_next_node", function(func, self, next_node_key)
	mod:echo("next node key")
	mod:echo(next_node_key)

	local deus_run_controller = self._deus_run_controller
	local level_transition_handler = Managers.level_transition_handler

	deus_run_controller:set_current_node_key(next_node_key)

	local current_node = deus_run_controller:get_current_node()
	mod:echo("PROGRESS")
	mod:echo(current_node.node_progress)
	return func(self, next_node_key)
end)

mod:hook_safe(StateIngame, "on_enter", function(func, self)
	local level_key = Managers.level_transition_handler:get_current_level_keys()
	local difficulty_tweak = Managers.level_transition_handler:get_current_difficulty_tweak()
	if level_key == mod.current_journey_level_name then
		mod.active_level = true
	else
		if mod.active_level then
			if mod.vanilla_breed_health then
				for breed_name, max_health in pairs(mod.vanilla_breed_health) do
					Breeds[breed_name].max_health = max_health
				end
			end
			mod.active_level = false
		end
		
	end
end)

mod.update = function(dt)
	if mod.active_level then
		local t = Managers.time:time("game")
		if t and t - mod.last_interval >= mod.interval * mod.difficulty_tables[mod.difficulty_tier].time_interval then
			-- Could do t here but i like a nice number
			mod.last_interval = mod.last_interval + mod.interval * mod.difficulty_tables[mod.difficulty_tier].time_interval
			mod:echo("scaling enemy")
			mod.scale_enemies_with_time()
		end
	end
end

function mod:scale_breed_health()
	for breed_name, breed_data in pairs(Breeds) do
		local max_health = breed_data.max_health
		if max_health then
			mod.vanilla_breed_health[breed_name] = table.clone(max_health)

			for i, health in ipairs(max_health) do
				max_health[i] = math.clamp(health * mod.scaling, 0, 8100)
			end
		end
	end
end

function mod:scale_enemies_with_time()
	mod.scaling = mod.scaling + 0.17
	mod.scale_breed_health(mod.scaling)
end

mod:ensure_init()