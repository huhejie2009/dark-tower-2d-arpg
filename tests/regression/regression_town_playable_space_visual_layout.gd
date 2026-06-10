extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var packed := load("res://scenes/Town.tscn")
	_expect(packed is PackedScene, "Town should load")
	if packed is PackedScene:
		var town: Node = packed.instantiate()
		if town is Control:
			(town as Control).set_anchors_preset(Control.PRESET_FULL_RECT)
		root.add_child(town)
		await process_frame
		var prep_panel := town.find_child("TownPrepPanel", true, false) as Control
		var player := town.find_child("TownPlayer", true, false) as Node2D
		var gate := town.find_child("TownTowerGateInteraction", true, false) as Node2D
		var hint := town.find_child("TownInteractionHint", true, false) as Control
		var menu_button := town.find_child("ReturnMainMenuButton", true, false) as Control
		_expect(prep_panel != null, "town should expose prep panel for layout QA")
		_expect(player != null, "town should expose player for layout QA")
		_expect(gate != null, "town should expose tower gate for layout QA")
		_expect(hint != null, "town should expose interaction hint for layout QA")
		_expect(menu_button != null, "town should expose menu button for layout QA")
		if prep_panel != null:
			_expect(prep_panel.position.x >= 860.0, "prep panel should live in a right-side town HUD lane")
			_expect(prep_panel.size.x <= 390.0, "prep panel should not consume the playable world width")
			if player != null:
				_expect(player.global_position.x <= prep_panel.position.x - 70.0, "player should start in visible playable space, not under the prep panel")
			if gate != null:
				_expect(gate.global_position.x <= prep_panel.position.x - 120.0, "tower gate should remain readable outside the prep panel")
		if hint != null:
			_expect(hint.position.y + hint.size.y <= 716.0, "interaction hint should fit in 720p")
		if menu_button != null:
			_expect(menu_button.position.y + menu_button.size.y <= 716.0, "main menu button should fit in 720p")
		town.queue_free()
		await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_TOWN_PLAYABLE_SPACE_VISUAL_LAYOUT_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
