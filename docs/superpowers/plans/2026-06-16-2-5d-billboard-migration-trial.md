# 2.5D Billboard Migration Trial Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an isolated Godot 4.6.2 prototype that tests whether Dark Tower should use a 3D room with 2D billboard actors.

**Architecture:** The prototype must not replace the current 2D game flow. It introduces isolated 3D prototype scripts, one standalone prototype scene, focused regression tests, and a visual QA snapshot contract so we can decide whether to migrate later.

**Tech Stack:** Godot 4.6.2, GDScript, headless regression scripts, Camera3D orthographic view, Sprite3D billboard actors, CharacterBody3D collision on the XZ combat plane.

---

## File Structure

- Create `scripts/prototype/CombatPlane3DService.gd`
  - Pure math helpers for XZ-plane distance, range checks, movement vector cleanup, and attack arc checks.
- Create `scripts/prototype/BillboardActorAnimationProfile.gd`
  - Resource-like script that stores sprite billboard animation contract data and exposes a serializable snapshot.
- Create `scripts/prototype/BillboardActor3D.gd`
  - CharacterBody3D wrapper for Sprite3D actors, movement, collision, direction selection, and test snapshots.
- Create `scripts/prototype/Prototype2_5DVisualQaService.gd`
  - Snapshot builder for the prototype scene: camera, room bounds, actor counts, collision markers, and acceptance flags.
- Create `scripts/app/Prototype2_5DCombatRoom.gd`
  - Scene controller for the isolated 2.5D combat room.
- Create `scenes/prototypes/Prototype2_5DCombatRoom.tscn`
  - Standalone prototype scene with no main menu route.
- Create focused regression tests:
  - `tests/regression/regression_combat_plane_3d_service.gd`
  - `tests/regression/regression_billboard_actor_animation_profile.gd`
  - `tests/regression/regression_billboard_actor_3d_contract.gd`
  - `tests/regression/regression_prototype_2_5d_scene_contract.gd`
  - `tests/regression/regression_prototype_2_5d_visual_qa_contract.gd`
- Create progress record:
  - `docs/progress/2026-06-16-2-5d-billboard-prototype-progress.md`

The current files `scenes/Game2D.tscn`, `scripts/app/Game2D.gd`, save services, inventory services, and main menu routing must not be modified in this prototype pass.

---

### Task 1: Combat Plane Math Service

**Files:**
- Create: `scripts/prototype/CombatPlane3DService.gd`
- Test: `tests/regression/regression_combat_plane_3d_service.gd`

- [ ] **Step 1: Write the failing test**

Create `tests/regression/regression_combat_plane_3d_service.gd`:

```gdscript
extends SceneTree

const CombatPlane3DService := preload("res://scripts/prototype/CombatPlane3DService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var origin := Vector3(0.0, 5.0, 0.0)
	var target := Vector3(3.0, -2.0, 4.0)
	_expect(is_equal_approx(CombatPlane3DService.distance_xz(origin, target), 5.0), "XZ distance should ignore Y")
	_expect(CombatPlane3DService.is_in_range_xz(origin, target, 5.0), "range check should include exact radius")
	_expect(not CombatPlane3DService.is_in_range_xz(origin, target, 4.99), "range check should reject outside radius")

	var input := CombatPlane3DService.normalize_move_input(Vector2(2.0, -2.0))
	_expect(is_equal_approx(input.length(), 1.0), "normalized input should have unit length")
	_expect(CombatPlane3DService.normalize_move_input(Vector2.ZERO) == Vector2.ZERO, "zero input should stay zero")

	var forward := Vector3(0.0, 0.0, -1.0)
	var inside := Vector3(0.0, 0.0, -3.0)
	var outside := Vector3(3.0, 0.0, 0.0)
	_expect(CombatPlane3DService.is_inside_attack_arc_xz(origin, inside, forward, 4.0, 70.0), "target in front should be inside arc")
	_expect(not CombatPlane3DService.is_inside_attack_arc_xz(origin, outside, forward, 4.0, 70.0), "target to side should be outside narrow arc")

	var snapshot := CombatPlane3DService.build_contract_snapshot()
	_expect(str(snapshot.get("plane", "")) == "xz", "snapshot should declare XZ plane")
	_expect(str(snapshot.get("collision_basis", "")) == "3d_shapes", "snapshot should declare 3D shape collision")
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_COMBAT_PLANE_3D_SERVICE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
& 'C:\Users\huhej\OneDrive\桌面\Godot_v4.6.2-stable_win64_console.exe' --headless --path 'H:\GODOT_PROJECT\dark-tower-2d-arpg' --script 'res://tests/regression/regression_combat_plane_3d_service.gd'
```

