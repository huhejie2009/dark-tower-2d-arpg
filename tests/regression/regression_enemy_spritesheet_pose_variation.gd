extends SceneTree

const FloorRulesScript := preload("res://scripts/rules/FloorRules.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for enemy_type in ["rot_melee", "shadow_archer", "tower_guardian"]:
		_check_enemy_sheet(enemy_type)
	_finish()

func _check_enemy_sheet(enemy_type: String) -> void:
	var data := FloorRulesScript.get_enemy_type_data(enemy_type, 1)
	var manifest: Dictionary = Dictionary(data.get("visual_asset_manifest", {}))
	_expect(str(manifest.get("pose_variation_version", "")) == "production_dark_armor_v3", "%s should use production dark armor animation sheets" % enemy_type)
	var image := Image.new()
	var path := str(manifest.get("sprite_sheet_path", ""))
	_expect(path != "", "%s should have a spritesheet path" % enemy_type)
	_expect(image.load(ProjectSettings.globalize_path(path)) == OK, "%s spritesheet should load" % enemy_type)
	var frame_size: Vector2i = manifest.get("frame_size", Vector2i.ZERO)
	_expect(frame_size == Vector2i(128, 128), "%s should use 128x128 frames" % enemy_type)
	var animations: Dictionary = Dictionary(manifest.get("animations", {}))
	_expect(_animation_pose_variation(image, frame_size, Dictionary(animations.get("idle", {})), 2.0, 2.0), "%s idle should breathe or shift across frames" % enemy_type)
	_expect(_animation_pose_variation(image, frame_size, Dictionary(animations.get("run", {})), 8.0, 4.0), "%s run should show a clear stepping silhouette, not a static wobble" % enemy_type)
	_expect(_animation_pose_variation(image, frame_size, Dictionary(animations.get("attack", {})), 14.0, 7.0), "%s attack should show a clear limb/weapon extension" % enemy_type)
	_expect(_animation_pose_variation(image, frame_size, Dictionary(animations.get("death", {})), 18.0, 10.0), "%s death should visibly collapse across frames" % enemy_type)

func _animation_pose_variation(image: Image, frame_size: Vector2i, animation: Dictionary, min_width_delta: float, min_center_delta: float) -> bool:
	if animation.is_empty():
		return false
	var from_frame := int(animation.get("from", 0))
	var to_frame := int(animation.get("to", from_frame))
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

func _opaque_bounds(image: Image, frame_size: Vector2i, frame: int) -> Rect2:
	var offset_x := frame * frame_size.x
	var min_x := frame_size.x
	var min_y := frame_size.y
	var max_x := -1
	var max_y := -1
	for y in range(frame_size.y):
		for x in range(frame_size.x):
			var color := image.get_pixel(offset_x + x, y)
			if color.a <= 0.08:
				continue
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			max_y = maxi(max_y, y)
	if max_x < min_x or max_y < min_y:
		return Rect2()
	return Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x + 1, max_y - min_y + 1))

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_ENEMY_SPRITESHEET_POSE_VARIATION_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
