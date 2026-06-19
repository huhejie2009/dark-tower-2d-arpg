# 2026-06-19 2.5D Enemy Readability VFX Contract Progress

## Goal

Improve first-pass combat readability in the 2.5D tower prototype without adding generated art. This pass adds stable temporary hooks for future authored projectile and boss skill VFX.

## Completed

- Added an independent `PrototypeRangedProjectileVfxRoot`.
- Added a temporary `enemy_projectile` marker for shadow archer attacks.
- Projectile feedback now records:
  - owner enemy type
  - from/to world positions
  - readable path length
  - lifetime
  - feedback count
  - hit confirmation
- Tower gatekeeper slam now starts in a `charging` phase.
- Boss slam warning remains visible during charge and damage resolves after the telegraph expires.
- Added deterministic `tick_boss_skill_for_test()`.
- Added `build_combat_readability_snapshot_for_test()` for projectile and boss telegraph QA.
- Added regression: `tests/regression/regression_prototype_2_5d_enemy_readability_vfx_contract.gd`.

## Acceptance

- Shadow archer attacks expose a visible independent projectile cue.
- Projectile cue has replaceable role metadata: `enemy_projectile`.
- Boss slam does not damage immediately when charge starts.
- Boss slam resolves after the charge timer and damages the player if they remain inside the warning radius.
- Existing ranged/boss behavior regression remains green.
- Existing player attack VFX regression remains green.

## Notes

- No generated art was added in this pass.
- The projectile marker and boss warning are still temporary Godot geometry.
- These hooks are intended to be swapped later with authored VFX, particles, sprite strips, or material effects without changing gameplay contracts.

## Not Done

- Authored projectile art.
- Authored boss charge/impact VFX.
- Real projectile travel simulation with dodge timing.
- Boss skill AI cadence in normal gameplay.
- Audio cues.
