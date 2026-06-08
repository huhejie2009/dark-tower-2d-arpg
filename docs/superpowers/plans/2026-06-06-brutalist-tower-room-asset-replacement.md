# Brutalist Tower Room Asset Replacement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current warm ornate room background with a playable cold brutalist tower interior that matches the approved megastructure tower concept direction.

**Architecture:** Keep the existing top-down production camera and foot-anchor collision model. Replace the environment asset path, visual contract, room colors, and prop names while preserving generated asset directories and IMAGE2-ready interfaces.

**Tech Stack:** Godot 4.6.2, GDScript, generated PNG environment assets, existing regression scripts under `tests/regression`.

---

### Task 1: Lock The New Visual Contract

**Files:**
- Modify: `H:\GODOT_PROJECT\dark-tower-2d-arpg\tests\regression\regression_image2_environment_background_contract.gd`
- Modify: `H:\GODOT_PROJECT\dark-tower-2d-arpg\tests\regression\regression_topdown_production_view_contract.gd`

- [ ] **Step 1: Write failing assertions**

Add checks that require:
- environment path contains `tower_interior_brutalist_room`
- contract exposes `world_art_anchor = "cold_megastructure_dark_core"`
- contract exposes `forbidden_style = "mhxy_ornate_palace"`
- visual style exposes `environment_family = "brutalist_tower_interior"`
- scene contains `TopDownDarkCoreLightChannel`

- [ ] **Step 2: Run the two tests**

Run:

```powershell
$godot = 'C:\Users\huhej\OneDrive\桌面\Godot_v4.6.2-stable_win64_console.exe'
$project = 'H:\GODOT_PROJECT\dark-tower-2d-arpg'
& $godot --headless --path $project --script 'res://tests/regression/regression_image2_environment_background_contract.gd'
& $godot --headless --path $project --script 'res://tests/regression/regression_topdown_production_view_contract.gd'
```

Expected before implementation: at least one assertion fails because the project still uses `mhxy_isometric_room_bg_v1.png` and does not expose the new art contract fields.

### Task 2: Add The New Environment Asset

**Files:**
- Create: `H:\GODOT_PROJECT\dark-tower-2d-arpg\assets\generated\environments\tower_interior_brutalist_room_v1.png`

- [ ] **Step 1: Generate or copy a project-bound PNG**

Create a top-down production room background based on the approved concept: cold concrete, wide megastructure interior, central dark blue vertical light channel, no ornate Chinese palace elements, no warm lanterns, no mountains.

- [ ] **Step 2: Let Godot import it**

Run headless editor import:

```powershell
$godot = 'C:\Users\huhej\OneDrive\桌面\Godot_v4.6.2-stable_win64_console.exe'
$project = 'H:\GODOT_PROJECT\dark-tower-2d-arpg'
& $godot --headless --editor --path $project --quit
```

Expected: exit code `0`, `.import` metadata created by Godot.

### Task 3: Replace Game2D Environment Wiring

**Files:**
- Modify: `H:\GODOT_PROJECT\dark-tower-2d-arpg\scripts\app\Game2D.gd`

- [ ] **Step 1: Update constants**

Set:

```gdscript
const ENVIRONMENT_FAMILY := "brutalist_tower_interior"
const WORLD_ART_ANCHOR := "cold_megastructure_dark_core"
const FORBIDDEN_STYLE := "mhxy_ornate_palace"
const IMAGE2_ENVIRONMENT_BACKGROUND_PATH := "res://assets/generated/environments/tower_interior_brutalist_room_v1.png"
```

- [ ] **Step 2: Rename and recolor tower interior layers**

Keep existing top-down geometry, but rename `mhxy` helpers toward tower interior naming and shift procedural fallback colors to cold gray-blue concrete with muted dark-blue light channels.

- [ ] **Step 3: Extend test contracts**

Return the new fields from `_get_visual_style_for_test()` and `_get_environment_asset_contract_for_test()`.

### Task 4: Verify And Document

**Files:**
- Create: `H:\GODOT_PROJECT\dark-tower-2d-arpg\docs\progress\2026-06-06-brutalist-tower-room-asset-replacement-progress.md`

- [ ] **Step 1: Run focused tests**

Run the two visual contract tests and scene boot test.

- [ ] **Step 2: Run complete regression**

Run all scripts under `tests/regression`.

- [ ] **Step 3: Start headless main project**

Run:

```powershell
$godot = 'C:\Users\huhej\OneDrive\桌面\Godot_v4.6.2-stable_win64_console.exe'
$project = 'H:\GODOT_PROJECT\dark-tower-2d-arpg'
& $godot --headless --path $project --quit-after 2
```

Expected: exit code `0`.

- [ ] **Step 4: Write progress note**

Record changed files, asset path, validation results, and boundaries: no save clearing, no old 3D project, no POLYGON resources.
