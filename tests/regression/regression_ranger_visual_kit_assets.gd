extends SceneTree

const RANGER_SHEET := "res://assets/generated/actors/player_ranger_sheet_v1.png"
const FRAME_SIZE := Vector2i(160, 160)
const FRAME_COUNT := 20

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_expect(FileAccess.file_exists(RANGER_SHEET), "ranger spritesheet should exist")
	if FileAccess.file_exists(RANGER_SHEET):
		var image := Image.new()
		_expect(image.load(ProjectSettings.globalize_path(RANGER_SHEET)) == OK, "ranger spritesheet should load")
		_expect(image.get_size() == Vector2i(FRAME_SIZE.x * FRAME_COUNT, FRAME_SIZE.y), "ranger spritesheet should be 20 horizontal 160x160 frames")
		_expect(_opaque_pixels(image, 0) > 450, "idle frame should contain visible ranger body")
		_expect(_opaque_pixels(image, 10) > 450, "attack frame should contain visible ranger body")
		_expect(_bounds_width(image, 10) > _bounds_width(image, 0), "attack frame should extend bow/arrow farther than idle")
		_expect(_center_x(image, 10) > _center_x(image, 0), "attack frame should shift bow draw/release pose forward")
		_expect(_blue_pixels(image, 10) > 12, "attack frame should include ice accent pixels")
	_finish()

func _opaque_pixels(image: Image, frame: int) -> int:
	var count := 0
	var origin_x := frame * FRAME_SIZE.x
	for y in range(FRAME_SIZE.y):
		for x in range(FRAME_SIZE.x):
			if image.get_pixel(origin_x + x, y).a > 0.08:
				count += 1
	return count

func _bounds_width(image: Image, frame: int) -> int:
	var origin_x := frame * FRAME_SIZE.x
	var min_x := FRAME_SIZE.x
	var max_x := 0
	for y in range(FRAME_SIZE.y):
		for x in range(FRAME_SIZE.x):
			if image.get_pixel(origin_x + x, y).a > 0.08:
				min_x = mini(min_x, x)
				max_x = maxi(max_x, x)
	return maxi(0, max_x - min_x)

func _center_x(image: Image, frame: int) -> float:
	var origin_x := frame * FRAME_SIZE.x
	var total := 0.0
	var count := 0
	for y in range(FRAME_SIZE.y):
		for x in range(FRAME_SIZE.x):
			if image.get_pixel(origin_x + x, y).a > 0.08:
				total += float(x)
				count += 1
	return total / float(maxi(1, count))

func _blue_pixels(image: Image, frame: int) -> int:
	var count := 0
	var origin_x := frame * FRAME_SIZE.x
	for y in range(FRAME_SIZE.y):
		for x in range(FRAME_SIZE.x):
			var color := image.get_pixel(origin_x + x, y)
			if color.a > 0.08 and color.b > 0.65 and color.g > 0.45 and color.r < 0.45:
				count += 1
	return count

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_RANGER_VISUAL_KIT_ASSETS_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
