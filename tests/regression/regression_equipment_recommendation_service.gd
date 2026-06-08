extends SceneTree

const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")
const EquipmentRecommendationServiceScript := preload("res://scripts/data/EquipmentRecommendationService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := PlayerDataServiceScript.build_starter_player("slot_1", "Test", "warrior")
	var candidate := {
		"instance_id": "rare_weapon",
		"name": "Rare Tower Blade",
		"slot": "weapon",
		"equipment_pool": "warrior",
		"item_level": 8,
		"rarity": "rare",
		"affixes": {"attack_damage": 34},
	}
	var recommendation := EquipmentRecommendationServiceScript.build_recommendation(player, candidate, {
		"source": "elite",
		"quality_tag": "elite_floor_08",
		"item_level": 9,
	})
	_expect(bool(recommendation.get("upgrade", false)), "strong candidate should be upgrade")
	_expect(int(recommendation.get("score", 0)) > int(recommendation.get("equipped_score", 0)), "candidate score should beat equipped score")
	_expect(int(recommendation.get("score_delta", 0)) > 0, "recommendation should expose positive score delta")
	_expect(["minor", "strong", "major"].has(str(recommendation.get("recommendation_rank", ""))), "recommendation should expose rank")
	_expect(str(recommendation.get("source_label", "")) == "Elite drop", "elite source should have readable label")
	_expect(str(recommendation.get("quality_tag", "")) == "elite_floor_08", "quality tag should pass through")

	var wrong_class := candidate.duplicate(true)
	wrong_class["equipment_pool"] = "mage"
	var blocked := EquipmentRecommendationServiceScript.build_recommendation(player, wrong_class, {"source": "boss"})
	_expect(not bool(blocked.get("upgrade", true)), "wrong class candidate should not be upgrade")
	_expect(str(blocked.get("equip_reason", "")) == "wrong_class", "wrong class reason should be exposed")

	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_EQUIPMENT_RECOMMENDATION_SERVICE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
