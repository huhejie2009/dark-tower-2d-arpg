extends SceneTree

const OUTPUT_PATH := "res://docs/qa/screenshots/town_playable_space_1280x720.png"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var packed := load("res://scenes/Town.tscn")
	if not (packed is PackedScene):
		push_error("Town scene failed to load.")
		quit(1)
		return
	var town: Node = packed.instantiate()
	if town is Control:
		(town as Control).set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(town)
	for _i in range(12):
		await process_frame
	RenderingServer.force_sync()
	var texture := root.get_texture()
	if texture == null:
		push_error("Town screenshot texture is null.")
		quit(1)
		return
	var image := texture.get_image()
	var absolute_path := ProjectSettings.globalize_path(OUTPUT_PATH)
	DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	var error := image.save_png(absolute_path)
	root.remove_child(town)
	town.queue_free()
	if error != OK:
		push_error("Failed to save town screenshot: %s" % error_string(error))
		quit(1)
		return
	print("TOWN_SCREENSHOT_SAVED %s" % absolute_path)
	quit(0)
