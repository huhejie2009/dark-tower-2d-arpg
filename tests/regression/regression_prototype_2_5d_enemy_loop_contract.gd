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

	_expect(scene.has_method("build_enemy_loop_snapshot_for_test"), "prototype should expose enemy loop snapshot")
	_expect(scene.has_method("set_player_position_for_test"), "prototype should expose deterministic player positioning")
	_expect(scene.has_method("defeat_enemy_for_test"), "prototype should expose deterministic enemy defeat")
	if not scene.has_method("build_enemy_loop_snapshot_for_test") or not scene.has_method("set_player_position_for_test") or not scene.has_method("defeat_enemy_for_test"):
		scene.queue_free()
		await process_frame
		_finish()
		return

	var initial: Dictionary = scene.call("build_enemy_loop_snapshot_for_test")
	_expect(int(initial.get("total_enemy_count", 0)) == 2, "prototype should start with two enemies")
	_expect(int(initial.get("living_enemy_count", 0)) == 2, "both enemies should start alive")
	_expect(not bool(initial.get("room_cleared", true)), "room should not start cleared")
	_expect(not bool(initial.get("exit_unlocked", true)), "exit should start locked")

	var initial_enemy_states: Array = Array(initial.get("enemy_states", []))
	_expect(initial_enemy_states.size() == 2, "snapshot should include each enemy")
	if initial_enemy_states.size() > 0:
		var first_enemy_position: Vector3 = Dictionary(initial_enemy_states[0]).get("position", Vector3.ZERO)
		scene.call("set_player_position_for_test", first_enemy_position + Vector3(0.45, 0.0, 0.0))
		for index in range(12):
			await physics_frame

		var attacking: Dictionary = scene.call("build_enemy_loop_snapshot_for_test")
		var attacking_enemy_states: Array = Array(attacking.get("enemy_states", []))
		if attacking_enemy_states.size() > 0:
			var enemy_zero := Dictionary(attacking_enemy_states[0])
			_expect(str(enemy_zero.get("mode", "")) == "attack", "enemy should enter attack mode near the player")
			_expect(Vector2(enemy_zero.get("move_input", Vector2.ONE)).length_squared() <= 0.0001, "attacking enemy should stop moving")
			_expect(float(enemy_zero.get("distance_to_player", 999.0)) <= float(attacking.get("enemy_attack_range", 0.0)) + 0.1, "attacking enemy should be inside attack range")

	scene.call("defeat_enemy_for_test", 0)
	await physics_frame
	var after_one_defeat: Dictionary = scene.call("build_enemy_loop_snapshot_for_test")
	_expect(int(after_one_defeat.get("living_enemy_count", 0)) == 1, "defeating one enemy should reduce living count")
	_expect(not bool(after_one_defeat.get("exit_unlocked", true)), "exit should stay locked while enemies remain")

	scene.call("defeat_enemy_for_test", 1)
	await physics_frame
	var after_all_defeated: Dictionary = scene.call("build_enemy_loop_snapshot_for_test")
	_expect(int(after_all_defeated.get("living_enemy_count", -1)) == 0, "all enemies should be defeated")
	_expect(bool(after_all_defeated.get("room_cleared", false)), "room should clear when all enemies are defeated")
	_expect(bool(after_all_defeated.get("exit_unlocked", false)), "exit should unlock after all enemies are defeated")

	scene.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_PROTOTYPE_2_5D_ENEMY_LOOP_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
