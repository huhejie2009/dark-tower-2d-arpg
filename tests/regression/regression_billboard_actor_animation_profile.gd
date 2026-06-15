extends SceneTree

const ProfileScript := preload("res://scripts/prototype/BillboardActorAnimationProfile.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var profile := ProfileScript.new()
	profile.actor_id = "player_warrior_trial"
	profile.art_family = "dark_high_res_pixel_actor"
	profile.directional_target = "4dir_first"
	profile.animation_pipeline = "action_separated"
	profile.weapon_layer_mode = "external_attach"
	profile.body_sprites_must_exclude_weapon = true
	profile.combat_vfx_separated = true
	profile.sprite_sheet_path = "res://assets/generated/actors/candidates/player_warrior_body_down_idle_normalized_v1.png"
	profile.frame_size = Vector2i(96, 96)
	profile.directions = PackedStringArray(["down", "left", "right", "up"])
	profile.actions = PackedStringArray(["idle", "run", "attack", "death"])

	var snapshot := profile.build_manifest_snapshot()
	_expect(str(snapshot.get("actor_id", "")) == "player_warrior_trial", "snapshot should preserve actor id")
	_expect(str(snapshot.get("actor_render_mode", "")) == "sprite3d_billboard", "profile should use sprite3d billboard render mode")
	_expect(str(snapshot.get("directional_target", "")) == "4dir_first", "profile should declare 4dir first")
	_expect(str(snapshot.get("animation_pipeline", "")) == "action_separated", "profile should preserve separated action pipeline")
	_expect(str(snapshot.get("weapon_layer_mode", "")) == "external_attach", "profile should preserve external weapon attach mode")
	_expect(bool(snapshot.get("body_sprites_must_exclude_weapon", false)), "body sprites should exclude baked weapons")
	_expect(bool(snapshot.get("combat_vfx_separated", false)), "combat VFX should remain separated")
	_expect(int(snapshot.get("direction_count", 0)) == 4, "snapshot should count four directions")
	_expect(int(snapshot.get("action_count", 0)) == 4, "snapshot should count four actions")
	_expect(profile.is_valid_for_trial(), "complete profile should be valid for trial")

	var invalid := ProfileScript.new()
	invalid.actor_id = "invalid_actor"
	_expect(not invalid.is_valid_for_trial(), "missing sprite sheet and frame size should be invalid")
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_BILLBOARD_ACTOR_ANIMATION_PROFILE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
