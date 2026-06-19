extends SceneTree

const SaveManagerScript := preload("res://scripts/save/SaveManager.gd")
const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")
const LootNotificationServiceScript := preload("res://scripts/data/LootNotificationService.gd")
const DeathSettlementServiceScript := preload("res://scripts/data/DeathSettlementService.gd")
const InventoryEquipmentWindowScript := preload("res://scripts/ui/InventoryEquipmentWindow.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := SaveManagerScript.create_character("slot_1", "汉化验收", "warrior")
	player["highest_floor"] = 5
	SaveManagerScript.save_active_player_data(player, 5)
	await _check_main_menu()
	await _check_character_select()
	await _check_town()
	await _check_inventory_equipment_window(player)
	_check_loot_notification(player)
	_check_death_settlement()
	_finish()

func _check_main_menu() -> void:
	var packed := load("res://scenes/MainMenu.tscn")
	_expect(packed is PackedScene, "main menu scene should load")
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	var start := scene.find_child("StartButton", true, false) as Button
	_expect(start != null, "main menu should expose start button")
	_expect(_has_chinese(start.text), "start button should be localized")
	scene.queue_free()
	await process_frame

func _check_character_select() -> void:
	var packed := load("res://scenes/CharacterSelect.tscn")
	_expect(packed is PackedScene, "character select scene should load")
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	var create := scene.find_child("CreateCharacterButton", true, false) as Button
	var selected_slot := scene.find_child("SelectedSlotSummary", true, false) as Label
	var selected_class := scene.find_child("SelectedClassSummary", true, false) as Label
	_expect(create != null and _has_chinese(create.text), "create character button should be localized")
	_expect(selected_slot != null and _has_chinese(selected_slot.text), "selected slot summary should be localized")
	_expect(selected_class != null and _has_chinese(selected_class.text), "selected class summary should be localized")
	scene.queue_free()
	await process_frame

func _check_town() -> void:
	var packed := load("res://scenes/Town.tscn")
	_expect(packed is PackedScene, "town scene should load")
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	var enter := scene.find_child("EnterTowerButton", true, false) as Button
	var best := scene.find_child("EnterBestFloorButton", true, false) as Button
	var inventory := scene.find_child("OpenInventoryButton", true, false) as Button
	var menu := scene.find_child("ReturnMainMenuButton", true, false) as Button
	var progress := scene.find_child("TownProgressSummary", true, false) as Label
	_expect(enter != null and _contains_any(enter.text, ["进入", "第 1 层"]), "fresh tower button should be localized")
	_expect(best != null and _contains_any(best.text, ["最高层", "第 5 层"]), "best floor button should be localized")
	_expect(inventory != null and _contains_any(inventory.text, ["背包", "装备"]), "inventory button should be localized")
	_expect(menu != null and _contains_any(menu.text, ["主菜单"]), "main menu button should be localized")
	_expect(progress != null and _contains_any(progress.text, ["最高层", "装备评分"]), "town progress summary should be localized")
	scene.queue_free()
	await process_frame

func _check_inventory_equipment_window(player: Dictionary) -> void:
	var window := InventoryEquipmentWindowScript.new()
	root.add_child(window)
	await process_frame
	window.set_player_data(player)
	var title := _find_label_with_text(window, "背包")
	var detail := window.find_child("ItemDetail", true, false) as Label
	var equip := window.find_child("EquipSelectedButton", true, false) as Button
	var sell := window.find_child("SellJunkButton", true, false) as Button
	var salvage := window.find_child("SalvageJunkButton", true, false) as Button
	_expect(title != null, "inventory title should be localized")
	_expect(detail != null and _has_chinese(detail.text), "empty item detail should be localized")
	_expect(equip != null and _has_chinese(equip.text), "equip action should be localized")
	_expect(sell != null and _has_chinese(sell.text), "sell junk action should be localized")
	_expect(salvage != null and _has_chinese(salvage.text), "salvage junk action should be localized")
	window.queue_free()
	await process_frame

func _check_loot_notification(player: Dictionary) -> void:
	var gold_note := LootNotificationServiceScript.build_pickup_notification(player, {"id": "gold", "name": "金币", "type": "currency", "amount": 7})
	var material_note := LootNotificationServiceScript.build_pickup_notification(player, {"id": "crystal_shard", "name": "水晶碎片", "type": "material", "amount": 2})
	var equip_note := LootNotificationServiceScript.build_pickup_notification(player, {
		"id": "zh_sword",
		"name": "试炼长剑",
		"type": "equipment",
		"equipment": {"slot": "weapon", "rarity": "rare", "score": 99, "stats": {"attack_damage": 99}},
	}, "boss_reward")
	_expect(_has_chinese(str(gold_note.get("headline", ""))), "currency notification headline should be localized")
	_expect(_has_chinese(str(material_note.get("headline", ""))), "material notification headline should be localized")
	_expect(_has_chinese(str(equip_note.get("headline", ""))), "equipment notification headline should be localized")
	_expect(_has_chinese(str(equip_note.get("source_label", ""))), "loot source label should be localized")

func _check_death_settlement() -> void:
	var settlement := DeathSettlementServiceScript.build_death_settlement({
		"floor": 5,
		"template_id": "boss_gatekeeper",
		"kill_count": 4,
		"pickup_names": ["金币", "守门者战利品"],
		"last_floor_rewards": {"is_boss_floor": true, "guaranteed_items": [{"name": "守门者战利品"}]},
	})
	_expect(_contains_any(str(settlement.get("floor_text", "")), ["第 5 层"]), "death floor section should be localized")
	_expect(_contains_any(str(settlement.get("combat_text", "")), ["击杀", "半血"]), "death combat section should be localized")
	_expect(_contains_any(str(settlement.get("loot_text", "")), ["拾取", "金币"]), "death loot section should be localized")
	_expect(_contains_any(str(settlement.get("summary_text", "")), ["返回主城", "半血"]), "death summary should be localized")

func _find_label_with_text(parent: Node, needle: String) -> Label:
	for child in parent.find_children("*", "Label", true, false):
		var label := child as Label
		if label != null and label.text.contains(needle):
			return label
	return null

func _has_chinese(text: String) -> bool:
	for i in range(text.length()):
		var code := text.unicode_at(i)
		if code >= 0x4E00 and code <= 0x9FFF:
			return true
	return false

func _contains_any(text: String, needles: Array[String]) -> bool:
	for needle in needles:
		if text.contains(needle):
			return true
	return false

func _finish() -> void:
	if failures.is_empty():
		print("REGRESSION_CORE_UI_CHINESE_LOCALIZATION_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
