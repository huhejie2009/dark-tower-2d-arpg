extends SceneTree

const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")
const Player2DScript := preload("res://scripts/combat/Player2D.gd")
const Enemy2DScript := preload("res://scripts/combat/Enemy2D.gd")
const Game2DScript := preload("res://scripts/app/Game2D.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	await _expect_class_cast_style("warrior", "warrior_cleave", "melee_arc", "attack_trail")
	await _expect_class_cast_style("ranger", "ranger_ice_shot", "projectile", "projectile_trail")
	await _expect_class_cast_style("mage", "mage_bolt", "projectile", "projectile_trail")
	await _expect_class_cast_style("acolyte", "bone_spike", "projectile", "projectile_trail")
	_expect_game2d_default_art_scope()
	_finish()

func _expect_class_cast_style(base_class: String, skill_id: String, cast_style: String, vfx_role: String) -> void:
	var arena := Node2D.new()
	root.add_child(arena)
	var player := Player2DScript.new()
	arena.add_child(player)
	player.global_position = Vector2.ZERO
	var data := PlayerDataServiceScript.build_starter_player("slot_1", "%s Test" % base_class, base_class)
	player.apply_player_data(data)

	var enemy := Enemy2DScript.new()
	arena.add_child(enemy)
	enemy.global_position = Vector2(120, 0)
	enemy.apply_enemy_data({"max_health": 200, "attack_damage": 0, "move_speed": 0.0})
	await process_frame

	var result: Dictionary = player.cast_basic(Vector2.RIGHT)
	_expect(str(result.get("skill_id", "")) == skill_id, "%s should cast %s" % [base_class, skill_id])
	_expect(str(result.get("cast_style", "")) == cast_style, "%s should use %s cast style" % [base_class, cast_style])
	_expect(_has_vfx_role(arena, vfx_role), "%s should spawn %s VFX" % [base_class, vfx_role])

	arena.queue_free()
	await process_frame

func _expect_game2d_default_art_scope() -> void:
	var game := Game2DScript.new()
	var warrior := Player2DScript.new()
	game.set("player", warrior)
	game.set("player_data", PlayerDataServiceScript.build_starter_player("slot_1", "Warrior", "warrior"))
	game.add_child(warrior)
	warrior.call("_ready")
	game.call("_apply_default_player_art")
	_expect(bool(game.call("_is_default_player_art_loaded")), "warrior should load default warrior art")

	var ranger := Player2DScript.new()
	game.remove_child(warrior)
	game.add_child(ranger)
	ranger.call("_ready")
	game.set("player", ranger)
	game.set("player_data", PlayerDataServiceScript.build_starter_player("slot_1", "Ranger", "ranger"))
	game.call("_apply_default_player_art")
	_expect(not bool(game.call("_is_default_player_art_loaded")), "ranger should not load warrior default art")
	ranger.free()
	warrior.free()
	game.free()

func _has_vfx_role(root_node: Node, role: String) -> bool:
	for child in root_node.get_children():
		if child.has_meta("vfx_role") and str(child.get_meta("vfx_role")) == role:
			return true
	return false

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_CLASS_BASIC_SKILL_PRESENTATION_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
