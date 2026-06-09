extends SceneTree

const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")
const InventoryDataServiceScript := preload("res://scripts/data/InventoryDataService.gd")
const EquipmentCompareSummaryServiceScript := preload("res://scripts/data/EquipmentCompareSummaryService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := PlayerDataServiceScript.build_starter_player("slot_1", "Compare Reasons", "warrior")
	var candidate := {
		"instance_id": "reason_sword",
		"name": "Reason Sword",
		"slot": "weapon",
		"equipment_pool": "warrior",
		"item_level": 6,
		"rarity": "rare",
		"affixes": {"attack_damage": 24, "critical_chance": 3},
	}
	player["inventory"] = InventoryDataServiceScript.add_item(Dictionary(player["inventory"]), {
		"id": "reason_sword",
		"name": "Reason Sword",
		"type": "equipment",
		"equipment": candidate,
	})

	var summary := EquipmentCompareSummaryServiceScript.build_summary(player, "reason_sword", candidate)
	_expect(summary.has("reason_lines"), "compare summary should expose reason_lines")
	var reasons: Array = Array(summary.get("reason_lines", []))
	_expect(reasons.size() >= 1, "compare summary should provide at least one reason")
	_expect(reasons.size() <= 3, "compare summary should cap reasons for readable UI")
	_expect(_contains_reason(reasons, "Score"), "reason_lines should explain score delta")
	_expect(_contains_reason(reasons, "attack_damage") or _contains_reason(reasons, "critical_chance"), "reason_lines should explain important stat delta")
	if not reasons.is_empty():
		_expect(str(summary.get("primary_reason", "")) == str(reasons[0]), "primary_reason should mirror first reason")
		_expect(str(summary.get("compact_text", "")).contains(str(reasons[0])), "compact text should include the primary reason")
	_finish()

func _contains_reason(reasons: Array, token: String) -> bool:
	for reason in reasons:
		if str(reason).contains(token):
			return true
	return false

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_ITEM_COMPARE_SUMMARY_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
