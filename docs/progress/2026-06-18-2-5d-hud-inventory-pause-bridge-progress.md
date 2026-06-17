# 2026-06-18 2.5D HUD / Inventory / Pause Bridge Progress

## Scope

This pass moves the accepted 2.5D tower runtime closer to a playable main game flow by connecting existing functional UI systems:

- `HudController`
- `InventoryEquipmentWindow`
- pause overlay / safe menu pause behavior

No new generated art assets were added. The goal is function and stability first.

## Completed

- `Prototype2_5DCombatRoom` now creates the shared HUD.
- HUD shows floor, living enemy count, objective, bag capacity, HP, MP, XP, level, and skill points.
- `Prototype2_5DCombatRoom` now creates the shared inventory/equipment window inside a 2.5D UI layer.
- Opening inventory with `I` or `C` pauses the SceneTree, preventing enemies and combat simulation from continuing while the player is reading gear.
- `Esc` closes inventory first; if inventory is closed, `Esc` toggles the pause overlay.
- The pause overlay exposes Resume, Inventory / Equipment, and Return To Town buttons.
- Inventory/equipment edits are saved through the existing `SaveManager` bridge and refresh the HUD.
- Combat input and next-floor interaction are blocked while pause or inventory UI is visible.

## Regression Added

- `tests/regression/regression_prototype_2_5d_hud_inventory_pause_bridge.gd`

The test verifies:

- shared HUD exists in the active 2.5D runtime
- shared inventory window exists
- pause overlay exists
- HUD reports floor and bag information
- opening inventory pauses combat
- cancel closes inventory before pause
- pause overlay focuses Resume
- inventory can open while paused without unpausing the game

## Remaining Work

- Replace temporary 2.5D debug HUD text with production HUD wording after the next UI pass.
- Add 2.5D loot reward bridge so the inventory window has meaningful combat loot to inspect.
- Add death settlement bridge for the 2.5D runtime.
- Add floor template rhythm and enemy type variation.
- Later: rebuild inventory/equipment UI visually, but keep these functional hooks stable.
