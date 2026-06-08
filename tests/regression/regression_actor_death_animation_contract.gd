extends SceneTree

const Player2DScript := preload("res://scripts/combat/Player2D.gd")
const Enemy2DScript := preload("res://scripts/combat/Enemy2D.gd")

func _initialize() -> void:
	var image := Image.create(256, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.65, 0.25, 0.95, 1.0))
	var image_path := "user://actor_death_animation_test.png"
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
			"death": {"from": 3, "to": 3, "fps": 6},
		},
	}

	_assert_death_animation(player, manifest, "player")
	_assert_death_animation(enemy, manifest, "enemy")

	player.queue_free()
	enemy.queue_free()
	await process_frame
	print("NEW_PROJECT_ACTOR_DEATH_ANIMATION_CONTRACT_OK")
	quit(0)

func _assert_death_animation(actor: Node, manifest: Dictionary, label: String) -> void:
	_expect(actor.has_method("apply_visual_asset_manifest_for_test"), "%s should apply visual manifests" % label)
	_expect(actor.has_method("get_actor_animation_state_for_test"), "%s should expose animation state" % label)
	if not actor.has_method("apply_visual_asset_manifest_for_test"):
		return
	actor.call("apply_visual_asset_manifest_for_test", manifest)
	if actor.has_method("take_damage"):
		actor.call("take_damage", 9999)
	var state: Dictionary = actor.call("get_actor_animation_state_for_test")
	_expect(str(state.get("animation", "")) == "death", "%s should switch to death animation on lethal damage" % label)
	_expect(int(state.get("frame_index", -1)) == 3, "%s death animation should start at manifest death frame" % label)
	_expect(bool(state.get("death_animation_triggered", false)), "%s should mark death animation as triggered" % label)

func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
