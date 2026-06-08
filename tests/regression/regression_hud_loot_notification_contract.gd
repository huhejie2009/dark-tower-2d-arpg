extends SceneTree

const HudControllerScript := preload("res://scripts/ui/HudController.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var hud := HudControllerScript.new()
	root.add_child(hud)
	await process_frame

	_expect(hud.find_child("LootNotificationLabel", true, false) != null, "HUD should expose loot notification label")
	_expect(hud.has_method("show_loot_notification"), "HUD should expose show_loot_notification")
	_expect(hud.has_method("get_last_loot_notification_for_test"), "HUD should expose last loot notification for tests")
	if hud.has_method("show_loot_notification"):
		hud.call("show_loot_notification", {
			"headline": "Upgrade found",
			"item_name": "Better Sword",
			"rarity": "magic",
			"score": 43,
			"upgrade": true,
			"accent_color": "#4fa3ff",
		})
		var label := hud.find_child("LootNotificationLabel", true, false) as Label
		_expect(label != null and label.visible, "loot notification label should become visible")
		if label != null:
			_expect(str(label.text).contains("Better Sword"), "loot notification should show item name")
			_expect(str(label.text).contains("Score 43"), "loot notification should show score")
		if hud.has_method("get_last_loot_notification_for_test"):
			var last: Dictionary = Dictionary(hud.call("get_last_loot_notification_for_test"))
			_expect(bool(last.get("upgrade", false)), "HUD should store notification payload")

	hud.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_HUD_LOOT_NOTIFICATION_CONTRACT_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
