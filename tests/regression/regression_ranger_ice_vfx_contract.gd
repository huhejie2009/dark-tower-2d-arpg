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
	var data := PlayerDataServiceScript.build_starter_player("slot_1", "Visual Ranger", "ranger")
	data["critical_chance"] = 100
	player.apply_player_data(data)

	var enemy := Enemy2DScript.new()
	arena.add_child(enemy)
	enemy.global_position = Vector2(120, 0)
	enemy.apply_enemy_data({"max_health": 300, "attack_damage": 0, "move_speed": 0.0})
	await process_frame

	var result: Dictionary = player.cast_basic(Vector2.RIGHT)
	_expect(str(result.get("skill_id", "")) == "ranger_ice_shot", "ranger should cast ice shot")
	_expect(bool(result.get("triggered", false)), "100 crit ranger should trigger ice lance")
	_expect(_has_vfx_role(arena, "ice_arrow_trail"), "ice shot should spawn ice arrow trail")
	_expect(_has_vfx_role(arena, "ice_lance_trail"), "triggered ice lance should spawn ice lance trail")
	_expect(_has_vfx_role(arena, "coc_trigger_flash"), "CoC trigger should spawn trigger flash")
	_expect(_role_line_width(arena, "ice_lance_trail") < _role_line_width(arena, "ice_arrow_trail"), "ice lance should be visually thinner than ice arrow")

	arena.queue_free()
	await process_frame
	_finish()

func _has_vfx_role(root_node: Node, role: String) -> bool:
	for child in root_node.get_children():
		if child.has_meta("vfx_role") and str(child.get_meta("vfx_role")) == role:
			return true
	return false

func _role_line_width(root_node: Node, role: String) -> float:
	for child in root_node.get_children():
		if child.has_meta("vfx_role") and str(child.get_meta("vfx_role")) == role:
			var line := child.find_child("*Line", true, false) as Line2D
			if line != null:
				return line.width
	return 999.0

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_RANGER_ICE_VFX_CONTRACT_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
