# 2.5D Floor 1-5 Playable Pacing V1 Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the accepted 2.5D tower runtime from a feature collection into a short playable segment by defining a stable first five-floor rhythm.

**Scope:** No new art or UI redesign. This pass is floor pacing metadata, enemy composition, HUD objective clarity, and deterministic continuous-floor verification.

---

### Task 1: Failing Regression

**Files:**
- Create: `tests/regression/regression_prototype_2_5d_floor_1_to_5_playable_pacing.gd`

- [x] Verify floors 1-5 expose fixed template IDs and pacing roles.
- [x] Verify each floor exposes readable goal hints and start messages.
- [x] Verify intended enemy composition and enemy counts.
- [x] Verify opening damage pressure stays below player max health.
- [x] Verify test can clear each floor and enter the next floor through the 2.5D flow.
- [x] Verify the chain ends on floor 5 as a boss floor.

### Task 2: First Playable Floor Table

**Files:**
- Modify: `scripts/rules/FloorRules.gd`

- [x] Add floor 1 melee intro with two basic enemies.
- [x] Add floor 2 melee density with four basic enemies.
- [x] Keep floor 3 ranged pressure with archers and melee.
- [x] Add floor 4 mixed pressure with guardian, melee, and archer enemies.
- [x] Keep floor 5 gatekeeper boss with supporting melee enemies.
- [x] Attach pacing metadata to all five templates.

### Task 3: Objective / Runtime Bridge

**Files:**
- Modify: `scripts/data/RoomObjectiveService.gd`
- Modify: `scripts/app/Prototype2_5DCombatRoom.gd`
- Modify: `tests/regression/regression_prototype_2_5d_floor_wave_template_bridge.gd`

- [x] Carry goal hint and start message into room objective state.
- [x] Show the floor goal hint in objective HUD text.
- [x] Use floor start message when entering a floor.
- [x] Add `build_floor_pacing_snapshot_for_test()`.
- [x] Add `enter_next_floor_for_test()`.
- [x] Update existing floor bridge regression expectations.

### Task 4: Verification

- [x] Run red/green pacing regression.
- [x] Run focused floor pacing regressions.
- [x] Run focused 2.5D regressions.
- [x] Run Godot AI plugin regression.
- [x] Run full regression and headless boot.
- [x] Commit and push intentional files only.
