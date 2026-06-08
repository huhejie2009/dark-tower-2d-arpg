extends SceneTree

const Player2DScript := preload("res://scripts/combat/Player2D.gd")
const Enemy2DScript := preload("res://scripts/combat/Enemy2D.gd")

func _initialize() -> void:
	var image := Image.create(192, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.2, 0.8, 1.0, 1.0))
	var image_path := "user://actor_animation_autoplay_test.png"
	_expect(image.save_png(image_path) == OK, "test spritesheet should be saved")

	var player := Player2DScript.new()
	player.name = "Player2D"
	root.add_child(player)
	var enemy := Enemy2DScript.new()
	enemy.name = "Enemy2D"
	root.add_child(enemy)
	await process_frame

	var manifest := {
		"asset_pipeline": "image2",
		"enabled": true,
		"hide_procedural_body": true,
		"sprite_sheet_path": image_path,
		"frame_size": Vector2i(64, 64),
		"animations": {
			"idle": {"from": 0, "to": 0, "fps": 8},
			"run": {"from": 1, "to": 2, "fps": 10},
			"attack": {"from": 0, "to": 2, "fps": 12},
		},
	}

	_assert_autoplay_and_visibility(player, manifest, "player", "PlayerBody")
	_assert_autoplay_and_visibility(enemy, manifest, "enemy", "EnemyBody")

	player.queue_free()
	enemy.queue_free()
	await process_frame
	print("NEW_PROJECT_ACTOR_ANIMATION_AUTOPLAY_AND_VISIBILITY_OK")
	quit(0)

func _assert_autoplay_and_visibility(actor: Node, manifest: Dictionary, label: String, body_name: String) -> void:
	_expect(actor.has_method("tick_actor_animation_for_test"), "%s should expose animation tick hook" % label)
	_expect(actor.has_method("apply_visual_asset_manifest_for_test"), "%s should apply visual manifests" % label)
	if not actor.has_method("apply_visual_asset_manifest_for_test"):
		return
	actor.call("apply_visual_asset_manifest_for_test", manifest)
	var body := actor.find_child(body_name, true, false) as CanvasItem
	_expect(body != null and not body.visible, "%s procedural body should hide when generated sprite is enabled" % label)
	actor.call("set_actor_animation_for_test", "run")
	var start_state: Dictionary = actor.call("get_actor_animation_state_for_test")
	_expect(int(start_state.get("frame_index", -1)) == 1, "%s run should start at frame 1" % label)
	if actor.has_method("tick_actor_animation_for_test"):
		actor.call("tick_actor_animation_for_test", 0.11)
		var advanced: Dictionary = actor.call("get_actor_animation_state_for_test")
		_expect(int(advanced.get("frame_index", -1)) == 2, "%s should auto-advance by fps over time" % label)

func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
