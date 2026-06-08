extends SceneTree

const Player2DScript := preload("res://scripts/combat/Player2D.gd")
const Enemy2DScript := preload("res://scripts/combat/Enemy2D.gd")

func _initialize() -> void:
	var player := Player2DScript.new()
	player.name = "Player2D"
	root.add_child(player)
	var enemy := Enemy2DScript.new()
	enemy.name = "Enemy2D"
	root.add_child(enemy)
	await process_frame

	_assert_spritesheet_contract(player, "player")
	_assert_spritesheet_contract(enemy, "enemy")

	player.queue_free()
	enemy.queue_free()
	await process_frame
	print("NEW_PROJECT_ACTOR_SPRITESHEET_ANIMATION_CONTRACT_OK")
	quit(0)

func _assert_spritesheet_contract(actor: Node, label: String) -> void:
	_expect(actor.has_method("set_actor_animation_for_test"), "%s should expose animation switch hook" % label)
	_expect(actor.has_method("advance_actor_animation_for_test"), "%s should expose animation advance hook" % label)
	_expect(actor.has_method("get_actor_animation_state_for_test"), "%s should expose animation state hook" % label)
	if not actor.has_method("apply_visual_asset_manifest_for_test"):
		return
	var manifest := {
		"asset_pipeline": "image2",
		"enabled": true,
		"sprite_sheet_path": "res://assets/generated/actors/%s_sheet.png" % label,
		"frame_size": Vector2i(64, 64),
		"animations": {
			"idle": {"from": 0, "to": 3, "fps": 8},
			"run": {"from": 4, "to": 9, "fps": 10},
			"attack": {"from": 10, "to": 15, "fps": 12},
		},
	}
	actor.call("apply_visual_asset_manifest_for_test", manifest)
	if actor.has_method("set_actor_animation_for_test") and actor.has_method("get_actor_animation_state_for_test"):
		actor.call("set_actor_animation_for_test", "run")
		var state: Dictionary = actor.call("get_actor_animation_state_for_test")
		_expect(str(state.get("animation", "")) == "run", "%s should switch to requested animation" % label)
		_expect(int(state.get("frame_index", -1)) == 4, "%s should start animation at manifest from frame" % label)
		_expect(state.get("frame_size", Vector2i.ZERO) == Vector2i(64, 64), "%s should preserve frame size" % label)
	if actor.has_method("advance_actor_animation_for_test") and actor.has_method("get_actor_animation_state_for_test"):
		actor.call("advance_actor_animation_for_test")
		var advanced: Dictionary = actor.call("get_actor_animation_state_for_test")
		_expect(int(advanced.get("frame_index", -1)) == 5, "%s should advance to the next spritesheet frame" % label)

func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
