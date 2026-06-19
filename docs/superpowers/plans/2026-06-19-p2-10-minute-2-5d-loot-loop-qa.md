# P2 10 Minute 2.5D Loot Loop QA Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Connect the active 2.5D tower runtime to the existing P2 10-minute loot-loop acceptance model and expose a deterministic QA report for the first playable climb.

**Architecture:** Reuse `P2LootLoopMetricsRecorder` and `P2LootLoopAcceptanceService` instead of inventing a second QA system. Add a 2.5D runtime bridge that records kills, pickups, floor clears, equipment changes, deaths, elapsed time, verification gates, and start-floor source, then expose a compact snapshot for regression and future Godot AI inspection.

**Tech Stack:** Godot 4.6.2, GDScript, existing regression scripts, godot-devtool MCP capability checks, PowerShell verification.

---

### Task 1: 2.5D P2 Loot Loop Regression

**Files:**
- Create: `tests/regression/regression_prototype_2_5d_p2_loot_loop_qa_bridge.gd`

- [x] Write a failing regression that loads `Prototype2_5DCombatRoom`.
- [x] Seed a transient player on floor 1 with stable warrior data.
- [x] Require `build_p2_loot_loop_qa_snapshot_for_test()`.
- [x] Require `set_p2_loot_loop_elapsed_seconds_for_test()`.
- [x] Clear three floors through the 2.5D test bridge.
- [x] Simulate one equipment change through a test method.
- [x] Verify metrics include at least three cleared floors, eight picked items, one equipment pickup, one upgrade candidate, one equipment change, ten minutes elapsed, zero P0 defects, and a readable report.
- [x] Verify the snapshot explains the current start floor and highest-floor relationship so unexpected high-floor starts are diagnosable.

### Task 2: Runtime Metrics Bridge

**Files:**
- Modify: `scripts/app/Prototype2_5DCombatRoom.gd`

- [x] Preload `P2LootLoopMetricsRecorder`.
- [x] Add `p2_loot_loop_metrics` and initialize it in `_ready()`.
- [x] Add elapsed-time recording in `_physics_process()`.
- [x] Record enemy drops and boss rewards through `record_pickup()`.
- [x] Record floor clears through `record_floor_cleared()`.
- [x] Record equipment changes through inventory-window save hooks.
- [x] Record deaths through the death-settlement path.
- [x] Add `build_p2_loot_loop_qa_snapshot_for_test()`.
- [x] Add `set_p2_loot_loop_elapsed_seconds_for_test()`.
- [x] Add `record_equipment_change_for_test()`.
- [x] Include `start_floor_source`, `current_floor`, `player_highest_floor`, HUD objective, last loot notification, metrics, and acceptance report in the snapshot.

### Task 3: Acceptance Text Cleanup

**Files:**
- Modify: `scripts/data/P2LootLoopAcceptanceService.gd`
- Modify: `docs/qa/2026-06-08-p2-10-minute-loot-loop-acceptance.md`

- [x] Replace garbled acceptance strings with readable Chinese and stable English metric keys.
- [x] Keep thresholds unchanged.
- [x] Preserve `evaluate_metrics(metrics)` output shape.

### Task 4: Documentation

**Files:**
- Modify: `README.md`
- Create: `docs/progress/2026-06-19-p2-10-minute-2-5d-loot-loop-qa-progress.md`

- [x] Document the 2.5D P2 QA bridge.
- [x] Document what the report proves and what remains manual.
- [x] Document verification evidence after checks pass.

### Task 5: Verification

- [x] Run new regression red before implementation.
- [x] Run new regression green after implementation.
- [x] Run focused P2 and 2.5D regressions.
- [x] Run Godot AI plugin regression.
- [x] Run full regression.
- [x] Run headless boot.
- [x] Run `git diff --check`.
- [x] Commit and push intentional files only.
