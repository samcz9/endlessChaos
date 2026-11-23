-- Runs on: ALL (deterministic). Registers the "Risk of Rats" Chaos Wastes journey:
--   start -> final(ARENA), where the arena is the Fortunes of War plaza level.
-- Everything here is additive: vanilla journeys and settings must keep working with the mod on.
local mod = get_mod("endlessChaos")

require("scripts/settings/dlcs/morris/deus_map_populate_settings")

local Util = mod.Util
local Lookups = mod.Lookups

local JOURNEY_NAME = Util.JOURNEY_NAME
local ARENA_LEVEL_KEY = Util.ARENA_LEVEL_KEY

local Journey = {}

local base_graphs = require("scripts/settings/dlcs/morris/deus_map_baked_base_graphs")

local THEME_PACKAGES = {
	wastes = "resource_packages/levels/dlcs/morris/wastes_common",
	tzeentch = "resource_packages/levels/dlcs/morris/tzeentch_common",
	nurgle = "resource_packages/levels/dlcs/morris/nurgle_common",
	slaanesh = "resource_packages/levels/dlcs/morris/slaanesh_common",
	khorne = "resource_packages/levels/dlcs/morris/khorne_common",
}

local JOURNEY_SETTINGS = {
	description = "journey_endless_chaos_desc",
	level_image = "morris_level_icon_04",
	display_name = "journey_endless_chaos_name",
	video_settings = {
		material_name = "video_default",
		resource = "video/area_videos/morris/area_video_morris",
	},
}

-- ##### Map graph ############################################################################

local function register_base_graph()
	base_graphs[JOURNEY_NAME] = {
		[0] = {
			start = {
				connected_to = 2,
				layout_x = 0,
				layout_y = 0.4549130485552151,
				name = "start",
				type = "START",
				next = {
					[1] = "final",
				},
				prev = {},
			},
			final = {
				layout_x = 0.12872723028946012,
				layout_y = 0.4382208721337627,
				name = "final",
				type = "ARENA",
				next = {},
				prev = {
					[1] = "start",
				},
			},
		},
	}
end

-- ##### Journey + map level ##################################################################

local function register_journey()
	local already_in_order = false

	for _, journey_name in ipairs(AvailableJourneyOrder) do
		if journey_name == JOURNEY_NAME then
			already_in_order = true

			break
		end
	end

	if not already_in_order then
		AvailableJourneyOrder[#AvailableJourneyOrder + 1] = JOURNEY_NAME
	end

	DeusJourneySettings[JOURNEY_NAME] = table.clone(JOURNEY_SETTINGS)

	local map_level_settings = {
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
			"resource_packages/levels/dlcs/morris/map",
		},
		level_particle_effects = {},
		level_screen_effects = {},
		locations = {},
	}

	table.merge(map_level_settings, table.clone(JOURNEY_SETTINGS))

	LevelSettings[JOURNEY_NAME] = map_level_settings

	Lookups.add("deus_journeys", JOURNEY_NAME)
	Lookups.add("mission_ids", JOURNEY_NAME)
end

-- ##### Arena level permutations #############################################################

local function base_arena_level_settings()
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
		base_level_name = ARENA_LEVEL_KEY,
		source_aux_bus_name = "environment_reverb_outside_source",
		disable_twitch_game_mode = true,
		disable_percentage_completed = true,
		packages = {
			"resource_packages/levels/dlcs/holly/plaza",
			"resource_packages/dlcs/morris_ingame",
			"units/props/inn/deus/deus_chest_01",
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
						healing_draught = 3,
					},
					level_events = {
						explosive_barrel = 2,
						lamp_oil = 2,
					},
				},
				secondary = {
					ammo = 4,
					deus_potions = 10,
					potions = 0,
					grenades = 6,
					healing = 2,
				},
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
						healing_draught = 4,
					},
					level_events = {
						explosive_barrel = 4,
						lamp_oil = 4,
					},
				},
				secondary = {
					ammo = 6,
					deus_potions = 8,
					potions = 0,
					grenades = 9,
					healing = 3,
				},
			},
		},
		loading_screen_wwise_events = {
			"nfl_loading_screen_plaza_01",
			"nfl_loading_screen_plaza_02",
		},
		locations = {
			"dlc1_2_location_survival_magnus_plaza",
			"dlc1_2_location_survival_magnus_tower",
			"dlc1_2_location_survival_magnus_wall",
			"dlc1_2_location_survival_magnus_market",
			"dlc1_2_location_survival_magnus_gate",
		},
		paths = {
			1,
		},
		themes = {
			DEUS_THEME_TYPES.KHORNE,
			DEUS_THEME_TYPES.NURGLE,
			DEUS_THEME_TYPES.SLAANESH,
			DEUS_THEME_TYPES.TZEENTCH,
			DEUS_THEME_TYPES.WASTES,
		},
	}
