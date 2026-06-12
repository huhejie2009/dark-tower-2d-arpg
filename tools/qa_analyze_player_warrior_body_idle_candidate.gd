extends SceneTree

const INPUT_PATH := "res://assets/generated/actors/candidates/player_warrior_body_down_idle_candidate_v1.png"
const METRICS_PATH := "res://docs/qa/pixel_actor_trial/player_warrior_body_down_idle_candidate_v1_metrics.json"
const PREVIEW_PATH := "res://docs/qa/pixel_actor_trial/player_warrior_body_down_idle_candidate_v1_baseline_preview.png"
const FRAME_COUNT := 8
const ALPHA_THRESHOLD := 16

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var image := Image.new()
	if image.load(ProjectSettings.globalize_path(INPUT_PATH)) != OK:
		push_error("Failed to load %s" % INPUT_PATH)
		quit(1)
		return
	var cell_width := int(floor(float(image.get_width()) / float(FRAME_COUNT)))
	if cell_width <= 0:
		push_error("Invalid cell width")
		quit(1)
		return
	var frame_metrics: Array[Dictionary] = []
	var global_foot_y := -1
	var min_foot_y := image.get_height()
	var max_foot_y := -1
	for frame in range(FRAME_COUNT):
		var bounds := _scan_frame_bounds(image, frame * cell_width, cell_width)
		frame_metrics.append(bounds)
		if bool(bounds.get("has_pixels", false)):
			var foot_y := int(bounds.get("max_y", 0))
			global_foot_y = maxi(global_foot_y, foot_y)
			min_foot_y = mini(min_foot_y, foot_y)
			max_foot_y = maxi(max_foot_y, foot_y)
	var foot_drift := max_foot_y - min_foot_y if max_foot_y >= 0 else 0
	var metrics := {
		"source": INPUT_PATH,
		"frame_count": FRAME_COUNT,
		"image_width": image.get_width(),
		"image_height": image.get_height(),
		"cell_width": cell_width,
		"alpha_threshold": ALPHA_THRESHOLD,
		"global_foot_y": global_foot_y,
		"min_foot_y": min_foot_y,
		"max_foot_y": max_foot_y,
		"max_foot_baseline_drift_px": foot_drift,
		"approved_for_manifest_switch": false,
		"runtime_connected": false,
		"frames": frame_metrics,
	}
	_write_json(METRICS_PATH, metrics)
	_write_preview(image, cell_width, frame_metrics, global_foot_y)
	print("PLAYER_WARRIOR_BODY_IDLE_CANDIDATE_QA_METRICS_OK")
	quit(0)

func _scan_frame_bounds(image: Image, start_x: int, cell_width: int) -> Dictionary:
	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1
	var pixel_count := 0
	var end_x := mini(start_x + cell_width, image.get_width())
	for y in range(image.get_height()):
		for x in range(start_x, end_x):
			if int(round(image.get_pixel(x, y).a * 255.0)) <= ALPHA_THRESHOLD:
				continue
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			max_y = maxi(max_y, y)
			pixel_count += 1
	if pixel_count <= 0:
		return {
			"has_pixels": false,
			"pixel_count": 0,
		}
	var local_center_x := float(min_x + max_x) * 0.5 - float(start_x)
	return {
		"has_pixels": true,
		"pixel_count": pixel_count,
		"min_x": min_x,
		"min_y": min_y,
		"max_x": max_x,
		"max_y": max_y,
		"local_center_x": local_center_x,
		"bounds_width": max_x - min_x + 1,
		"bounds_height": max_y - min_y + 1,
	}

func _write_json(path: String, metrics: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to write %s" % path)
		quit(1)
		return
	file.store_string(JSON.stringify(metrics, "\t"))
	file.close()

func _write_preview(source: Image, cell_width: int, frame_metrics: Array[Dictionary], foot_y: int) -> void:
	var preview := Image.create(source.get_width(), source.get_height(), false, Image.FORMAT_RGBA8)
	preview.fill(Color(0.02, 0.025, 0.03, 1.0))
	preview.blend_rect(source, Rect2i(Vector2i.ZERO, source.get_size()), Vector2i.ZERO)
	var grid_color := Color(0.1, 0.55, 1.0, 0.92)
	var foot_color := Color(1.0, 0.12, 0.08, 0.95)
	var bounds_color := Color(1.0, 0.72, 0.08, 0.95)
	for frame in range(FRAME_COUNT + 1):
		_draw_vline(preview, frame * cell_width, 0, preview.get_height() - 1, grid_color, 2)
	if foot_y >= 0:
		_draw_hline(preview, 0, preview.get_width() - 1, foot_y, foot_color, 3)
	for frame in range(FRAME_COUNT):
		var bounds := frame_metrics[frame]
		if not bool(bounds.get("has_pixels", false)):
			continue
		_draw_rect_outline(
			preview,
			Rect2i(
				Vector2i(int(bounds.get("min_x", 0)), int(bounds.get("min_y", 0))),
				Vector2i(int(bounds.get("bounds_width", 0)), int(bounds.get("bounds_height", 0)))
			),
			bounds_color,
			2
		)
	preview.save_png(ProjectSettings.globalize_path(PREVIEW_PATH))

func _draw_vline(image: Image, x: int, y0: int, y1: int, color: Color, width: int = 1) -> void:
	for offset in range(width):
		var draw_x := clampi(x + offset, 0, image.get_width() - 1)
		for y in range(maxi(0, y0), mini(image.get_height() - 1, y1) + 1):
			image.set_pixel(draw_x, y, color)

func _draw_hline(image: Image, x0: int, x1: int, y: int, color: Color, width: int = 1) -> void:
	for offset in range(width):
		var draw_y := clampi(y + offset, 0, image.get_height() - 1)
		for x in range(maxi(0, x0), mini(image.get_width() - 1, x1) + 1):
			image.set_pixel(x, draw_y, color)

func _draw_rect_outline(image: Image, rect: Rect2i, color: Color, width: int = 1) -> void:
	_draw_hline(image, rect.position.x, rect.position.x + rect.size.x - 1, rect.position.y, color, width)
	_draw_hline(image, rect.position.x, rect.position.x + rect.size.x - 1, rect.position.y + rect.size.y - 1, color, width)
	_draw_vline(image, rect.position.x, rect.position.y, rect.position.y + rect.size.y - 1, color, width)
	_draw_vline(image, rect.position.x + rect.size.x - 1, rect.position.y, rect.position.y + rect.size.y - 1, color, width)
