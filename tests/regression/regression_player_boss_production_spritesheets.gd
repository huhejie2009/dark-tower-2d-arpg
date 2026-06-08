extends SceneTree

const SHEETS := [
	{
		"name": "player_warrior",
		"path": "res://assets/generated/actors/player_warrior_sheet_v3.png",
		"frame_size": Vector2i(160, 160),
		"min_width": 54,
		"min_height": 76,
	},
	{
		"name": "boss_tower_gatekeeper",
		"path": "res://assets/generated/actors/boss_tower_gatekeeper_sheet_v3.png",
		"frame_size": Vector2i(192, 192),
		"min_width": 68,
		"min_height": 92,
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
	var path := str(sheet_data.get("path", ""))
	var frame_size: Vector2i = sheet_data.get("frame_size", Vector2i.ZERO)
	var image := Image.new()
	_expect(image.load(ProjectSettings.globalize_path(path)) == OK, "%s production spritesheet should load" % sheet_name)
	if image.is_empty():
		return
	_expect(image.get_size() == Vector2i(frame_size.x * 20, frame_size.y), "%s should be 20 horizontal frames" % sheet_name)
	for frame_index in [0, 4, 10, 16]:
		var bounds := _opaque_bounds(image, frame_size, frame_index)
		_expect(bounds.size.x >= int(sheet_data.get("min_width", 40)), "%s frame %d should have production-scale readable width" % [sheet_name, frame_index])
		_expect(bounds.size.y >= int(sheet_data.get("min_height", 60)), "%s frame %d should have production-scale readable height" % [sheet_name, frame_index])
		_expect(_count_green_screen_pixels(image, frame_size, frame_index) == 0, "%s frame %d should not contain green-screen remnants" % [sheet_name, frame_index])
	_expect(_animation_pose_variation(image, frame_size, 4, 9, 8.0, 4.0), "%s run segment should move beyond static wobble" % sheet_name)
	_expect(_animation_pose_variation(image, frame_size, 10, 15, 16.0, 6.0), "%s attack segment should have clear weapon/limb extension" % sheet_name)
	_expect(_animation_pose_variation(image, frame_size, 16, 19, 12.0, 8.0), "%s death segment should visibly collapse" % sheet_name)

func _animation_pose_variation(image: Image, frame_size: Vector2i, from_frame: int, to_frame: int, min_width_delta: float, min_center_delta: float) -> bool:
	var min_width := INF
	var max_width := 0.0
	var min_center_x := INF
	var max_center_x := -INF
	var min_center_y := INF
	var max_center_y := -INF
	var valid_count := 0
	for frame in range(from_frame, to_frame + 1):
		var bounds := _opaque_bounds(image, frame_size, frame)
		if bounds.size == Vector2.ZERO:
			continue
		valid_count += 1
		min_width = minf(min_width, bounds.size.x)
		max_width = maxf(max_width, bounds.size.x)
		var center := bounds.get_center()
		min_center_x = minf(min_center_x, center.x)
		max_center_x = maxf(max_center_x, center.x)
		min_center_y = minf(min_center_y, center.y)
		max_center_y = maxf(max_center_y, center.y)
	if valid_count < 2:
		return false
	var center_delta := maxf(max_center_x - min_center_x, max_center_y - min_center_y)
	return (max_width - min_width) >= min_width_delta or center_delta >= min_center_delta

func _opaque_bounds(image: Image, frame_size: Vector2i, frame_index: int) -> Rect2:
	var origin_x := frame_index * frame_size.x
	var min_x := frame_size.x
	var min_y := frame_size.y
	var max_x := -1
	var max_y := -1
	for y in range(frame_size.y):
		for x in range(frame_size.x):
			var color := image.get_pixel(origin_x + x, y)
			if color.a <= 0.12:
				continue
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			max_y = maxi(max_y, y)
	if max_x < min_x or max_y < min_y:
		return Rect2()
	return Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x + 1, max_y - min_y + 1))

func _count_green_screen_pixels(image: Image, frame_size: Vector2i, frame_index: int) -> int:
	var count := 0
	var origin_x := frame_index * frame_size.x
	for y in range(frame_size.y):
		for x in range(frame_size.x):
			var color := image.get_pixel(origin_x + x, y)
			if color.a > 0.35 and color.g > 0.46 and color.g > color.r * 1.35 and color.g > color.b * 1.35:
				count += 1
	return count

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_PLAYER_BOSS_PRODUCTION_SPRITESHEETS_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
