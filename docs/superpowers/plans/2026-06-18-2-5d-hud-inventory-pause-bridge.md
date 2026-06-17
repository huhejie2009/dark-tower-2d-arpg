# 2.5D HUD Inventory Pause Bridge Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give the accepted 2.5D tower runtime the same essential combat HUD, inventory/equipment window, and safe pause behavior that already exists in the legacy 2D combat runtime.

**Architecture:** Reuse `HudController` and `InventoryEquipmentWindow` instead of creating another UI stack. `Prototype2_5DCombatRoom` owns the bridge, synchronizes save data, and pauses the SceneTree whenever pause overlay or inventory is visible.

**Tech Stack:** Godot 4.6.2, GDScript, existing dark ARPG UI controllers, regression scripts under `tests/regression`.

---

### Task 1: Lock The 2.5D UI Bridge Contract

**Files:**
- Create: `tests/regression/regression_prototype_2_5d_hud_inventory_pause_bridge.gd`

- [x] **Step 1: Write the failing test**

Add a regression that instantiates `GameConstants.ACTIVE_GAME_SCENE`, confirms it exposes HUD/inventory/pause hooks, toggles inventory and pause, verifies `get_tree().paused`, and checks HUD text contains floor and bag information.

- [x] **Step 2: Run test to verify it fails**

Run:

```powershell
& 'C:\Users\huhej\OneDrive\桌面\Godot_v4.6.2-stable_win64_console.exe' --headless --path 'H:\GODOT_PROJECT\dark-tower-2d-arpg' --script 'res://tests/regression/regression_prototype_2_5d_hud_inventory_pause_bridge.gd'
```

Expected: FAIL because the 2.5D runtime has no HUD/inventory/pause bridge methods yet.

### Task 2: Reuse Shared HUD And Inventory In 2.5D

**Files:**
- Modify: `scripts/app/Prototype2_5DCombatRoom.gd`

- [x] **Step 1: Add existing UI preloads and state**

Preload `HudController`, `InventoryEquipmentWindow`, `InventoryDataService`, and `DarkArpgUiTheme`. Add `hud`, `inventory_window`, `pause_overlay`, and `pause_resume_button` fields.

- [x] **Step 2: Create UI after the 2.5D debug HUD**

Call `_create_hud()`, `_create_inventory_window()`, `_create_pause_overlay()`, and `_update_hud("Entered floor ...")` during `_ready()`.

- [x] **Step 3: Keep combat blocked while UI is open**

Make `_physics_process()` and mouse attack ignore combat when pause or inventory is visible. Keep UI controls in `PROCESS_MODE_ALWAYS`.

### Task 3: Input, Save, And Snapshot Hooks

**Files:**
- Modify: `scripts/app/Prototype2_5DCombatRoom.gd`

- [x] **Step 1: Add keyboard bridge**

Handle `Esc` with `_handle_cancel()`, `I/C` with `_toggle_inventory_window()`, and `E` only when combat is not menu-blocked.

- [x] **Step 2: Persist inventory/equipment edits**

Connect `inventory_window.player_data_changed` into `_on_player_data_changed()`, update local `player_data`, save active player data, and refresh HUD.

- [x] **Step 3: Expose test snapshots**

Add `build_hud_inventory_pause_snapshot_for_test()`, `_toggle_pause_for_test()`, `_toggle_inventory_window_for_test()`, and `_handle_cancel_for_test()`.

### Task 4: Verify And Document

**Files:**
- Modify: `README.md`
- Create: `docs/progress/2026-06-18-2-5d-hud-inventory-pause-bridge-progress.md`

- [ ] **Step 1: Run focused 2.5D regressions**

Run the new bridge test plus the existing 2.5D main-flow and visual tests.

- [ ] **Step 2: Run full regression**

Run all scripts under `tests/regression`.

- [ ] **Step 3: Launch smoke tests**

Run headless boot and a short runtime launch, then confirm no hidden Godot test process remains.

- [ ] **Step 4: Commit and push**

Stage only intentional files and push to `codex/pixel-actor-art-trial`.
