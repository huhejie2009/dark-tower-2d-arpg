# 2.5D Combat Rhythm And Player Feedback Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the accepted 2.5D tower prototype feel more like a readable game loop by giving the gatekeeper an automatic skill cadence and making player damage visibly/structurally legible.

**Scope:** No new generated art. This pass is gameplay timing, feedback state, and QA-facing snapshots only.

---

### Task 1: Failing Regression

**Files:**
- Create: `tests/regression/regression_prototype_2_5d_combat_rhythm_player_feedback.gd`

- [x] Verify the runtime exposes player damage feedback snapshots.
- [x] Verify the runtime exposes deterministic feedback ticking.
- [x] Verify the tower gatekeeper auto-starts slam when the player is in skill range.
- [x] Verify the resolved slam damages the player.
- [x] Verify player damage records hurt state, invulnerability, hit flash, knockback, event count, and source kind.
- [x] Verify immediate follow-up damage is blocked by invulnerability.

### Task 2: Boss Combat Cadence

**Files:**
- Modify: `scripts/app/Prototype2_5DCombatRoom.gd`

- [x] Add boss slam cooldown fields to enemy state.
- [x] Check boss skill intent before melee/ranged attack logic.
- [x] Start slam automatically when the player is inside readable skill range.
- [x] Preserve existing forced boss slam test hooks.

### Task 3: Player Damage Feedback

**Files:**
- Modify: `scripts/app/Prototype2_5DCombatRoom.gd`

- [x] Route player damage through `DamageFeedbackService`.
- [x] Add short invulnerability, hurt duration, hit flash timer, knockback vector, and source kind state.
- [x] Block immediate follow-up damage during invulnerability and count blocked hits.
- [x] Add deterministic tick and snapshot APIs.

### Task 4: Verification

**Files:**
- Modify: `README.md`
- Create: `docs/progress/2026-06-19-2-5d-combat-rhythm-player-feedback-progress.md`

- [x] Run red/green regression.
- [x] Run focused 2.5D regressions.
- [x] Run Godot AI plugin regression.
- [x] Run full regression and headless boot.
- [x] Commit and push intentional files only.
