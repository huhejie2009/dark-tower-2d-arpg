extends SceneTree

const GameConstantsScript := preload("res://scripts/app/GameConstants.gd")
const SaveManagerScript := preload("res://scripts/save/SaveManager.gd")
const TowerRunStartServiceScript := preload("res://scripts/data/TowerRunStartService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := SaveManagerScript.create_character("slot_1", "2.5D Behavior", "warrior")
	player["health"] = 120
	player["max_health"] = 120
	player["highest_floor"] = 5
	SaveManagerScript.save_active_player_data(player, 5)
	TowerRunStartServiceScript.request_start_floor(3)

	var packed := load(GameConstantsScript.ACTIVE_GAME_SCENE)
	_expect(packed is PackedScene, "active 2.5D game scene should load")
	if not packed is PackedScene:
		_finish()
		return

	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame

	_expect(scene.has_method("build_enemy_behavior_snapshot_for_test"), "2.5D runtime should expose enemy behavior snapshot")
	_expect(scene.has_method("tick_enemy_behavior_for_test"), "2.5D runtime should expose deterministic enemy behavior tick")
	_expect(scene.has_method("force_boss_slam_for_test"), "2.5D runtime should expose boss slam trigger")
	_expect(scene.has_method("resolve_boss_slam_for_test"), "2.5D runtime should expose boss slam resolver")
	if not scene.has_method("build_enemy_behavior_snapshot_for_test"):
		scene.queue_free()
		await process_frame
		_finish()
		return

	scene.call("_apply_floor_template_for_test", 3)
	await process_frame
	var ranged_initial: Dictionary = scene.call("build_enemy_behavior_snapshot_for_test")
	var archer_index := _find_enemy_index(ranged_initial, "shadow_archer")
	_expect(archer_index >= 0, "floor 3 should expose a shadow archer in behavior snapshot")
	if archer_index >= 0:
		var archer_state := Dictionary(Array(ranged_initial.get("enemy_states", []))[archer_index])
		var archer_position: Vector3 = archer_state.get("position", Vector3.ZERO)
		scene.call("set_player_position_for_test", archer_position + Vector3(0.35, 0.0, 0.0))
		scene.call("tick_enemy_behavior_for_test", 0.2)
		var retreat_snapshot: Dictionary = scene.call("build_enemy_behavior_snapshot_for_test")
		var retreat_state := Dictionary(Array(retreat_snapshot.get("enemy_states", []))[archer_index])
		_expect(str(retreat_state.get("behavior_intent", "")) == "retreat", "shadow archer should retreat when player is too close")
		_expect(Vector2(retreat_state.get("move_input", Vector2.ZERO)).length() > 0.1, "retreating archer should move away")
		_expect(bool(retreat_state.get("uses_projectile", false)), "shadow archer should keep projectile behavior flag")

		scene.call("set_player_position_for_test", archer_position + Vector3(3.0, 0.0, 0.0))
		var health_before := int(Dictionary(scene.call("build_enemy_behavior_snapshot_for_test")).get("player_health", 0))
		scene.call("tick_enemy_behavior_for_test", 2.0)
		var ranged_attack: Dictionary = scene.call("build_enemy_behavior_snapshot_for_test")
		var attack_state := Dictionary(Array(ranged_attack.get("enemy_states", []))[archer_index])
		_expect(str(attack_state.get("behavior_intent", "")) == "ranged_attack", "shadow archer should attack from preferred range")
		_expect(str(attack_state.get("last_attack_kind", "")) == "projectile", "shadow archer attack should be recorded as projectile")
		_expect(int(attack_state.get("attack_count", 0)) > int(retreat_state.get("attack_count", 0)), "ranged archer should increment attack count")
		_expect(int(ranged_attack.get("player_health", 0)) < health_before, "ranged archer attack should damage player")

	scene.call("_apply_floor_template_for_test", 5)
	await process_frame
	var boss_initial: Dictionary = scene.call("build_enemy_behavior_snapshot_for_test")
	var boss_index := _find_enemy_index(boss_initial, "tower_gatekeeper")
	_expect(boss_index >= 0, "floor 5 should expose tower gatekeeper in behavior snapshot")
	if boss_index >= 0:
		var boss_state := Dictionary(Array(boss_initial.get("enemy_states", []))[boss_index])
		var boss_position: Vector3 = boss_state.get("position", Vector3.ZERO)
		scene.call("set_player_position_for_test", boss_position + Vector3(0.5, 0.0, 0.0))
		var boss_health_before := int(Dictionary(scene.call("build_enemy_behavior_snapshot_for_test")).get("player_health", 0))
		scene.call("force_boss_slam_for_test", boss_index)
		var warning: Dictionary = scene.call("build_enemy_behavior_snapshot_for_test")
		_expect(bool(warning.get("boss_slam_warning_visible", false)), "gatekeeper slam should create a visible warning")
		_expect(str(warning.get("boss_slam_warning_role", "")) == "gatekeeper_slam_warning", "warning should expose replaceable role metadata")
		_expect(float(warning.get("boss_slam_radius", 0.0)) >= 1.0, "boss slam should expose a readable radius")
		scene.call("resolve_boss_slam_for_test")
		var resolved: Dictionary = scene.call("build_enemy_behavior_snapshot_for_test")
		_expect(not bool(resolved.get("boss_slam_warning_visible", true)), "resolved slam should hide warning")
		_expect(int(resolved.get("player_health", 0)) < boss_health_before, "boss slam should damage player inside radius")

	scene.queue_free()
	await process_frame
	_finish()

func _find_enemy_index(snapshot: Dictionary, enemy_type: String) -> int:
	var states: Array = Array(snapshot.get("enemy_states", []))
	for index in range(states.size()):
		if str(Dictionary(states[index]).get("enemy_type", "")) == enemy_type:
			return index
	return -1

func _finish() -> void:
	root.get_tree().paused = false
	if failures.is_empty():
		print("NEW_PROJECT_PROTOTYPE_2_5D_RANGED_BOSS_BEHAVIOR_BRIDGE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
