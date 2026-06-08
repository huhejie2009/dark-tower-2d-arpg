extends SceneTree

const Enemy2DScript := preload("res://scripts/combat/Enemy2D.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var image_path := "user://enemy_animation_readability_test.png"
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
	_expect(enemy.has_method("get_actor_presentation_state_for_test"), "enemy should expose runtime presentation state")

	enemy.call("update_actor_animation_state_for_test", Vector2.RIGHT, false)
	enemy.call("tick_actor_animation_for_test", 0.18)
	var run_state: Dictionary = enemy.call("get_actor_presentation_state_for_test") if enemy.has_method("get_actor_presentation_state_for_test") else {}
	_expect(str(run_state.get("animation", "")) == "run", "run presentation should track run animation")
	_expect(absf(float(run_state.get("visual_offset_y", 0.0))) >= 1.0 or absf(float(run_state.get("visual_rotation", 0.0))) >= 0.015, "run presentation should add visible bob or sway")

	enemy.call("update_actor_animation_state_for_test", Vector2.ZERO, true)
	enemy.call("tick_actor_animation_for_test", 0.18)
	var attack_state: Dictionary = enemy.call("get_actor_presentation_state_for_test") if enemy.has_method("get_actor_presentation_state_for_test") else {}
	_expect(str(attack_state.get("animation", "")) == "attack", "attack presentation should track attack animation")
	_expect(float(attack_state.get("visual_lunge_x", 0.0)) >= 6.0, "attack should add a visible lunge instead of only frame jitter")
	_expect(bool(attack_state.get("attack_arc_visible", false)), "attack should show a short melee arc cue")

	enemy.call("take_damage", 999)
	await process_frame
	enemy.call("tick_actor_animation_for_test", 0.18)
	var death_state: Dictionary = enemy.call("get_actor_presentation_state_for_test") if enemy.has_method("get_actor_presentation_state_for_test") else {}
	_expect(str(death_state.get("animation", "")) == "death", "death presentation should track death animation")
	_expect(float(death_state.get("visual_scale_y", 1.0)) < 1.0 or float(death_state.get("visual_alpha", 1.0)) < 1.0, "death should visibly collapse or fade")

	enemy.queue_free()
	await process_frame
	_finish()

func _create_test_sprite_sheet(path: String, frame_size: Vector2i, frame_count: int) -> void:
	var image := Image.create(frame_size.x * frame_count, frame_size.y, false, Image.FORMAT_RGBA8)
	for frame in range(frame_count):
		var color := Color(float(frame + 1) / float(frame_count), 0.18, 0.55, 1.0)
		image.fill_rect(Rect2i(Vector2i(frame * frame_size.x, 0), frame_size), color)
	image.save_png(path)

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_ENEMY_ANIMATION_READABILITY_CONTRACT_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
