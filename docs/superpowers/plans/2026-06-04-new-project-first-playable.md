# New 2D Dark ARPG First Playable Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a clean Godot 4.6.2 project that boots into a stable 2D dark ARPG loop with menu, character select, town, tower combat, drops, inventory, and regression tests.

**Architecture:** The new project is 2D-only. Scenes own presentation and input, while save/data/rule services operate on Dictionaries so combat does not directly mutate persistent storage every frame.

**Tech Stack:** Godot 4.6.2, GDScript, headless regression scripts.

---

### Task 1: Project Skeleton

**Files:**
- Create: `project.godot`
- Create: `scenes/MainMenu.tscn`
- Create: `scenes/CharacterSelect.tscn`
- Create: `scenes/Town.tscn`
- Create: `scenes/Game2D.tscn`

- [x] **Step 1: Create project config**

Configure `MainMenu.tscn` as the main scene and register gameplay input actions.

- [x] **Step 2: Create four bootable scenes**

Each scene has one root node and one script. No 3D nodes, no old project resources.

### Task 2: Core Services

**Files:**
- Create: `scripts/save/SaveSchema.gd`
- Create: `scripts/save/SaveManager.gd`
- Create: `scripts/data/PlayerDataService.gd`
- Create: `scripts/data/InventoryDataService.gd`
- Create: `scripts/data/EquipmentDataService.gd`
- Create: `scripts/data/TowerProgressService.gd`
- Create: `scripts/rules/ClassRules.gd`
- Create: `scripts/rules/SkillRules.gd`
- Create: `scripts/rules/EquipmentAffixRules.gd`
- Create: `scripts/rules/LootRules.gd`

- [x] **Step 1: Add pure data defaults**

Create default save, default character, starter equipment, tower progress, and deterministic simple loot.

- [x] **Step 2: Add save API**

Expose `load_save()`, `save_data()`, `create_character()`, `get_active_player_data()`, and `apply_floor_clear()`.

### Task 3: Combat Loop

**Files:**
- Create: `scripts/combat/Player2D.gd`
- Create: `scripts/combat/Enemy2D.gd`
- Create: `scripts/combat/DropItem2D.gd`
- Create: `scripts/combat/Skill2DLibrary.gd`
- Create: `scripts/combat/Vfx2DFactory.gd`
- Create: `scripts/ui/HudController.gd`
- Create: `scripts/app/SceneRouter.gd`
- Create: `scripts/app/GameConstants.gd`

- [x] **Step 1: Add movement and attack**

Player supports WASD/arrow movement and left mouse attack.

- [x] **Step 2: Add enemies and drops**

Enemies chase, attack, die once, and emit a drop. Drops collect into an inventory snapshot.

- [x] **Step 3: Add floor clear loop**

Clearing enemies opens a portal. Pressing E or entering the portal advances the floor.

### Task 4: Scene Scripts

**Files:**
- Create: `scripts/app/MainMenu.gd`
- Create: `scripts/app/CharacterSelect.gd`
- Create: `scripts/app/Town.gd`
- Create: `scripts/app/Game2D.gd`

- [x] **Step 1: Menu to character select**

Main menu can start the flow.

- [x] **Step 2: Character select to town**

Character select creates a starter warrior by default and enters town.

- [x] **Step 3: Town to tower**

Town enters `Game2D.tscn` and displays active character/floor.

### Task 5: Regression

**Files:**
- Create: `tests/regression/regression_scene_boot.gd`
- Create: `tests/regression/regression_game2d_input_contract.gd`
- Create: `tests/regression/regression_enemy_death_once.gd`
- Create: `tests/regression/regression_floor_clear_portal.gd`
- Create: `tests/regression/regression_pickup_inventory_bridge.gd`
- Create: `tests/regression/regression_equipment_can_equip.gd`

- [x] **Step 1: Run every new regression**

Expected outputs include scene boot OK, movement/attack OK, enemy death once OK, floor clear portal OK, pickup inventory OK, and equipment can equip OK.

- [x] **Step 2: Run project boot smoke**

Run the project headless with `--quit-after 5`.

### Task 6: Progress Documentation

**Files:**
- Create: `docs/progress/2026-06-04-new-project-first-playable-progress.md`

- [x] **Step 1: Record what exists**

Summarize created scenes, scripts, tests, and verification commands.
