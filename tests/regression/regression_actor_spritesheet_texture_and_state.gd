extends SceneTree

const Player2DScript := preload("res://scripts/combat/Player2D.gd")
const Enemy2DScript := preload("res://scripts/combat/Enemy2D.gd")

func _initialize() -> void:
	var image := Image.create(192, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color(1.0, 0.2, 0.2, 1.0))
	var image_path := "user://actor_spritesheet_test.png"
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
		"sprite_sheet_path": image_path,
		"frame_size": Vector2i(64, 64),
		"animations": {
			"idle": {"from": 0, "to": 0, "fps": 8},
			"run": {"from": 1, "to": 1, "fps": 10},
			"attack": {"from": 2, "to": 2, "fps": 12},
		},
	}

	_assert_actor_texture_and_state(player, manifest, "player")
	_assert_actor_texture_and_state(enemy, manifest, "enemy")

	player.queue_free()
	enemy.queue_free()
	await process_frame
	print("NEW_PROJECT_ACTOR_SPRITESHEET_TEXTURE_AND_STATE_OK")
	quit(0)

func _assert_actor_texture_and_state(actor: Node, manifest: Dictionary, label: String) -> void:
	_expect(actor.has_method("apply_visual_asset_manifest_for_test"), "%s should apply visual manifests" % label)
	_expect(actor.has_method("update_actor_animation_state_for_test"), "%s should expose state animation update hook" % label)
	_expect(actor.has_method("get_actor_animation_state_for_test"), "%s should expose animation state" % label)
	if not actor.has_method("apply_visual_asset_manifest_for_test"):
		return
	actor.call("apply_visual_asset_manifest_for_test", manifest)
	var sprite := actor.find_child("ActorSprite", true, false) as Sprite2D
	_expect(sprite != null and sprite.texture != null, "%s should load spritesheet texture from manifest path" % label)
	if actor.has_method("update_actor_animation_state_for_test") and actor.has_method("get_actor_animation_state_for_test"):
		actor.call("update_actor_animation_state_for_test", Vector2.RIGHT, false)
		var run_state: Dictionary = actor.call("get_actor_animation_state_for_test")
		_expect(str(run_state.get("animation", "")) == "run", "%s should switch to run while moving" % label)
		actor.call("update_actor_animation_state_for_test", Vector2.ZERO, true)
		var attack_state: Dictionary = actor.call("get_actor_animation_state_for_test")
		_expect(str(attack_state.get("animation", "")) == "attack", "%s should switch to attack while attacking" % label)
		actor.call("update_actor_animation_state_for_test", Vector2.ZERO, false)
		var post_attack_state: Dictionary = actor.call("get_actor_animation_state_for_test")
		if label == "enemy":
			_expect(str(post_attack_state.get("animation", "")) == "attack", "enemy should keep attack animation until its one-shot playback completes")
			actor.call("tick_actor_animation_for_test", 0.10)
			actor.call("update_actor_animation_state_for_test", Vector2.ZERO, false)
		var idle_state: Dictionary = actor.call("get_actor_animation_state_for_test")
		_expect(str(idle_state.get("animation", "")) == "idle", "%s should switch to idle while still" % label)

func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
