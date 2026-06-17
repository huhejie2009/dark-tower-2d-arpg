extends CharacterBody3D

const CombatPlane3DService := preload("res://scripts/prototype/CombatPlane3DService.gd")

var movement_speed: float = 160.0
var move_input: Vector2 = Vector2.ZERO
var facing_direction: String = "down"
var action_state: String = "idle"
var animation_profile: Resource = null
var visual_asset_manifest: Dictionary = {}
var actor_animation_name := "idle"
var actor_animation_frame := 0
var actor_animation_elapsed := 0.0
var actor_animation_locked_until_end := false

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
	update_actor_animation_state(move_input, action_state == "attack", action_state == "death")
	tick_actor_animation(_delta)
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
	update_actor_animation_state(move_input, action_state == "attack", action_state == "death")

func get_action_state() -> String:
	return action_state

func apply_animation_profile(profile: Resource) -> void:
	animation_profile = profile
	if profile != null and profile.has_method("to_visual_asset_manifest"):
		apply_visual_asset_manifest(profile.call("to_visual_asset_manifest"))
		return
	if profile != null and profile.get("sprite_sheet_path") != "":
		apply_visual_asset_manifest({
			"enabled": true,
			"sprite_sheet_path": str(profile.get("sprite_sheet_path")),
			"frame_size": profile.get("frame_size"),
			"direction_mode": "4dir",
			"direction_frame_offsets": {
				"down": 0,
				"left": 0,
				"right": 0,
				"up": 0,
			},
			"animations": {
				"idle": {"from": 0, "to": 0, "fps": 8, "loop": true},
				"run": {"from": 0, "to": 0, "fps": 10, "loop": true},
				"attack": {"from": 0, "to": 0, "fps": 12, "loop": false},
				"death": {"from": 0, "to": 0, "fps": 8, "loop": false},
			},
		})

func apply_visual_asset_manifest(manifest: Dictionary) -> void:
	visual_asset_manifest = manifest.duplicate(true)
	if actor_sprite != null:
		actor_sprite.visible = bool(visual_asset_manifest.get("enabled", false))
		actor_sprite.region_enabled = true
		_apply_actor_sprite_filter()
		_load_actor_sprite_texture()
	var animations := Dictionary(visual_asset_manifest.get("animations", {}))
	if animations.has("idle"):
		set_actor_animation("idle", true)

func get_visual_asset_manifest() -> Dictionary:
	return visual_asset_manifest.duplicate(true)

func set_actor_animation(animation_name: String, force_restart: bool = false, lock_until_end: bool = false) -> void:
	var animations := Dictionary(visual_asset_manifest.get("animations", {}))
	if not animations.has(animation_name):
		return
	if actor_animation_name == animation_name and not force_restart:
		return
	actor_animation_name = animation_name
	var animation := Dictionary(animations.get(animation_name, {}))
	actor_animation_frame = int(animation.get("from", 0))
	actor_animation_elapsed = 0.0
	actor_animation_locked_until_end = lock_until_end
	_apply_actor_sprite_region()

func advance_actor_animation() -> void:
	var animation := _get_current_animation_data()
	if animation.is_empty():
		return
	var from_frame := int(animation.get("from", actor_animation_frame))
	var to_frame := int(animation.get("to", from_frame))
	actor_animation_frame += 1
	if actor_animation_frame > to_frame:
		if _is_current_animation_one_shot():
			actor_animation_frame = to_frame
			actor_animation_locked_until_end = actor_animation_name == "attack" or actor_animation_name == "death"
		else:
			actor_animation_frame = from_frame
	_apply_actor_sprite_region()

func tick_actor_animation(delta: float) -> void:
	var animation := _get_current_animation_data()
	if animation.is_empty():
		return
	var fps := float(animation.get("fps", 0.0))
	if fps <= 0.0:
		return
	actor_animation_elapsed += maxf(0.0, delta)
	var frame_duration := 1.0 / fps
	while actor_animation_elapsed >= frame_duration:
		actor_animation_elapsed -= frame_duration
		advance_actor_animation()

func update_actor_animation_state(movement: Vector2, attacking: bool, dead: bool = false) -> void:
	if movement.length_squared() > 0.001:
		facing_direction = _direction_from_input(movement)
	var animations := Dictionary(visual_asset_manifest.get("animations", {}))
	if dead and animations.has("death"):
		set_actor_animation("death", true, true)
		action_state = "death"
		return
	if actor_animation_locked_until_end:
		if actor_animation_name == "death" or attacking:
			return
		actor_animation_locked_until_end = false
	if attacking and animations.has("attack"):
		set_actor_animation("attack", true, true)
		action_state = "attack"
	elif movement.length_squared() > 0.001 and animations.has("run"):
		set_actor_animation("run")
		action_state = "run"
	elif animations.has("idle"):
		set_actor_animation("idle")
		action_state = "idle"

