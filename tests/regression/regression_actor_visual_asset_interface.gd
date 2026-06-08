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

	_assert_actor_interface(player, "player")
	_assert_actor_interface(enemy, "enemy")

	player.queue_free()
	enemy.queue_free()
	await process_frame
	print("NEW_PROJECT_ACTOR_VISUAL_ASSET_INTERFACE_OK")
	quit(0)

func _assert_actor_interface(actor: Node, label: String) -> void:
	_expect(actor.find_child("ActorVisualRoot", true, false) != null, "%s should have an actor visual root for generated assets" % label)
	_expect(actor.find_child("ActorSprite", true, false) is Sprite2D, "%s should have a Sprite2D slot for generated sheets" % label)
	_expect(actor.has_method("apply_visual_asset_manifest_for_test"), "%s should expose visual asset manifest apply hook" % label)
	_expect(actor.has_method("get_visual_asset_manifest_for_test"), "%s should expose visual asset manifest read hook" % label)
	if actor.has_method("apply_visual_asset_manifest_for_test") and actor.has_method("get_visual_asset_manifest_for_test"):
		var manifest := {
			"asset_pipeline": "image2",
			"sprite_sheet_path": "res://assets/generated/actors/%s_sheet.png" % label,
			"frame_size": Vector2i(64, 64),
			"animations": {
				"idle": {"from": 0, "to": 3, "fps": 8},
				"run": {"from": 4, "to": 9, "fps": 10},
				"attack": {"from": 10, "to": 15, "fps": 12},
			},
		}
		actor.call("apply_visual_asset_manifest_for_test", manifest)
		var stored: Dictionary = actor.call("get_visual_asset_manifest_for_test")
		_expect(str(stored.get("asset_pipeline", "")) == "image2", "%s should preserve image2 pipeline tag" % label)
		_expect(str(stored.get("sprite_sheet_path", "")).contains("%s_sheet.png" % label), "%s should preserve sprite sheet path" % label)
		_expect(Dictionary(stored.get("animations", {})).has("idle"), "%s should preserve animation declarations" % label)

func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
