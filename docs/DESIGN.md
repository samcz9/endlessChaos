# Risk of Rats — Design

Endless, scaling Chaos Wastes mode for Vermintide 2. Enemies keep getting stronger over time with no cap. Players keep up by collecting boon drops from kills, and those boons stack without limit.

Source references point to the decompiled game source (Aussiemon/Vermintide-2-Source-Code, v6.13.0) as `vt2:path:line`, and to this mod as `mod:path:line`.

---

## 1. Goals

1. **Endless run.** Survive as long as possible. Difficulty rises with time (RoR2-style), not just with stages.
2. **Uncapped player scaling.** Boons can be stacked repeatedly. Movement speed, attack speed, crit and similar stats have no artificial ceilings, but stats that would break past 100% get diminishing returns.
3. **Boon drops.** Enemies drop pickups that grant a random boon. The drop chance depends on the enemy tier.
4. **Multiplayer first.** Every piece of logic has one clearly defined owner (host or owning client). Nothing relies on each peer independently computing the same "random" result.

---

## 2. How the engine actually works (the facts the design is built on)

### 2.1 Authority model

| Thing | Who owns it | How it reaches other peers |
|---|---|---|
| Enemy spawning, health, damage dealt/taken | **Host** | Health goes in the AI game-object `health` field at spawn (`vt2:scripts/network/game_object_initializers_extractors.lua:161`). Later changes go via `rpc_sync_damage_taken` (`vt2:.../generic_health_extension.lua:215-236`). |
| Damage math (`DamageUtils.apply_buffs_to_damage`) | **Host** | Clients only *predict* kills and cleave using `calculate_damage` (`vt2:.../action_sweep.lua:1289`). |
| Player power-up list | **Owning client** adds its own, then RPCs the host (`vt2:.../deus_run_controller.lua:1126-1190`) | The host stores it in `SharedState` and replicates it to everyone (`vt2:.../deus_run_state.lua:551`). |
| Activating a boon's buff on a player | The **owning client** (`add_power_ups` → `activate_deus_power_up`) | `BuffSystem.add_buff` sends `rpc_add_buff` **by `NetworkLookup.buff_templates` index** (`vt2:.../buff_system.lua:277-311`). |
| Re-applying boons after respawn or a new level | **Host** (`DeusSpawning._apply_initial_buffs`, `vt2:.../deus_spawning.lua:270-298`) | Same `add_buff` path. |
| Pickup spawning | **Host** (`PickupSystem.spawn_pickup`, `vt2:.../pickup_system.lua:1157`) | Network game object, identified by `NetworkLookup.pickup_names`. |
| Pickup `on_pick_up_func` | Runs on **every peer**: once for the interactor, and once on every other peer as a husk with `is_husk = true` (`vt2:.../interactions.lua:983,1078`) | — |
| Coins | Every peer is credited when anyone picks one up (`vt2:.../game_mode_deus.lua:689-721`) | — |

### 2.2 Things that cause desyncs and crashes

- **NetworkLookup indices.** Every table we add to (`buff_templates`, `pickup_names`, `item_names`, `deus_power_up_templates`, `mutator_templates`, `level_keys`, `mission_ids`, `deus_journeys`) has to be identical, in the same order, on every peer. A missing index puts `nil` in an RPC and crashes. **Consequence: every player must have the mod, the same version, and the same load order relative to other mods that touch lookups.** We enforce this with a handshake (§6.3).
- **Power-up template count.** It is written as a `uint8` (`vt2:helpers/deus_power_up_utils.lua:340`, asserted to be ≤ 256). Count the existing templates before adding custom ones.
- **Mutating global data on every peer.** For example, editing `Breeds[x].max_health`, or multiplying damage inside `DamageUtils.calculate_damage`. Clients use these values for prediction, so host and clients disagree.
- **Recycled AI units.** Pooled breeds (clan rats, stormvermin, marauders, chaos warriors, etc.) skip `max_health_modifier`/`prepare_func`. Unfreezing them resets health to `unmodified_max_health` and clears their buffs (`vt2:.../generic_health_extension.lua:94-105`, `vt2:.../buff_system.lua:136`). Scaling therefore has to be applied **after** every spawn, including unfreezes.
- **Network ranges.** `NetworkConstants.health`, `damage`, `damage_hotjoin_sync` and `velocity` come from the engine's `global.network_config`, which is not in the Lua dump. Read them at runtime with `NetworkConstants.health.max` and similar. Health above the range is **silently clamped**. Player hits are split into chunks, so huge health is still killable. Hot-join sync clamps to `damage_hotjoin_sync.max`.

