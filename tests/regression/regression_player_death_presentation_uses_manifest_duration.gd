extends SceneTree

const GameScene := preload("res://scenes/Game2D.tscn")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := GameScene.instantiate()
	root.add_child(scene)
	await process_frame
	_expect(scene.has_method("_get_death_presentation_delay_for_test"), "Game2D should expose death presentation delay lookup")
	var player := scene.get("player") as Node
	_expect(is_instance_valid(player), "Game2D should create player")
	if is_instance_valid(player):
		_expect(player.has_method("get_death_animation_duration_for_test"), "Player2D should expose death animation duration")
		if player.has_method("apply_visual_asset_manifest_for_test"):
			player.call("apply_visual_asset_manifest_for_test", {
				"asset_pipeline": "IMAGE2",
				"enabled": true,
				"sprite_sheet_path": "user://missing_player_death_duration_sheet.png",
				"frame_size": Vector2i(32, 32),
				"animations": {
					"idle": {"from": 0, "to": 0, "fps": 1},
					"death": {"from": 2, "to": 5, "fps": 8},
				},
			})
		if scene.has_method("_get_death_presentation_delay_for_test"):
			var delay := float(scene.call("_get_death_presentation_delay_for_test"))
			_expect(delay >= 0.49, "death presentation delay should use player manifest death duration")
		player.call("take_damage", 99999)
		await process_frame
		var overlay := scene.find_child("DeathSettlementOverlay", true, false) as CanvasLayer
		_expect(is_instance_valid(overlay) and not overlay.visible, "death settlement should not show before manifest death duration")
		await create_timer(0.24, true).timeout
		_expect(is_instance_valid(overlay) and not overlay.visible, "death settlement should still wait during manifest death duration")
		await create_timer(0.36, true).timeout
		_expect(is_instance_valid(overlay) and overlay.visible, "death settlement should show after manifest death duration")
	scene.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_PLAYER_DEATH_PRESENTATION_USES_MANIFEST_DURATION_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
