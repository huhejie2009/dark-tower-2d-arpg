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

	_expect(scene.has_method("get_player_screen_position_for_test"), "prototype should expose player screen position")
	_expect(scene.has_method("get_enemy_screen_position_for_test"), "prototype should expose enemy screen position")
	_expect(scene.has_method("build_player_attack_visual_snapshot_for_test"), "prototype should expose attack visual snapshot")
	_expect(scene.has_method("clear_player_attack_direction_override_for_test"), "prototype should be able to clear deterministic attack direction")
	if not scene.has_method("get_player_screen_position_for_test") or not scene.has_method("get_enemy_screen_position_for_test") or not scene.has_method("build_player_attack_visual_snapshot_for_test") or not scene.has_method("clear_player_attack_direction_override_for_test"):
		scene.queue_free()
		await process_frame
		_finish()
		return

	var enemy_loop: Dictionary = scene.call("build_enemy_loop_snapshot_for_test")
	var enemy_states: Array = Array(enemy_loop.get("enemy_states", []))
	_expect(enemy_states.size() == 2, "prototype should expose two enemies for mouse attack test")
	if enemy_states.size() == 0:
		scene.queue_free()
		await process_frame
		_finish()
		return

	var first_enemy_position: Vector3 = Dictionary(enemy_states[0]).get("position", Vector3.ZERO)
	scene.call("set_player_position_for_test", first_enemy_position + Vector3(-0.75, 0.0, 0.0))
	scene.call("clear_player_attack_direction_override_for_test")
	await process_frame
	await physics_frame

	var player_screen: Vector2 = scene.call("get_player_screen_position_for_test")
	var enemy_screen: Vector2 = scene.call("get_enemy_screen_position_for_test", 0)
	_expect(player_screen.distance_to(enemy_screen) > 1.0, "enemy screen position should be distinct from player screen position")

	scene.call("_input", _mouse_click(enemy_screen))
	await physics_frame

	var attack: Dictionary = scene.call("build_player_attack_snapshot_for_test")
	var visual: Dictionary = scene.call("build_player_attack_visual_snapshot_for_test")
	var after_enemy_loop: Dictionary = scene.call("build_enemy_loop_snapshot_for_test")
	var last_direction: Vector2 = attack.get("last_attack_direction", Vector2.ZERO)
	var visual_direction: Vector2 = visual.get("arc_direction", Vector2.ZERO)

	_expect(int(attack.get("last_hit_count", 0)) == 1, "mouse-directed attack should hit the clicked enemy")
	_expect(int(after_enemy_loop.get("living_enemy_count", 0)) == 1, "mouse-directed hit should defeat one enemy")
	_expect(str(attack.get("aim_source", "")) == "mouse", "attack snapshot should record mouse aim source")
	_expect(last_direction.x > 0.6 and absf(last_direction.y) < 0.45, "mouse click to the right should produce a +X attack direction")
	_expect(bool(visual.get("has_attack_arc_marker", false)), "attack should have a temporary arc marker")
	_expect(bool(visual.get("attack_arc_visible", false)), "attack arc marker should be visible during active attack")
	_expect(visual_direction.x > 0.6 and absf(visual_direction.y) < 0.45, "attack arc should face the mouse attack direction")
	_expect(float(visual.get("arc_range", 0.0)) >= float(attack.get("attack_range", 0.0)), "attack arc should cover the attack range")

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
		print("NEW_PROJECT_PROTOTYPE_2_5D_MOUSE_ATTACK_VISUAL_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
