extends SceneTree

const PrototypeScene := preload("res://scenes/prototypes/Prototype2_5DCombatRoom.tscn")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := PrototypeScene.instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame

	_expect(scene.has_method("build_animation_state_snapshot_for_test"), "prototype should expose animation state snapshot")
	if not scene.has_method("build_animation_state_snapshot_for_test"):
		scene.queue_free()
		await process_frame
		_finish()
		return

	var snapshot: Dictionary = scene.call("build_animation_state_snapshot_for_test")
	_expect(str(snapshot.get("player_asset_pipeline", "")) == "image2", "player should use image2 manifest in 2.5D prototype")
	_expect(str(snapshot.get("player_sprite_sheet_path", "")).ends_with("player_warrior_sheet_v3.png"), "player should use production warrior sheet")
	_expect(snapshot.get("player_frame_size", Vector2i.ZERO) == Vector2i(160, 160), "player should use 160x160 frame size")
	_expect(bool(snapshot.get("player_actor_sprite_visible", false)), "player sprite should be visible")
	_expect(bool(snapshot.get("player_actor_sprite_texture_loaded", false)), "player texture should load")
	_expect(str(snapshot.get("player_direction_mode", "")) == "runtime_flip_2dir", "player should use runtime flip direction mode")

	var enemy_animations: Array = Array(snapshot.get("enemy_animations", []))
	_expect(enemy_animations.size() == 2, "prototype should keep two enemies")
	if enemy_animations.size() >= 2:
		_check_enemy(Dictionary(enemy_animations[0]), "enemy_rot_melee_sheet_v3.png", "rot melee")
		_check_enemy(Dictionary(enemy_animations[1]), "enemy_shadow_archer_sheet_v3.png", "shadow archer")

	scene.queue_free()
	await process_frame
	_finish()

func _check_enemy(enemy_state: Dictionary, expected_file_name: String, label: String) -> void:
	_expect(str(enemy_state.get("asset_pipeline", "")) == "image2", "%s should use image2 manifest" % label)
	_expect(str(enemy_state.get("sprite_sheet_path", "")).ends_with(expected_file_name), "%s should use %s" % [label, expected_file_name])
	_expect(enemy_state.get("frame_size", Vector2i.ZERO) == Vector2i(128, 128), "%s should use 128x128 frame size" % label)
	_expect(bool(enemy_state.get("actor_sprite_visible", false)), "%s sprite should be visible" % label)
	_expect(bool(enemy_state.get("actor_sprite_texture_loaded", false)), "%s texture should load" % label)
	_expect(str(enemy_state.get("direction_mode", "")) == "runtime_flip_2dir", "%s should use runtime flip direction mode" % label)
	_expect(bool(enemy_state.get("body_weapon_separated", false)), "%s body and weapon layers should remain separated" % label)

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_PROTOTYPE_2_5D_REAL_ACTOR_TEXTURES_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
