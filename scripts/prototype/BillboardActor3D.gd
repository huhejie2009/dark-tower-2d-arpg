extends CharacterBody3D

const CombatPlane3DService := preload("res://scripts/prototype/CombatPlane3DService.gd")

var movement_speed: float = 160.0
var move_input: Vector2 = Vector2.ZERO
var facing_direction: String = "down"
var action_state: String = "idle"
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

func _physics_process(_delta: float) -> void:
	var move_velocity := CombatPlane3DService.vector3_from_move_input(move_input, movement_speed)
	velocity = Vector3(move_velocity.x, velocity.y, move_velocity.z)
	if move_input.length_squared() > 0.0001:
		facing_direction = _direction_from_input(move_input)
	if action_state != "attack" and action_state != "death":
		action_state = "run" if move_input.length_squared() > 0.0001 else "idle"
	move_and_slide()

func set_move_input(value: Vector2) -> void:
	move_input = CombatPlane3DService.normalize_move_input(value)
	if move_input.length_squared() > 0.0001:
		facing_direction = _direction_from_input(move_input)

func set_movement_speed(value: float) -> void:
	movement_speed = maxf(value, 0.0)

func set_action_state(value: String) -> void:
	var normalized := value.strip_edges()
	action_state = normalized if normalized != "" else "idle"

func get_action_state() -> String:
	return action_state

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
		"action_state": action_state,
		"profile_actor_id": profile_id,
	}

func _direction_from_input(input: Vector2) -> String:
	if absf(input.x) > absf(input.y):
		return "right" if input.x > 0.0 else "left"
	return "down" if input.y > 0.0 else "up"