end

local function register_arena_levels(terror_event_blueprints)
	local settings = base_arena_level_settings()

	-- ipairs over fixed arrays: registration order (and so lookup indices) is deterministic.
	for _, theme_name in ipairs(settings.themes) do
		for _, path in ipairs(settings.paths) do
			local level_settings = table.clone(settings)
			local permutation_key = ARENA_LEVEL_KEY .. "_" .. theme_name .. "_path" .. path

			level_settings.level_name = "levels/honduras_dlcs/holly/plaza/world"
			level_settings.theme = theme_name
			level_settings.display_name = ARENA_LEVEL_KEY .. "_title"
			level_settings.description_text = ARENA_LEVEL_KEY .. "_desc"
			level_settings.level_key = permutation_key
			level_settings.level_image = "level_icon_weaves"
			level_settings.loading_ui_package_name = level_settings.loading_ui_package_name or "morris/deus_loading_screen_1"
			level_settings.game_mode = "deus"
			level_settings.mechanism = "deus"
			level_settings.disable_percentage_completed = true
			level_settings.allowed_locked_director_functions = {
				beastmen = true,
			}
			level_settings.disable_quickplay = true
			level_settings.packages[#level_settings.packages + 1] = THEME_PACKAGES[theme_name]

			LevelSettings[permutation_key] = level_settings
			TerrorEventBlueprints[permutation_key] = terror_event_blueprints

			Lookups.add("level_keys", permutation_key)
			Lookups.add("mission_ids", permutation_key)
		end
	end
end

-- ##### Map populate settings ################################################################

local AVAILABLE_CURSES = {
	nurgle = {
		"curse_corrupted_flesh",
	},
	tzeentch = {
		"curse_change_of_tzeentch",
	},
	khorne = {
		"curse_skulls_of_fury",
		"curse_khorne_champions",
		"curse_blood_storm",
	},
	slaanesh = {
		"curse_empathy",
		"curse_abundance_of_life",
	},
}

local function register_populate_settings()
	-- Start from a vanilla journey so any field added by future game patches is present,
	-- then override what Risk of Rats needs. Never replace DEUS_MAP_POPULATE_SETTINGS itself:
	-- doing so deletes the vanilla journeys and crashes every normal Chaos Wastes run.
	local config = table.clone(DEUS_MAP_POPULATE_SETTINGS.journey_ruin)

	config.CURSES_HOT_SPOT_MAX_RANGE = 0.3
	config.CURSES_HOT_SPOTS_MAX_COUNT = 1
	config.CURSES_HOT_SPOT_MIN_RANGE = 0.2
	config.CURSES_MIN_PROGRESS = 0.35
	config.CURSES_HOT_SPOTS_MIN_COUNT = 1
	config.MINOR_MODIFIABLE_MIN_PROGRESS = -0.1
	config.POWER_UP_LOOKAHEAD = 2
	config.MINOR_MODIFIABLE_NODE_CHANCE = 1
	config.AVAILABLE_GODS = {
		"nurgle",
		"tzeentch",
		"khorne",
		"slaanesh",
	}
	config.AVAILABLE_CURSES = {
		SIGNATURE = AVAILABLE_CURSES,
		TRAVEL = AVAILABLE_CURSES,
		ARENA = AVAILABLE_CURSES,
	}
	config.CURSEABLE_NODE_TYPES = {
		"SIGNATURE",
		"TRAVEL",
	}
	config.MUTATORS = {
		SIGNATURE = {},
		TRAVEL = {},
		SHOP = {},
		ARENA = {},
		START = {},
	}
	config.CONFLICT_DIRECTORS = {
		default = {
			"risk_of_rats",
		},
	}
	config.LEVEL_AVAILABILITY = {
		TRAVEL = {},
		SIGNATURE = {},
		ARENA = {
			[ARENA_LEVEL_KEY] = {
				themes = {
					DEUS_THEME_TYPES.KHORNE,
					DEUS_THEME_TYPES.SLAANESH,
					DEUS_THEME_TYPES.TZEENTCH,
					DEUS_THEME_TYPES.WASTES,
				},
				paths = {
					1,
				},
			},
		},
	}
	config.LEVEL_VALIDATIONS = {
		SIGNATURE = {
			"prevent_same_level_choice",
		},
		TRAVEL = {
			"prevent_same_level_choice",
		},
		SHOP = {
			"prevent_same_level_choice",
		},
		ARENA = {},
		START = {},
	}
	config.LABEL_OVERRIDES = {}

	DEUS_MAP_POPULATE_SETTINGS[JOURNEY_NAME] = config
end

-- ##### Conflict director ####################################################################

local function register_conflict_director()
	local director = {
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
			"chaos",
		},
		contained_breeds = {},
	}

	for i = 1, #Difficulties do
		local difficulty = Difficulties[i]
		local difficulty_breeds = {}

		ConflictUtils.find_conflict_director_breeds(director, difficulty, difficulty_breeds)

		director.contained_breeds[difficulty] = difficulty_breeds
	end

	ConflictDirectors.risk_of_rats = director
