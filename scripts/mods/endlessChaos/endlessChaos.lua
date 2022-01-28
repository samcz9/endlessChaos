local mod = get_mod("endlessChaos")
require("scripts/managers/game_mode/mechanisms/deus_generate_graph")
require("scripts/helpers/deus_gen_utils")
require("scripts/settings/dlcs/morris/deus_map_populate_settings")
require("scripts/managers/game_mode/mechanisms/deus_base_graph_generator")
require("scripts/managers/game_mode/mechanisms/deus_layout_base_graph")
require("scripts/managers/game_mode/mechanisms/deus_populate_graph")

local base_graphs = require("scripts/settings/dlcs/morris/deus_map_baked_base_graphs")

function table_to_string(tbl)
    local result = "{"
    for k, v in pairs(tbl) do
        -- Check the key type (ignore any numerical keys - assume its an array)
        if type(k) == "string" then
            result = result.."[\""..k.."\"]".."="
        end

        -- Check the value type
        if type(v) == "table" then
            result = result..table_to_string(v)
        elseif type(v) == "boolean" then
            result = result..tostring(v)
        else
            result = result.."\""..v.."\""
        end
        result = result..","
    end
    -- Remove leading commas from the result
    if result ~= "{" then
        result = result:sub(1, result:len()-1)
    end
    return result.."}"
end

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
			"curse_change_of_tzeentch",
			"curse_egg_of_tzeentch"
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
	new_journey_name = mod:get_journey_name()
	journey_created = false
	for _, journey_name in ipairs(AvailableJourneyOrder) do
		mod:echo(journey_name)
		if journey_name == new_journey_name then
			journey_created = true
		end
	end
	mod:echo(journey_created)
	if not journey_created then
		table.insert(AvailableJourneyOrder, new_journey_name)
	end
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
	if next(mod.loot_tables) == nil then
		mod.loot_tables = mod:dofile("scripts/mods/endlessChaos/endless_chaos_pickup_system")
	end
end

local function is_element_available(element)
	local conflict_director = Managers.state.conflict
	local director = ConflictDirectors[conflict_director.initial_conflict_settings]
	local factions = director.factions
	local current_difficulty, current_difficulty_tweak = Managers.state.difficulty:get_difficulty_rank()

	if element.minimum_difficulty_tweak and current_difficulty_tweak < element.minimum_difficulty_tweak then
		return false
	end

	if element.difficulty_requirement then
		if current_difficulty < element.difficulty_requirement then
			return false
		end
	elseif element.only_on_difficulty and current_difficulty ~= element.only_on_difficulty then
		return false
	end

	if factions and element.faction_requirement then
		local requirement = element.faction_requirement

		if not table.contains(factions, requirement) then
			return false
		end
	end

	if factions and element.faction_requirement_list then
		local requirements = element.faction_requirement_list

		for _, requirement in ipairs(requirements) do
			if not table.contains(factions, requirement) then
				return false
			end
		end
	end

	return true
end

local MAX_INJECTION_DEPTH = 10

