extends SceneTree

const Player2DScript := preload("res://scripts/combat/Player2D.gd")
const Enemy2DScript := preload("res://scripts/combat/Enemy2D.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var host := Node2D.new()
	root.add_child(host)

	var attacker := Node2D.new()
	attacker.global_position = Vector2.ZERO
	host.add_child(attacker)

	var enemy := Enemy2DScript.new()
	enemy.global_position = Vector2(40, 0)
	host.add_child(enemy)

	var player := Player2DScript.new()
	player.global_position = Vector2(100, 0)
	host.add_child(player)
	await process_frame

	_expect(enemy.has_method("get_damage_feedback_state_for_test"), "Enemy2D should expose damage feedback state")
	_expect(enemy.has_method("tick_damage_feedback_for_test"), "Enemy2D should expose damage feedback ticking")
	enemy.take_damage(10, attacker)
	if enemy.has_method("get_damage_feedback_state_for_test"):
		var enemy_state: Dictionary = Dictionary(enemy.call("get_damage_feedback_state_for_test"))
		_expect(bool(enemy_state.get("active", false)), "enemy damage feedback should become active")
		_expect(float(enemy_state.get("stagger_remaining", 0.0)) > 0.0, "enemy should expose stagger remaining")
		_expect(float(enemy_state.get("hit_flash_remaining", 0.0)) > 0.0, "enemy should expose hit flash remaining")
		_expect(float(enemy_state.get("knockback_distance", 0.0)) > 0.0, "enemy should expose knockback distance")
		_expect(enemy.global_position.x > 40.0, "enemy should be moved away from attacker by feedback knockback")
	if enemy.has_method("tick_damage_feedback_for_test") and enemy.has_method("get_damage_feedback_state_for_test"):
		enemy.call("tick_damage_feedback_for_test", 0.5)
		var enemy_after: Dictionary = Dictionary(enemy.call("get_damage_feedback_state_for_test"))
		_expect(not bool(enemy_after.get("active", true)), "enemy feedback should expire after ticking")

	_expect(player.has_method("get_damage_feedback_state_for_test"), "Player2D should expose damage feedback state")
	player.take_damage(9, enemy)
	if player.has_method("get_damage_feedback_state_for_test"):
		var player_state: Dictionary = Dictionary(player.call("get_damage_feedback_state_for_test"))
		_expect(bool(player_state.get("active", false)), "player damage feedback should become active")
		_expect(float(player_state.get("camera_shake", 0.0)) > 0.0, "player feedback should expose camera shake")
		_expect(str(player_state.get("target_kind", "")) == "player", "player feedback should classify target kind")

	host.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_ACTOR_DAMAGE_FEEDBACK_STATE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
