extends SceneTree

const GameConstantsScript := preload("res://scripts/app/GameConstants.gd")
const SaveManagerScript := preload("res://scripts/save/SaveManager.gd")
const TowerRunStartServiceScript := preload("res://scripts/data/TowerRunStartService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := SaveManagerScript.create_character("slot_1", "2.5D Rhythm", "warrior")
	player["health"] = 180
	player["max_health"] = 180
	player["highest_floor"] = 5
	SaveManagerScript.save_active_player_data(player, 5)
	TowerRunStartServiceScript.request_start_floor(5)

	var packed := load(GameConstantsScript.ACTIVE_GAME_SCENE)
	_expect(packed is PackedScene, "active 2.5D game scene should load")
	if not packed is PackedScene:
		_finish()
		return

	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame

	_expect(scene.has_method("build_player_damage_feedback_snapshot_for_test"), "2.5D runtime should expose player damage feedback snapshot")
	_expect(scene.has_method("tick_player_feedback_for_test"), "2.5D runtime should expose deterministic player feedback tick")
	_expect(scene.has_method("tick_enemy_behavior_for_test"), "2.5D runtime should expose enemy behavior tick")
	_expect(scene.has_method("tick_boss_skill_for_test"), "2.5D runtime should expose boss skill tick")
	if not scene.has_method("build_player_damage_feedback_snapshot_for_test"):
		scene.queue_free()
		await process_frame
		_finish()
		return

	scene.call("_apply_floor_template_for_test", 5)
	await process_frame
	var boss_index := _find_enemy_index(scene.call("build_enemy_behavior_snapshot_for_test"), "tower_gatekeeper")
	_expect(boss_index >= 0, "floor 5 should expose tower gatekeeper")
	if boss_index >= 0:
		var boss_state := Dictionary(Array(Dictionary(scene.call("build_enemy_behavior_snapshot_for_test")).get("enemy_states", []))[boss_index])
		var boss_position: Vector3 = boss_state.get("position", Vector3.ZERO)
		scene.call("set_player_position_for_test", boss_position + Vector3(0.6, 0.0, 0.0))
		var start_position: Vector3 = Dictionary(scene.call("build_player_damage_feedback_snapshot_for_test")).get("player_position", Vector3.ZERO)

		scene.call("tick_enemy_behavior_for_test", 0.35)
		var auto_warning: Dictionary = scene.call("build_combat_readability_snapshot_for_test")
		_expect(str(auto_warning.get("boss_slam_phase", "")) == "charging", "boss should auto-start slam when player is in readable skill range")
		_expect(bool(auto_warning.get("boss_slam_warning_visible", false)), "auto boss slam should show warning")

		var health_before := int(Dictionary(scene.call("build_enemy_behavior_snapshot_for_test")).get("player_health", 0))
		scene.call("tick_boss_skill_for_test", 1.0)
		var feedback: Dictionary = scene.call("build_player_damage_feedback_snapshot_for_test")
		var health_after := int(Dictionary(scene.call("build_enemy_behavior_snapshot_for_test")).get("player_health", 0))
		_expect(health_after < health_before, "resolved auto boss slam should damage the player")
		_expect(bool(feedback.get("player_hurt_active", false)), "player should enter hurt feedback state after damage")
		_expect(float(feedback.get("player_invulnerability_remaining", 0.0)) > 0.0, "player should receive a short invulnerability window")
		_expect(float(feedback.get("hit_flash_remaining", 0.0)) > 0.0, "player damage should expose hit flash timing")
		_expect(Vector2(feedback.get("last_knockback_vector", Vector2.ZERO)).length() > 0.01, "player damage should record a knockback vector")
		_expect(int(feedback.get("player_damage_event_count", 0)) >= 1, "player damage should increment feedback event count")
		_expect(str(feedback.get("last_damage_source_kind", "")) == "boss_slam", "player damage should record boss slam as source kind")
		var after_hit_position: Vector3 = feedback.get("player_position", Vector3.ZERO)
		_expect(after_hit_position.distance_to(start_position) > 0.01, "player should be nudged by knockback after a readable hit")

		scene.call("force_enemy_attack_player_for_test", boss_index)
		var blocked: Dictionary = scene.call("build_player_damage_feedback_snapshot_for_test")
		var health_after_blocked := int(Dictionary(scene.call("build_enemy_behavior_snapshot_for_test")).get("player_health", 0))
		_expect(health_after_blocked == health_after, "invulnerability should block immediate follow-up damage")
		_expect(int(blocked.get("blocked_damage_event_count", 0)) >= 1, "blocked damage should be counted for QA")

		scene.call("tick_player_feedback_for_test", 1.0)
		var settled: Dictionary = scene.call("build_player_damage_feedback_snapshot_for_test")
		_expect(not bool(settled.get("player_hurt_active", true)), "hurt feedback should settle after its duration")
		_expect(float(settled.get("player_invulnerability_remaining", 1.0)) <= 0.0, "invulnerability should expire")

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
		print("NEW_PROJECT_PROTOTYPE_2_5D_COMBAT_RHYTHM_PLAYER_FEEDBACK_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
