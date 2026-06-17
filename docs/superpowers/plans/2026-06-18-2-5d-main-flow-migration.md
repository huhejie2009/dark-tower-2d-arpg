# 2.5D Main Flow Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将已验收的 2.5D 战斗原型迁移为主游戏进塔路径的第一阶段运行时，接入玩家数据、楼层请求、进度保存和旧 2D 回退合同。

**Architecture:** `GameConstants.ACTIVE_GAME_SCENE` 继续指向 2.5D 场景；`Prototype2_5DCombatRoom` 从隔离原型升级为主流程兼容场景，消费 `SaveManager` 与 `TowerRunStartService`。旧 `Game2D.tscn` 不删除，保留为 `GAME_2D_SCENE` fallback 和回归参照。

**Tech Stack:** Godot 4.6.2, GDScript, 2.5D Node3D combat room, existing save/routing services, headless regression scripts.

---

### Task 1: 主流程迁移合同

**Files:**
- Create: `tests/regression/regression_prototype_2_5d_main_flow_migration_contract.gd`
- Modify: `scripts/app/Prototype2_5DCombatRoom.gd`
- Modify: `README.md`
- Create: `docs/progress/2026-06-18-prototype-2-5d-main-flow-migration-progress.md`

- [ ] **Step 1: Write the failing test**

新增测试，断言：

```text
GameConstants.ACTIVE_GAME_SCENE == GameConstants.PROTOTYPE_2_5D_COMBAT_SCENE
GameConstants.GAME_2D_SCENE remains res://scenes/Game2D.tscn
2.5D scene consumes TowerRunStartService requested floor
2.5D scene loads SaveManager active player data
2.5D scene exposes main-flow snapshot
2.5D scene can advance to next floor and save highest_floor
2.5D scene exposes return-to-town bridge for main flow
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
& $godot --headless --path $project --script res://tests/regression/regression_prototype_2_5d_main_flow_migration_contract.gd
```

Expected: FAIL because the prototype scene does not yet expose `current_floor`, `player_data`, or main-flow bridge methods.

- [ ] **Step 3: Implement minimal bridge**

In `Prototype2_5DCombatRoom.gd`:

- preload `SaveManager`, `TowerRunStartService`, and `SceneRouter`
- add `player_data`, `current_floor`, `legacy_fallback_scene`
- in `_ready()`, load active player and consume pending floor before building actors
- add `_enter_next_floor()` to increment floor, save active player data, reset room clear state, rebuild enemies
- add `_return_to_town()` and `_return_to_town_for_test()`
- add `build_main_flow_migration_snapshot_for_test()`
- wire `E` to `_enter_next_floor()` when `exit_unlocked`

- [ ] **Step 4: Run focused verification**

Run:

```powershell
& $godot --headless --path $project --script res://tests/regression/regression_prototype_2_5d_main_flow_migration_contract.gd
& $godot --headless --path $project --script res://tests/regression/regression_active_game_mode_2_5d.gd
& $godot --headless --path $project --script res://tests/regression/regression_town_tower_start_options.gd
& $godot --headless --path $project --script res://tests/regression/regression_scene_boot.gd
```

Expected: all PASS.

### Task 2: 验证与提交

- [ ] **Step 1: Run full regression**

Run `git diff --check`, all `tests/regression/*.gd`, headless boot, and process residual check.

- [ ] **Step 2: Commit and push**

Stage only touched files, commit:

```text
Migrate 2.5D prototype into main tower flow
```
