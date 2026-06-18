# 2.5D Floor Wave Template Bridge Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Connect the accepted 2.5D tower runtime to the existing floor template rules so tower floors have distinct enemy waves and objective pacing.

**Architecture:** `Prototype2_5DCombatRoom` will reuse `FloorRules.build_floor_template()` and `RoomObjectiveService` instead of hard-coded two-enemy prototype spawning. The 2D floor spawn coordinates will be converted into 2.5D XZ coordinates through a small local mapper, keeping later authored room assets free to swap the mapper without changing floor content rules.

**Tech Stack:** Godot 4.6.2, GDScript, existing `FloorRules`, `RoomObjectiveService`, 2.5D `BillboardActor3D` runtime.

---

### Task 1: Failing Regression

**Files:**
- Create: `tests/regression/regression_prototype_2_5d_floor_wave_template_bridge.gd`

- [ ] Instantiate the active 2.5D runtime on floors 1, 3, 4, and 5.
- [ ] Verify the scene exposes a floor wave snapshot and floor template test hook.
- [ ] Verify floor 1 is `standard_clear`, floor 3 is `ranged_pressure`, floor 4 is `guardian_mix`, and floor 5 is `boss_gatekeeper`.
- [ ] Verify snapshots expose enemy types, ranks, objective text, and template enemy counts.

### Task 2: Runtime Template Bridge

**Files:**
- Modify: `scripts/app/Prototype2_5DCombatRoom.gd`

- [ ] Preload `FloorRules` and `RoomObjectiveService`.
- [ ] Add `current_floor_template` and `room_objective_state`.
- [ ] Replace hard-coded two-enemy reset with `_spawn_floor_template(FloorRules.build_floor_template(current_floor))`.
- [ ] Build enemy state from `FloorRules.get_enemy_type_data()` so type, rank, boss/elite flags, health, speed, damage, cooldown, and range are available to 2.5D combat.
- [ ] Convert 2D spawn positions to 2.5D XZ positions with clamp bounds that avoid walls.
- [ ] Update HUD objective from `RoomObjectiveService` and record defeated enemies into objective state.
- [ ] Add a `build_floor_wave_snapshot_for_test()` snapshot and `_apply_floor_template_for_test(floor)` hook.

### Task 3: Compatibility Updates

**Files:**
- Modify affected 2.5D regression tests that assumed exactly two enemies.

- [ ] Change fixed-count assertions into assertions based on snapshot counts.
- [ ] Keep attack and clear behavior assertions intact.

### Task 4: Verification And Documentation

**Files:**
- Modify: `README.md`
- Create: `docs/progress/2026-06-18-2-5d-floor-wave-template-bridge-progress.md`

- [ ] Document the 2.5D floor wave bridge.
- [ ] Run the new regression red/green, focused 2.5D regressions, full regression loop, and headless boot.
- [ ] Commit and push only intentional files.
