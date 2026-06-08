extends SceneTree

const Enemy2DScript := preload("res://scripts/combat/Enemy2D.gd")

func _initialize() -> void:
	var image := Image.create(256, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.1, 0.1, 0.1, 1.0))
	var image_path := "user://enemy_death_collision_test.png"
	_expect(image.save_png(image_path) == OK, "test spritesheet should be saved")

	var enemy := Enemy2DScript.new()
	enemy.name = "Enemy2D"
	root.add_child(enemy)
	await process_frame

	var collision := enemy.find_child("CollisionShape2D", true, false) as CollisionShape2D
	_expect(collision != null and not collision.disabled, "enemy collision should start enabled")

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
	enemy.take_damage(9999)
	await process_frame

	collision = enemy.find_child("CollisionShape2D", true, false) as CollisionShape2D
	_expect(is_instance_valid(enemy), "enemy should still exist during death animation")
	_expect(collision != null and collision.disabled, "enemy collision should disable during death animation")

	enemy.queue_free()
	await process_frame
	print("NEW_PROJECT_ENEMY_DEATH_DISABLES_COLLISION_OK")
	quit(0)

func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