Expected: FAIL because `scripts/prototype/CombatPlane3DService.gd` does not exist.

- [ ] **Step 3: Write minimal implementation**

Create `scripts/prototype/CombatPlane3DService.gd`:

```gdscript
extends RefCounted

static func distance_xz(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))

static func is_in_range_xz(a: Vector3, b: Vector3, radius: float) -> bool:
	return distance_xz(a, b) <= maxf(radius, 0.0)

static func normalize_move_input(input: Vector2) -> Vector2:
	if input.length_squared() <= 0.0001:
		return Vector2.ZERO
	return input.normalized()

static func vector3_from_move_input(input: Vector2, speed: float) -> Vector3:
	var normalized := normalize_move_input(input)
	return Vector3(normalized.x * speed, 0.0, normalized.y * speed)

static func is_inside_attack_arc_xz(origin: Vector3, target: Vector3, forward: Vector3, radius: float, half_angle_degrees: float) -> bool:
	if not is_in_range_xz(origin, target, radius):
		return false
	var to_target := Vector2(target.x - origin.x, target.z - origin.z)
	if to_target.length_squared() <= 0.0001:
		return true
	var forward_xz := Vector2(forward.x, forward.z)
	if forward_xz.length_squared() <= 0.0001:
		forward_xz = Vector2(0.0, -1.0)
	var angle := rad_to_deg(absf(forward_xz.normalized().angle_to(to_target.normalized())))
	return angle <= maxf(half_angle_degrees, 0.0)

static func build_contract_snapshot() -> Dictionary:
	return {
		"plane": "xz",
		"height_axis": "y",
		"collision_basis": "3d_shapes",
		"pickup_basis": "xz_distance",
		"attack_basis": "xz_arc_or_radius",
	}
```

- [ ] **Step 4: Run test to verify it passes**

Run the same command as Step 2.

Expected: PASS and output contains `NEW_PROJECT_COMBAT_PLANE_3D_SERVICE_OK`.

- [ ] **Step 5: Commit**

```powershell
& 'C:\Users\huhej\AppData\Local\GitHubDesktop\app-3.5.12\resources\app\git\cmd\git.exe' add -- scripts/prototype/CombatPlane3DService.gd tests/regression/regression_combat_plane_3d_service.gd
& 'C:\Users\huhej\AppData\Local\GitHubDesktop\app-3.5.12\resources\app\git\cmd\git.exe' commit -m "Add 3D combat plane service"
```

---

### Task 2: Billboard Animation Profile Contract

**Files:**
- Create: `scripts/prototype/BillboardActorAnimationProfile.gd`
- Test: `tests/regression/regression_billboard_actor_animation_profile.gd`

- [ ] **Step 1: Write the failing test**

Create `tests/regression/regression_billboard_actor_animation_profile.gd`:

