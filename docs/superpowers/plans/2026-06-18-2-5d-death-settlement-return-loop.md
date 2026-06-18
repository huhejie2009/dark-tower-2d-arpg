# 2.5D Death Settlement Return Loop Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the accepted 2.5D tower runtime support player death, settlement, safe pause, and return-to-town save behavior.

**Architecture:** Reuse the existing `DeathSettlementService` and 2D UI theme patterns, but keep the implementation inside `Prototype2_5DCombatRoom.gd`. Enemy attacks become real damage events against `player_data`; reaching zero health enters a one-shot death settlement state that blocks combat and persists a half-health return snapshot.

**Tech Stack:** Godot 4.6.2, GDScript, existing SaveManager / DeathSettlementService / HUD / InventoryEquipmentWindow services.

---

### Task 1: Failing Regression

**Files:**
- Create: `tests/regression/regression_prototype_2_5d_death_settlement_return_loop.gd`

- [ ] Write a regression that instantiates `GameConstants.ACTIVE_GAME_SCENE`, starts a low-health warrior on floor 8, calls `force_enemy_attack_player_for_test(0)`, and expects `build_death_settlement_snapshot_for_test()` to report an active death settlement overlay, paused tree, zero current health in runtime, half-health saved player, and a non-empty settlement summary.

- [ ] Run the new regression and verify it fails because the 2.5D runtime does not expose the death settlement test API yet.

### Task 2: 2.5D Death Settlement UI And State

**Files:**
- Modify: `scripts/app/Prototype2_5DCombatRoom.gd`

- [ ] Add `DeathSettlementService` preload, death overlay nodes, death state flags, and constants for panel sizing.

- [ ] Create `_create_death_overlay()` in `_ready()` after pause overlay creation.

- [ ] Add `_apply_damage_to_player()`, `_on_player_died()`, `_show_death_settlement()`, `_return_to_town_after_death()`, `_build_death_settlement()`, and snapshot/test helper methods.

- [ ] Update enemy attack resolution so attack cooldown ticks deal deterministic player damage.

- [ ] Update combat blocking and pause sync so death settlement keeps the tree paused and prevents input/combat loops.

### Task 3: Documentation And Verification

**Files:**
- Modify: `README.md`
- Create: `docs/progress/2026-06-18-2-5d-death-settlement-return-loop-progress.md`

- [ ] Document the new 2.5D death/return loop.

- [ ] Run the new regression, related 2.5D regressions, scene boot smoke, full regression loop, and headless boot.

- [ ] Commit and push only the intentional files.
