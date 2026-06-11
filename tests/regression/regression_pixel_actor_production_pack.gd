extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var pack_path := "res://docs/content/2026-06-11-pixel-actor-production-pack.md"
	var preview_path := "res://docs/concepts/pixel_actor_trial/pixel_actor_lineup_preview_v1.png"
	_expect(FileAccess.file_exists(pack_path), "pixel actor production pack should exist")
	_expect(FileAccess.file_exists(preview_path), "pixel actor lineup preview should exist")
	if FileAccess.file_exists(pack_path):
		var text := FileAccess.get_file_as_string(pack_path)
		_expect(text.contains("player_warrior_4dir_pixel_sheet_v1.png"), "pack should name the player 4dir target sheet")
		_expect(text.contains("enemy_rot_melee_4dir_pixel_sheet_v1.png"), "pack should name the rot melee 4dir target sheet")
		_expect(text.contains("enemy_shadow_archer_4dir_pixel_sheet_v1.png"), "pack should name the shadow archer 4dir target sheet")
		_expect(text.contains("\"direction_order\": [\"down\", \"left\", \"right\", \"up\"]"), "pack should define the 4dir order")
		_expect(text.contains("idle frames 0-3"), "pack should define idle frames")
		_expect(text.contains("run frames 4-9"), "pack should define run frames")
		_expect(text.contains("attack frames 10-15"), "pack should define attack frames")
		_expect(text.contains("death frames 16-19"), "pack should define death frames")
		_expect(text.contains("run must show alternating feet"), "pack should require readable footstep animation")
		_expect(text.contains("Do not include hit sparks"), "pack should keep combat VFX separate from actor frames")
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_PIXEL_ACTOR_PRODUCTION_PACK_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
