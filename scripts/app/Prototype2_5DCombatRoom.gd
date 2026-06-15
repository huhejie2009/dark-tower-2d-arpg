extends Node3D

const BillboardActor3D := preload("res://scripts/prototype/BillboardActor3D.gd")
const Prototype2_5DVisualQaService := preload("res://scripts/prototype/Prototype2_5DVisualQaService.gd")

var player: Node3D
var enemies: Array[Node3D] = []
var wall_nodes: Array[Node3D] = []
var column_nodes: Array[Node3D] = []
var actor_visible_markers: Array[MeshInstance3D] = []
var floor_mesh: MeshInstance3D
var exit_marker: Node3D
var camera: Camera3D
var world_environment: WorldEnvironment
var key_light: DirectionalLight3D
var debug_hud: CanvasLayer
var camera_follow_offset := Vector3(0.0, 10.0, 10.0)
var player_move_input_override_enabled := false
var player_move_input_override := Vector2.ZERO
var active_move_input := Vector2.ZERO

func _ready() -> void:
	_build_visibility_baseline()
	_build_room()
	_build_camera()
	_build_actors()
	_build_exit_marker()
	_build_debug_hud()

func _physics_process(_delta: float) -> void:
	active_move_input = _read_player_move_input()
	if player != null and player.has_method("set_move_input"):
		player.call("set_move_input", active_move_input)
	_update_camera_follow()

func _build_visibility_baseline() -> void:
	world_environment = WorldEnvironment.new()
	world_environment.name = "PrototypeWorldEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.035, 0.043, 0.055)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.28, 0.32, 0.38)
	environment.ambient_light_energy = 1.1
	world_environment.environment = environment
	add_child(world_environment)

	key_light = DirectionalLight3D.new()
	key_light.name = "PrototypeKeyLight"
	key_light.light_energy = 2.2
	key_light.rotation_degrees = Vector3(-55.0, -30.0, 0.0)
	add_child(key_light)

func _build_room() -> void:
	floor_mesh = MeshInstance3D.new()
	floor_mesh.name = "GreyboxFloor"
	var plane := PlaneMesh.new()
	plane.size = Vector2(18.0, 12.0)
	floor_mesh.mesh = plane
	floor_mesh.material_override = _make_material(Color(0.16, 0.18, 0.20), Color(0.02, 0.025, 0.03))
	add_child(floor_mesh)

	_create_wall("NorthWall", Vector3(0.0, 0.75, -6.0), Vector3(18.0, 1.5, 0.35))
	_create_wall("SouthWall", Vector3(0.0, 0.75, 6.0), Vector3(18.0, 1.5, 0.35))
	_create_wall("WestWall", Vector3(-9.0, 0.75, 0.0), Vector3(0.35, 1.5, 12.0))
	_create_wall("EastWall", Vector3(9.0, 0.75, 0.0), Vector3(0.35, 1.5, 12.0))
	_create_column("ColumnA", Vector3(-3.5, 0.75, -1.5))
	_create_column("ColumnB", Vector3(3.5, 0.75, 1.5))

func _create_wall(node_name: String, node_position: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = node_position
	add_child(body)

	var shape_node := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape_node.shape = box
	body.add_child(shape_node)

	var mesh_node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_node.mesh = mesh
	mesh_node.material_override = _make_material(Color(0.23, 0.24, 0.25), Color(0.015, 0.018, 0.022))
	body.add_child(mesh_node)
	wall_nodes.append(body)

func _create_column(node_name: String, node_position: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = node_position
	add_child(body)

	var shape_node := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.8, 1.5, 0.8)
	shape_node.shape = box
	body.add_child(shape_node)

	var mesh_node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.8, 1.5, 0.8)
	mesh_node.mesh = mesh
	mesh_node.material_override = _make_material(Color(0.31, 0.32, 0.34), Color(0.025, 0.028, 0.032))
	body.add_child(mesh_node)
	column_nodes.append(body)

func _build_camera() -> void:
	camera = Camera3D.new()
	camera.name = "PrototypeCamera3D"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 12.0
	camera.position = Vector3(0.0, 10.0, 10.0)
	camera.current = true
	add_child(camera)
	camera.look_at(Vector3.ZERO, Vector3.UP)

func _build_actors() -> void:
	player = BillboardActor3D.new()
	player.name = "PlayerBillboard"
	player.position = Vector3(0.0, 0.0, 2.0)
	player.set_movement_speed(4.5)
	add_child(player)
	_add_actor_visible_marker(player, Color(0.22, 0.65, 1.0), "PlayerReadableMarker")
	_update_camera_follow()

	for index in range(2):
		var enemy := BillboardActor3D.new()
		enemy.name = "EnemyBillboard%d" % (index + 1)
		enemy.position = Vector3(-2.0 + float(index) * 4.0, 0.0, -2.0)
		enemy.set_movement_speed(3.2)
		add_child(enemy)
		_add_actor_visible_marker(enemy, Color(0.95, 0.20, 0.16), "EnemyReadableMarker")
		enemies.append(enemy)

