extends Node2D

const Player2DScript := preload("res://scripts/combat/Player2D.gd")
const Enemy2DScript := preload("res://scripts/combat/Enemy2D.gd")
const DropItem2DScript := preload("res://scripts/combat/DropItem2D.gd")
const HudControllerScript := preload("res://scripts/ui/HudController.gd")
const SaveManagerScript := preload("res://scripts/save/SaveManager.gd")
const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")
const InventoryDataServiceScript := preload("res://scripts/data/InventoryDataService.gd")
const DeathSettlementServiceScript := preload("res://scripts/data/DeathSettlementService.gd")
const LootNotificationServiceScript := preload("res://scripts/data/LootNotificationService.gd")
const LootRulesScript := preload("res://scripts/rules/LootRules.gd")
const FloorRulesScript := preload("res://scripts/rules/FloorRules.gd")
const TowerProgressServiceScript := preload("res://scripts/data/TowerProgressService.gd")
const TowerRunStartServiceScript := preload("res://scripts/data/TowerRunStartService.gd")
const SceneRouterScript := preload("res://scripts/app/SceneRouter.gd")
const InventoryEquipmentWindowScript := preload("res://scripts/ui/InventoryEquipmentWindow.gd")
const P2LootLoopMetricsRecorderScript := preload("res://scripts/data/P2LootLoopMetricsRecorder.gd")
const DarkArpgUiThemeScript := preload("res://scripts/ui/DarkArpgUiTheme.gd")

const ROOM_VISUAL_MODE := "topdown_production"
const ENVIRONMENT_FAMILY := "brutalist_tower_interior"
const WORLD_ART_ANCHOR := "cold_megastructure_dark_core"
const FORBIDDEN_STYLE := "mhxy_ornate_palace"
const PSEUDO_34_CAMERA_ZOOM := Vector2(1.0, 1.0)
const PSEUDO_34_SKEW := 0.0
const PSEUDO_34_VERTICAL_COMPRESS := 1.0
const DEFAULT_DEATH_PRESENTATION_DELAY := 0.35
const DEATH_SETTLEMENT_PANEL_SIZE := Vector2(560, 500)
const DEATH_SETTLEMENT_SECTION_MIN_HEIGHT := 64
const IMAGE2_ENVIRONMENT_BACKGROUND_PATH := "res://assets/generated/environments/tower_interior_brutalist_room_v1.png"
const DEFAULT_PLAYER_IMAGE2_SPRITE_PATH := "res://assets/generated/actors/player_warrior_sheet_v3.png"

var player_data: Dictionary = {}
var player: CharacterBody2D
var hud: CanvasLayer
var inventory_window: Control
var pause_overlay: CanvasLayer
var pause_resume_button: Button
var death_overlay: CanvasLayer
var death_summary_label: Label
var death_floor_section: Label
var death_kills_section: Label
var death_loot_section: Label
var death_boss_reward_section: Label
var death_return_town_button: Button
var arena_root: Node2D
var pseudo_34_door_count: int = 0
var pseudo_34_wall_count: int = 0
var pseudo_34_solid_obstacle_count: int = 0
var tower_boundary_body_count: int = 0
var topdown_visual_only_obstacle_count: int = 0
var tower_interior_layer_count: int = 0
var image2_environment_background: Sprite2D
var image2_environment_background_loaded: bool = false
var solid_spawn_blockers: Array[Rect2] = []
var active_exit_door_position := Vector2.ZERO
var south_exit_door: Polygon2D
var safe_spawn_directions: Array[Vector2] = [
	Vector2.RIGHT,
	Vector2.LEFT,
	Vector2.UP,
	Vector2.DOWN,
	Vector2(1, 1).normalized(),
	Vector2(-1, 1).normalized(),
	Vector2(1, -1).normalized(),
	Vector2(-1, -1).normalized(),
]
var current_floor: int = 1
var current_floor_template: Dictionary = {}
var enemies_alive: int = 0
var kill_index: int = 0
var floor_kill_count: int = 0
var floor_pickup_names: Array[String] = []
var last_floor_rewards: Dictionary = {}
var last_loot_notification: Dictionary = {}
var portal_available: bool = false
var portal: Area2D
var room_rect := Rect2(Vector2(-620, -340), Vector2(1240, 680))
var save_scheduled: bool = false
var transition_locked: bool = false
var floor_transition_locked: bool = false
var death_settlement_active: bool = false
var death_presentation_pending: bool = false
var death_presentation_delay_override := -1.0
var p2_loot_loop_metrics: Dictionary = P2LootLoopMetricsRecorderScript.create_metrics()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_input_actions()
	player_data = SaveManagerScript.get_active_player_data()
	current_floor = TowerRunStartServiceScript.consume_start_floor(player_data)
	_create_arena()
	_spawn_player()
	_spawn_wave()
	_create_hud()
	_create_inventory_window()
	_create_pause_overlay()
	_create_death_overlay()
	_update_hud("Entered floor %d. Left click attacks, I opens inventory, Esc pauses." % current_floor)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if is_instance_valid(player) and not _is_menu_blocking_combat():
			var result: Dictionary = player.cast_basic(_get_attack_direction())
			_update_hud("Basic attack hit %d target(s)." % int(result.get("hit_count", 0)))
			get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_handle_cancel()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_I or event.keycode == KEY_C:
			_toggle_inventory_window()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_E and portal_available and not _is_menu_blocking_combat():
			_enter_next_floor()

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(player) or _is_menu_blocking_combat():
		return
	p2_loot_loop_metrics = P2LootLoopMetricsRecorderScript.add_elapsed_seconds(p2_loot_loop_metrics, _delta)
	player.set_move_vector(_get_move_vector())
	player.face_world_position(get_global_mouse_position())
	player.global_position = player.global_position.clamp(room_rect.position + Vector2(24, 24), room_rect.end - Vector2(24, 24))
	_update_foot_anchor_z_sort()

func _ensure_input_actions() -> void:
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("move_forward", [KEY_W, KEY_UP])
	_add_key_action("move_back", [KEY_S, KEY_DOWN])

