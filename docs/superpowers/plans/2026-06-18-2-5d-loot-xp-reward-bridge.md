# 2.5D Loot XP Reward Bridge Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the accepted 2.5D tower runtime produce real ARPG progression: enemy XP, kill drops, floor-clear rewards, boss-floor guaranteed equipment, HUD updates, and saved progress.

**Architecture:** Reuse existing production services from the legacy 2D combat runtime: `PlayerDataService`, `InventoryDataService`, `LootRules`, `LootNotificationService`, and `TowerProgressService`. The 2.5D scene owns only bridge state such as kill count, pickup names, last reward, and last notification.

**Tech Stack:** Godot 4.6.2, GDScript, existing save/inventory/loot services, regression scripts under `tests/regression`.

---

### Task 1: Lock The 2.5D Reward Contract

**Files:**
- Create: `tests/regression/regression_prototype_2_5d_loot_xp_reward_bridge.gd`

- [x] **Step 1: Write the failing test**

Instantiate `GameConstants.ACTIVE_GAME_SCENE` on floor 5 with a player close to leveling. Kill one enemy and assert XP, level, inventory, loot notification, and HUD data change. Kill the second enemy and assert floor-clear rewards, boss guaranteed equipment, saved highest floor, and pending floor rewards are recorded.

- [x] **Step 2: Run test to verify it fails**

Run:

```powershell
& 'C:\Users\huhej\OneDrive\桌面\Godot_v4.6.2-stable_win64_console.exe' --headless --path 'H:\GODOT_PROJECT\dark-tower-2d-arpg' --script 'res://tests/regression/regression_prototype_2_5d_loot_xp_reward_bridge.gd'
```

Expected: FAIL because `Prototype2_5DCombatRoom` does not yet expose reward snapshots or apply XP/loot/floor rewards.

### Task 2: Add Reward State And Service Bridges

**Files:**
- Modify: `scripts/app/Prototype2_5DCombatRoom.gd`

- [x] **Step 1: Add preloads**

Preload:

```gdscript
const LootNotificationServiceScript := preload("res://scripts/data/LootNotificationService.gd")
const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")
const TowerProgressServiceScript := preload("res://scripts/data/TowerProgressService.gd")
const LootRulesScript := preload("res://scripts/rules/LootRules.gd")
```

- [x] **Step 2: Add state**

Track `kill_index`, `floor_kill_count`, `floor_pickup_names`, `last_floor_rewards`, and `last_loot_notification`.

### Task 3: Apply Enemy XP And Drops

**Files:**
- Modify: `scripts/app/Prototype2_5DCombatRoom.gd`

- [x] **Step 1: Store enemy identity**

Enemy states include `enemy_type`, `display_rank`, `is_elite`, and `is_boss`.

- [x] **Step 2: Award XP and direct drop on defeat**

On `_defeat_enemy`, increment kill state, call `PlayerDataService.add_experience`, generate a deterministic drop through `LootRules.generate_enemy_drop`, add it to inventory, show HUD loot notification, save, and refresh HUD.

### Task 4: Apply Floor Clear Rewards

**Files:**
- Modify: `scripts/app/Prototype2_5DCombatRoom.gd`

- [x] **Step 1: Build and apply floor reward**

When all enemies are defeated, call the same floor reward flow as `Game2D`: `TowerProgressService.build_floor_reward`, add boss guaranteed item when needed, save through `SaveManager.apply_floor_clear`, and keep `exit_unlocked`.

- [x] **Step 2: Reset per-floor state on next floor**

Reset kill count, pickup names, last floor reward, and notification when entering the next floor and spawning a new wave.

### Task 5: Verify And Document

**Files:**
- Modify: `README.md`
- Create: `docs/progress/2026-06-18-2-5d-loot-xp-reward-bridge-progress.md`

- [ ] **Step 1: Run focused 2.5D regressions**

Run the new reward test plus HUD/pause, main-flow, scene boot, enemy loop, and real texture tests.

- [ ] **Step 2: Run full regression**

Run every script under `tests/regression`.

- [ ] **Step 3: Launch smoke tests**

Run headless boot, short runtime launch, and process cleanup check.

- [ ] **Step 4: Commit and push**

Stage only intentional code, test, README, plan, and progress files.
