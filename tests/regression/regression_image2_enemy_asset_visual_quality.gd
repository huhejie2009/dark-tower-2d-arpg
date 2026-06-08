extends SceneTree

const FRAME_SIZE := Vector2i(128, 128)
const FRAME_COUNT := 20
const SHEETS := [
	{
		"name": "rot_melee",
		"path": "res://assets/generated/actors/enemy_rot_melee_sheet_v3.png",
		"min_opaque_width": 42,
		"min_opaque_height": 58,
	},
	{
		"name": "shadow_archer",
		"path": "res://assets/generated/actors/enemy_shadow_archer_sheet_v3.png",
		"min_opaque_width": 42,
		"min_opaque_height": 58,
	},
	{
		"name": "tower_guardian",
		"path": "res://assets/generated/actors/enemy_tower_guardian_sheet_v3.png",
		"min_opaque_width": 48,
		"min_opaque_height": 62,
	},
]

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for sheet_data in SHEETS:
		_check_sheet(Dictionary(sheet_data))
	_finish()

func _check_sheet(sheet_data: Dictionary) -> void:
	var sheet_name := str(sheet_data.get("name", "unknown"))
	var sheet_path := str(sheet_data.get("path", ""))
	var image := Image.new()
	var load_result := image.load(ProjectSettings.globalize_path(sheet_path))
	_expect(load_result == OK, "%s sheet should load from disk" % sheet_name)
	if load_result != OK:
		return
	_expect(image.get_size() == Vector2i(FRAME_SIZE.x * FRAME_COUNT, FRAME_SIZE.y), "%s sheet should be 20 horizontal 128x128 frames" % sheet_name)
	var min_width := int(sheet_data.get("min_opaque_width", 20))
	var min_height := int(sheet_data.get("min_opaque_height", 30))
	for frame_index in [0, 4, 10, 16]:
		var bounds := _get_opaque_bounds(image, frame_index)
		_expect(bounds.size.x >= min_width, "%s frame %d should have readable opaque width" % [sheet_name, frame_index])
		_expect(bounds.size.y >= min_height, "%s frame %d should have readable opaque height" % [sheet_name, frame_index])
		_expect(bounds.size.x <= FRAME_SIZE.x, "%s frame %d opaque width should fit frame" % [sheet_name, frame_index])
		_expect(bounds.size.y <= FRAME_SIZE.y, "%s frame %d opaque height should fit frame" % [sheet_name, frame_index])
		_expect(_count_green_screen_pixels(image, frame_index) == 0, "%s frame %d should not contain visible green-screen backing" % [sheet_name, frame_index])

func _get_opaque_bounds(image: Image, frame_index: int) -> Rect2i:
	var min_x := FRAME_SIZE.x
	var min_y := FRAME_SIZE.y
	var max_x := -1
	var max_y := -1
	var origin_x := frame_index * FRAME_SIZE.x
	for y in range(FRAME_SIZE.y):
		for x in range(FRAME_SIZE.x):
			var color := image.get_pixel(origin_x + x, y)
			if color.a > 0.12:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)
	if max_x < min_x or max_y < min_y:
		return Rect2i(Vector2i.ZERO, Vector2i.ZERO)
	return Rect2i(Vector2i(min_x, min_y), Vector2i(max_x - min_x + 1, max_y - min_y + 1))

func _count_green_screen_pixels(image: Image, frame_index: int) -> int:
	var count := 0
	var origin_x := frame_index * FRAME_SIZE.x
	for y in range(FRAME_SIZE.y):
		for x in range(FRAME_SIZE.x):
			var color := image.get_pixel(origin_x + x, y)
			if color.a > 0.35 and color.g > 0.46 and color.g > color.r * 1.35 and color.g > color.b * 1.35:
				count += 1
	return count

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_IMAGE2_ENEMY_ASSET_VISUAL_QUALITY_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