function mod:mod_process_terror_event_recursive(processed_elements, data, depth, event_name)
	fassert(depth < MAX_INJECTION_DEPTH, "Injecting terror events lead to high level of recursion, please check if there is a possible loop, or increase MAX_INJECTION_DEPTH.")

	local level_transition_handler = Managers.level_transition_handler
	local level_key = level_transition_handler:get_current_level_keys()
	local injected_elements = TerrorEventBlueprints[level_key][event_name] or GenericTerrorEvents[event_name]
	fassert(injected_elements, "No terror event called '%s', exists. Make sure it is added to level %s, or generic, terror event file if its supposed to be there.", event_name, level_key)

	for _, element in ipairs(injected_elements) do
		if is_element_available(element) then
			if element[1] == "inject_event" then
				local injected_event_name = nil

				if element.event_name_list then
					local seed, index = Math.next_random(data.seed, 1, #element.event_name_list)
					injected_event_name = element.event_name_list[index]
					data.seed = seed
				else
					injected_event_name = element.event_name
				end

				processed_elements = mod:mod_process_terror_event_recursive(processed_elements, data, depth + 1, injected_event_name)
			else
				element.base_event_name = event_name
				processed_elements[#processed_elements + 1] = element
			end
		end
	end

	return processed_elements
end

function mod:mod_process_terror_event(data, base_event_name)
	local processed_elements = mod:mod_process_terror_event_recursive({}, data, 0, base_event_name)

	if script_data.debug_terror then
		print("process_terror_event: " .. table.tostring(processed_elements))
	end

	return processed_elements
end

mod.active_level = false

mod:hook(TerrorEventMixer, "start_event", function(func, event_name, data)
	if script_data.only_allowed_terror_event ~= event_name and script_data.ai_terror_events_disabled then
		return
	end

	if data then
		data.seed = data.seed or 0
	else
		data = {
			seed = 0
		}
	end

	print(string.format("TerrorEventMixer.start_event: %s (seed: %d)", event_name, data.seed))

	local seed, _ = Math.next_random(data.seed)
	data.seed = seed
	local active_events = TerrorEventMixer.active_events
	local elements = mod:mod_process_terror_event(data, event_name)

	Managers.state.game_mode:post_process_terror_event(elements)

	if #elements > 0 then
		local new_event = {
			index = 1,
			ends_at = 0,
			name = event_name,
			elements = elements,
			data = data,
			max_active_enemies = math.huge
		}
		active_events[#active_events + 1] = new_event
		local element = elements[1]
		local func_name = element[1]
		local t = Managers.time:time("game")

		TerrorEventMixer.init_functions[func_name](new_event, element, t)
	end

	if event_name == "plaza_wave_1" then
		mod.active_level = true
		current_difficulty, current_difficulty_tweak = Managers.state.difficulty:get_difficulty()
		mod.difficulty = current_difficulty
	end
	Managers.telemetry.events:terror_event_started(event_name)
	

end)

mod:hook_safe(DeusRunController, "setup_run", function(self, run_seed, difficulty, journey_name, dominant_god, initial_own_soft_currency, telemetry_id)
	self._path_graph["final"]["run_progress"] = .9999999
end)


-- ENEMY SCALING STUFF --
mod.difficulty_tier = {
	easy = {
		scaling = 1.0,
		tweak = 0,
		time_interval = 1
	},
	normal = {
		scaling = 1.0,
		tweak = 1,
		time_interval = 1
	},
	hard = {
		scaling = 1.0,
		tweak = 2,
		time_interval = 1
	},
	harder = {
		scaling = 1.0,
		tweak = 3,
		time_interval = 1
	},
	hardest = {
		scaling = 1.0,
		tweak = 5,
		time_interval = 1
	},
	cataclysm = {
		scaling = 1.0,
		tweak = 7,
		time_interval = 1
	},
	cataclysm_2 = {
		scaling = 1.0,
		tweak = 9,
		time_interval = 1
	},
	cataclysm_3 = {
		scaling = 1.0,
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
		mod.active_level = false
	end
end)

mod.time_started = false
mod.interval = 60
mod.scaling = 1.0
mod.last_interval = 0

mod.update = function(dt)
	if mod.active_level then
		local t = Managers.time:time("game")
		if t and t - mod.last_interval >= mod.interval * mod.difficulty_tier[mod.difficulty].time_interval then
			-- Could do t here but i like a nice number
			mod.last_interval = mod.last_interval + mod.interval * mod.difficulty_tier[mod.difficulty].time_interval
			mod:echo("scaling enemy")
			mod:scale_enemies_with_time()
		end
	end
end

local function scale_breed_health()
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
	scale_breed_health(mod.scaling)
end


-- POWER UP STUFF --
local AllPickups = AllPickups
local ItemMasterList = ItemMasterList

function mod:update_power_up_attributes(power_ups)
	DeusPowerUpTemplates = DeusPowerUpTemplates or {}
	for power_up_name, power_up_settings in pairs(power_ups) do
		if DeusPowerUpTemplates[power_up_name] then
			local power_up_template = DeusPowerUpTemplates[power_up.name]
			for power_up_attribute, power_up_value in pairs(power_up_settings) do
				power_up_template[power_up_attribute] = power_up_value
			end
		end
	end
end

function mod:add_pickup_template(pickup_name, pickup_data)
	local pickup_already_exists = rawget(AllPickups, pickup_name)
	local item_name = pickup_name
	local item_already_exists = rawget(ItemMasterList, item_name)
	if item_already_exists and pickup_already_exists then
		return
	end
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

local function rollLootDrop(percent)
	return percent >= math.random(1, 1000)
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

mod:hook(DeathSystem, "kill_unit", function(func, self, unit, killing_blow)
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
	
	func(self, unit, killing_blow)
end)

local function get_random_buff(_deus_run_controller, tier, player_unit)
	local power_up = nil
	local current_node = _deus_run_controller:get_current_node()
	local res = ""
	for i = 1, 5 do
		res = res .. string.char(math.random(97, 122))
	end
	local seed = HashUtils.fnv32_hash(res .. "_" .. current_node.weapon_pickup_seed)
	if tier == "stats" then
		power_up = _deus_run_controller:generate_random_power_ups(1, DeusPowerUpAvailabilityTypes.terror_event, seed)
	else
		power_up = _deus_run_controller:generate_random_power_ups(1, DeusPowerUpAvailabilityTypes.cursed_chest, seed)
	end
	for id, power_up in ipairs(power_up) do
		mod:echo(id)
		mod:echo(power_up.name)
	end
	if power_up then
		return power_up[1]
	end
end

local function give_power_up(_deus_run_controller, power_up, interactor_unit)
	player_unit_id = interactor_unit:local_player_id()
	_deus_run_controller:add_power_ups({
		power_up
	}, player_unit_id)

	local buff_system = Managers.state.entity:system("buff_system")
	local talent_interface = Managers.backend:get_talents_interface()
	local deus_backend = Managers.backend:get_interface("deus")
	local own_peer_id = _deus_run_controller:get_own_peer_id()
	local local_player_unit = interactor_unit.player_unit

	local profile_index, career_index = _deus_run_controller:get_player_profile(own_peer_id, player_unit_id)
	mod:echo("pu")
	mod:echo(power_up)
	mod:echo("bs")
	mod:echo(buff_system)
	mod:echo("ti")
	mod:echo(talent_interface)
	mod:echo("db")
	mod:echo(deus_backend)
	mod:echo("rc")
	mod:echo(run_controller)
	mod:echo("lpu")
	mod:echo(local_player_unit)
	mod:echo("pi")
	mod:echo(profile_index)
	mod:echo("ci")
	mod:echo(career_index)


	DeusPowerUpUtils.activate_deus_power_up(power_up, buff_system, talent_interface, deus_backend, _deus_run_controller, local_player_unit, profile_index, career_index)
	mod:echo("Granted power up " .. power_up.name)
end

function mod:apply_buff(tier, interactor_unit)
	_deus_run_controller = Managers.mechanism:game_mechanism():get_deus_run_controller()
	local player_manager = Managers.player
	local interactor_player = player_manager:unit_owner(interactor_unit)
	power_up = get_random_buff(_deus_run_controller, tier, interactor_player)
	if power_up then
		mod:echo("giving power up to: ")
		give_power_up(_deus_run_controller, power_up, interactor_player)
		mod:echo("power up granted")
	end
end



mod:ensure_init()



--[[

GUID: 8c270409-981f-4b6f-b2dd-868755a67ec2
Log File: 
Info Type: 
-----------------------------------------------
[Script Error]: foundation/scripts/util/error.lua:26: DeusPowerUpUtils.activate_deus_power_up invalid arguments
-----------------------------------------------
[Crash Link]:
crashify://8c270409-981f-4b6f-b2dd-868755a67ec2

]]--