```gdscript
extends SceneTree

const ProfileScript := preload("res://scripts/prototype/BillboardActorAnimationProfile.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var profile := ProfileScript.new()
	profile.actor_id = "player_warrior_trial"
	profile.art_family = "dark_high_res_pixel_actor"
	profile.directional_target = "4dir_first"
	profile.animation_pipeline = "action_separated"
	profile.weapon_layer_mode = "external_attach"
	profile.body_sprites_must_exclude_weapon = true
	profile.combat_vfx_separated = true
	profile.sprite_sheet_path = "res://assets/generated/actors/candidates/player_warrior_body_down_idle_normalized_v1.png"
	profile.frame_size = Vector2i(96, 96)
	profile.directions = PackedStringArray(["down", "left", "right", "up"])
	profile.actions = PackedStringArray(["idle", "run", "attack", "death"])

	var snapshot := profile.build_manifest_snapshot()
	_expect(str(snapshot.get("actor_id", "")) == "player_warrior_trial", "snapshot should preserve actor id")
	_expect(str(snapshot.get("actor_render_mode", "")) == "sprite3d_billboard", "profile should use sprite3d billboard render mode")
	_expect(str(snapshot.get("directional_target", "")) == "4dir_first", "profile should declare 4dir first")
	_expect(str(snapshot.get("animation_pipeline", "")) == "action_separated", "profile should preserve separated action pipeline")
	_expect(str(snapshot.get("weapon_layer_mode", "")) == "external_attach", "profile should preserve external weapon attach mode")
	_expect(bool(snapshot.get("body_sprites_must_exclude_weapon", false)), "body sprites should exclude baked weapons")
	_expect(bool(snapshot.get("combat_vfx_separated", false)), "combat VFX should remain separated")
	_expect(int(snapshot.get("direction_count", 0)) == 4, "snapshot should count four directions")
	_expect(int(snapshot.get("action_count", 0)) == 4, "snapshot should count four actions")
	_expect(profile.is_valid_for_trial(), "complete profile should be valid for trial")

	var invalid := ProfileScript.new()
	invalid.actor_id = "invalid_actor"
	_expect(not invalid.is_valid_for_trial(), "missing sprite sheet and frame size should be invalid")
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_BILLBOARD_ACTOR_ANIMATION_PROFILE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
& 'C:\Users\huhej\OneDrive\桌面\Godot_v4.6.2-stable_win64_console.exe' --headless --path 'H:\GODOT_PROJECT\dark-tower-2d-arpg' --script 'res://tests/regression/regression_billboard_actor_animation_profile.gd'
```

Expected: FAIL because `BillboardActorAnimationProfile.gd` does not exist.

- [ ] **Step 3: Write minimal implementation**

Create `scripts/prototype/BillboardActorAnimationProfile.gd`:

```gdscript
extends Resource

@export var actor_id: String = ""
@export var actor_render_mode: String = "sprite3d_billboard"
@export var art_family: String = "dark_high_res_pixel_actor"
@export var directional_target: String = "4dir_first"
@export var animation_pipeline: String = "action_separated"
@export var weapon_layer_mode: String = "external_attach"
@export var body_sprites_must_exclude_weapon: bool = true
@export var combat_vfx_separated: bool = true
@export var sprite_sheet_path: String = ""
@export var frame_size: Vector2i = Vector2i.ZERO
@export var directions: PackedStringArray = PackedStringArray(["down", "left", "right", "up"])
@export var actions: PackedStringArray = PackedStringArray(["idle", "run", "attack", "death"])

func is_valid_for_trial() -> bool:
	return actor_id != "" and sprite_sheet_path != "" and frame_size.x > 0 and frame_size.y > 0 and directions.size() >= 4 and actions.size() >= 4

func build_manifest_snapshot() -> Dictionary:
	return {
		"actor_id": actor_id,
		"actor_render_mode": actor_render_mode,
		"art_family": art_family,
		"directional_target": directional_target,
		"animation_pipeline": animation_pipeline,
		"weapon_layer_mode": weapon_layer_mode,
		"body_sprites_must_exclude_weapon": body_sprites_must_exclude_weapon,
		"combat_vfx_separated": combat_vfx_separated,
		"sprite_sheet_path": sprite_sheet_path,
		"frame_size": frame_size,
		"directions": Array(directions),
		"actions": Array(actions),
		"direction_count": directions.size(),
		"action_count": actions.size(),
		"valid_for_trial": is_valid_for_trial(),
	}
```

- [ ] **Step 4: Run test to verify it passes**

Run the same command as Step 2.

Expected: PASS and output contains `NEW_PROJECT_BILLBOARD_ACTOR_ANIMATION_PROFILE_OK`.

- [ ] **Step 5: Commit**

```powershell
& 'C:\Users\huhej\AppData\Local\GitHubDesktop\app-3.5.12\resources\app\git\cmd\git.exe' add -- scripts/prototype/BillboardActorAnimationProfile.gd tests/regression/regression_billboard_actor_animation_profile.gd
& 'C:\Users\huhej\AppData\Local\GitHubDesktop\app-3.5.12\resources\app\git\cmd\git.exe' commit -m "Add billboard actor animation profile"
```

---

### Task 3: Billboard Actor 3D Contract