### 2.3 Player stat caps (engine side)

The buff system itself never clamps: `apply_buffs_to_value = value * (1 + Σmult) + Σbonus`. The caps are in the code that reads the stats:

| Stat | Behavior when stacked | Where |
|---|---|---|
| Movement speed (`movespeed` boon) | Compounds ×1.05 per copy; **walking is uncapped** | `player_character_state_walking.lua:302` |
| | **Air movement and jump-start clamp to the base 4.0** | `player_character_state_helper.lua:481`, `player_character_state_jumping.lua:46,177` |
| Attack speed | Uncapped. Animation speed clamps to `animation_variable_float` while the logical action keeps shortening | `action_utils.lua:538`, `weapon_unit_extension.lua:487,497` |
| Crit chance | Saturates (>0.99 always crits) | `pseudo_random_distribution.lua:7` |
| Crit power, power vs X | Uncapped (applied after the 2000 power-level clamp) | `damage_utils.lua:290`, `action_utils.lua:301` |
| Max health | Uncapped in Lua; clamped to `NetworkConstants.health` | `player_unit_health_extension.lua:149`, `damage_utils.lua:1683` |
| Stamina (`max_fatigue`) | **Clamped to 1..100 points (50 shields); the HUD shows at most 20** | `generic_status_extension.lua:527`, `ui_settings.lua:19` |
| Block arc | Clamped 0..360° | `generic_status_extension.lua:568` |
| **Cooldown, block cost, revive/respawn time** | **Additive negatives go past -100% and invert** (blocking *restores* stamina, cooldown pinned at 0) | `career_extension.lua:423`, `generic_status_extension.lua:802` |
| Damage taken | Same inversion risk at Σ ≤ -1 | `damage_utils.lua:2160` |

### 2.4 How vanilla grants the stat boons

- All "stat" boons live only in the **rare** pool, with availability type `terror_event`. They are never rolled randomly. Each map node gets one fixed stat boon (`deus_populate_graph.lua:903-941`), granted as a **party** power-up when the level ends.
- `max_amount` is copied from the template into the runtime table **when the settings load** (`DeusPowerUps[rarity][name].max_amount`, `deus_power_up_settings.lua:7121-7176`). Changing `DeusPowerUpTemplates` afterwards has no effect.
- `get_maxed_out_power_ups` (`deus_power_up_utils.lua:44-62`) counts from a *set*, so it only ever excludes boons with `max_amount <= 1`. This is a vanilla bug we can use.
- Each power-up's buff is `"power_up_<name>_<rarity>"`. Its values come from `MorrisBuffTweakData` and do not depend on rarity.

---

## 3. Bugs found in the current code

| # | Where | Problem | Impact |
|---|---|---|---|
| 1 | `mod:endlessChaos.lua:583` | `DEUS_MAP_POPULATE_SETTINGS = { journey_endless_chaos = ... }` replaces the whole table, wiping `journey_ruin/cave/ice/citadel` | **Any vanilla Chaos Wastes run crashes** with the mod enabled (`deus_run_controller.lua:282` gets `nil`) |
| 2 | `mod:endless_chaos_pickup_system.lua:45-99` | `on_pick_up_func` uses `Managers.player:local_player()` and runs on every peer | Every player rolls and applies a boon to themselves when *anyone* picks up a die; bots trigger it on the host |
| 3 | `mod:endlessChaos.lua:973-988` | `give_power_up` calls `add_power_ups` (which already activates the buff) **and** `activate_deus_power_up` | Every boon's buff is applied twice; respawn then restores only one copy |
| 4 | `mod:endlessChaos.lua:844-853` | Writes `DeusPowerUpTemplates[attr] = value` (top level, not per power-up), uses `max_stacks` instead of `max_amount`, and edits templates after load | Power-up caps are never actually changed |
| 5 | `mod:endlessChaos.lua:775-792, 802-825` | Scales `Breeds[*]` and multiplies damage in `calculate_damage` on every peer, timed by a local clock | Host and clients desync; damage prediction is wrong; recycled units ignore it. The stagger code computes a value and never assigns it |
| 6 | `mod:endlessChaos.lua:864` | `ItemMasterList[item_name] = item` where `item` is an undefined global | No item entry is created (nil) |
| 7 | `mod:endlessChaosPlazaEvent.lua:95-106` | `ipairs(Breeds)` on a map, plus an undefined `breed` | The loop never runs; the breed lists are empty |
| 8 | `mod:power_up_customizations.lua:47` | Replaces the global `DeusPowerUpAvailabilityTypes` wholesale | Fragile: any future vanilla type would be lost. Add a key instead |
| 9 | `mod:endlessChaos_localization.lua:47` | Duplicate key `endless_chaos_buff_pickup_exotic_hud_desc` | The unique pickup has no HUD text |
| 10 | Several files | Leaked globals (`buffs_to_customize`, `stat_power_ups`, `NewJourneySettings`, `new_journey_name`, `breed`, `drop`, `power_up`, ...) | Collisions with other mods; hard to debug |

