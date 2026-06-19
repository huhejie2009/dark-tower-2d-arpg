extends SceneTree

const GameConstantsScript := preload("res://scripts/app/GameConstants.gd")
const SaveManagerScript := preload("res://scripts/save/SaveManager.gd")
const TowerRunStartServiceScript := preload("res://scripts/data/TowerRunStartService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := SaveManagerScript.create_character("slot_1", "2.5D Readability", "warrior")
	player["health"] = 140
	player["max_health"] = 140
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

	_expect(scene.has_method("build_combat_readability_snapshot_for_test"), "2.5D runtime should expose combat readability snapshot")
	_expect(scene.has_method("tick_enemy_behavior_for_test"), "2.5D runtime should expose deterministic enemy behavior tick")
	_expect(scene.has_method("tick_boss_skill_for_test"), "2.5D runtime should expose deterministic boss skill tick")
	if not scene.has_method("build_combat_readability_snapshot_for_test"):
		scene.queue_free()
		await process_frame
		_finish()
		return

	scene.call("_apply_floor_template_for_test", 3)
	await process_frame
	var archer_index := _find_enemy_index(scene.call("build_enemy_behavior_snapshot_for_test"), "shadow_archer")
	_expect(archer_index >= 0, "floor 3 should expose a shadow archer")
	if archer_index >= 0:
		var archer_state := Dictionary(Array(Dictionary(scene.call("build_enemy_behavior_snapshot_for_test")).get("enemy_states", []))[archer_index])
		var archer_position: Vector3 = archer_state.get("position", Vector3.ZERO)
		scene.call("set_player_position_for_test", archer_position + Vector3(3.0, 0.0, 0.0))
		var before_projectile: Dictionary = scene.call("build_combat_readability_snapshot_for_test")
		scene.call("tick_enemy_behavior_for_test", 2.0)
		var projectile_snapshot: Dictionary = scene.call("build_combat_readability_snapshot_for_test")
		_expect(bool(projectile_snapshot.get("ranged_projectile_root_exists", false)), "ranged projectile vfx should have an independent root")
		_expect(bool(projectile_snapshot.get("ranged_projectile_visible", false)), "ranged attack should show a projectile marker")
		_expect(str(projectile_snapshot.get("ranged_projectile_role", "")) == "enemy_projectile", "ranged projectile should expose replaceable role metadata")
		_expect(str(projectile_snapshot.get("ranged_projectile_owner_type", "")) == "shadow_archer", "projectile should record enemy owner type")
		_expect(int(projectile_snapshot.get("ranged_projectile_count", 0)) > int(before_projectile.get("ranged_projectile_count", 0)), "ranged attack should increment projectile feedback count")
		_expect(float(projectile_snapshot.get("ranged_projectile_path_length", 0.0)) > 0.5, "projectile should record a readable travel path")
		_expect(bool(projectile_snapshot.get("ranged_projectile_hit_confirmed", false)), "projectile feedback should record hit confirmation")

	scene.call("_apply_floor_template_for_test", 5)
	await process_frame
	var boss_index := _find_enemy_index(scene.call("build_enemy_behavior_snapshot_for_test"), "tower_gatekeeper")
	_expect(boss_index >= 0, "floor 5 should expose tower gatekeeper")
	if boss_index >= 0:
		var boss_state := Dictionary(Array(Dictionary(scene.call("build_enemy_behavior_snapshot_for_test")).get("enemy_states", []))[boss_index])
		var boss_position: Vector3 = boss_state.get("position", Vector3.ZERO)
		scene.call("set_player_position_for_test", boss_position + Vector3(0.5, 0.0, 0.0))
		var health_before := int(Dictionary(scene.call("build_enemy_behavior_snapshot_for_test")).get("player_health", 0))
		scene.call("force_boss_slam_for_test", boss_index)
		var charging: Dictionary = scene.call("build_combat_readability_snapshot_for_test")
		_expect(str(charging.get("boss_slam_phase", "")) == "charging", "forced boss slam should start with a readable charge phase")
		_expect(bool(charging.get("boss_slam_warning_visible", false)), "boss charge should show danger warning before damage")
		_expect(float(charging.get("boss_slam_charge_remaining", 0.0)) > 0.0, "boss charge should expose remaining charge time")
		_expect(int(Dictionary(scene.call("build_enemy_behavior_snapshot_for_test")).get("player_health", 0)) == health_before, "boss charge should not damage immediately")

		scene.call("tick_boss_skill_for_test", 0.2)
		var still_charging: Dictionary = scene.call("build_combat_readability_snapshot_for_test")
		_expect(str(still_charging.get("boss_slam_phase", "")) == "charging", "boss slam should stay charging before the telegraph expires")
		_expect(int(Dictionary(scene.call("build_enemy_behavior_snapshot_for_test")).get("player_health", 0)) == health_before, "early boss skill tick should not damage player")

		scene.call("tick_boss_skill_for_test", 1.0)
		var resolved: Dictionary = scene.call("build_combat_readability_snapshot_for_test")
		_expect(str(resolved.get("boss_slam_phase", "")) == "resolved", "boss slam should resolve after charge time")
		_expect(not bool(resolved.get("boss_slam_warning_visible", true)), "resolved boss slam should hide danger warning")
		_expect(int(resolved.get("boss_slam_resolve_count", 0)) >= 1, "boss slam should record a resolve count")
		_expect(int(Dictionary(scene.call("build_enemy_behavior_snapshot_for_test")).get("player_health", 0)) < health_before, "resolved boss slam should damage player inside warning")

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
		print("NEW_PROJECT_PROTOTYPE_2_5D_ENEMY_READABILITY_VFX_CONTRACT_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
