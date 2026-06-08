extends SceneTree

const FloorRulesScript := preload("res://scripts/rules/FloorRules.gd")
const Enemy2DScript := preload("res://scripts/combat/Enemy2D.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var host := Node2D.new()
	root.add_child(host)

	var target := PlayerBodyStub.new()
	host.add_child(target)

	var archer := Enemy2DScript.new()
	archer.apply_enemy_data(FloorRulesScript.get_enemy_type_data("shadow_archer", 3))
	archer.target = target
	host.add_child(archer)
	await process_frame

	_expect(archer.has_method("get_behavior_profile_for_test"), "Enemy2D should expose behavior profile")
	_expect(archer.has_method("get_behavior_state_for_test"), "Enemy2D should expose behavior state")
	_expect(archer.has_method("evaluate_behavior_intent_for_test"), "Enemy2D should expose behavior intent evaluation")
	if archer.has_method("get_behavior_profile_for_test"):
		var profile: Dictionary = Dictionary(archer.call("get_behavior_profile_for_test"))
		_expect(str(profile.get("archetype", "")) == "ranged_kiter", "archer should apply ranged behavior profile")

	archer.global_position = Vector2(60, 0)
	target.global_position = Vector2.ZERO
	if archer.has_method("evaluate_behavior_intent_for_test"):
		var close_intent: Dictionary = Dictionary(archer.call("evaluate_behavior_intent_for_test", target.global_position))
		_expect(str(close_intent.get("intent", "")) == "retreat", "archer too close should retreat")

	archer.global_position = Vector2(180, 0)
	if archer.has_method("evaluate_behavior_intent_for_test"):
		var attack_intent: Dictionary = Dictionary(archer.call("evaluate_behavior_intent_for_test", target.global_position))
		_expect(str(attack_intent.get("intent", "")) == "attack", "archer in preferred band should attack")
		_expect(float(attack_intent.get("attack_windup", 0.0)) > 0.0, "attack intent should include windup")

	var melee := Enemy2DScript.new()
	melee.apply_enemy_data(FloorRulesScript.get_enemy_type_data("rot_melee", 3))
	melee.target = target
	host.add_child(melee)
	await process_frame
	melee.global_position = Vector2(140, 0)
	if melee.has_method("evaluate_behavior_intent_for_test"):
		var melee_intent: Dictionary = Dictionary(melee.call("evaluate_behavior_intent_for_test", target.global_position))
		_expect(str(melee_intent.get("intent", "")) == "approach", "melee outside range should approach")

	host.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_ENEMY_BEHAVIOR_STATE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

class PlayerBodyStub:
	extends CharacterBody2D

	var damage_taken := 0

	func take_damage(amount: int, _attacker: Node = null) -> void:
		damage_taken += amount
