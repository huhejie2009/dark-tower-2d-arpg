# 2.5D Enemy Readability VFX Contract Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make enemy attacks more readable before final authored art arrives. Shadow archer attacks need an independent projectile cue, and tower gatekeeper slam needs a charge/telegraph window before damage.

**Scope:** Do not add generated art. Use temporary Godot geometry only as replaceable VFX hooks with stable role metadata and regression snapshots.

---

### Task 1: Failing Regression

**Files:**
- Create: `tests/regression/regression_prototype_2_5d_enemy_readability_vfx_contract.gd`

- [x] Verify the 2.5D runtime exposes a combat readability snapshot.
- [x] Verify shadow archer ranged attacks create an independent projectile marker.
- [x] Verify projectile feedback records owner type, path length, count, and hit confirmation.
- [x] Verify tower gatekeeper slam starts with a charge phase and does not damage immediately.
- [x] Verify the slam resolves after charge time and damages the player inside the warning area.

### Task 2: Projectile Readability Hook

**Files:**
- Modify: `scripts/app/Prototype2_5DCombatRoom.gd`

- [x] Add an independent `PrototypeRangedProjectileVfxRoot`.
- [x] Add a replaceable `enemy_projectile` marker.
- [x] Record projectile from/to positions, owner type, count, lifetime, and hit confirmation.
- [x] Keep the projectile cue separate from actor and weapon sprites.

### Task 3: Boss Telegraph Timing

**Files:**
- Modify: `scripts/app/Prototype2_5DCombatRoom.gd`

- [x] Change forced boss slam into a charge phase.
- [x] Add deterministic boss skill tick for regression tests.
- [x] Resolve damage only after the telegraph expires or an explicit test resolver is called.
- [x] Record phase, remaining charge time, radius, resolve count, and hit confirmation.

### Task 4: Verification And Documentation

**Files:**
- Modify: `README.md`
- Create: `docs/progress/2026-06-19-2-5d-enemy-readability-vfx-contract-progress.md`

- [x] Document the temporary VFX contract.
- [x] Run red/green regression.
- [x] Run focused enemy readability regressions.
- [x] Run focused 2.5D regression set.
- [x] Run full regression and headless boot.
- [x] Commit and push intentional files only.
