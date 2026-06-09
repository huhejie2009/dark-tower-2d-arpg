extends SceneTree

const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")
const InventoryDataServiceScript := preload("res://scripts/data/InventoryDataService.gd")
const EquipmentDataServiceScript := preload("res://scripts/data/EquipmentDataService.gd")
const GameConstantsScript := preload("res://scripts/app/GameConstants.gd")

var failures: Array[String] = []

func _init() -> void:
	var player := PlayerDataServiceScript.build_starter_player("slot_1", "Ring Migration", "warrior")
	player["inventory"] = InventoryDataServiceScript.add_item(Dictionary(player["inventory"]), _ring_payload("legacy_ring", 2))
	player["equipped_items"] = {"weapon": "", "armor": "", "gloves": "", "ring": "legacy_ring"}

	var normalized := PlayerDataServiceScript.normalize_player_data(player)
	var equipped: Dictionary = Dictionary(normalized.get("equipped_items", {}))
	_expect(GameConstantsScript.EQUIPMENT_SLOTS.has("ring_1"), "equipment slots should expose ring_1")
	_expect(GameConstantsScript.EQUIPMENT_SLOTS.has("ring_2"), "equipment slots should expose ring_2")
	_expect(str(equipped.get("ring_1", "")) == "legacy_ring", "legacy ring should migrate into ring_1")
	_expect(str(equipped.get("ring_2", "")) == "", "ring_2 should exist and start empty")
	_expect(not equipped.has("ring"), "canonical equipped items should not keep the legacy ring key")

	normalized["inventory"] = InventoryDataServiceScript.add_item(Dictionary(normalized["inventory"]), _ring_payload("new_ring", 4))
	var can_equip_new_ring := EquipmentDataServiceScript.can_equip(normalized, "new_ring")
	_expect(bool(can_equip_new_ring.get("ok", false)), "new ring should be equippable after legacy migration")
	_expect(str(can_equip_new_ring.get("slot", "")) == "ring_2", "new ring should target empty ring_2 when ring_1 is occupied")

	var equip_result := EquipmentDataServiceScript.equip_item(normalized, "new_ring")
	_expect(bool(equip_result.get("ok", false)), "equipping new ring should succeed")
	var after_equip: Dictionary = Dictionary(equip_result.get("player_data", {}))
	var after_equipped: Dictionary = Dictionary(after_equip.get("equipped_items", {}))
	_expect(str(after_equipped.get("ring_1", "")) == "legacy_ring", "equipping ring_2 should not overwrite ring_1")
	_expect(str(after_equipped.get("ring_2", "")) == "new_ring", "new ring should be equipped in ring_2")
	_finish()

func _ring_payload(id: String, level: int) -> Dictionary:
	return {
		"id": id,
		"name": id,
		"type": "equipment",
		"equipment": {
			"instance_id": id,
			"name": id,
			"slot": "ring",
			"equipment_pool": "warrior",
			"item_level": level,
			"rarity": "magic",
			"affixes": {"critical_chance": level},
		},
	}

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_EQUIPMENT_SLOT_MIGRATION_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

