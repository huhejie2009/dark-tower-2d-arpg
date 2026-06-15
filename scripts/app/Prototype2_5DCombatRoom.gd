extends Node3D

const BillboardActor3D := preload("res://scripts/prototype/BillboardActor3D.gd")
const Prototype2_5DVisualQaService := preload("res://scripts/prototype/Prototype2_5DVisualQaService.gd")

var player: Node3D
var enemies: Array[Node3D] = []
var wall_nodes: Array[Node3D] = []
var column_nodes: Array[Node3D] = []
var exit_marker: Node3D
var camera: Camera3D

func _ready() -> void:
	_build_room()
	_build_camera()
	_build_actors()
	_build_exit_marker()

func _build_room() -> void:
	var floor_mesh := MeshInstance3D.new()
	floor_mesh.name = "GreyboxFloor"
	var plane := PlaneMesh.new()
	plane.size = Vector2(18.0, 12.0)
	floor_mesh.mesh = plane
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
	body.add_child(mesh_node)
	column_nodes.append(body)

func _build_camera() -> void:
	camera = Camera3D.new()
	camera.name = "PrototypeCamera3D"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 12.0
	camera.position = Vector3(0.0, 10.0, 10.0)
	camera.rotation_degrees = Vector3(-50.0, 0.0, 0.0)
	camera.current = true
	add_child(camera)

func _build_actors() -> void:
	player = BillboardActor3D.new()
	player.name = "PlayerBillboard"
	player.position = Vector3(0.0, 0.0, 2.0)
	add_child(player)

	for index in range(2):
		var enemy := BillboardActor3D.new()
		enemy.name = "EnemyBillboard%d" % (index + 1)
		enemy.position = Vector3(-2.0 + float(index) * 4.0, 0.0, -2.0)
		add_child(enemy)
		enemies.append(enemy)

func _build_exit_marker() -> void:
	exit_marker = MeshInstance3D.new()
	exit_marker.name = "ExitMarker"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.55
	mesh.bottom_radius = 0.55
	mesh.height = 0.08
	exit_marker.mesh = mesh
	exit_marker.position = Vector3(0.0, 0.05, -4.8)
	add_child(exit_marker)

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
