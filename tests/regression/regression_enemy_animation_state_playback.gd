extends SceneTree

const Enemy2DScript := preload("res://scripts/combat/Enemy2D.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var image_path := "user://enemy_animation_state_playback_test.png"
	_create_test_sprite_sheet(image_path, Vector2i(64, 64), 20)
	var enemy := Enemy2DScript.new()
	root.add_child(enemy)
	await process_frame
	enemy.call("apply_visual_asset_manifest_for_test", {
		"asset_pipeline": "image2",
		"enabled": true,
		"hide_procedural_body": true,
		"sprite_sheet_path": image_path,
		"frame_size": Vector2i(64, 64),
		"animations": {
			"idle": {"from": 0, "to": 3, "fps": 8},
			"run": {"from": 4, "to": 9, "fps": 8},
			"attack": {"from": 10, "to": 15, "fps": 8},
			"death": {"from": 16, "to": 19, "fps": 8},
		},
	})

	enemy.call("update_actor_animation_state_for_test", Vector2.RIGHT, false)
	enemy.call("tick_actor_animation_for_test", 0.13)
	enemy.call("update_actor_animation_state_for_test", Vector2.RIGHT, false)
	enemy.call("tick_actor_animation_for_test", 0.13)
	var run_state: Dictionary = enemy.call("get_actor_animation_state_for_test")
	_expect(str(run_state.get("animation", "")) == "run", "enemy movement should select run animation")
	_expect(int(run_state.get("frame_index", -1)) > 5, "run animation should keep advancing instead of resetting near frame 4 every frame")

	enemy.call("update_actor_animation_state_for_test", Vector2.ZERO, true)
	enemy.call("tick_actor_animation_for_test", 0.13)
	enemy.call("update_actor_animation_state_for_test", Vector2.ZERO, false)
	enemy.call("tick_actor_animation_for_test", 0.13)
	var attack_state: Dictionary = enemy.call("get_actor_animation_state_for_test")
	_expect(str(attack_state.get("animation", "")) == "attack", "enemy attack animation should not be cancelled by idle on the next frame")
	_expect(int(attack_state.get("frame_index", -1)) > 10, "attack animation should advance through its frames")

	enemy.call("take_damage", 999)
	await process_frame
	enemy.call("tick_actor_animation_for_test", 0.13)
	enemy.call("tick_actor_animation_for_test", 0.13)
	var death_state: Dictionary = enemy.call("get_actor_animation_state_for_test")
	_expect(str(death_state.get("animation", "")) == "death", "enemy death should select death animation")
	_expect(int(death_state.get("frame_index", -1)) > 16, "death animation should advance after enemy dies")
	_expect(bool(death_state.get("death_animation_triggered", false)), "death animation trigger flag should be set")

	enemy.queue_free()
	await process_frame
	_finish()

func _create_test_sprite_sheet(path: String, frame_size: Vector2i, frame_count: int) -> void:
	var image := Image.create(frame_size.x * frame_count, frame_size.y, false, Image.FORMAT_RGBA8)
	for frame in range(frame_count):
		var color := Color(float(frame + 1) / float(frame_count), 0.25, 0.75, 1.0)
		image.fill_rect(Rect2i(Vector2i(frame * frame_size.x, 0), frame_size), color)
	image.save_png(path)

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_ENEMY_ANIMATION_STATE_PLAYBACK_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
