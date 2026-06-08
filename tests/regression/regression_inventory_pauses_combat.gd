extends SceneTree

const Game2DScene := preload("res://scenes/Game2D.tscn")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := Game2DScene.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	_expect(scene.has_method("_toggle_inventory_window"), "Game2D should expose inventory toggle")
	_expect(paused == false, "game should start unpaused")

	if scene.has_method("_toggle_inventory_window"):
		scene.call("_toggle_inventory_window")
		await process_frame
		var inventory := scene.find_child("InventoryEquipmentWindow", true, false) as Control
		_expect(inventory != null and inventory.visible, "inventory should open")
		_expect(paused == true, "opening inventory should pause combat")

		scene.call("_toggle_inventory_window")
		await process_frame
		_expect(inventory != null and not inventory.visible, "inventory should close")
		_expect(paused == false, "closing inventory should resume combat")

	scene.queue_free()
	await process_frame
	paused = false
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_INVENTORY_PAUSES_COMBAT_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
