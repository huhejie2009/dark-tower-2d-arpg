extends SceneTree

const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")
const InventoryDataServiceScript := preload("res://scripts/data/InventoryDataService.gd")
const EquipmentDataServiceScript := preload("res://scripts/data/EquipmentDataService.gd")

var failures: Array[String] = []

func _init() -> void:
	var player := PlayerDataServiceScript.build_starter_player("slot_1", "Test", "warrior")
	var bow := {"instance_id": "ranger_bow", "name": "游侠弓", "slot": "weapon", "equipment_pool": "ranger", "affixes": {"projectile_count": 1}}
	player["inventory"] = InventoryDataServiceScript.add_item(Dictionary(player["inventory"]), {"id": "ranger_bow", "name": "游侠弓", "type": "equipment", "equipment": bow})
	var denied := EquipmentDataServiceScript.can_equip(player, "ranger_bow")
	_expect(not bool(denied.get("ok", true)), "warrior should not equip ranger bow")
	var weapon_id := str(Dictionary(player.get("equipped_items", {})).get("weapon", ""))
	var allowed := EquipmentDataServiceScript.can_equip(player, weapon_id)
	_expect(bool(allowed.get("ok", false)), "warrior should equip starter weapon")
	var equip_result := EquipmentDataServiceScript.equip_item(player, weapon_id)
	_expect(bool(equip_result.get("ok", false)), "equip starter should succeed")
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_EQUIPMENT_CAN_EQUIP_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
