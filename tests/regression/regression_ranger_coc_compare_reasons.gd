extends SceneTree

const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")
const InventoryDataServiceScript := preload("res://scripts/data/InventoryDataService.gd")
const InventoryEquipmentWindowScript := preload("res://scripts/ui/InventoryEquipmentWindow.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := PlayerDataServiceScript.build_starter_player("slot_1", "CoC Explain", "ranger")
	var bow := {
		"instance_id": "explain_bow",
		"name": "解释用冰弓",
		"slot": "weapon",
		"equipment_pool": "ranger",
		"equipment_type": "bow",
		"item_level": 6,
		"rarity": "rare",
		"affixes": {"critical_chance": 9, "cold_damage": 12, "ice_lance_pierce": 1},
	}
	player["inventory"] = InventoryDataServiceScript.add_item(Dictionary(player["inventory"]), {
		"id": "explain_bow",
		"name": "解释用冰弓",
		"type": "equipment",
		"equipment": bow,
	})

	var window := InventoryEquipmentWindowScript.new()
	root.add_child(window)
	window.set_player_data(player)
	await process_frame

	var summary: Dictionary = Dictionary(window.call("get_item_compare_summary_for_test", "explain_bow"))
	var reasons := "\n".join(Array(summary.get("reason_lines", [])))
	_expect(reasons.contains("更频繁触发冰矢"), "compare reasons should explain crit")
	_expect(reasons.contains("增强寒冰射击和冰矢"), "compare reasons should explain cold damage")
	_expect(reasons.contains("冰矢穿透"), "compare reasons should explain pierce")
	var detail := str(window.call("describe_item_for_test", "explain_bow"))
	_expect(detail.contains("更频繁触发冰矢"), "detail should show crit reason")
	_expect(detail.contains("增强寒冰射击和冰矢"), "detail should show cold reason")
	_expect(detail.contains("冰矢穿透"), "detail should show pierce reason")

	window.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_RANGER_COC_COMPARE_REASONS_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