func _build_exit_marker() -> void:
	exit_marker = MeshInstance3D.new()
	exit_marker.name = "ExitMarker"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.55
	mesh.bottom_radius = 0.55
	mesh.height = 0.08
	exit_marker.mesh = mesh
	exit_marker.material_override = _make_material(Color(0.12, 0.55, 0.95), Color(0.03, 0.16, 0.28))
	exit_marker.position = Vector3(0.0, 0.05, -4.8)
	add_child(exit_marker)

func _build_debug_hud() -> void:
	debug_hud = CanvasLayer.new()
	debug_hud.name = "PrototypeDebugHUD"
	add_child(debug_hud)

	var label := Label.new()
	label.name = "PrototypeModeLabel"
	label.text = "2.5D PROTOTYPE - greybox visibility pass"
	label.position = Vector2(24.0, 20.0)
	label.add_theme_color_override("font_color", Color(0.72, 0.86, 1.0))
	label.add_theme_font_size_override("font_size", 20)
	debug_hud.add_child(label)

func _add_actor_visible_marker(actor: Node3D, color: Color, node_name: String) -> void:
	var marker := MeshInstance3D.new()
	marker.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.28
	mesh.bottom_radius = 0.36
	mesh.height = 0.18
	marker.mesh = mesh
	marker.position = Vector3(0.0, 0.11, 0.0)
	marker.material_override = _make_material(color, color * 0.25)
	actor.add_child(marker)
	actor_visible_markers.append(marker)

func _make_material(albedo: Color, emission: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = albedo
	material.emission_enabled = true
	material.emission = emission
	material.roughness = 0.85
	return material

func _read_player_move_input() -> Vector2:
	if player_move_input_override_enabled:
		return player_move_input_override
	return Input.get_vector("move_left", "move_right", "move_forward", "move_back")

func _update_camera_follow() -> void:
	if camera == null or player == null:
		return
	var target_position := player.global_position
	camera.global_position = target_position + camera_follow_offset
	camera.look_at(target_position, Vector3.UP)

func set_player_move_input_for_test(value: Vector2) -> void:
	player_move_input_override_enabled = true
	player_move_input_override = value

func clear_player_move_input_override_for_test() -> void:
	player_move_input_override_enabled = false
	player_move_input_override = Vector2.ZERO

func build_prototype_snapshot_for_test() -> Dictionary:
	return {
		"prototype_id": "2_5d_billboard_combat_room",
		"isolated_from_main_flow": true,
		"has_camera_3d": camera != null,
		"camera_orthographic": camera != null and camera.projection == Camera3D.PROJECTION_ORTHOGONAL,
		"wall_count": wall_nodes.size(),
		"column_count": column_nodes.size(),
		"player_count": 1 if player != null else 0,
		"enemy_count": enemies.size(),
		"has_exit_marker": exit_marker != null,
	}

func build_visual_qa_snapshot_for_test() -> Dictionary:
	var actor_snapshots: Array[Dictionary] = []
	if player != null and player.has_method("build_contract_snapshot"):
		actor_snapshots.append(player.call("build_contract_snapshot"))
	for enemy in enemies:
		if enemy != null and enemy.has_method("build_contract_snapshot"):
			actor_snapshots.append(enemy.call("build_contract_snapshot"))
	return Prototype2_5DVisualQaService.build_snapshot(build_prototype_snapshot_for_test(), actor_snapshots)

func build_visibility_snapshot_for_test() -> Dictionary:
	return {
		"has_world_environment": world_environment != null and world_environment.environment != null,
		"has_key_light": key_light != null,
		"floor_has_material": floor_mesh != null and floor_mesh.material_override != null,
		"wall_visible_material_count": _count_visible_materials(wall_nodes),
		"column_visible_material_count": _count_visible_materials(column_nodes),
		"actor_visible_marker_count": actor_visible_markers.size(),
		"exit_marker_has_material": exit_marker != null and exit_marker.get("material_override") != null,
		"has_debug_hud": debug_hud != null and debug_hud.has_node("PrototypeModeLabel"),
		"camera_has_visible_background": world_environment != null and world_environment.environment != null,
	}

func build_player_control_snapshot_for_test() -> Dictionary:
	var player_snapshot: Dictionary = {}
	if player != null and player.has_method("build_contract_snapshot"):
		player_snapshot = player.call("build_contract_snapshot")
	return {
		"can_control_player": player != null and player.has_method("set_move_input"),
		"movement_plane": str(player_snapshot.get("plane", "")),
		"player_position": player.global_position if player != null else Vector3.ZERO,
		"player_movement_speed": float(player_snapshot.get("movement_speed", 0.0)),
		"player_facing_direction": str(player_snapshot.get("facing_direction", "")),
		"active_move_input": active_move_input,
		"input_override_enabled": player_move_input_override_enabled,
		"camera_current": camera != null and camera.current,
		"camera_orthographic": camera != null and camera.projection == Camera3D.PROJECTION_ORTHOGONAL,
		"camera_tracks_player": camera != null and player != null,
		"camera_position": camera.global_position if camera != null else Vector3.ZERO,
		"camera_follow_offset": camera_follow_offset,
		"camera_size": camera.size if camera != null else 0.0,
	}

func _count_visible_materials(nodes: Array[Node3D]) -> int:
	var count := 0
	for node in nodes:
		for child in node.get_children():
			if child is MeshInstance3D and child.material_override != null:
				count += 1
	return count
