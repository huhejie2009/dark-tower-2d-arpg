extends SceneTree

const HudControllerScript := preload("res://scripts/ui/HudController.gd")
const InventoryEquipmentWindowScript := preload("res://scripts/ui/InventoryEquipmentWindow.gd")
const Game2DScript := preload("res://scripts/app/Game2D.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	await _check_hud_safe_rects()
	await _check_inventory_reading_space()
	await _check_death_settlement_reading_space()
	_finish()

func _check_hud_safe_rects() -> void:
	var hud := HudControllerScript.new()
	root.add_child(hud)
	await process_frame
	_expect(hud.has_method("get_visual_qa_rects_for_test"), "HUD should expose visual QA rects")
	if hud.has_method("get_visual_qa_rects_for_test"):
		var rects: Dictionary = Dictionary(hud.call("get_visual_qa_rects_for_test", Vector2(800, 600)))
		var inventory_rect: Rect2 = Rect2(rects.get("inventory", Rect2()))
		var loot_rect: Rect2 = Rect2(rects.get("loot", Rect2()))
		var panel_rect: Rect2 = Rect2(rects.get("hud_panel", Rect2()))
		var objective_rect: Rect2 = Rect2(rects.get("objective", Rect2()))
		var health_rect: Rect2 = Rect2(rects.get("health_bar", Rect2()))
		var xp_rect: Rect2 = Rect2(rects.get("experience_bar", Rect2()))
		_expect(inventory_rect.position.x >= 0.0 and inventory_rect.end.x <= 800.0, "inventory HUD hint should stay inside 800px width")
		_expect(loot_rect.position.x >= 0.0 and loot_rect.end.x <= 800.0, "loot notification should stay inside 800px width")
		_expect(panel_rect.position.x >= 0.0 and panel_rect.end.x <= 800.0, "main HUD panel should stay inside 800px width")
		_expect(panel_rect.position.y >= 0.0 and panel_rect.end.y <= 600.0, "main HUD panel should stay inside 600px height")
		_expect(objective_rect.size.x >= 240.0 and objective_rect.size.y >= 28.0, "objective HUD text should reserve readable space")
		_expect(objective_rect.end.y <= health_rect.position.y - 2.0, "objective HUD text should not overlap health bar")
		_expect(xp_rect.end.y <= panel_rect.end.y - 4.0, "experience bar should stay inside main HUD panel")
	root.remove_child(hud)
	hud.free()

func _check_inventory_reading_space() -> void:
	var window := InventoryEquipmentWindowScript.new()
	root.add_child(window)
	await process_frame
	var rect := window.get_responsive_window_rect_for_test(Vector2(1280, 720))
	_expect(rect.size.x >= 960.0, "inventory window should reserve enough width for equipment, grid, and detail columns at 1280x720")
	_expect(rect.size.y >= 560.0, "inventory window should reserve enough height to lower text density at 1280x720")
	_expect(window.has_method("get_visual_qa_metrics_for_test"), "inventory should expose visual QA density metrics")
	if window.has_method("get_visual_qa_metrics_for_test"):
		var metrics: Dictionary = Dictionary(window.call("get_visual_qa_metrics_for_test", Vector2(1280, 720)))
		_expect(int(metrics.get("grid_columns", 0)) >= 9, "inventory grid should show at least 9 columns on 1280px width")
		_expect(float(metrics.get("detail_min_width", 0.0)) >= 260.0, "item detail column should be wide enough for readable comparison text")
	root.remove_child(window)
	window.free()

func _check_death_settlement_reading_space() -> void:
	var scene := Game2DScript.new()
	root.add_child(scene)
	await process_frame
	_expect(scene.has_method("get_death_settlement_visual_qa_for_test"), "Game2D should expose death settlement visual QA metrics")
	if scene.has_method("get_death_settlement_visual_qa_for_test"):
		var metrics: Dictionary = Dictionary(scene.call("get_death_settlement_visual_qa_for_test"))
		var panel_size: Vector2 = Vector2(metrics.get("panel_size", Vector2.ZERO))
		_expect(panel_size.x >= 560.0, "death settlement panel should be wide enough for summary sections")
		_expect(panel_size.y >= 480.0, "death settlement panel should be tall enough for result hierarchy")
		_expect(int(metrics.get("section_min_height", 0)) >= 64, "death settlement sections should have enough vertical reading space")
	root.remove_child(scene)
	scene.free()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_UI_VISUAL_QA_LAYOUT_CONTRACT_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
