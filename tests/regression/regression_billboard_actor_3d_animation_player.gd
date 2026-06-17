extends SceneTree

const BillboardActor3D := preload("res://scripts/prototype/BillboardActor3D.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var actor := BillboardActor3D.new()
	actor.name = "BillboardAnimationActor"
	root.add_child(actor)
	await process_frame

	_expect(actor.has_method("apply_visual_asset_manifest_for_test"), "billboard actor should apply visual asset manifests")
	_expect(actor.has_method("set_actor_animation_for_test"), "billboard actor should expose animation switch hook")
	_expect(actor.has_method("tick_actor_animation_for_test"), "billboard actor should expose animation tick hook")
	_expect(actor.has_method("get_actor_animation_state_for_test"), "billboard actor should expose animation state snapshot")
	_expect(actor.has_node("VisualRoot/WeaponSprite"), "billboard actor should keep weapon sprite separated from body sprite")
	if not actor.has_method("apply_visual_asset_manifest_for_test") or not actor.has_method("set_actor_animation_for_test") or not actor.has_method("tick_actor_animation_for_test") or not actor.has_method("get_actor_animation_state_for_test"):
		actor.queue_free()
		await process_frame
		_finish()
		return

	var image := Image.create(384, 192, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.2, 0.8, 1.0, 1.0))
	var image_path := "user://billboard_actor_animation_player_test.png"
	_expect(image.save_png(image_path) == OK, "test spritesheet should be saved")

	var manifest := {
		"asset_pipeline": "test",
		"enabled": true,
		"sprite_sheet_path": image_path,
		"frame_size": Vector2i(32, 48),
		"direction_mode": "4dir",
		"direction_frame_offsets": {
			"down": 0,
			"left": 12,
			"right": 24,
			"up": 36,
		},
		"animations": {
			"idle": {"from": 0, "to": 1, "fps": 8, "loop": true},
			"run": {"from": 4, "to": 5, "fps": 10, "loop": true},
			"attack": {"from": 8, "to": 9, "fps": 10, "loop": false},
			"death": {"from": 10, "to": 11, "fps": 6, "loop": false},
		},
	}
	actor.call("apply_visual_asset_manifest_for_test", manifest)
	actor.call("update_actor_animation_state_for_test", Vector2.RIGHT, false, false)
	var run_state: Dictionary = actor.call("get_actor_animation_state_for_test")
	_expect(str(run_state.get("animation", "")) == "run", "moving billboard actor should switch to run")
	_expect(int(run_state.get("frame_index", -1)) == 4, "run animation should start at manifest from frame")
	_expect(int(run_state.get("resolved_frame_index", -1)) == 28, "right-facing run should apply 4dir frame offset")
	_expect(run_state.get("frame_size", Vector2i.ZERO) == Vector2i(32, 48), "animation snapshot should preserve frame size")
	_expect(bool(run_state.get("body_weapon_separated", false)), "body and weapon layers should remain separated")

	actor.call("tick_actor_animation_for_test", 0.11)
	var advanced: Dictionary = actor.call("get_actor_animation_state_for_test")
	_expect(int(advanced.get("frame_index", -1)) == 5, "tick should advance to next frame")
	_expect(int(advanced.get("resolved_frame_index", -1)) == 29, "resolved frame should advance inside facing offset")

	actor.call("update_actor_animation_state_for_test", Vector2.ZERO, true, false)
	var attack_state: Dictionary = actor.call("get_actor_animation_state_for_test")
	_expect(str(attack_state.get("animation", "")) == "attack", "attacking billboard actor should switch to attack")
	actor.call("tick_actor_animation_for_test", 0.25)
	var settled_attack: Dictionary = actor.call("get_actor_animation_state_for_test")
	_expect(int(settled_attack.get("frame_index", -1)) == 9, "one-shot attack should hold on its final frame")
	_expect(bool(settled_attack.get("animation_locked_until_end", false)), "one-shot attack should lock until gameplay changes state")

	actor.call("update_actor_animation_state_for_test", Vector2.ZERO, false, true)
	var death_state: Dictionary = actor.call("get_actor_animation_state_for_test")
	_expect(str(death_state.get("animation", "")) == "death", "dead billboard actor should switch to death")
	_expect(bool(death_state.get("animation_locked_until_end", false)), "death animation should lock until end")

	actor.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_BILLBOARD_ACTOR_3D_ANIMATION_PLAYER_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
