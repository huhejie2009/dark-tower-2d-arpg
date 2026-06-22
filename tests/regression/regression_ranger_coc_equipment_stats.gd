extends SceneTree

const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")
const InventoryDataServiceScript := preload("res://scripts/data/InventoryDataService.gd")
const EquipmentDataServiceScript := preload("res://scripts/data/EquipmentDataService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := PlayerDataServiceScript.build_starter_player("slot_1", "CoC Gear", "ranger")
	var bow := {
		"instance_id": "coc_bow",
		"name": "Ice Trigger Bow",
		"slot": "weapon",
		"equipment_pool": "ranger",
		"equipment_type": "bow",
		"item_level": 5,
		"rarity": "rare",
		"affixes": {"critical_chance": 7, "cold_damage": 12, "coc_cooldown_recovery": 4},
		"socketed_gems": ["frost_gem", "pierce_gem"],
	}
	player["inventory"] = InventoryDataServiceScript.add_item(Dictionary(player["inventory"]), {
		"id": "coc_bow",
		"name": "Ice Trigger Bow",
		"type": "equipment",
		"equipment": bow,
	})
	var equip: Dictionary = EquipmentDataServiceScript.equip_item(player, "coc_bow")
	_expect(bool(equip.get("ok", false)), "ranger should equip CoC bow")
	player = Dictionary(equip.get("player_data", player))
	var totals := EquipmentDataServiceScript.build_stat_totals(player)
	_expect(int(totals.get("critical_chance", 0)) >= 7, "equipment totals should include crit")
	_expect(int(totals.get("cold_damage", 0)) == 18, "equipment totals should include cold affix plus frost gem")
	_expect(int(totals.get("coc_cooldown_recovery", 0)) == 4, "equipment totals should include cooldown recovery")
	_expect(int(totals.get("ice_lance_pierce", 0)) == 1, "equipment totals should include pierce gem")
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_RANGER_COC_EQUIPMENT_STATS_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