func _add_key_action(action_name: String, keys: Array[int]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for keycode in keys:
		var has_key := false
		for existing in InputMap.action_get_events(action_name):
			if existing is InputEventKey and existing.keycode == keycode:
				has_key = true
				break
		if has_key:
			continue
		var event := InputEventKey.new()
		event.keycode = keycode
		InputMap.action_add_event(action_name, event)

func _create_arena() -> void:
	arena_root = Node2D.new()
	arena_root.name = "ArenaRoot"
	add_child(arena_root)
	_create_pseudo_34_floor()

func _create_pseudo_34_floor() -> void:
	solid_spawn_blockers = []
	pseudo_34_door_count = 0
	pseudo_34_wall_count = 0
	pseudo_34_solid_obstacle_count = 0
	tower_boundary_body_count = 0
	topdown_visual_only_obstacle_count = 0
	tower_interior_layer_count = 0
	image2_environment_background_loaded = false
	var floor_root := Node2D.new()
	floor_root.name = "TopDownFloor"
	floor_root.z_index = -50
	arena_root.add_child(floor_root)
	_create_image2_environment_background(floor_root)

	var points := _get_pseudo_34_room_points()
	var floor := Polygon2D.new()
	floor.name = "DungeonFloor"
	floor.polygon = points
	floor.color = Color(0.10, 0.13, 0.15, 0.12 if image2_environment_background_loaded else 1.0)
	floor_root.add_child(floor)

	var grid := Node2D.new()
	grid.name = "TopDownTileGrid"
	floor_root.add_child(grid)
	_add_pseudo_34_tile_grid(grid)

	var border := Line2D.new()
	border.name = "TopDownRoomBorder"
	border.width = 5.0
	border.closed = true
	border.default_color = Color(0.36, 0.50, 0.58, 0.14 if image2_environment_background_loaded else 1.0)
	border.points = points
	floor_root.add_child(border)

	_add_tower_interior_layers(floor_root)
	_add_pseudo_34_walls_and_doors(floor_root)
	_add_pseudo_34_obstacle(floor_root, Vector2(-360, -170), Vector2(190, 54))
	_add_pseudo_34_obstacle(floor_root, Vector2(360, -170), Vector2(190, 54))
	_add_pseudo_34_obstacle(floor_root, Vector2(-510, 118), Vector2(150, 122))
	_add_pseudo_34_obstacle(floor_root, Vector2(510, 118), Vector2(150, 122))

func _create_image2_environment_background(parent: Node) -> void:
	image2_environment_background = Sprite2D.new()
	image2_environment_background.name = "IMAGE2EnvironmentBackground"
	image2_environment_background.z_index = -90
	parent.add_child(image2_environment_background)
	var image := Image.new()
	var image_path := ProjectSettings.globalize_path(IMAGE2_ENVIRONMENT_BACKGROUND_PATH)
	if image.load(image_path) != OK:
		return
	var texture := ImageTexture.create_from_image(image)
	image2_environment_background.texture = texture
	image2_environment_background.centered = true
	image2_environment_background.global_position = room_rect.get_center()
	var target_width := room_rect.size.x + 260.0
	var target_height := room_rect.size.y + 170.0
	var texture_size := texture.get_size()
	if texture_size.x > 0.0 and texture_size.y > 0.0:
		var scale_factor: float = maxf(target_width / texture_size.x, target_height / texture_size.y)
		image2_environment_background.scale = Vector2.ONE * scale_factor
	image2_environment_background_loaded = true

func _get_pseudo_34_room_points() -> PackedVector2Array:
	var top_left := room_rect.position
	var top_right := Vector2(room_rect.end.x, room_rect.position.y)
	var bottom_right := room_rect.end
	var bottom_left := Vector2(room_rect.position.x, room_rect.end.y)
	return PackedVector2Array([top_left, top_right, bottom_right, bottom_left])

func _add_pseudo_34_tile_grid(grid: Node2D) -> void:
	var tile_size := 64.0
	var grid_color := Color(0.62, 0.72, 0.76, 0.035 if image2_environment_background_loaded else 0.18)
	var y_mid := room_rect.get_center().y
	var x := room_rect.position.x + tile_size
	while x < room_rect.end.x:
		var line := Line2D.new()
		line.width = 1.0
		line.default_color = grid_color
		line.points = PackedVector2Array([
			_pseudo_34_visual_point(Vector2(x, room_rect.position.y)),
			_pseudo_34_visual_point(Vector2(x, room_rect.end.y)),
		])
		grid.add_child(line)
		x += tile_size
	var y := room_rect.position.y + tile_size
	while y < room_rect.end.y:
		var line := Line2D.new()
		line.width = 1.0
		line.default_color = grid_color
		line.points = PackedVector2Array([
			_pseudo_34_visual_point(Vector2(room_rect.position.x, y)),
			_pseudo_34_visual_point(Vector2(room_rect.end.x, y)),
		])
		grid.add_child(line)
		y += tile_size

func _pseudo_34_visual_point(point: Vector2) -> Vector2:
	var y_mid := room_rect.get_center().y
	var compressed_y := y_mid + (point.y - y_mid) * PSEUDO_34_VERTICAL_COMPRESS
	var skew_factor := inverse_lerp(room_rect.position.y, room_rect.end.y, point.y) - 0.5
	return Vector2(point.x - skew_factor * PSEUDO_34_SKEW, compressed_y)

func _add_pseudo_34_obstacle(parent: Node, position: Vector2, size: Vector2) -> void:
	var visual_height := maxf(58.0, size.y * 1.95)
	var footprint_size := Vector2(maxf(42.0, size.x * 0.34), maxf(24.0, size.y * 0.48))
	var column := Node2D.new()
	column.name = "TopDownColumnVisual"
	column.global_position = position
	column.z_index = int(round(position.y))
	parent.add_child(column)

	var shadow := Polygon2D.new()
	shadow.name = "TopDownColumnShadow"
	shadow.z_index = -1
	shadow.polygon = PackedVector2Array([
		Vector2(-footprint_size.x * 0.65, -footprint_size.y * 0.15),
		Vector2(footprint_size.x * 0.65, -footprint_size.y * 0.15),
		Vector2(footprint_size.x * 0.76, footprint_size.y * 0.35),
		Vector2(-footprint_size.x * 0.76, footprint_size.y * 0.35),
	])
	shadow.color = Color(0.0, 0.0, 0.0, 0.24)
	column.add_child(shadow)

	var shaft := Polygon2D.new()
	shaft.name = "TopDownColumnShaft"
	shaft.polygon = PackedVector2Array([
		Vector2(-footprint_size.x * 0.45, -visual_height),
		Vector2(footprint_size.x * 0.45, -visual_height),
		Vector2(footprint_size.x * 0.58, 0.0),
		Vector2(-footprint_size.x * 0.58, 0.0),
	])
	shaft.color = Color(0.23, 0.27, 0.29, 0.10 if image2_environment_background_loaded else 1.0)
	column.add_child(shaft)

	var base := Polygon2D.new()
	base.name = "TopDownColumnFootprintVisual"
	base.polygon = PackedVector2Array([
		Vector2(-footprint_size.x * 0.5, -footprint_size.y * 0.5),
		Vector2(footprint_size.x * 0.5, -footprint_size.y * 0.5),
		Vector2(footprint_size.x * 0.5, footprint_size.y * 0.5),
		Vector2(-footprint_size.x * 0.5, footprint_size.y * 0.5),
	])
	base.color = Color(0.16, 0.20, 0.22, 0.12 if image2_environment_background_loaded else 1.0)
	column.add_child(base)

	var body := StaticBody2D.new()
	body.name = "TopDownColumnFootprintBody"
	body.global_position = position + Vector2(0.0, footprint_size.y * 0.12)
	arena_root.add_child(body)
	var shape := RectangleShape2D.new()
	shape.size = footprint_size
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	collision.shape = shape
	body.add_child(collision)
	solid_spawn_blockers.append(Rect2(body.global_position - footprint_size * 0.5, footprint_size))
	pseudo_34_solid_obstacle_count += 1
	topdown_visual_only_obstacle_count += 1

func _add_tower_interior_layers(parent: Node) -> void:
	var back_layer := Node2D.new()
	back_layer.name = "TopDownBackWallLayer"
	back_layer.z_index = -42
	parent.add_child(back_layer)
	var back_wall := Polygon2D.new()
	back_wall.name = "TopDownBackWallVisual"
	back_wall.polygon = PackedVector2Array([
		Vector2(room_rect.position.x + 64.0, room_rect.position.y - 96.0),
		Vector2(room_rect.end.x - 64.0, room_rect.position.y - 96.0),
		Vector2(room_rect.end.x - 64.0, room_rect.position.y + 62.0),
		Vector2(room_rect.position.x + 64.0, room_rect.position.y + 62.0),
	])
	back_wall.color = Color(0.14, 0.18, 0.20, 0.12 if image2_environment_background_loaded else 1.0)
	back_layer.add_child(back_wall)
	_add_tower_light_channel(back_layer, Vector2(-340, -305), "TopDownSideLightChannel")
	_add_tower_light_channel(back_layer, Vector2(340, -305), "TopDownSideLightChannel")
	_add_tower_dark_core(back_layer)
	tower_interior_layer_count += 1

	var roof_layer := Node2D.new()
	roof_layer.name = "TopDownUpperOccluderLayer"
	roof_layer.z_index = -40
	parent.add_child(roof_layer)
	var roof := Polygon2D.new()
	roof.name = "TopDownUpperConcreteLip"
	roof.polygon = PackedVector2Array([
		Vector2(room_rect.position.x - 30.0, room_rect.position.y - 116.0),
		Vector2(room_rect.end.x + 30.0, room_rect.position.y - 116.0),
		Vector2(room_rect.end.x + 30.0, room_rect.position.y - 62.0),
		Vector2(room_rect.position.x - 30.0, room_rect.position.y - 62.0),
	])
	roof.color = Color(0.07, 0.09, 0.11, 0.12 if image2_environment_background_loaded else 1.0)
	roof_layer.add_child(roof)
	tower_interior_layer_count += 1

	var front_layer := Node2D.new()
	front_layer.name = "TopDownForegroundOccluderLayer"
	front_layer.z_index = 35
	parent.add_child(front_layer)
	var railing := Polygon2D.new()
	railing.name = "TopDownForegroundConcreteEdge"
	railing.polygon = PackedVector2Array([
		Vector2(room_rect.position.x + 70.0, room_rect.end.y - 26.0),
		Vector2(room_rect.end.x - 70.0, room_rect.end.y - 26.0),
		Vector2(room_rect.end.x - 30.0, room_rect.end.y + 62.0),
		Vector2(room_rect.position.x + 30.0, room_rect.end.y + 62.0),
	])
	railing.color = Color(0.08, 0.10, 0.12, 0.10 if image2_environment_background_loaded else 0.96)
	front_layer.add_child(railing)
	tower_interior_layer_count += 1

func _add_tower_light_channel(parent: Node, position: Vector2, channel_name: String) -> void:
	var window := Polygon2D.new()
	window.name = channel_name
	window.polygon = PackedVector2Array([
		position + Vector2(-24, -42),
		position + Vector2(24, -42),
		position + Vector2(24, 42),
		position + Vector2(-24, 42),
	])
	window.color = Color(0.04, 0.17, 0.24, 0.16 if image2_environment_background_loaded else 0.82)
	parent.add_child(window)

func _add_tower_dark_core(parent: Node) -> void:
	var core := Polygon2D.new()
	core.name = "TopDownDarkCoreLightChannel"
	var center_x := room_rect.get_center().x
	core.polygon = PackedVector2Array([
		Vector2(center_x - 34.0, room_rect.position.y - 104.0),
		Vector2(center_x + 34.0, room_rect.position.y - 104.0),
		Vector2(center_x + 18.0, room_rect.position.y + 146.0),
		Vector2(center_x - 18.0, room_rect.position.y + 146.0),
	])
	core.color = Color(0.02, 0.12, 0.18, 0.20 if image2_environment_background_loaded else 0.94)
	parent.add_child(core)

	var glow := Polygon2D.new()
	glow.name = "TopDownDarkCoreGlow"
	glow.polygon = PackedVector2Array([
		Vector2(center_x - 88.0, room_rect.position.y - 104.0),
		Vector2(center_x + 88.0, room_rect.position.y - 104.0),
		Vector2(center_x + 46.0, room_rect.position.y + 172.0),
		Vector2(center_x - 46.0, room_rect.position.y + 172.0),
	])
	glow.color = Color(0.05, 0.36, 0.50, 0.06 if image2_environment_background_loaded else 0.30)
	parent.add_child(glow)

func _is_position_blocked(position: Vector2, radius: float = 24.0) -> bool:
	for blocker in solid_spawn_blockers:
		var expanded := Rect2(blocker.position - Vector2.ONE * radius, blocker.size + Vector2.ONE * radius * 2.0)
		if expanded.has_point(position):
			return true
	return false

func _find_safe_spawn_position(position: Vector2, radius: float = 24.0) -> Vector2:
	var clamped := position.clamp(room_rect.position + Vector2.ONE * radius, room_rect.end - Vector2.ONE * radius)
	if not _is_position_blocked(clamped, radius):
		return clamped
	for distance in [48.0, 80.0, 120.0, 168.0, 224.0, 288.0]:
		for direction in safe_spawn_directions:
			var candidate: Vector2 = (clamped + direction * distance).clamp(room_rect.position + Vector2.ONE * radius, room_rect.end - Vector2.ONE * radius)
			if not _is_position_blocked(candidate, radius):
				return candidate
	return room_rect.get_center()

func _is_position_blocked_for_test(position: Vector2, radius: float = 24.0) -> bool:
	return _is_position_blocked(position, radius)

func _find_safe_spawn_position_for_test(position: Vector2, radius: float = 24.0) -> Vector2:
	return _find_safe_spawn_position(position, radius)

func _update_foot_anchor_z_sort() -> void:
	if is_instance_valid(player):
		player.z_index = int(round(player.global_position.y))
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var enemy_node := enemy as Node2D
		if is_instance_valid(enemy_node):
			enemy_node.z_index = int(round(enemy_node.global_position.y))
	for drop in get_tree().get_nodes_in_group("drops"):
		var drop_node := drop as Node2D
		if is_instance_valid(drop_node):
			drop_node.z_index = int(round(drop_node.global_position.y))

func _add_pseudo_34_walls_and_doors(parent: Node) -> void:
	var thickness := 42.0
	_add_pseudo_34_wall(parent, "TopDownNorthWall", Vector2(room_rect.get_center().x, room_rect.position.y - thickness * 0.5), Vector2(room_rect.size.x - 220.0, thickness))
	_add_pseudo_34_wall(parent, "TopDownSouthWall", Vector2(room_rect.get_center().x, room_rect.end.y + thickness * 0.5), Vector2(room_rect.size.x - 250.0, thickness))
	_add_pseudo_34_wall(parent, "TopDownWestWall", Vector2(room_rect.position.x - thickness * 0.5, room_rect.get_center().y), Vector2(thickness, room_rect.size.y - 150.0))
	_add_pseudo_34_wall(parent, "TopDownEastWall", Vector2(room_rect.end.x + thickness * 0.5, room_rect.get_center().y), Vector2(thickness, room_rect.size.y - 150.0))
	_add_room_boundary_body("TopDownNorthWallBody", Vector2(room_rect.get_center().x, room_rect.position.y - thickness * 0.5), Vector2(room_rect.size.x - 220.0, thickness))
	_add_room_boundary_body("TopDownSouthWallBody", Vector2(room_rect.get_center().x, room_rect.end.y + thickness * 0.5), Vector2(room_rect.size.x - 250.0, thickness))
	_add_room_boundary_body("TopDownWestWallBody", Vector2(room_rect.position.x - thickness * 0.5, room_rect.get_center().y), Vector2(thickness, room_rect.size.y - 150.0))
	_add_room_boundary_body("TopDownEastWallBody", Vector2(room_rect.end.x + thickness * 0.5, room_rect.get_center().y), Vector2(thickness, room_rect.size.y - 150.0))
	_add_pseudo_34_door(parent, "TopDownNorthDoor", Vector2(room_rect.get_center().x, room_rect.position.y + 18.0), Vector2(132, 34))
	_add_pseudo_34_door(parent, "TopDownSouthDoor", Vector2(room_rect.get_center().x, room_rect.end.y - 18.0), Vector2(150, 38))

func _add_room_boundary_body(body_name: String, position: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.name = body_name
	body.global_position = position
	arena_root.add_child(body)
	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	collision.shape = shape
	body.add_child(collision)
	tower_boundary_body_count += 1

func _add_pseudo_34_wall(parent: Node, wall_name: String, position: Vector2, size: Vector2) -> void:
	var wall := Polygon2D.new()
	wall.name = wall_name
	var half := size * 0.5
	wall.polygon = PackedVector2Array([
		position + Vector2(-half.x, -half.y),
		position + Vector2(half.x, -half.y),
		position + Vector2(half.x, half.y),
		position + Vector2(-half.x, half.y),
	])
	wall.color = Color(0.24, 0.27, 0.28, 0.08 if image2_environment_background_loaded else 1.0)
	parent.add_child(wall)
	pseudo_34_wall_count += 1

func _add_pseudo_34_door(parent: Node, door_name: String, position: Vector2, size: Vector2) -> void:
	var door := Polygon2D.new()
	door.name = door_name
	door.set_meta("active", false)
	var half := size * 0.5
	door.polygon = PackedVector2Array([
		position + Vector2(-half.x, -half.y),
		position + Vector2(half.x, -half.y),
		position + Vector2(half.x, half.y),
		position + Vector2(-half.x, half.y),
	])
	door.color = Color(0.12, 0.10, 0.08, 0.10 if image2_environment_background_loaded else 1.0)
	parent.add_child(door)
	if door_name.ends_with("SouthDoor"):
		south_exit_door = door
		active_exit_door_position = position + Vector2(0.0, -46.0)
	pseudo_34_door_count += 1

func _activate_exit_door() -> void:
	if not is_instance_valid(south_exit_door):
		return
	south_exit_door.set_meta("active", true)
	south_exit_door.color = Color(0.28, 0.58, 0.78, 1.0)

func _get_active_exit_door_position_for_test() -> Vector2:
	return active_exit_door_position

func _spawn_player() -> void:
	player = Player2DScript.new()
	player.name = "Player2D"
	player.apply_player_data(player_data)
	player.died.connect(_on_player_died)
	player.health_changed.connect(_on_player_health_changed)
	arena_root.add_child(player)
	_apply_default_player_art()
	player.global_position = _find_safe_spawn_position(Vector2.ZERO, 24.0)
	var camera := Camera2D.new()
	camera.enabled = true
	camera.zoom = PSEUDO_34_CAMERA_ZOOM
	player.add_child(camera)

func _apply_default_player_art() -> void:
	if not is_instance_valid(player) or not player.has_method("apply_visual_asset_manifest"):
		return
	if not FileAccess.file_exists(DEFAULT_PLAYER_IMAGE2_SPRITE_PATH):
		return
	player.apply_visual_asset_manifest({
		"asset_pipeline": "IMAGE2",
		"pose_variation_version": "production_dark_armor_v3",
		"art_family": "dark_high_res_pixel_actor",
		"environment_pairing": "painterly_brutalist_tower",
		"texture_filter": "nearest",
		"directional_target": "4dir",
		"separate_combat_vfx": true,
		"contact_shadow": {
			"required": true,
			"style": "soft_grounded_cold_ambient",
		},
		"direction_mode": "runtime_flip_2dir",
		"enabled": true,
		"sprite_sheet_path": DEFAULT_PLAYER_IMAGE2_SPRITE_PATH,
		"frame_size": Vector2i(160, 160),
		"hide_procedural_body": true,
		"animations": {
			"idle": {"from": 0, "to": 3, "fps": 6},
			"run": {"from": 4, "to": 9, "fps": 9},
			"attack": {"from": 10, "to": 15, "fps": 10},
			"death": {"from": 16, "to": 19, "fps": 6},
		},
	})

func _is_default_player_art_loaded() -> bool:
	if not is_instance_valid(player):
		return false
	var actor_sprite := player.find_child("ActorSprite", true, false) as Sprite2D
	return is_instance_valid(actor_sprite) and actor_sprite.texture != null and actor_sprite.visible

func _is_player_procedural_body_hidden() -> bool:
	if not is_instance_valid(player):
		return false
	var body := player.find_child("PlayerBody", true, false) as CanvasItem
	return is_instance_valid(body) and not body.visible

func _get_visual_style_for_test() -> Dictionary:
	return {
		"room_visual_mode": ROOM_VISUAL_MODE,
		"environment_family": ENVIRONMENT_FAMILY,
		"camera_zoom": PSEUDO_34_CAMERA_ZOOM,
		"logic_room_rect": room_rect,
		"visual_vertical_compress": PSEUDO_34_VERTICAL_COMPRESS,
		"elevated_layer_count": tower_interior_layer_count,
		"uses_foot_anchor_sorting": true,
	}

func _get_room_navigation_contract_for_test() -> Dictionary:
	return {
		"door_count": pseudo_34_door_count,
		"wall_count": pseudo_34_wall_count,
		"solid_obstacle_count": pseudo_34_solid_obstacle_count,
		"boundary_body_count": tower_boundary_body_count,
		"visual_only_obstacle_count": topdown_visual_only_obstacle_count,
		"elevated_layer_count": tower_interior_layer_count,
		"obstacles_collide": pseudo_34_solid_obstacle_count > 0,
		"footprint_colliders_only": topdown_visual_only_obstacle_count == pseudo_34_solid_obstacle_count,
		"logic_room_rect": room_rect,
	}

func _get_collision_layout_for_test() -> Dictionary:
	return {
		"environment_family": ENVIRONMENT_FAMILY,
		"boundary_body_count": tower_boundary_body_count,
		"footprint_body_count": pseudo_34_solid_obstacle_count,
		"uses_footprint_only_obstacles": topdown_visual_only_obstacle_count == pseudo_34_solid_obstacle_count,
		"center_lane_clear": not _is_position_blocked(room_rect.get_center(), 32.0) and not _is_position_blocked(room_rect.get_center() + Vector2(0, 120), 32.0),
		"logic_room_rect": room_rect,
	}

func _get_environment_asset_contract_for_test() -> Dictionary:
	return {
		"asset_pipeline": "IMAGE2",
		"background_path": IMAGE2_ENVIRONMENT_BACKGROUND_PATH,
		"environment_family": ENVIRONMENT_FAMILY,
		"world_art_anchor": WORLD_ART_ANCHOR,
		"forbidden_style": FORBIDDEN_STYLE,
		"background_loaded": image2_environment_background_loaded,
		"procedural_visuals_muted": image2_environment_background_loaded,
	}

func _get_default_actor_art_contract_for_test() -> Dictionary:
	var manifest := {}
	if is_instance_valid(player) and player.has_method("get_visual_asset_manifest"):
		manifest = player.get_visual_asset_manifest()
	return {
		"player_asset_pipeline": "IMAGE2",
		"player_sprite_path": DEFAULT_PLAYER_IMAGE2_SPRITE_PATH,
		"player_sprite_loaded": _is_default_player_art_loaded(),
		"player_procedural_hidden": _is_player_procedural_body_hidden(),
		"actor_art_family": str(manifest.get("art_family", "")),
		"actor_environment_pairing": str(manifest.get("environment_pairing", "")),
		"actor_texture_filter": str(manifest.get("texture_filter", "")),
		"actor_directional_target": str(manifest.get("directional_target", "")),
	}

func _spawn_wave() -> void:
	_spawn_floor_template(FloorRulesScript.build_floor_template(current_floor))

func _spawn_floor_template(template: Dictionary) -> void:
	current_floor_template = template.duplicate(true)
	_clear_active_enemies()
	enemies_alive = 0
	floor_kill_count = 0
	floor_pickup_names = []
	last_floor_rewards = {}
	for spawn_data in Array(template.get("enemies", [])):
		var spawn: Dictionary = Dictionary(spawn_data)
		var enemy: CharacterBody2D = Enemy2DScript.new()
		enemy.name = "Enemy2D"
		var enemy_data := FloorRulesScript.get_enemy_type_data(str(spawn.get("enemy_type", "rot_melee")), current_floor, Dictionary(spawn.get("modifiers", {})))
		enemy.apply_enemy_data(enemy_data)
		var desired_position: Vector2 = spawn.get("position", Vector2.ZERO) if spawn.get("position", null) is Vector2 else Vector2.ZERO
		enemy.global_position = _find_safe_spawn_position(desired_position, 54.0)
		enemy.target = player
		enemy.died.connect(_on_enemy_died)
		arena_root.add_child(enemy)
		enemies_alive += 1
	_update_hud("Floor %d: %s" % [current_floor, str(template.get("template_id", "clear"))])

func _clear_active_enemies() -> void:
	if not is_instance_valid(arena_root):
		return
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var node := enemy as Node
		if is_instance_valid(node):
			node.queue_free()

func _on_enemy_died(enemy: Node) -> void:
	enemies_alive = maxi(0, enemies_alive - 1)
	kill_index += 1
	floor_kill_count += 1
	var xp_result := _award_enemy_experience(_build_enemy_experience_source(enemy))
	if enemy is Node2D:
		_spawn_drop((enemy as Node2D).global_position)
	if enemies_alive <= 0:
		_on_floor_cleared()
	else:
		var level_note := " Level up!" if bool(xp_result.get("leveled_up", false)) else ""
		_update_hud("Enemies left: %d | +%d XP%s" % [enemies_alive, int(xp_result.get("experience_gained", 0)), level_note])

func _build_enemy_experience_source(enemy: Node) -> Dictionary:
	if enemy == null:
		return {}
	var enemy_type_value = enemy.get("enemy_type")
	var display_rank_value = enemy.get("display_rank")
	var is_elite_value = enemy.get("is_elite")
	var is_boss_value = enemy.get("is_boss")
	return {
		"enemy_type": str(enemy_type_value) if enemy_type_value != null else "rot_melee",
		"display_rank": str(display_rank_value) if display_rank_value != null else "normal",
		"is_elite": bool(is_elite_value) if is_elite_value != null else false,
		"is_boss": bool(is_boss_value) if is_boss_value != null else false,
	}

func _award_enemy_experience(enemy_data: Dictionary) -> Dictionary:
	var before_level := int(player_data.get("player_level", 1))
	var experience := _get_enemy_experience_reward(enemy_data)
	player_data = PlayerDataServiceScript.add_experience(player_data, experience)
	if is_instance_valid(player):
		player.apply_player_data(player_data)
	_schedule_save()
	return {
		"experience_gained": experience,
		"leveled_up": int(player_data.get("player_level", 1)) > before_level,
		"player_level": int(player_data.get("player_level", 1)),
	}

func _get_enemy_experience_reward(enemy_data: Dictionary) -> int:
	var base := 18 + current_floor * 3
	match str(enemy_data.get("enemy_type", "rot_melee")):
		"shadow_archer":
			base += 4
		"tower_guardian":
			base += 10
		"tower_gatekeeper":
			base += 35
	if bool(enemy_data.get("is_boss", false)) or str(enemy_data.get("display_rank", "")) == "boss":
		base *= 4
	elif bool(enemy_data.get("is_elite", false)) or str(enemy_data.get("display_rank", "")) == "elite":
		base *= 2
	return maxi(1, base)

func _award_enemy_experience_for_test(enemy_data: Dictionary) -> Dictionary:
	return _award_enemy_experience(enemy_data)

func _spawn_drop(position: Vector2) -> void:
	var drop: Area2D = DropItem2DScript.new()
	drop.name = "DropItem2D"
	drop.global_position = _find_safe_spawn_position(position, 18.0)
	drop.set_payload(LootRulesScript.generate_enemy_drop(current_floor, str(player_data.get("base_class", "warrior")), kill_index))
	drop.collected.connect(_on_drop_collected)
	arena_root.add_child(drop)

func _on_drop_collected(payload: Dictionary) -> void:
	var notification := _build_loot_notification(payload, "drop")
	player_data["inventory"] = InventoryDataServiceScript.add_item(Dictionary(player_data.get("inventory", {})), payload)
	floor_pickup_names.append(str(payload.get("name", "Item")))
	p2_loot_loop_metrics = P2LootLoopMetricsRecorderScript.record_pickup(p2_loot_loop_metrics, payload, notification)
	_schedule_save()
	_show_loot_notification(notification)
	_update_hud(str(notification.get("log_text", "Picked up: %s" % str(payload.get("name", "Item")))))

func _on_floor_cleared() -> void:
	if portal_available:
		return
	portal_available = true
	var rewards: Dictionary = _build_floor_clear_rewards(current_floor, str(player_data.get("base_class", "warrior")))
	player_data = _apply_floor_clear_rewards_to_player(player_data, rewards)
	p2_loot_loop_metrics = P2LootLoopMetricsRecorderScript.record_floor_cleared(p2_loot_loop_metrics)
	last_floor_rewards = rewards.duplicate(true)
	SaveManagerScript.apply_floor_clear(current_floor, rewards, _build_current_player_snapshot())
	_activate_exit_door()
	_spawn_portal()
	_update_hud("Floor %d cleared. Reward saved. Press E or step into the portal." % current_floor)

func _clear_floor_for_test() -> void:
	_on_floor_cleared()

func _build_floor_clear_rewards(floor: int, base_class: String) -> Dictionary:
	var rewards := TowerProgressServiceScript.build_floor_reward(floor)
	if bool(rewards.get("guaranteed_magic_equipment", false)):
		rewards["guaranteed_items"] = [LootRulesScript.generate_boss_clear_reward(floor, base_class)]
	else:
		rewards["guaranteed_items"] = []
	return rewards

func _apply_floor_clear_rewards_to_player(data: Dictionary, rewards: Dictionary) -> Dictionary:
	var result := data.duplicate(true)
	var inventory: Dictionary = Dictionary(result.get("inventory", {}))
	for item in Array(rewards.get("guaranteed_items", [])):
		var payload: Dictionary = Dictionary(item)
		var notification := _build_loot_notification(payload, "boss_reward")
		inventory = InventoryDataServiceScript.add_item(inventory, payload)
		floor_pickup_names.append(str(payload.get("name", "Item")))
		last_loot_notification = notification
		p2_loot_loop_metrics = P2LootLoopMetricsRecorderScript.record_pickup(p2_loot_loop_metrics, payload, notification)
	result["inventory"] = inventory
	return result

func _build_floor_clear_rewards_for_test(floor: int, base_class: String) -> Dictionary:
	return _build_floor_clear_rewards(floor, base_class)

func _apply_floor_clear_rewards_to_player_for_test(data: Dictionary, rewards: Dictionary) -> Dictionary:
	return _apply_floor_clear_rewards_to_player(data, rewards)

func _build_loot_notification(payload: Dictionary, source: String = "drop") -> Dictionary:
	return LootNotificationServiceScript.build_pickup_notification(player_data, payload, source)

func _build_loot_notification_for_test(payload: Dictionary, source: String = "drop") -> Dictionary:
	return _build_loot_notification(payload, source)

func _show_loot_notification(notification: Dictionary) -> void:
	last_loot_notification = notification.duplicate(true)
	if is_instance_valid(hud) and hud.has_method("show_loot_notification"):
		hud.show_loot_notification(notification)

func _get_last_loot_notification_for_test() -> Dictionary:
	return last_loot_notification.duplicate(true)

func _spawn_portal() -> void:
	portal = Area2D.new()
	portal.name = "NextFloorPortal"
	portal.global_position = _find_safe_spawn_position(active_exit_door_position, 52.0)
	portal.body_entered.connect(_on_portal_body_entered)
	arena_root.add_child(portal)
	var shape := CircleShape2D.new()
	shape.radius = 52.0
	var collision := CollisionShape2D.new()
	collision.shape = shape
	portal.add_child(collision)
	var ring := Line2D.new()
	ring.width = 6.0
	ring.closed = true
	ring.default_color = Color(0.35, 0.72, 1.0, 0.95)
	for i in range(32):
		var angle := TAU * float(i) / 32.0
		ring.add_point(Vector2(cos(angle), sin(angle)) * 44.0)
	portal.add_child(ring)

func _spawn_portal_for_test() -> void:
	if is_instance_valid(portal):
		portal.queue_free()
		portal = null
	_spawn_portal()

func _on_portal_body_entered(body: Node) -> void:
	if body == player:
		_enter_next_floor()

func _enter_next_floor() -> void:
	if not portal_available or floor_transition_locked or transition_locked:
		return
	floor_transition_locked = true
	current_floor += 1
	player_data = _build_current_player_snapshot()
	player_data["highest_floor"] = current_floor
	SaveManagerScript.save_active_player_data(player_data, current_floor)
	portal_available = false
	if is_instance_valid(portal):
		portal.queue_free()
	for child in arena_root.get_children():
		if child.get_script() == DropItem2DScript:
			child.queue_free()
	player.global_position = _find_safe_spawn_position(Vector2.ZERO, 24.0)
	_spawn_wave()
	_update_hud("Entered floor %d." % current_floor)
	floor_transition_locked = false

func _apply_floor_template_for_test(floor: int) -> void:
	current_floor = maxi(1, floor)
	portal_available = false
	if is_instance_valid(portal):
		portal.queue_free()
	_spawn_wave()

func _return_to_town() -> void:
	if not _lock_transition():
		return
	get_tree().paused = false
	player_data = _build_current_player_snapshot()
	SaveManagerScript.save_active_player_data(player_data, current_floor)
	SceneRouterScript.go_to_town(get_tree())

func _on_player_died() -> void:
	if death_settlement_active:
		return
	death_settlement_active = true
	death_presentation_pending = true
	p2_loot_loop_metrics = P2LootLoopMetricsRecorderScript.record_death(p2_loot_loop_metrics)
	if is_instance_valid(player):
		player.set_move_vector(Vector2.ZERO)
	player_data = _build_current_player_snapshot()
	player_data["health"] = maxi(1, int(player_data.get("max_health", 120)) / 2)
	SaveManagerScript.save_active_player_data(player_data, current_floor)
	_update_hud("You fell. Returning after death animation...")
	var delay := _get_death_presentation_delay()
	if delay <= 0.0:
		_finish_death_presentation()
		return
	get_tree().create_timer(delay, true).timeout.connect(_finish_death_presentation)

func _finish_death_presentation() -> void:
	if not death_presentation_pending:
		return
	death_presentation_pending = false
	_show_death_settlement()

func _get_death_presentation_delay() -> float:
	if death_presentation_delay_override >= 0.0:
		return death_presentation_delay_override
	if is_instance_valid(player) and player.has_method("get_death_animation_duration_for_test"):
		var animation_delay := float(player.call("get_death_animation_duration_for_test"))
		if animation_delay > 0.0:
			return animation_delay
	return DEFAULT_DEATH_PRESENTATION_DELAY

func _return_to_town_after_death() -> void:
	if not _lock_transition():
		return
	get_tree().paused = false
	SaveManagerScript.save_active_player_data(player_data, current_floor)
	SceneRouterScript.go_to_town(get_tree())

func _build_current_player_snapshot() -> Dictionary:
	var snapshot: Dictionary = player.export_player_patch() if is_instance_valid(player) else player_data.duplicate(true)
	snapshot["inventory"] = Dictionary(player_data.get("inventory", {})).duplicate(true)
	snapshot["highest_floor"] = current_floor
	return snapshot

func _schedule_save() -> void:
	if save_scheduled:
		return
	save_scheduled = true
	get_tree().create_timer(0.8).timeout.connect(_flush_save)

func _flush_save() -> void:
	if not save_scheduled:
		return
	save_scheduled = false
	player_data = _build_current_player_snapshot()
	SaveManagerScript.save_active_player_data(player_data, current_floor)

func _create_hud() -> void:
	hud = HudControllerScript.new()
	hud.name = "HudController"
	add_child(hud)

func _create_inventory_window() -> void:
	inventory_window = InventoryEquipmentWindowScript.new()
	inventory_window.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(inventory_window)
	inventory_window.set_player_data(player_data)
	inventory_window.player_data_changed.connect(_on_player_data_changed)
	inventory_window.close_requested.connect(func(): _set_inventory_window_visible(false))

func _create_pause_overlay() -> void:
	pause_overlay = CanvasLayer.new()
	pause_overlay.name = "PauseOverlay"
	pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_overlay.visible = false
	add_child(pause_overlay)

	var veil := ColorRect.new()
	veil.name = "PauseDarkVeil"
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.color = Color(0.0, 0.0, 0.0, 0.48)
	pause_overlay.add_child(veil)

	var panel := PanelContainer.new()
	panel.position = Vector2(490, 205)
	panel.size = Vector2(300, 230)
	DarkArpgUiThemeScript.style_panel(panel, true)
	pause_overlay.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	var title := Label.new()
	title.text = "Paused"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	DarkArpgUiThemeScript.style_title(title, 24)
	box.add_child(title)

	pause_resume_button = Button.new()
	pause_resume_button.name = "ResumeButton"
	pause_resume_button.text = "Resume"
	pause_resume_button.custom_minimum_size = Vector2(260, 42)
	DarkArpgUiThemeScript.style_button(pause_resume_button, true)
	pause_resume_button.pressed.connect(_toggle_pause)
	box.add_child(pause_resume_button)

	var inventory := Button.new()
	inventory.name = "PauseInventoryButton"
	inventory.text = "Inventory / Equipment"
	inventory.custom_minimum_size = Vector2(260, 42)
	DarkArpgUiThemeScript.style_button(inventory)
	inventory.pressed.connect(_toggle_inventory_window)
	box.add_child(inventory)

	var town := Button.new()
	town.name = "ReturnTownButton"
	town.text = "Return To Town"
	town.custom_minimum_size = Vector2(260, 42)
	DarkArpgUiThemeScript.style_button(town)
	town.pressed.connect(_return_to_town)
	box.add_child(town)

func _create_death_overlay() -> void:
	death_overlay = CanvasLayer.new()
	death_overlay.name = "DeathSettlementOverlay"
	death_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	death_overlay.visible = false
	add_child(death_overlay)

	var veil := ColorRect.new()
	veil.name = "DeathDarkVeil"
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.color = Color(0.0, 0.0, 0.0, 0.62)
	death_overlay.add_child(veil)

	var panel := PanelContainer.new()
	panel.position = Vector2(360, 110)
	panel.size = DEATH_SETTLEMENT_PANEL_SIZE
	DarkArpgUiThemeScript.style_panel(panel, true)
	death_overlay.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	var title := Label.new()
	title.text = "Death Settlement"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	DarkArpgUiThemeScript.style_title(title, 26)
	box.add_child(title)

	death_floor_section = _make_death_section_label("DeathFloorSection")
	box.add_child(death_floor_section)
	death_kills_section = _make_death_section_label("DeathKillsSection")
	box.add_child(death_kills_section)
	death_loot_section = _make_death_section_label("DeathLootSection")
	box.add_child(death_loot_section)
	death_boss_reward_section = _make_death_section_label("DeathBossRewardSection")
	box.add_child(death_boss_reward_section)

	death_summary_label = Label.new()
	death_summary_label.name = "DeathSummary"
	death_summary_label.visible = false
	death_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	death_summary_label.custom_minimum_size = Vector2(460, 1)
	DarkArpgUiThemeScript.style_body_label(death_summary_label, 15, true)
	box.add_child(death_summary_label)

	death_return_town_button = Button.new()
	death_return_town_button.name = "DeathReturnTownButton"
	death_return_town_button.text = "Return To Town"
	death_return_town_button.custom_minimum_size = Vector2(380, 46)
	DarkArpgUiThemeScript.style_button(death_return_town_button, true)
	death_return_town_button.pressed.connect(_return_to_town_after_death)
	box.add_child(death_return_town_button)

func _make_death_section_label(label_name: String) -> Label:
	var label := Label.new()
	label.name = label_name
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(520, DEATH_SETTLEMENT_SECTION_MIN_HEIGHT)
	DarkArpgUiThemeScript.style_body_label(label, 15)
	return label

func get_death_settlement_visual_qa_for_test() -> Dictionary:
	return {
		"panel_size": DEATH_SETTLEMENT_PANEL_SIZE,
		"section_min_height": DEATH_SETTLEMENT_SECTION_MIN_HEIGHT,
	}

func _show_death_settlement() -> void:
	if not is_instance_valid(death_overlay):
		return
	if is_instance_valid(pause_overlay):
		pause_overlay.visible = false
	if is_instance_valid(inventory_window):
		inventory_window.visible = false
	_refresh_death_settlement_sections()
	death_overlay.visible = true
	get_tree().paused = true
	_grab_focus_when_ready(death_return_town_button)

func _show_death_settlement_for_test() -> void:
	_show_death_settlement()

func _set_death_presentation_delay_for_test(delay: float) -> void:
	death_presentation_delay_override = maxf(0.0, delay)

func _is_death_presentation_pending_for_test() -> bool:
	return death_presentation_pending

func _get_death_presentation_delay_for_test() -> float:
	return _get_death_presentation_delay()

func _refresh_death_settlement_sections() -> void:
	var settlement := _build_death_settlement()
	if is_instance_valid(death_floor_section):
		death_floor_section.text = str(settlement.get("floor_text", ""))
	if is_instance_valid(death_kills_section):
		death_kills_section.text = str(settlement.get("combat_text", ""))
	if is_instance_valid(death_loot_section):
		death_loot_section.text = str(settlement.get("loot_text", ""))
	if is_instance_valid(death_boss_reward_section):
		death_boss_reward_section.text = str(settlement.get("boss_reward_text", ""))
	if is_instance_valid(death_summary_label):
		death_summary_label.text = str(settlement.get("summary_text", ""))

func _refresh_death_settlement_sections_for_test() -> void:
	_refresh_death_settlement_sections()

func _build_death_settlement() -> Dictionary:
	return DeathSettlementServiceScript.build_death_settlement({
		"floor": current_floor,
		"template_id": str(current_floor_template.get("template_id", "unknown")),
		"kill_count": floor_kill_count,
		"pickup_names": floor_pickup_names,
		"last_floor_rewards": last_floor_rewards,
		"return_health_mode": "half",
	})

func _build_death_settlement_for_test() -> Dictionary:
	return _build_death_settlement()

func _build_death_summary_text() -> String:
	return str(_build_death_settlement().get("summary_text", ""))

func _build_death_summary_text_for_test() -> String:
	return _build_death_summary_text()

func _build_boss_reward_summary() -> String:
	var settlement := _build_death_settlement()
	var boss_text := str(settlement.get("boss_reward_text", "Boss reward\nnone"))
	return boss_text.replace("Boss reward\n", "")

func _toggle_pause() -> void:
	if not is_instance_valid(pause_overlay):
		return
	if death_settlement_active:
		return
	pause_overlay.visible = not pause_overlay.visible
	_sync_menu_pause_state()
	if pause_overlay.visible:
		_grab_focus_when_ready(pause_resume_button)

func _toggle_pause_for_test() -> void:
	_toggle_pause()

func _handle_cancel() -> void:
	if death_settlement_active:
		return
	if is_instance_valid(inventory_window) and inventory_window.visible:
		_set_inventory_window_visible(false)
		if is_instance_valid(pause_overlay) and pause_overlay.visible:
			_grab_focus_when_ready(pause_resume_button)
		return
	_toggle_pause()

func _handle_cancel_for_test() -> void:
	_handle_cancel()

func _grab_focus_when_ready(control: Control) -> void:
	if not is_instance_valid(control):
		return
	control.call_deferred("grab_focus")

func _toggle_inventory_window() -> void:
	if not is_instance_valid(inventory_window):
		return
	_set_inventory_window_visible(not inventory_window.visible)

func _set_inventory_window_visible(visible: bool) -> void:
	if not is_instance_valid(inventory_window):
		return
	inventory_window.visible = visible
	if visible:
		inventory_window.set_player_data(player_data)
	_sync_menu_pause_state()

func _sync_menu_pause_state() -> void:
	if death_settlement_active:
		return
	var pause_visible := is_instance_valid(pause_overlay) and pause_overlay.visible
	var inventory_visible := is_instance_valid(inventory_window) and inventory_window.visible
	get_tree().paused = pause_visible or inventory_visible

func _on_player_data_changed(updated: Dictionary) -> void:
	if _equipment_snapshot_changed(player_data, updated):
		p2_loot_loop_metrics = P2LootLoopMetricsRecorderScript.record_equipment_change(p2_loot_loop_metrics)
	if _skill_node_level_total(updated) > _skill_node_level_total(player_data):
		p2_loot_loop_metrics = P2LootLoopMetricsRecorderScript.record_skill_upgrade(p2_loot_loop_metrics)
	player_data = updated.duplicate(true)
	if is_instance_valid(player):
		player.apply_player_data(player_data)
	_schedule_save()
	_update_hud("Equipment updated.")

func _on_player_health_changed(current: int, maximum: int) -> void:
	player_data["health"] = current
	player_data["max_health"] = maximum
	if is_instance_valid(hud) and hud.has_method("set_player_vitals"):
		hud.set_player_vitals(
			current,
			maximum,
			int(player_data.get("mana", 0)),
			int(player_data.get("max_mana", 1))
		)

func _equipment_snapshot_changed(before: Dictionary, after: Dictionary) -> bool:
	return Dictionary(before.get("equipped_items", {})) != Dictionary(after.get("equipped_items", {}))

func _skill_node_level_total(data: Dictionary) -> int:
	var total := 0
	for value in Dictionary(data.get("unlocked_skill_nodes", {})).values():
		total += maxi(0, int(value))
	return total

func _get_p2_loot_loop_metrics_for_test() -> Dictionary:
	return P2LootLoopMetricsRecorderScript.normalize_metrics(p2_loot_loop_metrics)

func _get_p2_loot_loop_report_for_test() -> Dictionary:
	return P2LootLoopMetricsRecorderScript.build_acceptance_report(p2_loot_loop_metrics)

func _set_p2_loot_loop_elapsed_seconds_for_test(seconds: float) -> void:
	p2_loot_loop_metrics = P2LootLoopMetricsRecorderScript.record_elapsed_seconds(p2_loot_loop_metrics, seconds)

func _is_menu_blocking_combat() -> bool:
	return death_settlement_active or (is_instance_valid(pause_overlay) and pause_overlay.visible) or (is_instance_valid(inventory_window) and inventory_window.visible)

func _lock_transition() -> bool:
	if transition_locked:
		return false
	transition_locked = true
	return true

func _update_hud(message: String) -> void:
	if not is_instance_valid(hud):
		return
	hud.set_status("Floor %d | Enemies %d" % [current_floor, enemies_alive])
	hud.set_log(message)
	var capacity: Dictionary = InventoryDataServiceScript.build_capacity_summary(Dictionary(player_data.get("inventory", {})))
	hud.set_inventory(str(capacity.get("summary_text", "Bag 0/40")))
	if hud.has_method("set_player_vitals"):
		var health := int(player_data.get("health", 0))
		var max_health := int(player_data.get("max_health", 1))
		if is_instance_valid(player):
			health = int(player.get("health"))
			max_health = int(player.get("max_health"))
		hud.set_player_vitals(
			health,
			max_health,
			int(player_data.get("mana", 0)),
			int(player_data.get("max_mana", 1))
		)
	if hud.has_method("set_player_progress"):
		hud.set_player_progress(
			int(player_data.get("player_level", 1)),
			int(player_data.get("current_exp", 0)),
			int(player_data.get("exp_to_next_level", 100)),
			int(player_data.get("skill_points", 0))
		)

func _get_move_vector() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_forward", "move_back")

func _get_attack_direction() -> Vector2:
	var mouse_direction: Vector2 = get_global_mouse_position() - player.global_position
	var nearest: Node2D = null
	var nearest_distance: float = INF
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var enemy_2d := enemy as Node2D
		if not is_instance_valid(enemy_2d):
			continue
		var distance: float = player.global_position.distance_to(enemy_2d.global_position)
		if distance < nearest_distance and distance <= 150.0:
			nearest = enemy_2d
			nearest_distance = distance
	if is_instance_valid(nearest):
		return nearest.global_position - player.global_position
	return mouse_direction
