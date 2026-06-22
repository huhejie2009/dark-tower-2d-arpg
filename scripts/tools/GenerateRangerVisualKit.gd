extends SceneTree

const OUT_PATH := "res://assets/generated/actors/player_ranger_sheet_v1.png"
const FRAME_SIZE := Vector2i(160, 160)
const FRAME_COUNT := 20

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var image := Image.create(FRAME_SIZE.x * FRAME_COUNT, FRAME_SIZE.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for frame in range(FRAME_COUNT):
		_draw_frame(image, frame)
	var absolute_path := ProjectSettings.globalize_path(OUT_PATH)
	var err := image.save_png(absolute_path)
	if err != OK:
		push_error("failed to save ranger visual kit: %s" % err)
		quit(1)
	print("GENERATED_RANGER_VISUAL_KIT %s" % OUT_PATH)
	quit(0)

func _draw_frame(image: Image, frame: int) -> void:
	var local_frame := frame
	var phase := 0.0
	var animation := "idle"
	if frame >= 4 and frame <= 9:
		animation = "run"
		local_frame = frame - 4
		phase = float(local_frame) / 6.0
	elif frame >= 10 and frame <= 15:
		animation = "attack"
		local_frame = frame - 10
		phase = float(local_frame) / 6.0
	elif frame >= 16:
		animation = "death"
		local_frame = frame - 16
		phase = float(local_frame) / 4.0
	else:
		phase = float(frame) / 4.0

	var origin := Vector2i(frame * FRAME_SIZE.x, 0)
	var hip := Vector2(76, 94)
	if animation == "run":
		hip.y += sin(phase * TAU) * 3.0
	elif animation == "attack":
		hip.x += phase * 8.0
	elif animation == "death":
		hip.y += phase * 26.0
		hip.x += phase * 12.0

	_draw_shadow(image, origin, hip)
	_draw_ranger_body(image, origin, hip, animation, phase)
	_draw_bow(image, origin, hip, animation, phase)
	_draw_ice_accents(image, origin, hip, animation, phase)

func _draw_shadow(image: Image, origin: Vector2i, hip: Vector2) -> void:
	_fill_ellipse(image, origin + Vector2i(int(hip.x - 28), 126), Vector2i(58, 12), Color(0.01, 0.015, 0.02, 0.30))

func _draw_ranger_body(image: Image, origin: Vector2i, hip: Vector2, animation: String, phase: float) -> void:
	var cloak := Color(0.06, 0.11, 0.14, 1.0)
	var armor := Color(0.12, 0.18, 0.20, 1.0)
	var trim := Color(0.18, 0.56, 0.68, 1.0)
	var skin := Color(0.62, 0.58, 0.48, 1.0)
	var head := Vector2(hip.x - 1.0, hip.y - 43.0)
	if animation == "death":
		head.y += phase * 18.0
		head.x += phase * 18.0
	var torso := Vector2(hip.x, hip.y - 20.0)
	_fill_ellipse(image, origin + Vector2i(int(torso.x - 19), int(torso.y - 22)), Vector2i(38, 45), Color(0.025, 0.05, 0.07, 0.88))
	_fill_ellipse(image, origin + Vector2i(int(torso.x - 15), int(torso.y - 18)), Vector2i(30, 39), armor)
	_fill_ellipse(image, origin + Vector2i(int(head.x - 12), int(head.y - 13)), Vector2i(24, 24), cloak)
	_fill_ellipse(image, origin + Vector2i(int(head.x - 7), int(head.y - 7)), Vector2i(14, 12), skin)
	_draw_line(image, origin + Vector2i(int(torso.x - 11), int(torso.y - 14)), origin + Vector2i(int(torso.x + 11), int(torso.y + 16)), trim, 3)

	var leg_swing := sin(phase * TAU) * 9.0 if animation == "run" else 0.0
	_draw_line(image, origin + Vector2i(int(hip.x - 7), int(hip.y)), origin + Vector2i(int(hip.x - 18 - leg_swing), 124), Color(0.08, 0.12, 0.13, 1.0), 5)
	_draw_line(image, origin + Vector2i(int(hip.x + 8), int(hip.y)), origin + Vector2i(int(hip.x + 16 + leg_swing), 124), Color(0.08, 0.12, 0.13, 1.0), 5)

func _draw_bow(image: Image, origin: Vector2i, hip: Vector2, animation: String, phase: float) -> void:
	var bow_color := Color(0.36, 0.21, 0.10, 1.0)
	var string_color := Color(0.70, 0.82, 0.82, 0.9)
	var ice := Color(0.48, 0.86, 1.0, 0.95)
	var bow_x := hip.x + 28.0
	var bow_y := hip.y - 30.0
	var draw_back := 0.0
	if animation == "attack":
		draw_back = sin(clampf(phase, 0.0, 1.0) * PI) * 20.0
		bow_x += phase * 14.0
	_draw_line(image, origin + Vector2i(int(bow_x), int(bow_y - 30)), origin + Vector2i(int(bow_x + 11), int(bow_y)), bow_color, 4)
	_draw_line(image, origin + Vector2i(int(bow_x + 11), int(bow_y)), origin + Vector2i(int(bow_x), int(bow_y + 30)), bow_color, 4)
	_draw_line(image, origin + Vector2i(int(bow_x), int(bow_y - 30)), origin + Vector2i(int(bow_x - draw_back), int(bow_y)), string_color, 1)
	_draw_line(image, origin + Vector2i(int(bow_x - draw_back), int(bow_y)), origin + Vector2i(int(bow_x), int(bow_y + 30)), string_color, 1)
	if animation == "attack":
		_draw_line(image, origin + Vector2i(int(bow_x - draw_back - 8), int(bow_y)), origin + Vector2i(int(bow_x + 52), int(bow_y)), ice, 3)
		_fill_triangle(image, origin + Vector2i(int(bow_x + 60), int(bow_y)), origin + Vector2i(int(bow_x + 48), int(bow_y - 6)), origin + Vector2i(int(bow_x + 48), int(bow_y + 6)), ice)

func _draw_ice_accents(image: Image, origin: Vector2i, hip: Vector2, animation: String, phase: float) -> void:
	var ice := Color(0.30, 0.78, 1.0, 0.82)
	_fill_ellipse(image, origin + Vector2i(int(hip.x + 8), int(hip.y - 39)), Vector2i(5, 5), ice)
	if animation == "attack":
		for i in range(4):
			_fill_ellipse(image, origin + Vector2i(int(hip.x + 54 + i * 9), int(hip.y - 31 + sin(phase * TAU + i) * 4.0)), Vector2i(4, 4), Color(0.48, 0.88, 1.0, 0.72))

func _fill_ellipse(image: Image, top_left: Vector2i, size: Vector2i, color: Color) -> void:
	var rx := maxf(1.0, float(size.x) / 2.0)
	var ry := maxf(1.0, float(size.y) / 2.0)
	var center := Vector2(float(top_left.x) + rx, float(top_left.y) + ry)
	for y in range(maxi(0, top_left.y), mini(image.get_height(), top_left.y + size.y)):
		for x in range(maxi(0, top_left.x), mini(image.get_width(), top_left.x + size.x)):
			var p := Vector2(float(x), float(y))
			if pow((p.x - center.x) / rx, 2.0) + pow((p.y - center.y) / ry, 2.0) <= 1.0:
				image.set_pixel(x, y, color)

func _draw_line(image: Image, from_point: Vector2i, to_point: Vector2i, color: Color, width: int) -> void:
	var steps := maxi(1, int(from_point.distance_to(to_point)))
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var point := Vector2(from_point).lerp(Vector2(to_point), t)
		_fill_ellipse(image, Vector2i(point.x - width, point.y - width), Vector2i(width * 2 + 1, width * 2 + 1), color)

func _fill_triangle(image: Image, a: Vector2i, b: Vector2i, c: Vector2i, color: Color) -> void:
	var min_x := maxi(0, mini(a.x, mini(b.x, c.x)))
	var max_x := mini(image.get_width() - 1, maxi(a.x, maxi(b.x, c.x)))
	var min_y := maxi(0, mini(a.y, mini(b.y, c.y)))
	var max_y := mini(image.get_height() - 1, maxi(a.y, maxi(b.y, c.y)))
	var area := _edge(a, b, c)
	if absf(float(area)) <= 0.001:
		return
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var p := Vector2i(x, y)
			var w0 := _edge(b, c, p)
			var w1 := _edge(c, a, p)
			var w2 := _edge(a, b, p)
			if (w0 >= 0 and w1 >= 0 and w2 >= 0) or (w0 <= 0 and w1 <= 0 and w2 <= 0):
				image.set_pixel(x, y, color)

func _edge(a: Vector2i, b: Vector2i, c: Vector2i) -> int:
	return (c.x - a.x) * (b.y - a.y) - (c.y - a.y) * (b.x - a.x)