---

## 4. Game structure

### Option A — Single endless arena (current direction, recommended for v1)

- Journey graph `start → final(ARENA)`. The arena is the Fortunes of War plaza level.
- Endless waves: the host chains terror events. It reuses the 8 plaza wave blueprints, then loops through procedurally built waves (§5.3).
- **Pros:** one level to tune; no graph regeneration; boons persist through respawns via vanilla `_apply_initial_buffs`.
- **Cons:** less variety; no shop or shrine nodes, so coins have nothing to buy unless we add a vendor.

### Option B — Looping Chaos Wastes map (RoR2 "loop", v2 stretch)

- After the ARENA node, the run would normally end because `current_node.next` is empty (`deus_mechanism.lua:643-660`). Instead, the host generates a new graph and the run continues.
- Hard part: `_path_graph` is generated **locally on every peer** from `run_seed` (`deus_run_controller.lua:284`). Each loop would need a host-chosen seed and loop index sent through a VMF RPC so every peer rebuilds the same graph.
- Uses every vanilla level, plus shops, shrines and curses. Much more content, but much more surface area.

**Recommendation:** ship Option A. Write the scaling and drop systems so they don't care which level they run in, so Option B can be added later without a rewrite.

---

## 5. Enemy scaling (host only)

### 5.1 Difficulty coefficient

A single number on the host drives everything, using a RoR2-style formula:

```
coeff(t, wave) = (1 + time_factor[difficulty] * minutes_elapsed) * wave_factor ^ waves_completed
```

Starting values (to tune):

- `time_factor`: recruit 0.03 … cata3 0.08
- `wave_factor`: 1.10

The coefficient feeds into:

