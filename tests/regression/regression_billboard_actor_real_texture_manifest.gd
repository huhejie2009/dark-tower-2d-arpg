extends SceneTree

const BillboardActor3D := preload("res://scripts/prototype/BillboardActor3D.gd")
const ManifestLibrary := preload("res://scripts/prototype/BillboardActorManifestLibrary.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	await _check_actor_manifest(
		ManifestLibrary.make_player_warrior_v3(),
		"player_warrior_sheet_v3.png",
		Vector2i(160, 160),
		"player warrior"
	)
	await _check_actor_manifest(
		ManifestLibrary.make_rot_melee_v3(),
		"enemy_rot_melee_sheet_v3.png",
		Vector2i(128, 128),
		"rot melee"
	)
	await _check_actor_manifest(
		ManifestLibrary.make_shadow_archer_v3(),
		"enemy_shadow_archer_sheet_v3.png",
		Vector2i(128, 128),
		"shadow archer"
	)
	_finish()

func _check_actor_manifest(manifest: Dictionary, expected_file_name: String, expected_frame_size: Vector2i, label: String) -> void:
	_expect(str(manifest.get("asset_pipeline", "")) == "image2", "%s should use image2 pipeline" % label)
	_expect(str(manifest.get("pose_variation_version", "")) == "production_dark_armor_v3", "%s should use production pose variation" % label)
	_expect(str(manifest.get("texture_filter", "")) == "nearest", "%s should request nearest filtering" % label)
	_expect(str(manifest.get("direction_mode", "")) == "runtime_flip_2dir", "%s should use runtime flip direction mode" % label)
	_expect(bool(manifest.get("enabled", false)), "%s manifest should be enabled" % label)
	_expect(bool(manifest.get("hide_procedural_body", false)), "%s manifest should hide procedural bodies" % label)
	_expect(bool(manifest.get("body_sprites_must_exclude_weapon", false)), "%s body sheet should exclude baked weapon" % label)
	_expect(bool(manifest.get("combat_vfx_separated", false)), "%s combat VFX should be separate" % label)
	_expect(str(manifest.get("sprite_sheet_path", "")).ends_with(expected_file_name), "%s should reference %s" % [label, expected_file_name])
	_expect(manifest.get("frame_size", Vector2i.ZERO) == expected_frame_size, "%s should preserve frame size" % label)
	var animations := Dictionary(manifest.get("animations", {}))
	for animation_name in ["idle", "run", "attack", "death"]:
		_expect(animations.has(animation_name), "%s should include %s animation" % [label, animation_name])

	var actor := BillboardActor3D.new()
	actor.name = "%sRealTextureActor" % label.capitalize().replace(" ", "")
	root.add_child(actor)
	await process_frame
	actor.call("apply_visual_asset_manifest_for_test", manifest)
	var idle_state: Dictionary = actor.call("get_actor_animation_state_for_test")
	_expect(str(idle_state.get("animation", "")) == "idle", "%s should start idle after applying manifest" % label)
	_expect(int(idle_state.get("frame_index", -1)) == 0, "%s idle should start at frame 0" % label)
	_expect(int(idle_state.get("resolved_frame_index", -1)) == 0, "%s runtime flip mode should not add frame offset" % label)
	_expect(bool(idle_state.get("actor_sprite_visible", false)), "%s actor sprite should be visible" % label)
	_expect(bool(idle_state.get("actor_sprite_texture_loaded", false)), "%s actor sprite should load texture" % label)
	_expect(bool(idle_state.get("actor_sprite_region_enabled", false)), "%s actor sprite should use regions" % label)
	_expect(idle_state.get("actor_sprite_region_rect", Rect2()).size == Vector2(expected_frame_size), "%s region should match one frame" % label)

	actor.call("update_actor_animation_state_for_test", Vector2.RIGHT, false, false)
	var run_state: Dictionary = actor.call("get_actor_animation_state_for_test")
	_expect(str(run_state.get("animation", "")) == "run", "%s movement should switch to run" % label)
	_expect(int(run_state.get("frame_index", -1)) == 4, "%s run should start at frame 4" % label)
	_expect(int(run_state.get("resolved_frame_index", -1)) == 4, "%s resolved run frame should match runtime flip source frame" % label)

	actor.call("update_actor_animation_state_for_test", Vector2.ZERO, true, false)
	var attack_state: Dictionary = actor.call("get_actor_animation_state_for_test")
	_expect(str(attack_state.get("animation", "")) == "attack", "%s attacking should switch to attack" % label)
	_expect(int(attack_state.get("frame_index", -1)) == 10, "%s attack should start at frame 10" % label)

	actor.call("update_actor_animation_state_for_test", Vector2.ZERO, false, true)
	var death_state: Dictionary = actor.call("get_actor_animation_state_for_test")
	_expect(str(death_state.get("animation", "")) == "death", "%s dead state should switch to death" % label)
	_expect(int(death_state.get("frame_index", -1)) == 16, "%s death should start at frame 16" % label)

	actor.queue_free()
	await process_frame

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_BILLBOARD_ACTOR_REAL_TEXTURE_MANIFEST_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
