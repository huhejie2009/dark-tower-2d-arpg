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

	_expect(scene.has_method("build_player_attack_feedback_snapshot_for_test"), "prototype should expose attack animation/vfx feedback snapshot")
	_expect(scene.has_method("get_enemy_screen_position_for_test"), "prototype should expose enemy screen position")
	_expect(scene.has_method("set_player_position_for_test"), "prototype should expose deterministic player positioning")
	_expect(scene.has_method("clear_player_attack_direction_override_for_test"), "prototype should allow mouse aim without direction override")
	if not scene.has_method("build_player_attack_feedback_snapshot_for_test") or not scene.has_method("get_enemy_screen_position_for_test") or not scene.has_method("set_player_position_for_test") or not scene.has_method("clear_player_attack_direction_override_for_test"):
		scene.queue_free()
		await process_frame
		_finish()
		return

	var enemy_loop: Dictionary = scene.call("build_enemy_loop_snapshot_for_test")
	var enemy_states: Array = Array(enemy_loop.get("enemy_states", []))
	_expect(enemy_states.size() == 2, "prototype should expose two enemies for attack feedback test")
	if enemy_states.is_empty():
		scene.queue_free()
		await process_frame
		_finish()
		return

	var first_enemy_position: Vector3 = Dictionary(enemy_states[0]).get("position", Vector3.ZERO)
	scene.call("set_player_position_for_test", first_enemy_position + Vector3(-0.75, 0.0, 0.0))
	scene.call("clear_player_attack_direction_override_for_test")
	await process_frame
	await physics_frame

	var before: Dictionary = scene.call("build_player_attack_feedback_snapshot_for_test")
	_expect(str(before.get("player_action_state", "")) == "idle", "player actor should start from idle when not moving")
	_expect(bool(before.get("hit_vfx_root_exists", false)), "hit vfx should have an independent root")
	_expect(not bool(before.get("hit_vfx_visible", true)), "hit vfx should start hidden")

	scene.call("_input", _mouse_click(scene.call("get_enemy_screen_position_for_test", 0)))
	await physics_frame

	var after: Dictionary = scene.call("build_player_attack_feedback_snapshot_for_test")
	var vfx_parent_path := str(after.get("hit_vfx_parent_path", ""))
	var vfx_position: Vector3 = after.get("last_hit_vfx_position", Vector3.ZERO)
	_expect(str(after.get("player_action_state", "")) == "attack", "accepted attack should set the player actor to attack state")
	_expect(bool(after.get("hit_vfx_visible", false)), "a successful hit should show independent hit vfx")
	_expect(str(after.get("hit_vfx_role", "")) == "hit_impact", "hit vfx should expose its role for future asset replacement")
	_expect(bool(after.get("hit_vfx_independent_from_actor", false)), "hit vfx should be independent from actor and weapon sprites")
	_expect(not vfx_parent_path.contains("PlayerBillboard"), "hit vfx parent should not be under player actor")
	_expect(vfx_position.distance_to(first_enemy_position) < 0.8, "hit vfx should appear near the struck enemy")

	for _index in range(40):
		await physics_frame

	var settled: Dictionary = scene.call("build_player_attack_feedback_snapshot_for_test")
	_expect(str(settled.get("player_action_state", "")) != "attack", "player actor should leave attack state after cooldown")
	_expect(not bool(settled.get("hit_vfx_visible", true)), "hit vfx should hide after its lifetime")

	scene.queue_free()
	await process_frame
	_finish()

func _mouse_click(position: Vector2) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = position
	return event

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_PROTOTYPE_2_5D_ATTACK_ANIMATION_VFX_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
