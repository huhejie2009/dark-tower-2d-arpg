extends SceneTree

const Player2DScript := preload("res://scripts/combat/Player2D.gd")
const Enemy2DScript := preload("res://scripts/combat/Enemy2D.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var image_path := "user://actor_directional_manifest_test.png"
	_create_test_sprite_sheet(image_path, Vector2i(32, 32), 80)
	var manifest := {
		"asset_pipeline": "image2",
		"enabled": true,
		"hide_procedural_body": true,
		"sprite_sheet_path": image_path,
		"frame_size": Vector2i(32, 32),
		"direction_mode": "4dir",
		"direction_order": ["down", "left", "right", "up"],
		"direction_frame_offsets": {
			"down": 0,
			"left": 20,
			"right": 40,
			"up": 60,
		},
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
	_check_actor_direction(player, Vector2.DOWN, "down", 4, "player")
	_check_actor_direction(player, Vector2.LEFT, "left", 24, "player")
	_check_actor_direction(player, Vector2.RIGHT, "right", 44, "player")
	_check_actor_direction(player, Vector2.UP, "up", 64, "player")
	player.queue_free()
	await process_frame

func _check_enemy(manifest: Dictionary) -> void:
	var enemy := Enemy2DScript.new()
	root.add_child(enemy)
	await process_frame
	enemy.call("apply_visual_asset_manifest_for_test", manifest)
	_check_actor_direction(enemy, Vector2.DOWN, "down", 4, "enemy")
	_check_actor_direction(enemy, Vector2.LEFT, "left", 24, "enemy")
	_check_actor_direction(enemy, Vector2.RIGHT, "right", 44, "enemy")
	_check_actor_direction(enemy, Vector2.UP, "up", 64, "enemy")
	enemy.queue_free()
	await process_frame

func _check_actor_direction(actor: Node, direction: Vector2, expected_bucket: String, expected_resolved_run_frame: int, label: String) -> void:
	if actor is Player2D:
		actor.call("set_move_vector", direction)
		actor.call("face_world_position", (actor as Node2D).global_position + direction)
	else:
		actor.call("update_actor_animation_state_for_test", direction, false)
	if actor.has_method("set_actor_animation_for_test"):
		actor.call("set_actor_animation_for_test", "run")
	var state: Dictionary = actor.call("get_actor_presentation_state_for_test")
	_expect(str(state.get("direction_mode", "")) == "4dir", "%s should expose 4dir manifest mode" % label)
	_expect(str(state.get("facing_bucket", "")) == expected_bucket, "%s should resolve %s facing bucket" % [label, expected_bucket])
	_expect(int(state.get("resolved_frame_index", -1)) == expected_resolved_run_frame, "%s should offset run frame for %s direction" % [label, expected_bucket])
	_expect(not bool(state.get("sprite_flipped_h", true)), "%s 4dir manifest should not use runtime horizontal flip" % label)

func _create_test_sprite_sheet(path: String, frame_size: Vector2i, frame_count: int) -> void:
	var image := Image.create(frame_size.x * frame_count, frame_size.y, false, Image.FORMAT_RGBA8)
	for frame in range(frame_count):
		var rect := Rect2i(Vector2i(frame * frame_size.x, 0), frame_size)
		var color := Color(float(frame + 1) / float(frame_count), 0.2, 0.6, 1.0)
		image.fill_rect(rect, color)
	image.save_png(path)

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_ACTOR_DIRECTIONAL_MANIFEST_CONTRACT_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
