extends SceneTree

const BillboardActor3D := preload("res://scripts/prototype/BillboardActor3D.gd")
const ProfileScript := preload("res://scripts/prototype/BillboardActorAnimationProfile.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var actor := BillboardActor3D.new()
	actor.name = "PlayerBillboard"
	root.add_child(actor)
	await process_frame

	_expect(actor is CharacterBody3D, "billboard actor should be a CharacterBody3D")
	_expect(actor.has_node("VisualRoot"), "actor should have VisualRoot")
	_expect(actor.has_node("VisualRoot/ActorSprite"), "actor should have ActorSprite")
	_expect(actor.has_node("VisualRoot/WeaponSprite"), "actor should reserve WeaponSprite")
	_expect(actor.has_node("CollisionShape3D"), "actor should have CollisionShape3D")

	var profile := ProfileScript.new()
	profile.actor_id = "player_warrior_trial"
	profile.sprite_sheet_path = "res://assets/generated/actors/candidates/player_warrior_body_down_idle_normalized_v1.png"
	profile.frame_size = Vector2i(96, 96)
	actor.apply_animation_profile(profile)

	var snapshot := actor.build_contract_snapshot()
	_expect(str(snapshot.get("actor_render_mode", "")) == "sprite3d_billboard", "snapshot should declare sprite3d billboard")
	_expect(str(snapshot.get("plane", "")) == "xz", "snapshot should declare XZ movement plane")
	_expect(bool(snapshot.get("has_collision_shape", false)), "snapshot should confirm collision shape")
	_expect(bool(snapshot.get("has_weapon_sprite", false)), "snapshot should confirm weapon layer")
	_expect(str(snapshot.get("profile_actor_id", "")) == "player_warrior_trial", "snapshot should include profile actor id")

	actor.set_move_input(Vector2(1.0, -1.0))
	actor.set_movement_speed(120.0)
	await process_frame
	var velocity_snapshot := actor.build_contract_snapshot()
	_expect(float(velocity_snapshot.get("movement_speed", 0.0)) == 120.0, "snapshot should expose movement speed")
	_expect(str(velocity_snapshot.get("facing_direction", "")) == "right" or str(velocity_snapshot.get("facing_direction", "")) == "up", "actor should derive a cardinal facing direction")

	actor.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_BILLBOARD_ACTOR_3D_CONTRACT_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
