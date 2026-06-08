extends SceneTree

const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")
const LootNotificationServiceScript := preload("res://scripts/data/LootNotificationService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := PlayerDataServiceScript.build_starter_player("slot_1", "Test", "warrior")
	var better_payload := {
		"id": "better_weapon",
		"name": "Better Sword",
		"type": "equipment",
		"amount": 1,
		"equipment": {
			"instance_id": "better_weapon",
			"name": "Better Sword",
			"slot": "weapon",
			"equipment_pool": "warrior",
			"item_level": 4,
			"rarity": "magic",
			"affixes": {"attack_damage": 28},
		},
	}
	var material_payload := {"id": "crystal_shard", "name": "Crystal Shard", "type": "material", "amount": 2}
	var boss_payload := better_payload.duplicate(true)

	var equipment_note: Dictionary = LootNotificationServiceScript.build_pickup_notification(player, better_payload)
	_expect(str(equipment_note.get("item_name", "")) == "Better Sword", "equipment notification should include item name")
	_expect(str(equipment_note.get("item_type", "")) == "equipment", "equipment notification should include item type")
	_expect(str(equipment_note.get("rarity", "")) == "magic", "equipment notification should include rarity")
	_expect(bool(equipment_note.get("upgrade", false)), "stronger same-slot equipment should be marked as upgrade")
	_expect(int(equipment_note.get("score", 0)) > 0, "equipment notification should include score")
	_expect(str(equipment_note.get("log_text", "")).contains("Better Sword"), "log text should mention item name")
	_expect(str(equipment_note.get("accent_color", "")) != "", "notification should include accent color")

	var material_note: Dictionary = LootNotificationServiceScript.build_pickup_notification(player, material_payload)
	_expect(str(material_note.get("item_type", "")) == "material", "material notification should include item type")
	_expect(str(material_note.get("quantity_text", "")) == "x2", "material notification should include amount")
	_expect(not bool(material_note.get("upgrade", true)), "material should not be marked as upgrade")

	var boss_note: Dictionary = LootNotificationServiceScript.build_pickup_notification(player, boss_payload, "boss_reward")
	_expect(bool(boss_note.get("boss_reward", false)), "boss reward source should be marked")
	_expect(str(boss_note.get("headline", "")).contains("Boss"), "boss reward headline should be distinct")

	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_LOOT_NOTIFICATION_SERVICE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