- `health_mult = 1 + health_weight * (coeff - 1)`
- `damage_mult = 1 + damage_weight * (coeff - 1)`
- Spawn pressure (horde size and frequency, special count, threat-delay thresholds)
- Monster and elite modifier count (§5.4)
- Drop rate (it rises with coeff, so the players' ceiling rises too)

Elapsed time comes from `Managers.time:time("game")` and is read **on the host only**. The host sends `coeff` to clients via VMF RPC every few seconds, but **only for UI** (a difficulty meter like RoR2's).

### 5.2 Applying scaling to every enemy

- **Hook:** `GameModeManager.ai_spawned` (or `ConflictDirector._post_spawn_unit`), host only. This covers fresh spawns and unfrozen recycled units.
- **How:** the **local** buff extension on the host. This is *not* `BuffSystem.add_buff`, so there is no RPC and no custom lookup. It uses stock templates scaled with `external_optional_multiplier` (supported in `buff_extension.lua:240-243`):

  ```lua
  local buff_ext = ScriptUnit.extension(unit, "buff_system")
  buff_ext:add_buff("grudge_mark_health", { external_optional_multiplier = health_mult - 1 })  -- max_health stat + ai_update_max_health
  buff_ext:add_buff("grudge_mark_damage", { external_optional_multiplier = damage_mult - 1 })  -- damage_dealt stat
  ```

- `ai_update_max_health` → `set_max_health` reaches clients through the game-object field (fresh spawn) or `rpc_sync_damage_taken` (unfreeze). Clients see the correct health bar with nothing extra from us.
- `damage_dealt` is only read in the host's `apply_buffs_to_damage`. Nothing to sync.
- Clamp `health_mult * base` below `min(NetworkConstants.health.max, NetworkConstants.damage_hotjoin_sync.max)`. Past that point, add `damage_taken` reduction instead, so enemies keep getting tankier without overflowing the network type.
- **No more edits to `Breeds` and no `calculate_damage` hook.**

### 5.3 Spawn pressure and endless waves

- On level start (host): disable plaza flow-driven wave progression, or hook `flow_event wave_N_complete`, and drive waves ourselves.
- Wave `n`:
  - For the first 8 waves, use the plaza blueprints, with `set_freeze_condition max_active_enemies` raised.
  - After that, build element lists procedurally from horde compositions, specials and bosses, weighted by `coeff`. Start them with `Managers.state.conflict:start_terror_event`.
- Between waves there is a short breather (RoR2's teleporter-charged moment). Each wave completed bumps `waves_completed`.
- Optional "always-on" pressure: tweak `CurrentPacing` / `CurrentHordeSettings` / `CurrentSpecialsSettings` and `conflict.delay_*_threat_value` with `coeff`.

### 5.4 Monster and elite modifiers

- Chaos Wastes already has the pieces: grudge-mark enhancements via `TerrorEventUtils.add_enhancements_to_spawn_data` (the `pre_spawn_func`), Khorne champions and Belakor lieutenants.
- Use the enhancement path (`apply_breed_enhancements` runs in `_post_spawn_unit`). It is networked *and* shows grudge-mark icons on clients, and every buff is vanilla, so lookups are safe.
- The number of enhancements per elite or monster rises with `coeff`.

---

## 6. Player scaling

### 6.1 Boon drops

Flow, with an owner at each step:

1. **Kill (host).** Hook the death reaction or `server_ai_killed`. Roll against a loot table by breed tier (trash / elite / special / boss). The roll is scaled by `coeff` and by a pity counter, so drops can't dry up.
2. **Spawn (host).** Call `Managers.state.entity:system("pickup_system"):spawn_pickup(name, pos, rot, true, "dropped")` directly instead of queuing an RPC to ourselves. Add a lifetime so the arena doesn't fill with dice.
3. **Pick up (every peer runs `on_pick_up_func`).** Grant only when the interactor belongs to this peer:

   ```lua
   on_pick_up_func = function (world, interactor_unit, is_server, interactable_unit, is_husk)
       local owner = Managers.player:owner(interactor_unit)
       if is_husk or not owner or not owner.local_player or owner.bot_player then return end
       mod:grant_random_boon(tier)   -- runs on the picker's machine only
   end
   ```

4. **Grant (owning client).** `run_controller:generate_random_power_ups(1, availability, seed)` → `run_controller:add_power_ups({power_up}, local_player_id, true)`. Call it **once**: it handles activation, the RPC to the host, and the reward popup.
5. **Persist (host).** Vanilla `DeusSpawning._apply_initial_buffs` re-adds every stored boon on respawn.

- **Bots:** set `disallow_bot_pickup = true`, as coins do. If we want bots to scale too, the host can grant bot boons via `add_power_ups` with the bot's `local_player_id`.
- **Shared vs. individual drops** is a design choice (see §8). Coins are shared in vanilla. Shared drops would be: the host spawns the pickup, and when it is picked up the host sends a VMF RPC to `"all"`, and each peer grants itself a boon.

### 6.2 Uncapping and stacking

- **Stack limit:** at load, set `DeusPowerUps[rarity][name].max_amount = math.huge` for the stat boons. Edit the runtime table, not `DeusPowerUpTemplates`. Thanks to the set-count bug, anything with `max_amount > 1` is never excluded from rolls.
- **Pool:** add a custom availability key (`DeusPowerUpAvailabilityTypes.risk_of_rats = "risk_of_rats"`) and append it to each eligible power-up's `availability` list:
  - stat boons for "stats" drops
  - shrine and cursed-chest boons for rare and above
  - Uniques that don't stack meaningfully stay `max_amount = 1`.
- **Diminishing returns for inverting stats.** Hook `BuffExtension.apply_buffs_to_value` for `activated_cooldown`, `block_cost`, `faster_revive`, `faster_respawn`, `damage_taken` and `curse_protection`. Remap the summed negative multiplier hyperbolically, RoR2-style:

  ```
  effective = -(1 - 1 / (1 + k * |Σ|))     -- approaches -100% but never reaches it
  ```

  This is a *local, deterministic* transform of values every peer already computes identically, so it needs no sync, as long as every peer runs the mod.
- **Raise the engine clamps** that conflict with "no caps":
  - **Air movement:** hook `PlayerCharacterStateHelper.move_in_air` and the jump state to use the per-unit `move_speed` instead of the global 4.0. Otherwise high move speed feels awful when jumping.
  - **Stamina:** the 100-point clamp in `_get_current_max_fatigue_points`. Raise it modestly; the UI only draws 20 shields, so the fatigue UI would need work too.
  - Crit chance saturates naturally. Overflow could later convert into crit power, like RoR2's Predatory Instincts.
- **Scale check:** each copy is one buff instance plus one `rpc_add_buff`. On respawn the host re-sends *every* boon. With hundreds of boons that is a burst of RPCs, and `SharedState` re-sends the whole encoded power-up list (about 12 bytes per boon, chunked into 500-character pieces) on every pickup. If profiling shows a problem, a later optimization is to "fold" N copies of a stat boon into one custom stacking buff with `external_optional_multiplier = N * per_copy`. That buff needs one custom buff template, which is fine once the handshake (§6.3) is in place.

### 6.3 Mod-required handshake

- Use VMF `network_register` / `network_send`. VMF only delivers to peers that have the mod (`vmf/.../network.lua:234-268`).
- **When a peer joins, the host sends `{version, lookup_fingerprint}`.** The fingerprint is a hash over our `NetworkLookup` additions and their indices. The client replies with its own.
- **If anything doesn't match, or there is no reply within N seconds**, the host refuses to start the Risk of Rats journey, or kicks to the lobby, and posts a chat message explaining why. This turns "mysterious crash" into a clear error.

---

## 7. Module layout (proposed)

```
scripts/mods/endlessChaos/
  endlessChaos.lua                -- entry: requires modules, registers hooks, mod events
  core/
    net.lua                       -- VMF RPC registration, handshake, coeff broadcast
    lookups.lua                   -- ALL NetworkLookup additions in one place (deterministic order) + fingerprint
    util.lua                      -- is_host(), local player helpers, safe logging
  journey/
    journey.lua                   -- DeusJourneySettings / LevelSettings / populate settings (additive only!)
    arena_waves.lua               -- endless wave director (host)
    plaza_blueprints.lua          -- (current endlessChaosPlazaEvent.lua)
  scaling/
    difficulty.lua                -- coeff(t, wave), tunables per difficulty (host)
    enemy_scaling.lua             -- ai_spawned hook, local buffs, health clamp (host)
    modifiers.lua                 -- elite/monster enhancement selection (host)
  boons/
    drops.lua                     -- kill roll, loot tables, spawn_pickup (host)
    pickups.lua                   -- pickup templates + on_pick_up_func (owner check)
    grant.lua                     -- generate + add_power_ups (owning client)
    uncap.lua                     -- max_amount, availability, diminishing returns, clamp hooks
  ui/
    difficulty_meter.lua          -- client-only HUD from broadcast coeff
  localization.lua
```

**Rule of thumb, written as a header comment in each file:** "Runs on: HOST | OWNER | ALL (deterministic)".

---

## 8. Decisions and open questions

Decided (2026-11-22):

1. **Structure:** Option A. v1 stays on the Fortunes of War arena; the map loop is a later goal.
2. **Drops:** individual. Whoever grabs the drop gets the boon. Bots and other NPCs never pick them up.
3. **Drop model:** the loot die (`units/props/dice_bowl/pup_loot_die`).
4. **Coins:** collectable, with no use yet.

Open:

5. **Talent boons** (the `talent_X_Y` power-ups): allow them in drops? They go through `deus_backend:set_deus_talent_ids`, which is more invasive than buff boons. Currently allowed, because they are in the `cursed_chest` pool that rare-and-up drops roll from.

---

## 9. Milestones

> **Milestone 1 status (2026-11-22):** code written and statically checked, **not yet tested in-game**.
> Beyond bugs 1–10, it also fixes:
> - `num_spawned_enemies` called the nonexistent `ConflictDirector:spawned_units()`, a host error at the first wave wait.
> - The journey leaked into Chaos Wastes quickplay, the public lobby browser, and the weekly Belakor rotation (all three iterate `AvailableJourneyOrder`).
> - Winning the run would error in journey-completion stats.
> - The old `givebuff` command referenced a boon (`deus_extra_shot`) that no longer exists.
> - Boon caps above 1 were never enforced. A reroll in `grant.lua` now enforces them.
>
> Enemy scaling is **removed** until milestone 2.

1. **Stabilize (no new features).**
   - Fix bugs 1–10.
   - Split into modules.
   - Centralize lookups.
   - Add the handshake.
   - *Test:* a vanilla Chaos Wastes run still works with the mod on; a 2-player session reaches the arena.
2. **Enemy scaling v2.**
   - Host coeff.
   - Spawn-hook local buffs.
   - Remove `Breeds` and `calculate_damage` edits.
   - Debug command that prints `NetworkConstants.health/damage/damage_hotjoin_sync` max values.
   - *Test:* the client health bar matches the host on fresh and recycled units.
3. **Drops and grants.**
   - Owner-checked pickup.
   - Single `add_power_ups`.
   - Uncapped `max_amount`.
   - Custom availability pool.
   - *Test:* 2 clients plus host each pick up dice; only the picker gains a boon; boons survive death.
4. **Endless waves.** Wave director with procedural waves after wave 8, difficulty meter UI.
5. **Uncap polish.** Diminishing returns, air-move clamp, stamina clamp, crit overflow.
6. **Stretch.** Map loop (Option B), folded stat buffs for performance, custom boons.