**Files:**
- Create: `scripts/prototype/BillboardActor3D.gd`
- Test: `tests/regression/regression_billboard_actor_3d_contract.gd`

- [ ] **Step 1: Write the failing test**

Create `tests/regression/regression_billboard_actor_3d_contract.gd`:

```gdscript
extends SceneTree

const BillboardActor3D := preload("res://scripts/prototype/BillboardActor3D.gd")
const ProfileScript := preload("res://scripts/prototype/BillboardActorAnimationProfile.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var actor := BillboardActor3D.new()
	actor.name = "PlayerBillboard"
	root.add_child(actor)
	await process_frame

	_expect(actor is CharacterBody3D, "billboard actor should be a CharacterBody3D")
	_expect(actor.has_node("VisualRoot"), "actor should have VisualRoot")
	_expect(actor.has_node("VisualRoot/ActorSprite"), "actor should have ActorSprite")
	_expect(actor.has_node("VisualRoot/WeaponSprite"), "actor should reserve WeaponSprite")
	_expect(actor.has_node("CollisionShape3D"), "actor should have CollisionShape3D")

	var profile := ProfileScript.new()
	profile.actor_id = "player_warrior_trial"
	profile.sprite_sheet_path = "res://assets/generated/actors/candidates/player_warrior_body_down_idle_normalized_v1.png"
	profile.frame_size = Vector2i(96, 96)
	actor.apply_animation_profile(profile)

	var snapshot := actor.build_contract_snapshot()
	_expect(str(snapshot.get("actor_render_mode", "")) == "sprite3d_billboard", "snapshot should declare sprite3d billboard")
	_expect(str(snapshot.get("plane", "")) == "xz", "snapshot should declare XZ movement plane")
	_expect(bool(snapshot.get("has_collision_shape", false)), "snapshot should confirm collision shape")
	_expect(bool(snapshot.get("has_weapon_sprite", false)), "snapshot should confirm weapon layer")
	_expect(str(snapshot.get("profile_actor_id", "")) == "player_warrior_trial", "snapshot should include profile actor id")

	actor.set_move_input(Vector2(1.0, -1.0))
	actor.set_movement_speed(120.0)
	await process_frame
	var velocity_snapshot := actor.build_contract_snapshot()
	_expect(float(velocity_snapshot.get("movement_speed", 0.0)) == 120.0, "snapshot should expose movement speed")
	_expect(str(velocity_snapshot.get("facing_direction", "")) == "right" or str(velocity_snapshot.get("facing_direction", "")) == "up", "actor should derive a cardinal facing direction")

	actor.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_BILLBOARD_ACTOR_3D_CONTRACT_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
& 'C:\Users\huhej\OneDrive\桌面\Godot_v4.6.2-stable_win64_console.exe' --headless --path 'H:\GODOT_PROJECT\dark-tower-2d-arpg' --script 'res://tests/regression/regression_billboard_actor_3d_contract.gd'
```

Expected: FAIL because `BillboardActor3D.gd` does not exist.

- [ ] **Step 3: Write minimal implementation**

Create `scripts/prototype/BillboardActor3D.gd`:

```gdscript
extends CharacterBody3D

const CombatPlane3DService := preload("res://scripts/prototype/CombatPlane3DService.gd")

var movement_speed: float = 160.0
var move_input: Vector2 = Vector2.ZERO
var facing_direction: String = "down"
var animation_profile: Resource = null

@onready var visual_root: Node3D = $VisualRoot
@onready var actor_sprite: Sprite3D = $VisualRoot/ActorSprite
@onready var weapon_sprite: Sprite3D = $VisualRoot/WeaponSprite
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

func _init() -> void:
	if not has_node("VisualRoot"):
		var root_node := Node3D.new()
		root_node.name = "VisualRoot"
		add_child(root_node)
		var body_sprite := Sprite3D.new()
		body_sprite.name = "ActorSprite"
		body_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		body_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		root_node.add_child(body_sprite)
		var weapon := Sprite3D.new()
		weapon.name = "WeaponSprite"
		weapon.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		weapon.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		root_node.add_child(weapon)
	if not has_node("CollisionShape3D"):
		var shape_node := CollisionShape3D.new()
		shape_node.name = "CollisionShape3D"
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.35
		capsule.height = 1.6
		shape_node.shape = capsule
		add_child(shape_node)

func _physics_process(delta: float) -> void:
	var move_velocity := CombatPlane3DService.vector3_from_move_input(move_input, movement_speed)
	velocity = Vector3(move_velocity.x, velocity.y, move_velocity.z)
	if move_input.length_squared() > 0.0001:
		facing_direction = _direction_from_input(move_input)
	move_and_slide()

func set_move_input(value: Vector2) -> void:
	move_input = CombatPlane3DService.normalize_move_input(value)
	if move_input.length_squared() > 0.0001:
		facing_direction = _direction_from_input(move_input)

func set_movement_speed(value: float) -> void:
	movement_speed = maxf(value, 0.0)

func apply_animation_profile(profile: Resource) -> void:
	animation_profile = profile
	if profile != null and profile.get("sprite_sheet_path") != "":
		var texture := load(str(profile.get("sprite_sheet_path")))
		if texture is Texture2D:
			actor_sprite.texture = texture

func build_contract_snapshot() -> Dictionary:
	var profile_id := ""
	if animation_profile != null:
		profile_id = str(animation_profile.get("actor_id"))
	return {
		"actor_render_mode": "sprite3d_billboard",
		"plane": "xz",
		"has_visual_root": has_node("VisualRoot"),
		"has_actor_sprite": has_node("VisualRoot/ActorSprite"),
		"has_weapon_sprite": has_node("VisualRoot/WeaponSprite"),
		"has_collision_shape": has_node("CollisionShape3D") and collision_shape.shape != null,
		"movement_speed": movement_speed,
		"facing_direction": facing_direction,
		"profile_actor_id": profile_id,
	}

func _direction_from_input(input: Vector2) -> String:
	if absf(input.x) > absf(input.y):
		return "right" if input.x > 0.0 else "left"
	return "down" if input.y > 0.0 else "up"
```

- [ ] **Step 4: Run test to verify it passes**

Run the same command as Step 2.

Expected: PASS and output contains `NEW_PROJECT_BILLBOARD_ACTOR_3D_CONTRACT_OK`.

- [ ] **Step 5: Commit**

```powershell
& 'C:\Users\huhej\AppData\Local\GitHubDesktop\app-3.5.12\resources\app\git\cmd\git.exe' add -- scripts/prototype/BillboardActor3D.gd tests/regression/regression_billboard_actor_3d_contract.gd
& 'C:\Users\huhej\AppData\Local\GitHubDesktop\app-3.5.12\resources\app\git\cmd\git.exe' commit -m "Add 3D billboard actor contract"
```

---

### Task 4: Isolated Prototype Scene Boot

**Files:**
- Create: `scripts/app/Prototype2_5DCombatRoom.gd`
- Create: `scenes/prototypes/Prototype2_5DCombatRoom.tscn`
- Test: `tests/regression/regression_prototype_2_5d_scene_contract.gd`

- [ ] **Step 1: Write the failing test**

Create `tests/regression/regression_prototype_2_5d_scene_contract.gd`:

```gdscript
extends SceneTree

const PrototypeScene := preload("res://scenes/prototypes/Prototype2_5DCombatRoom.tscn")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := PrototypeScene.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	_expect(scene.has_method("build_prototype_snapshot_for_test"), "prototype should expose test snapshot")
	var snapshot: Dictionary = scene.call("build_prototype_snapshot_for_test")
	_expect(str(snapshot.get("prototype_id", "")) == "2_5d_billboard_combat_room", "snapshot should identify prototype")
	_expect(bool(snapshot.get("isolated_from_main_flow", false)), "prototype should stay isolated from main flow")
	_expect(bool(snapshot.get("has_camera_3d", false)), "prototype should have Camera3D")
	_expect(bool(snapshot.get("camera_orthographic", false)), "camera should be orthographic")
	_expect(int(snapshot.get("wall_count", 0)) >= 4, "prototype should have at least four wall blockers")
	_expect(int(snapshot.get("column_count", 0)) >= 2, "prototype should have at least two columns")
	_expect(int(snapshot.get("player_count", 0)) == 1, "prototype should have one player actor")
	_expect(int(snapshot.get("enemy_count", 0)) == 2, "prototype should have two enemies")
	_expect(bool(snapshot.get("has_exit_marker", false)), "prototype should have an exit marker")

	scene.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_PROTOTYPE_2_5D_SCENE_CONTRACT_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
& 'C:\Users\huhej\OneDrive\桌面\Godot_v4.6.2-stable_win64_console.exe' --headless --path 'H:\GODOT_PROJECT\dark-tower-2d-arpg' --script 'res://tests/regression/regression_prototype_2_5d_scene_contract.gd'
```

