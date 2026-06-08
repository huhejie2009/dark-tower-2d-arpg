extends SceneTree

const Game2DScene := preload("res://scenes/Game2D.tscn")

func _initialize() -> void:
	var scene := Game2DScene.instantiate()
	root.add_child(scene)
	await process_frame

	_expect(scene.has_method("_get_visual_style_for_test"), "Game2D should expose top-down visual style contract")
	if scene.has_method("_get_visual_style_for_test"):
		var style: Dictionary = scene.call("_get_visual_style_for_test")
		_expect(str(style.get("room_visual_mode", "")) == "topdown_production", "room visual mode should be topdown_production")
		_expect(style.get("camera_zoom", Vector2.ZERO) is Vector2, "camera zoom should be a Vector2")
		_expect(Vector2(style.get("camera_zoom", Vector2.ZERO)) == Vector2(1.0, 1.0), "top-down production view should use neutral camera zoom")
		_expect(style.get("logic_room_rect", Rect2()) is Rect2, "style should keep the logical room rect visible for tests")
		_expect(float(style.get("visual_vertical_compress", 0.0)) == 1.0, "top-down production view should not compress depth")
		_expect(int(style.get("elevated_layer_count", 0)) >= 3, "top-down view should expose back/front occlusion layers")
		_expect(bool(style.get("uses_foot_anchor_sorting", false)), "top-down view should sort by foot anchors")

	_expect(scene.find_child("TopDownFloor", true, false) != null, "Game2D should create top-down floor visual root")
	_expect(scene.find_child("TopDownTileGrid", true, false) != null, "Game2D should create orthogonal top-down tile grid")
	_expect(scene.find_child("TopDownBackWallLayer", true, false) != null, "Game2D should create back wall layer")
	_expect(scene.find_child("TopDownUpperOccluderLayer", true, false) != null, "Game2D should create upper occluder layer")
	_expect(scene.find_child("TopDownForegroundOccluderLayer", true, false) != null, "Game2D should create foreground occluder layer")

	var player := scene.find_child("Player2D", true, false)
	_expect(player != null, "player should exist")
	if player != null:
		_expect(player.find_child("PlayerShadow", true, false) != null, "Player2D should create a foot shadow")
		_expect(player.find_child("PlayerFacingHint", true, false) != null, "Player2D should create a facing hint")

	var enemy := scene.find_child("Enemy2D", true, false)
	_expect(enemy != null, "enemy should exist")
	if enemy != null:
		_expect(enemy.find_child("EnemyShadow", true, false) != null, "Enemy2D should create a foot shadow")

	scene.queue_free()
	await process_frame
	print("NEW_PROJECT_TOPDOWN_VISUAL_CONTRACT_OK")
	quit(0)

func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