end

-- ##### Hooks ################################################################################

local function register_hooks()
	mod:hook(DeusMechanism, "get_loading_tip", function (func, self, ...)
		local run_controller = self._deus_run_controller

		if run_controller and run_controller:get_journey_name() == JOURNEY_NAME then
			return "risk_of_rats_desc"
		end

		return func(self, ...)
	end)

	-- Runs on every peer: each one generates the map graph locally from the run seed.
	mod:hook_safe(DeusRunController, "setup_run", function (self, run_seed, difficulty, journey_name)
		if journey_name == JOURNEY_NAME and self._path_graph and self._path_graph.final then
			self._path_graph.final.run_progress = 0.9999999
		end
	end)

	-- Starting a Risk of Rats run with a peer that lacks the mod (or has a different build)
	-- crashes that peer. Refuse to start the vote instead and say why.
	mod:hook(DeusMechanism, "request_vote", function (func, self, params, ...)
		if params and params.mission_id == JOURNEY_NAME then
			local ready, reason = mod.Net.all_peers_ready()

			if not ready then
				mod:echo("[Risk of Rats] Can't start: not every player has a matching Risk of Rats mod (%s). Type /ec_status for details.", tostring(reason))

				return
			end

			-- Never list a Risk of Rats lobby publicly: vanilla players browsing lobbies crash on
			-- the unknown journey. Friends can still join through invites.
			params.private_game = true
		end

		return func(self, params, ...)
	end)

	-- Vanilla systems that iterate AvailableJourneyOrder must not see our journey:
	--   * Chaos Wastes quickplay picks a random unlocked journey (would matchmake vanilla players
	--     into a Risk of Rats run, bypassing the request_vote check above).
	--   * The weekly Belakor rotation uses cycle % #AvailableJourneyOrder (a fifth entry shifts
	--     which vanilla journey gets Belakor, and could pick ours).
	local function call_with_vanilla_journey_order(func, ...)
		local index = table.index_of(AvailableJourneyOrder, JOURNEY_NAME)

		if not index or index < 1 then
			return func(...)
		end

		table.remove(AvailableJourneyOrder, index)

		local results = {
			pcall(func, ...),
		}

		table.insert(AvailableJourneyOrder, index, JOURNEY_NAME)

		if not results[1] then
			error(results[2], 0)
		end

		return unpack(results, 2, table.maxn(results))
	end

	-- Global names as strings: VMF delays the hook if the class isn't loaded yet.
	mod:hook("MatchmakingManager", "gather_party_unlocked_journeys", function (func, ...)
		return call_with_vanilla_journey_order(func, ...)
	end)

	mod:hook("BackendInterfaceDeusPlayFab", "_generate_belakor_curse_cycle", function (func, ...)
		return call_with_vanilla_journey_order(func, ...)
	end)

	-- Journey completion stats are built at game load from the vanilla journey list, so our
	-- journey has no stat entry and registering a completion would error. Skip it.
	mod:hook("StatisticsUtil", "register_journey_complete", function (func, statistics_db, player, journey_name, ...)
		if journey_name == JOURNEY_NAME then
			return
		end

		return func(statistics_db, player, journey_name, ...)
	end)
end

function Journey.init(terror_event_blueprints)
	register_base_graph()
	register_journey()
	register_arena_levels(terror_event_blueprints)
	register_populate_settings()
	register_conflict_director()
	register_hooks()
end

return Journey
