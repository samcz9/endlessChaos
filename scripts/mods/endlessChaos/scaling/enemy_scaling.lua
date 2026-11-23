-- Runs on: HOST. Scales every enemy the conflict director spawns in the Risk of Rats arena.
--
-- How it stays multiplayer safe (see docs/DESIGN.md section 5.2):
--   * Buffs go straight onto the host's buff extension (buff_ext:add_buff). That is local: no
--     rpc_add_buff, nothing sent on hot join.
--   * Max health: apply_max_health_buff_for_ai -> GenericHealthExtension.set_max_health, which
--     sends the new value to every connected client with rpc_sync_damage_taken. Players who join
--     later get it from sync_max_health_to_joiner below.
--   * Damage dealt and damage taken are only read in the host's DamageUtils.apply_buffs_to_damage.
--   * ConflictDirector._post_spawn_unit runs for fresh spawns AND for recycled (unfrozen) units.
--     Freezing clears buffs and resets health, so every reuse gets scaled again here.
--   * Nothing global is edited (no Breeds changes, no calculate_damage hook).
local mod = get_mod("endlessChaos")

local EnemyScaling = {}

local TEMPLATE_HEALTH = "risk_of_rats_enemy_health"
local TEMPLATE_DAMAGE = "risk_of_rats_enemy_damage"
local TEMPLATE_TOUGHNESS = "risk_of_rats_enemy_toughness"

-- Stay a bit under the network limit so rounding never hits the clamp.
local HEALTH_CAP_MARGIN = 0.95

-- Our own templates, so they never merge with grudge-mark stacks. The multiplier is always
-- passed in through external_optional_multiplier.
local BUFF_TEMPLATES = {
	{
		TEMPLATE_HEALTH,
		{
			buffs = {
				-- Same pattern as vanilla belakor_shadow_lieutenant: the apply func adds
				-- base * multiplier on top of the current max health (so bonuses that other buffs
				-- set directly are kept), and the stat keeps our share if a later
				-- ai_update_max_health recomputes max health from the stats.
				{
					apply_buff_func = "apply_max_health_buff_for_ai",
					multiplier = 0,
					name = "risk_of_rats_enemy_health",
					remove_buff_func = "remove_max_health_buff_for_ai",
					stat_buff = "max_health",
				},
			},
		},
	},
	{
		TEMPLATE_DAMAGE,
		{
			buffs = {
				{
					multiplier = 0,
					name = "risk_of_rats_enemy_damage",
					stat_buff = "damage_dealt",
				},
			},
		},
	},
	{
		TEMPLATE_TOUGHNESS,
		{
			buffs = {
				{
					multiplier = 0,
					name = "risk_of_rats_enemy_toughness",
					stat_buff = "damage_taken",
				},
			},
		},
	},
}

local function register_buff_templates()
	for _, entry in ipairs(BUFF_TEMPLATES) do
		local name, template = entry[1], entry[2]

		BuffTemplates[name] = template

		-- The buffs are only ever added locally on the host, so no id should go over the wire.
		-- Registered anyway (in a fixed order) so an unexpected sync can't send a nil id.
		mod.Lookups.add("buff_templates", name)
	end
end

-- Highest max health that survives the network: the health field itself and the hot-join
-- damage sync (a joining client would otherwise get a clamped damage value).
local function health_cap()
	local constants = rawget(_G, "NetworkConstants")
	local health_info = constants and constants.health
	local hotjoin_info = constants and constants.damage_hotjoin_sync
	local cap = math.huge

	if health_info and health_info.max then
		cap = math.min(cap, health_info.max)
	end

	if hotjoin_info and hotjoin_info.max then
		cap = math.min(cap, hotjoin_info.max)
	end

	return cap * HEALTH_CAP_MARGIN
end

