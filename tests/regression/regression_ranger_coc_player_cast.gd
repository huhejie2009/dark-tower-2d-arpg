extends SceneTree

const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")
const Player2DScript := preload("res://scripts/combat/Player2D.gd")
const Enemy2DScript := preload("res://scripts/combat/Enemy2D.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var arena := Node2D.new()
	root.add_child(arena)
	var player := Player2DScript.new()
	arena.add_child(player)
	player.global_position = Vector2.ZERO
	var data := PlayerDataServiceScript.build_starter_player("slot_1", "CoC Ranger", "ranger")
	data["critical_chance"] = 100
	player.apply_player_data(data)

	var enemy := Enemy2DScript.new()
	arena.add_child(enemy)
	enemy.global_position = Vector2(120, 0)
	enemy.apply_enemy_data({"max_health": 200, "attack_damage": 0, "move_speed": 0.0})
	await process_frame

	var result: Dictionary = player.cast_basic(Vector2.RIGHT)
	_expect(str(result.get("skill_id", "")) == "ranger_ice_shot", "ranger should cast ice shot")
	_expect(bool(result.get("critical_hit", false)), "100 crit ranger should crit")
	_expect(bool(result.get("triggered", false)), "critical ice shot should trigger ice lance")
	_expect(str(result.get("trigger_skill_id", "")) == "ice_lance", "trigger skill should be ice_lance")

	var blocked: Dictionary = player.cast_basic(Vector2.RIGHT)
	_expect(not bool(blocked.get("triggered", true)), "immediate second cast should not trigger during cooldown or attack recovery")

	arena.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_RANGER_COC_PLAYER_CAST_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
