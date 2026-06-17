# 2026-06-18 2.5D Loot / XP / Reward Bridge Progress

## Scope

This pass connects the accepted 2.5D tower runtime to the existing ARPG reward loop:

- enemy XP
- enemy drop payloads
- loot notifications
- inventory insertion
- floor-clear rewards
- boss-floor guaranteed equipment
- saved highest-floor progress

No generated art assets were added.

## Completed

- `Prototype2_5DCombatRoom` now reuses the existing reward services:
  - `PlayerDataService`
  - `InventoryDataService`
  - `LootRules`
  - `LootNotificationService`
  - `TowerProgressService`
- Defeating a 2.5D enemy now:
  - increments kill counters
  - grants deterministic XP using the same enemy XP formula family as `Game2D`
  - can level up the player
  - generates a deterministic loot payload
  - inserts the payload directly into inventory
  - shows the existing HUD loot notification
  - saves player data
- Clearing a 2.5D floor now:
  - builds floor rewards through `TowerProgressService`
  - grants boss-floor guaranteed equipment on floor multiples of 5
  - records pending gold/crystal rewards through `SaveManager.apply_floor_clear`
  - saves next-floor progress
  - unlocks the exit
- The 2.5D reward snapshot exposes structured QA state for future tests.

## Regression Added

- `tests/regression/regression_prototype_2_5d_loot_xp_reward_bridge.gd`

The test verifies:

- floor 5 start request is honored
- enemy defeat grants XP and can level up a near-level player
- enemy drop enters inventory
- loot notification is produced
- HUD status and bag text remain synchronized
- clearing floor 5 grants boss-floor rewards
- guaranteed boss equipment enters inventory
- saved player level and highest-floor progress persist
- pending gold/crystal floor rewards are saved

## Remaining Work

- Replace direct-to-inventory drops with visible ground pickups once 2.5D room interaction is stable.
- Add pickup VFX/audio and short floating text.
- Add 2.5D death settlement bridge.
- Add enemy/floor template variation so reward pacing has real combat variety.
