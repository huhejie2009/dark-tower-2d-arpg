extends SceneTree

const Enemy2DScript := preload("res://scripts/combat/Enemy2D.gd")

var death_signal_count := 0

func _initialize() -> void:
	var image := Image.create(256, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.35, 0.35, 0.35, 1.0))
	var image_path := "user://enemy_death_delay_test.png"
	_expect(image.save_png(image_path) == OK, "test spritesheet should be saved")

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
			"death": {"from": 1, "to": 3, "fps": 6},
		},
	}
	enemy.call("apply_visual_asset_manifest_for_test", manifest)
	_expect(enemy.has_method("get_death_animation_duration_for_test"), "Enemy2D should expose death animation duration")
	if enemy.has_method("get_death_animation_duration_for_test"):
		var duration: float = enemy.call("get_death_animation_duration_for_test")
		_expect(duration >= 0.45, "death animation duration should be derived from frames and fps")

	enemy.died.connect(func(_enemy: Node) -> void:
		death_signal_count += 1
	)
	enemy.take_damage(9999)
	await process_frame
	_expect(death_signal_count == 1, "enemy death should still emit died signal immediately")
	_expect(bool(enemy.get("is_dead")), "enemy should be marked dead immediately")
	_expect(is_instance_valid(enemy), "enemy should remain alive long enough to show death animation")

	await create_timer(0.18).timeout
	_expect(is_instance_valid(enemy), "enemy should not free before death animation delay")
	await create_timer(0.55).timeout
	_expect(not is_instance_valid(enemy), "enemy should free after death animation delay")

	print("NEW_PROJECT_ENEMY_DEATH_ANIMATION_DELAYED_FREE_OK")
	quit(0)

func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
