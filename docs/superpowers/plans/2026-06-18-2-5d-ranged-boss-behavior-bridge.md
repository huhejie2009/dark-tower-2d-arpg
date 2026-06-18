# 2.5D Ranged And Boss Behavior Bridge Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make 2.5D enemy types play differently: shadow archers kite and attack at range, while the tower gatekeeper exposes a readable warning-based slam.

**Architecture:** Keep the logic inside `Prototype2_5DCombatRoom` for this phase, but drive it from existing `FloorRules` enemy data. Add a compact behavior snapshot API so future authored VFX/AI work can replace the programmatic placeholder without changing tests or downstream tooling.

**Tech Stack:** Godot 4.6.2, GDScript, existing `FloorRules`, 2.5D billboard runtime, programmatic placeholder VFX.

---

### Task 1: Failing Regression

**Files:**
- Create: `tests/regression/regression_prototype_2_5d_ranged_boss_behavior_bridge.gd`

- [ ] Apply floor 3 and verify a `shadow_archer` retreats when the player is too close.
- [ ] Verify the same archer can attack from range and damage the player without needing melee distance.
- [ ] Apply floor 5 and verify a `tower_gatekeeper` can spawn a named slam warning marker.
- [ ] Resolve the slam and verify player health changes when standing inside the warning radius.

### Task 2: 2.5D Ranged Behavior

**Files:**
- Modify: `scripts/app/Prototype2_5DCombatRoom.gd`

- [ ] Add ranged behavior fields to enemy state: `uses_projectile`, `preferred_distance`, `retreat_distance`, `behavior_intent`, `last_attack_kind`.
- [ ] Update `_update_enemy_loop()` so `shadow_archer` retreats, approaches, or attacks based on distance.
- [ ] Keep melee enemies on the existing chase/attack path.
- [ ] Add behavior snapshot and deterministic tick hooks.

### Task 3: 2.5D Boss Slam Placeholder

**Files:**
- Modify: `scripts/app/Prototype2_5DCombatRoom.gd`

- [ ] Add a scene-level boss VFX root and warning marker.
- [ ] Add `force_boss_slam_for_test()` and `resolve_boss_slam_for_test()` hooks.
- [ ] Store last boss skill state in a snapshot.
- [ ] Damage the player if inside the warning radius.

### Task 4: Verification And Documentation

**Files:**
- Modify: `README.md`
- Create: `docs/progress/2026-06-18-2-5d-ranged-boss-behavior-bridge-progress.md`

- [ ] Document the behavior bridge and note that VFX is still programmatic placeholder.
- [ ] Run red/green regression, focused 2.5D tests, full regression, and headless boot.
- [ ] Commit and push only intentional files.
