extends SceneTree

const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")
const EquipmentDataServiceScript := preload("res://scripts/data/EquipmentDataService.gd")

var failures: Array[String] = []

func _init() -> void:
	var player := PlayerDataServiceScript.build_starter_player("slot_1", "Test", "warrior")
	var weapon_id := str(Dictionary(player.get("equipped_items", {})).get("weapon", ""))
	_expect(weapon_id != "", "starter weapon should be equipped")

	var equipped_stats := EquipmentDataServiceScript.build_stat_totals(player)
	_expect(int(equipped_stats.get("attack_damage", 0)) > int(player.get("attack_damage", 0)), "equipped weapon should add attack damage")

	var result: Dictionary = {}
	var equipment_service := EquipmentDataServiceScript.new()
	if not equipment_service.has_method("unequip_slot"):
		_expect(false, "EquipmentDataService should expose unequip_slot")
	else:
		result = Dictionary(equipment_service.call("unequip_slot", player, "weapon"))
		_expect(result.get("ok", false) == true, "unequip weapon should succeed")
	var updated: Dictionary = Dictionary(result.get("player_data", player))
	_expect(str(Dictionary(updated.get("equipped_items", {})).get("weapon", "missing")) == "", "weapon slot should be empty after unequip")

	var unequipped_stats := EquipmentDataServiceScript.build_stat_totals(updated)
	_expect(int(unequipped_stats.get("attack_damage", 0)) == int(updated.get("attack_damage", 0)), "unequipped weapon stats should be removed")
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_EQUIPMENT_UNEQUIP_AND_STATS_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
