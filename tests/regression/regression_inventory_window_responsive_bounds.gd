extends SceneTree

const WindowScript := preload("res://scripts/ui/InventoryEquipmentWindow.gd")
const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := PlayerDataServiceScript.build_starter_player("slot_1", "Bounds", "warrior")
	var window := WindowScript.new()
	root.add_child(window)
	window.set_player_data(player)
	window.visible = true
	await process_frame
	await process_frame

	_expect(window.has_method("get_responsive_window_rect_for_test"), "inventory window should expose responsive bounds calculation")
	var viewport_size := Vector2(800, 600)
	var rect := Rect2()
	if window.has_method("get_responsive_window_rect_for_test"):
		rect = window.call("get_responsive_window_rect_for_test", viewport_size)
	_expect(rect.position.x >= 0.0, "inventory window should not overflow past left viewport edge")
	_expect(rect.position.y >= 0.0, "inventory window should not overflow past top viewport edge")
	_expect(rect.end.x <= viewport_size.x, "inventory window should not overflow past right viewport edge")
	_expect(rect.end.y <= viewport_size.y, "inventory window should not overflow past bottom viewport edge")

	window.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_INVENTORY_WINDOW_RESPONSIVE_BOUNDS_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
