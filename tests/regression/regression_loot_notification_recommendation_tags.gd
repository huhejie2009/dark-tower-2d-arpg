extends SceneTree

const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")
const LootNotificationServiceScript := preload("res://scripts/data/LootNotificationService.gd")
const HudControllerScript := preload("res://scripts/ui/HudController.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := PlayerDataServiceScript.build_starter_player("slot_1", "Test", "warrior")
	var payload := {
		"id": "boss_rare_weapon",
		"name": "Gatekeeper Rare Blade",
		"type": "equipment",
		"amount": 1,
		"source": "boss",
		"loot_quality": {
			"source": "boss",
			"quality_tag": "boss_floor_10",
			"item_level": 12,
			"guaranteed_equipment": true,
		},
		"equipment": {
			"instance_id": "boss_rare_weapon",
			"name": "Gatekeeper Rare Blade",
			"slot": "weapon",
			"equipment_pool": "warrior",
			"item_level": 12,
			"rarity": "rare",
			"affixes": {"attack_damage": 42},
		},
	}
	var note := LootNotificationServiceScript.build_pickup_notification(player, payload, "boss_reward")
	_expect(str(note.get("source_label", "")) == "Boss reward", "notification should expose boss source label")
	_expect(str(note.get("quality_tag", "")) == "boss_floor_10", "notification should include quality tag")
	_expect(int(note.get("score_delta", 0)) > 0, "notification should include score delta")
	_expect(str(note.get("recommendation_rank", "")) != "", "notification should include recommendation rank")
	_expect(str(note.get("recommendation_text", "")).contains("+"), "recommendation text should show positive delta")
	_expect(str(note.get("short_tag", "")).contains("Boss"), "short tag should mention boss")

	var hud := HudControllerScript.new()
	root.add_child(hud)
	await process_frame
	hud.show_loot_notification(note)
	var label := hud.find_child("LootNotificationLabel", true, false) as Label
	_expect(label != null and str(label.text).contains("Boss"), "HUD loot notification should render source tag")
	_expect(label != null and str(label.text).contains("+"), "HUD loot notification should render recommendation delta")
	hud.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_LOOT_NOTIFICATION_RECOMMENDATION_TAGS_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
