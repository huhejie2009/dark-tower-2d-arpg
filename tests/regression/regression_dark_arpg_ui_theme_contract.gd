extends SceneTree

const DarkArpgUiThemeScript := preload("res://scripts/ui/DarkArpgUiTheme.gd")
const HudControllerScript := preload("res://scripts/ui/HudController.gd")
const InventoryEquipmentWindowScript := preload("res://scripts/ui/InventoryEquipmentWindow.gd")
const MainMenuScript := preload("res://scripts/app/MainMenu.gd")
const CharacterSelectScript := preload("res://scripts/app/CharacterSelect.gd")
const TownScript := preload("res://scripts/app/Town.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var palette := DarkArpgUiThemeScript.get_palette_for_test()
	_expect(str(palette.get("style_id", "")) == DarkArpgUiThemeScript.STYLE_ID, "theme should expose a stable style id")
	_expect(not DarkArpgUiThemeScript.STYLE_ID.to_lower().contains("diablo"), "theme style id should describe Dark Tower, not an external art direction")
	_expect(palette.has("primary"), "theme palette should expose primary action color")
	_expect(palette.has("panel"), "theme palette should expose panel color")
	_expect(palette.has("health"), "theme palette should expose health color")
	_expect(palette.has("mana"), "theme palette should expose mana color")

	var hud := HudControllerScript.new()
	root.add_child(hud)
	await process_frame
	_expect(str(hud.call("get_ui_style_id_for_test")) == DarkArpgUiThemeScript.STYLE_ID, "HUD should use the shared dark ARPG UI style")
	_expect(hud.find_child("DarkArpgHudPanel", true, false) != null, "HUD should have a themed backing panel")
	root.remove_child(hud)
	hud.free()

	var inventory := InventoryEquipmentWindowScript.new()
	root.add_child(inventory)
	await process_frame
	_expect(str(inventory.call("get_ui_style_id_for_test")) == DarkArpgUiThemeScript.STYLE_ID, "inventory should use the shared dark ARPG UI style")
	_expect(inventory.find_child("InventoryEquipmentPanel", true, false) != null, "inventory should keep its themed panel node")
	root.remove_child(inventory)
	inventory.free()

	var main_menu := MainMenuScript.new()
	root.add_child(main_menu)
	await process_frame
	_expect(str(main_menu.call("get_ui_style_id_for_test")) == DarkArpgUiThemeScript.STYLE_ID, "main menu should use the shared dark ARPG UI style")
	root.remove_child(main_menu)
	main_menu.free()

	var character_select := CharacterSelectScript.new()
	root.add_child(character_select)
	await process_frame
	_expect(str(character_select.call("get_ui_style_id_for_test")) == DarkArpgUiThemeScript.STYLE_ID, "character select should use the shared dark ARPG UI style")
	root.remove_child(character_select)
	character_select.free()

	var town := TownScript.new()
	root.add_child(town)
	await process_frame
	_expect(str(town.call("get_ui_style_id_for_test")) == DarkArpgUiThemeScript.STYLE_ID, "town should use the shared dark ARPG UI style")
	root.remove_child(town)
	town.free()

	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_DARK_ARPG_UI_THEME_CONTRACT_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