func get_actor_animation_state() -> Dictionary:
	return {
		"animation": actor_animation_name,
		"frame_index": actor_animation_frame,
		"resolved_frame_index": _get_resolved_actor_frame_index(),
		"frame_size": visual_asset_manifest.get("frame_size", Vector2i.ZERO),
		"sprite_sheet_path": str(visual_asset_manifest.get("sprite_sheet_path", "")),
		"asset_pipeline": str(visual_asset_manifest.get("asset_pipeline", "")),
		"pose_variation_version": str(visual_asset_manifest.get("pose_variation_version", "")),
		"texture_filter": str(visual_asset_manifest.get("texture_filter", "")),
		"direction_mode": str(visual_asset_manifest.get("direction_mode", "")),
		"facing_direction": facing_direction,
		"action_state": action_state,
		"animation_locked_until_end": actor_animation_locked_until_end,
		"body_weapon_separated": has_node("VisualRoot/ActorSprite") and has_node("VisualRoot/WeaponSprite") and actor_sprite != weapon_sprite,
		"actor_sprite_visible": actor_sprite != null and actor_sprite.visible,
		"actor_sprite_texture_loaded": actor_sprite != null and actor_sprite.texture != null,
		"actor_sprite_region_enabled": actor_sprite != null and actor_sprite.region_enabled,
		"actor_sprite_region_rect": actor_sprite.region_rect if actor_sprite != null else Rect2(),
	}

func apply_visual_asset_manifest_for_test(manifest: Dictionary) -> void:
	apply_visual_asset_manifest(manifest)

func set_actor_animation_for_test(animation_name: String) -> void:
	set_actor_animation(animation_name)

func advance_actor_animation_for_test() -> void:
	advance_actor_animation()

func tick_actor_animation_for_test(delta: float) -> void:
	tick_actor_animation(delta)

func get_actor_animation_state_for_test() -> Dictionary:
	return get_actor_animation_state()

func update_actor_animation_state_for_test(movement: Vector2, attacking: bool, dead: bool = false) -> void:
	update_actor_animation_state(movement, attacking, dead)

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
		"actor_animation_name": actor_animation_name,
		"actor_animation_frame": actor_animation_frame,
		"profile_actor_id": profile_id,
	}

func _direction_from_input(input: Vector2) -> String:
	if absf(input.x) > absf(input.y):
		return "right" if input.x > 0.0 else "left"
	return "down" if input.y > 0.0 else "up"

func _get_current_animation_data() -> Dictionary:
	var animations := Dictionary(visual_asset_manifest.get("animations", {}))
	return Dictionary(animations.get(actor_animation_name, {}))

func _is_current_animation_one_shot() -> bool:
	var animation := _get_current_animation_data()
	if animation.has("loop"):
		return not bool(animation.get("loop", true))
	return actor_animation_name == "attack" or actor_animation_name == "death"

func _get_direction_frame_offset() -> int:
	var direction_mode := str(visual_asset_manifest.get("direction_mode", "runtime_flip_2dir"))
	if direction_mode != "4dir" and direction_mode != "8dir":
		return 0
	var offsets := Dictionary(visual_asset_manifest.get("direction_frame_offsets", {}))
	return int(offsets.get(facing_direction, 0))

func _get_resolved_actor_frame_index() -> int:
	return _get_direction_frame_offset() + actor_animation_frame

func _apply_actor_sprite_region() -> void:
	if actor_sprite == null:
		return
	var frame_size: Vector2i = visual_asset_manifest.get("frame_size", Vector2i.ZERO)
	if frame_size.x <= 0 or frame_size.y <= 0:
		return
	actor_sprite.region_enabled = true
	actor_sprite.region_rect = Rect2(Vector2(_get_resolved_actor_frame_index() * frame_size.x, 0.0), Vector2(frame_size))

func _load_actor_sprite_texture() -> void:
	if actor_sprite == null:
		return
	var path := str(visual_asset_manifest.get("sprite_sheet_path", ""))
	if path == "":
		return
	if path.begins_with("res://") and ResourceLoader.exists(path):
		var texture := load(path)
		if texture is Texture2D:
			actor_sprite.texture = texture
			return
	if not FileAccess.file_exists(path):
		return
	var image := Image.new()
	if image.load(ProjectSettings.globalize_path(path)) != OK:
		return
	actor_sprite.texture = ImageTexture.create_from_image(image)

func _apply_actor_sprite_filter() -> void:
	if actor_sprite == null:
		return
	var filter := str(visual_asset_manifest.get("texture_filter", "nearest"))
	if filter == "nearest":
		actor_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	else:
		actor_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
