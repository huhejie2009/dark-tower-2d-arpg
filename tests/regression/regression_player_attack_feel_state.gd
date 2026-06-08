extends SceneTree

const Player2DScript := preload("res://scripts/combat/Player2D.gd")
const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var host := Node2D.new()
	root.add_child(host)
	var player := Player2DScript.new()
	host.add_child(player)
	player.apply_player_data(PlayerDataServiceScript.build_starter_player("slot_1", "Test", "warrior"))
	await process_frame

	_expect(player.has_method("get_attack_feel_state_for_test"), "Player2D should expose attack feel state")
	_expect(player.has_method("get_basic_attack_feel_for_test"), "Player2D should expose current basic attack feel profile")
	if player.has_method("get_basic_attack_feel_for_test"):
		var feel: Dictionary = Dictionary(player.call("get_basic_attack_feel_for_test"))
		_expect(str(feel.get("skill_id", "")) == "warrior_cleave", "player feel profile should match basic skill")
		_expect(float(feel.get("hit_frame", 0.0)) > 0.0, "player feel profile should include hit frame")

	var result: Dictionary = player.cast_basic(Vector2.RIGHT)
	_expect(bool(result.get("accepted", true)), "first attack should be accepted")
	_expect(str(result.get("attack_phase", "")) == "windup", "accepted attack should start in windup phase")
	_expect(float(result.get("hit_frame", 0.0)) > 0.0, "attack result should include hit frame")
	if player.has_method("get_attack_feel_state_for_test"):
		var state: Dictionary = Dictionary(player.call("get_attack_feel_state_for_test"))
		_expect(str(state.get("phase", "")) == "windup", "attack state should start as windup")
		_expect(float(state.get("cooldown_remaining", 0.0)) > 0.0, "attack state should expose cooldown")

	var buffered: Dictionary = player.cast_basic(Vector2.RIGHT)
	_expect(not bool(buffered.get("accepted", true)), "second immediate attack should not execute")
	_expect(bool(buffered.get("buffered", false)), "second immediate attack should be buffered")

	if player.has_method("tick_attack_feel_for_test") and player.has_method("get_attack_feel_state_for_test"):
		player.call("tick_attack_feel_for_test", 0.12)
		var after_windup: Dictionary = Dictionary(player.call("get_attack_feel_state_for_test"))
		_expect(str(after_windup.get("phase", "")) == "active" or str(after_windup.get("phase", "")) == "recovery", "attack should progress after windup")
	else:
		_expect(false, "Player2D should expose attack feel ticking for tests")

	host.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_PLAYER_ATTACK_FEEL_STATE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
