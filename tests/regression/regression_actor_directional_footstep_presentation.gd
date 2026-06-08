extends SceneTree

const Player2DScript := preload("res://scripts/combat/Player2D.gd")
const Enemy2DScript := preload("res://scripts/combat/Enemy2D.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var image_path := "user://directional_footstep_test.png"
	_create_test_sprite_sheet(image_path, Vector2i(64, 64), 20)
	var manifest := {
		"asset_pipeline": "image2",
		"enabled": true,
		"hide_procedural_body": true,
		"sprite_sheet_path": image_path,
		"frame_size": Vector2i(64, 64),
		"direction_mode": "runtime_flip_2dir",
		"animations": {
			"idle": {"from": 0, "to": 3, "fps": 8},
			"run": {"from": 4, "to": 9, "fps": 8},
			"attack": {"from": 10, "to": 15, "fps": 8},
			"death": {"from": 16, "to": 19, "fps": 8},
		},
	}
	await _check_player(manifest)
	await _check_enemy(manifest)
	_finish()

func _check_player(manifest: Dictionary) -> void:
	var player := Player2DScript.new()
	root.add_child(player)
	await process_frame
	player.call("apply_visual_asset_manifest_for_test", manifest)
	player.call("set_move_vector", Vector2.LEFT)
	player.call("face_world_position", player.global_position + Vector2.LEFT)
	player.call("tick_actor_animation_for_test", 0.18)
	_expect(player.has_method("get_actor_presentation_state_for_test"), "player should expose presentation state")
	var left_state: Dictionary = player.call("get_actor_presentation_state_for_test")
	_expect(str(left_state.get("facing_bucket", "")) == "left", "player should classify left-facing presentation")
	_expect(bool(left_state.get("sprite_flipped_h", false)), "player should flip sprite for left-facing presentation")
	_expect(absf(float(left_state.get("footstep_offset_x", 0.0))) >= 1.0 or absf(float(left_state.get("visual_offset_y", 0.0))) >= 1.0, "player run should add visible alternating footstep movement")
	player.call("set_move_vector", Vector2.RIGHT)
	player.call("face_world_position", player.global_position + Vector2.RIGHT)
	player.call("tick_actor_animation_for_test", 0.18)
	var right_state: Dictionary = player.call("get_actor_presentation_state_for_test")
	_expect(str(right_state.get("facing_bucket", "")) == "right", "player should classify right-facing presentation")
	_expect(not bool(right_state.get("sprite_flipped_h", true)), "player should not flip sprite for right-facing presentation")
	player.queue_free()
	await process_frame

func _check_enemy(manifest: Dictionary) -> void:
	var enemy := Enemy2DScript.new()
	root.add_child(enemy)
	await process_frame
	enemy.call("apply_visual_asset_manifest_for_test", manifest)
	enemy.call("update_actor_animation_state_for_test", Vector2.LEFT, false)
	enemy.call("tick_actor_animation_for_test", 0.18)
	var state: Dictionary = enemy.call("get_actor_presentation_state_for_test")
	_expect(str(state.get("facing_bucket", "")) == "left", "enemy should classify movement-facing presentation")
	_expect(bool(state.get("sprite_flipped_h", false)), "enemy should flip sprite for left movement")
	_expect(absf(float(state.get("footstep_offset_x", 0.0))) >= 1.0 or absf(float(state.get("visual_offset_y", 0.0))) >= 1.0, "enemy run should add visible alternating footstep movement")
	enemy.queue_free()
	await process_frame

func _create_test_sprite_sheet(path: String, frame_size: Vector2i, frame_count: int) -> void:
	var image := Image.create(frame_size.x * frame_count, frame_size.y, false, Image.FORMAT_RGBA8)
	for frame in range(frame_count):
		var color := Color(float(frame + 1) / float(frame_count), 0.18, 0.55, 1.0)
		image.fill_rect(Rect2i(Vector2i(frame * frame_size.x, 0), frame_size), color)
	image.save_png(path)

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_ACTOR_DIRECTIONAL_FOOTSTEP_PRESENTATION_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
