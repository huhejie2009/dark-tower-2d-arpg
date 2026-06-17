# 2.5D Billboard Animation Player Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a first-pass frame animation playback skeleton for 2.5D Sprite3D billboard actors without adding new final art assets.

**Architecture:** `BillboardActor3D` owns animation manifests, frame timing, facing buckets, region selection, and test snapshots. `Prototype2_5DCombatRoom` only synchronizes gameplay state into actor animation state for player and enemies, keeping combat logic separate from sprite slicing and later asset replacement.

**Tech Stack:** Godot 4.6.2, GDScript, Sprite3D regions, headless regression scripts.

---

### Task 1: Billboard Actor Animation Playback Contract

**Files:**
- Modify: `scripts/prototype/BillboardActor3D.gd`
- Test: `tests/regression/regression_billboard_actor_3d_animation_player.gd`

- [ ] **Step 1: Write the failing test**

Create `tests/regression/regression_billboard_actor_3d_animation_player.gd` that instantiates `BillboardActor3D`, applies a manifest with `idle/run/attack/death`, sets 4-direction offsets, switches states, advances time, and expects:

```gdscript
actor.has_method("apply_visual_asset_manifest_for_test")
actor.has_method("set_actor_animation_for_test")
actor.has_method("tick_actor_animation_for_test")
actor.has_method("get_actor_animation_state_for_test")
```

The test should also verify `run` begins at frame `4`, advances to `5`, 4-dir facing changes resolved frame by offset, attack can be one-shot, and weapon sprite remains a separate node.

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
& 'C:\Users\huhej\OneDrive\桌面\Godot_v4.6.2-stable_win64_console.exe' --headless --path 'H:\GODOT_PROJECT\dark-tower-2d-arpg' --script 'res://tests/regression/regression_billboard_actor_3d_animation_player.gd'
```

Expected: FAIL because `BillboardActor3D` does not yet expose the manifest animation playback hooks.

- [ ] **Step 3: Write minimal implementation**

In `BillboardActor3D.gd`, add:

```gdscript
var visual_asset_manifest: Dictionary = {}
var actor_animation_name := "idle"
var actor_animation_frame := 0
var actor_animation_elapsed := 0.0
var actor_animation_locked_until_end := false
```

Add methods:

```gdscript
apply_visual_asset_manifest(manifest: Dictionary)
set_actor_animation(animation_name: String, force_restart: bool = false, lock_until_end: bool = false)
advance_actor_animation()
tick_actor_animation(delta: float)
get_actor_animation_state() -> Dictionary
update_actor_animation_state(movement: Vector2, attacking: bool, dead: bool = false)
```

Expose matching `_for_test` wrappers and apply Sprite3D `region_enabled` / `region_rect` using frame size and direction offsets.

- [ ] **Step 4: Run test to verify it passes**

Run the same focused test. Expected: `NEW_PROJECT_BILLBOARD_ACTOR_3D_ANIMATION_PLAYER_OK`.

### Task 2: 2.5D Combat Scene Animation State Sync

**Files:**
- Modify: `scripts/app/Prototype2_5DCombatRoom.gd`
- Test: `tests/regression/regression_prototype_2_5d_animation_state_sync.gd`

- [ ] **Step 1: Write the failing test**

Create a scene-level regression that instantiates `Prototype2_5DCombatRoom`, verifies player and enemy animation snapshots exist, moves player to trigger `run`, performs mouse attack to trigger `attack`, advances frames to return to `idle`, then defeats an enemy and expects the enemy animation to be `death`.

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
& 'C:\Users\huhej\OneDrive\桌面\Godot_v4.6.2-stable_win64_console.exe' --headless --path 'H:\GODOT_PROJECT\dark-tower-2d-arpg' --script 'res://tests/regression/regression_prototype_2_5d_animation_state_sync.gd'
```

Expected: FAIL because the combat scene does not yet expose animation sync snapshots and enemies do not sync death state into billboard animation.

- [ ] **Step 3: Write minimal implementation**

In `Prototype2_5DCombatRoom.gd`, add helper methods:

```gdscript
_update_actor_animation(actor: Node3D, movement: Vector2, attacking: bool, dead: bool)
build_animation_state_snapshot_for_test() -> Dictionary
```

Call `_update_actor_animation()` during player movement, enemy chase/attack/idle changes, and `_defeat_enemy()`.

- [ ] **Step 4: Run focused tests**

Run the new scene test, the previous attack/VFX test, and the existing 2.5D player/enemy tests.

Expected: all focused tests exit with code `0`.

### Task 3: Documentation, Full Regression, Commit

**Files:**
- Modify: `README.md`
- Create: `docs/progress/2026-06-17-prototype-2-5d-animation-player-progress.md`

- [ ] **Step 1: Document progress**

Write a Chinese progress note explaining that this is a playback skeleton and interface stabilization pass, not final art.

- [ ] **Step 2: Run full regression**

Run the project regression loop over all `tests/regression/*.gd`.

Expected: `ALL_NEW_PROJECT_REGRESSION_OK`.

- [ ] **Step 3: Run headless boot and process check**

Run the main project headless boot with `--quit`, then verify no residual headless test process remains.

- [ ] **Step 4: Commit and push**

Stage only files touched by this task, excluding generated `.uid` and `.import` files. Commit with:

```bash
git commit -m "Add 2.5D billboard animation player"
```

Push the current branch.