local function apply_health(unit, buff_ext, health_mult)
	local health_ext = ScriptUnit.has_extension(unit, "health_system")

	if not health_ext or health_ext.is_invincible then
		return
	end

	local base = health_ext.unmodified_max_health

	if not base or base <= 0 or base == math.huge then
		return
	end

	-- Our buff adds base * extra on top of the current max health, which already includes
	-- grudge marks and mutator boss bonuses applied before _post_spawn_unit.
	local existing = health_ext:get_max_health() / base
	local wanted_extra = health_mult - 1
	local allowed_extra = math.max(health_cap() / base - existing, 0)
	local extra = math.min(wanted_extra, allowed_extra)

	if extra > 0 then
		buff_ext:add_buff(TEMPLATE_HEALTH, {
			external_optional_multiplier = extra,
		})
	end

	-- Whatever doesn't fit in max health becomes damage reduction, so enemies keep getting
	-- tankier past the network limit. damage_taken multiplies: damage * (1 + m).
	if extra < wanted_extra then
		local overflow = (existing + wanted_extra) / (existing + extra)

		buff_ext:add_buff(TEMPLATE_TOUGHNESS, {
			external_optional_multiplier = 1 / overflow - 1,
		})
	end
end

local function should_scale(unit, breed)
	if not ALIVE[unit] or not breed or breed.is_hero or breed.is_player then
		return false
	end

	-- Necromancer skeletons and other pets come through the conflict director too.
	local side_manager = Managers.state.side
	local side = side_manager and side_manager.side_by_unit[unit]

	if side and side:name() == "heroes" then
		return false
	end

	return true
end

function EnemyScaling.scale_unit(unit, breed)
	if not should_scale(unit, breed) then
		return
	end

	local buff_ext = ScriptUnit.has_extension(unit, "buff_system")

	if not buff_ext then
		return
	end

	local health_mult, damage_mult = mod.Difficulty.multipliers()

	if health_mult > 1 then
		apply_health(unit, buff_ext, health_mult)
	end

	if damage_mult > 1 then
		buff_ext:add_buff(TEMPLATE_DAMAGE, {
			external_optional_multiplier = damage_mult - 1,
		})
	end
end

-- Host only. Vanilla hot-join sync sends enemy damage but not max health (the game object's
-- health field keeps the unscaled spawn value), so a player joining mid-arena would see broken
-- health bars. Send the real max health of every enemy whose max health was changed.
-- Hooked on HealthSystem rather than GenericHealthExtension: class() copies methods into
-- subclasses (rat ogre, loot rat, ...), so a hook on the base class would miss them.
local function sync_max_health_to_joiner(health_system, peer_id)
	if not mod.Util.in_endless_arena() then
		return
	end

	local network_manager = Managers.state.network

	if not network_manager then
		return
	end

	for unit, health_ext in pairs(health_system.unit_extensions) do
		if HEALTH_ALIVE[unit] and ScriptUnit.has_extension(unit, "ai_system") and health_ext.unmodified_max_health and health_ext.health ~= health_ext.unmodified_max_health and health_ext.network_transmit then
			local go_id, is_level_unit = network_manager:game_object_or_level_id(unit)

			if go_id then
				local state_id = NetworkLookup.health_statuses[health_ext.state]
				local set_max_health = true

				health_ext.network_transmit:send_rpc("rpc_sync_damage_taken", peer_id, go_id, is_level_unit, set_max_health, health_ext.health, state_id)
			end
		end
	end
end

function EnemyScaling.init()
	register_buff_templates()

	mod:hook_safe("HealthSystem", "hot_join_sync", function (self, peer_id)
		if mod.Util.is_server() then
			sync_max_health_to_joiner(self, peer_id)
		end
	end)

	-- Host only: the conflict director never spawns on clients. hook_safe errors are logged
	-- by VMF instead of crashing the host.
	mod:hook_safe("ConflictDirector", "_post_spawn_unit", function (self, ai_unit, go_id, breed)
		if not mod.Util.is_server() or not mod.Util.in_endless_arena() then
			return
		end

		EnemyScaling.scale_unit(ai_unit, breed)
	end)
end

return EnemyScaling