Expected: FAIL because `scenes/prototypes/Prototype2_5DCombatRoom.tscn` does not exist.

- [ ] **Step 3: Write minimal implementation**

Create `scripts/app/Prototype2_5DCombatRoom.gd`:

```gdscript
extends Node3D

const BillboardActor3D := preload("res://scripts/prototype/BillboardActor3D.gd")

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
```

Create `scenes/prototypes/Prototype2_5DCombatRoom.tscn`:

```text
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/app/Prototype2_5DCombatRoom.gd" id="1_prototype"]

[node name="Prototype2_5DCombatRoom" type="Node3D"]
script = ExtResource("1_prototype")
```

- [ ] **Step 4: Run test to verify it passes**

Run the same command as Step 2.

Expected: PASS and output contains `NEW_PROJECT_PROTOTYPE_2_5D_SCENE_CONTRACT_OK`.

- [ ] **Step 5: Commit**

```powershell
& 'C:\Users\huhej\AppData\Local\GitHubDesktop\app-3.5.12\resources\app\git\cmd\git.exe' add -- scripts/app/Prototype2_5DCombatRoom.gd scenes/prototypes/Prototype2_5DCombatRoom.tscn tests/regression/regression_prototype_2_5d_scene_contract.gd
& 'C:\Users\huhej\AppData\Local\GitHubDesktop\app-3.5.12\resources\app\git\cmd\git.exe' commit -m "Add isolated 2.5D combat room prototype"
```

---

### Task 5: Visual QA Snapshot Contract

**Files:**
- Create: `scripts/prototype/Prototype2_5DVisualQaService.gd`
- Modify: `scripts/app/Prototype2_5DCombatRoom.gd`
- Test: `tests/regression/regression_prototype_2_5d_visual_qa_contract.gd`

- [ ] **Step 1: Write the failing test**

Create `tests/regression/regression_prototype_2_5d_visual_qa_contract.gd`:

```gdscript
extends SceneTree

const PrototypeScene := preload("res://scenes/prototypes/Prototype2_5DCombatRoom.tscn")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := PrototypeScene.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	_expect(scene.has_method("build_visual_qa_snapshot_for_test"), "prototype should expose visual QA snapshot")
	var snapshot: Dictionary = scene.call("build_visual_qa_snapshot_for_test")
	_expect(str(snapshot.get("qa_id", "")) == "prototype_2_5d_visual_readability", "snapshot should identify visual QA")
	_expect(bool(snapshot.get("camera_has_readable_angle", false)), "camera angle should be accepted")
	_expect(bool(snapshot.get("room_has_boundaries", false)), "room should expose boundaries")
	_expect(bool(snapshot.get("actors_have_billboard_contract", false)), "actors should expose billboard contract")
	_expect(bool(snapshot.get("columns_have_collision_footprint", false)), "columns should have collision footprint")
	_expect(bool(snapshot.get("main_flow_untouched", false)), "prototype should confirm main flow remains untouched")

	scene.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_PROTOTYPE_2_5D_VISUAL_QA_CONTRACT_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
& 'C:\Users\huhej\OneDrive\桌面\Godot_v4.6.2-stable_win64_console.exe' --headless --path 'H:\GODOT_PROJECT\dark-tower-2d-arpg' --script 'res://tests/regression/regression_prototype_2_5d_visual_qa_contract.gd'
```

Expected: FAIL because `build_visual_qa_snapshot_for_test()` is not implemented.

- [ ] **Step 3: Write minimal implementation**

Create `scripts/prototype/Prototype2_5DVisualQaService.gd`:

```gdscript
extends RefCounted

static func build_snapshot(scene_snapshot: Dictionary, actor_snapshots: Array[Dictionary]) -> Dictionary:
	var actor_contracts_valid := not actor_snapshots.is_empty()
	for actor_snapshot in actor_snapshots:
		actor_contracts_valid = actor_contracts_valid and str(actor_snapshot.get("actor_render_mode", "")) == "sprite3d_billboard"
		actor_contracts_valid = actor_contracts_valid and str(actor_snapshot.get("plane", "")) == "xz"
	return {
		"qa_id": "prototype_2_5d_visual_readability",
		"camera_has_readable_angle": bool(scene_snapshot.get("camera_orthographic", false)) and bool(scene_snapshot.get("has_camera_3d", false)),
		"room_has_boundaries": int(scene_snapshot.get("wall_count", 0)) >= 4,
		"actors_have_billboard_contract": actor_contracts_valid,
		"columns_have_collision_footprint": int(scene_snapshot.get("column_count", 0)) >= 2,
		"main_flow_untouched": bool(scene_snapshot.get("isolated_from_main_flow", false)),
		"acceptance_summary": "camera room actors columns isolation",
	}
```

Modify `scripts/app/Prototype2_5DCombatRoom.gd` by adding the preload and method:

```gdscript
const Prototype2_5DVisualQaService := preload("res://scripts/prototype/Prototype2_5DVisualQaService.gd")
```

```gdscript
func build_visual_qa_snapshot_for_test() -> Dictionary:
	var actor_snapshots: Array[Dictionary] = []
	if player != null and player.has_method("build_contract_snapshot"):
		actor_snapshots.append(player.call("build_contract_snapshot"))
	for enemy in enemies:
		if enemy != null and enemy.has_method("build_contract_snapshot"):
			actor_snapshots.append(enemy.call("build_contract_snapshot"))
	return Prototype2_5DVisualQaService.build_snapshot(build_prototype_snapshot_for_test(), actor_snapshots)
```

- [ ] **Step 4: Run test to verify it passes**

Run the same command as Step 2.

Expected: PASS and output contains `NEW_PROJECT_PROTOTYPE_2_5D_VISUAL_QA_CONTRACT_OK`.

- [ ] **Step 5: Commit**

```powershell
& 'C:\Users\huhej\AppData\Local\GitHubDesktop\app-3.5.12\resources\app\git\cmd\git.exe' add -- scripts/prototype/Prototype2_5DVisualQaService.gd scripts/app/Prototype2_5DCombatRoom.gd tests/regression/regression_prototype_2_5d_visual_qa_contract.gd
& 'C:\Users\huhej\AppData\Local\GitHubDesktop\app-3.5.12\resources\app\git\cmd\git.exe' commit -m "Add 2.5D prototype visual QA contract"
```

---

### Task 6: Prototype Regression Bundle and Progress Record

**Files:**
- Create: `docs/progress/2026-06-16-2-5d-billboard-prototype-progress.md`
- Modify: `tests/regression/regression_scene_boot.gd`

- [ ] **Step 1: Write the failing scene boot extension**

Modify `tests/regression/regression_scene_boot.gd` by adding the prototype path to `SCENES`:

```gdscript
const SCENES := [
	"res://scenes/MainMenu.tscn",
	"res://scenes/CharacterSelect.tscn",
	"res://scenes/Town.tscn",
	"res://scenes/Game2D.tscn",
	"res://scenes/prototypes/Prototype2_5DCombatRoom.tscn",
]
```

- [ ] **Step 2: Run scene boot to verify current state**

Run:

```powershell
& 'C:\Users\huhej\OneDrive\桌面\Godot_v4.6.2-stable_win64_console.exe' --headless --path 'H:\GODOT_PROJECT\dark-tower-2d-arpg' --script 'res://tests/regression/regression_scene_boot.gd'
```

Expected after Tasks 1-5: PASS and output contains `NEW_PROJECT_SCENE_BOOT_ALL_OK`.

- [ ] **Step 3: Run the focused 2.5D regression bundle**

Run:

```powershell
$godot = 'C:\Users\huhej\OneDrive\桌面\Godot_v4.6.2-stable_win64_console.exe'
$project = 'H:\GODOT_PROJECT\dark-tower-2d-arpg'
$checks = @(
  'res://tests/regression/regression_combat_plane_3d_service.gd',
  'res://tests/regression/regression_billboard_actor_animation_profile.gd',
  'res://tests/regression/regression_billboard_actor_3d_contract.gd',
  'res://tests/regression/regression_prototype_2_5d_scene_contract.gd',
  'res://tests/regression/regression_prototype_2_5d_visual_qa_contract.gd',
  'res://tests/regression/regression_scene_boot.gd'
)
foreach ($check in $checks) {
  Write-Host "RUN $check"
  & $godot --headless --path $project --script $check
  if ($LASTEXITCODE -ne 0) {
    Write-Host "FAILED $check EXIT $LASTEXITCODE"
    exit $LASTEXITCODE
  }
}
Write-Host 'NEW_PROJECT_2_5D_PROTOTYPE_REGRESSION_OK'
```

Expected: PASS and output contains `NEW_PROJECT_2_5D_PROTOTYPE_REGRESSION_OK`.

- [ ] **Step 4: Write progress record**

Create `docs/progress/2026-06-16-2-5d-billboard-prototype-progress.md`:

```markdown
# 2026-06-16 2.5D 纸片角色原型进度

## 本轮目标

建立一个独立 2.5D 原型切片，用于验证“3D 房间 + 2D Sprite3D 角色”的方向是否值得正式迁移。

## 已完成

- 新增 XZ 平面战斗数学服务。
- 新增 2D billboard 角色动画 profile 契约。
- 新增 Sprite3D billboard 角色节点契约。
- 新增独立 2.5D 战斗房间原型场景。
- 新增视觉 QA 快照契约。
- 将原型场景纳入 scene boot，但未接入主菜单和正式流程。

## 保护边界

- 未清空、覆盖或迁移玩家存档。
- 未修改主菜单入口。
- 未替换当前正式 `Game2D.tscn`。
- 未把背包、装备、主城、商人、仓库系统迁入 3D。

## 验证

```text
NEW_PROJECT_2_5D_PROTOTYPE_REGRESSION_OK
NEW_PROJECT_SCENE_BOOT_ALL_OK
```

## 下一步建议

使用 Godot 编辑器或截图工具观察 `res://scenes/prototypes/Prototype2_5DCombatRoom.tscn` 的实际画面。如果空间、遮挡和角色纸片感可接受，再进入“玩家可控移动 + 敌人追击 + 清怪出口”的第二轮原型。
```

- [ ] **Step 5: Commit**

```powershell
& 'C:\Users\huhej\AppData\Local\GitHubDesktop\app-3.5.12\resources\app\git\cmd\git.exe' add -- tests/regression/regression_scene_boot.gd docs/progress/2026-06-16-2-5d-billboard-prototype-progress.md
& 'C:\Users\huhej\AppData\Local\GitHubDesktop\app-3.5.12\resources\app\git\cmd\git.exe' commit -m "Record 2.5D prototype verification"
```

---

## Final Verification

After all tasks complete, run:

```powershell
$godot = 'C:\Users\huhej\OneDrive\桌面\Godot_v4.6.2-stable_win64_console.exe'
$project = 'H:\GODOT_PROJECT\dark-tower-2d-arpg'
$tests = Get-ChildItem -Path "$project\tests\regression" -File -Filter '*.gd' | Sort-Object Name | ForEach-Object { 'res://tests/regression/' + $_.Name }
foreach ($test in $tests) {
  Write-Host "RUN $test"
  & $godot --headless --path $project --script $test
  if ($LASTEXITCODE -ne 0) {
    Write-Host "FAILED $test EXIT $LASTEXITCODE"
    exit $LASTEXITCODE
  }
}
Write-Host 'ALL_NEW_PROJECT_REGRESSION_OK'
```

Expected: output contains `ALL_NEW_PROJECT_REGRESSION_OK`.

Check for leftover headless Godot test processes:

```powershell
Get-CimInstance Win32_Process | Where-Object { $_.Name -like 'Godot_v4.6.2-stable_win64*' } | Select-Object ProcessId,Name,CommandLine
```

Expected: no lingering process with `--headless` in `CommandLine`.

Push after final verification:

```powershell
& 'C:\Users\huhej\AppData\Local\GitHubDesktop\app-3.5.12\resources\app\git\cmd\git.exe' push origin codex/pixel-actor-art-trial
```
