extends CharacterBody2D
class_name Player2D

const ClassRulesScript := preload("res://scripts/rules/ClassRules.gd")
const Skill2DLibraryScript := preload("res://scripts/combat/Skill2DLibrary.gd")
const CombatFeelServiceScript := preload("res://scripts/data/CombatFeelService.gd")
const DamageFeedbackServiceScript := preload("res://scripts/data/DamageFeedbackService.gd")
const PROCEDURAL_VISUAL_NAMES := ["PlayerBody", "PlayerBodyOutline", "PlayerFacingHint"]

signal died
signal health_changed(current: int, maximum: int)

@export var move_speed := 280.0

var player_data: Dictionary = {}
var move_vector := Vector2.ZERO
var attack_ready := true
var attack_cooldown_remaining := 0.0
var attack_feel_profile: Dictionary = {}
var attack_phase := "ready"
var attack_elapsed := 0.0
var buffered_attack := false
var buffered_attack_direction := Vector2.RIGHT
var health := 120
var max_health := 120
var attack_damage := 24
var basic_skill_id := "warrior_cleave"
var visual_asset_manifest: Dictionary = {}
var actor_visual_root: Node2D
var actor_sprite: Sprite2D
var actor_animation_name := "idle"
var actor_animation_frame := 0
var actor_animation_elapsed := 0.0
var death_animation_triggered := false
var facing_direction := Vector2.RIGHT
var last_move_direction := Vector2.RIGHT
var footstep_offset_x := 0.0
var last_damage_feedback: Dictionary = {}
var damage_stagger_remaining := 0.0
var damage_hit_flash_remaining := 0.0

func _ready() -> void:
	_create_collision()
	_create_visuals()
	_refresh_attack_feel_profile()
	health_changed.emit(health, max_health)

func apply_player_data(data: Dictionary) -> void:
	player_data = data.duplicate(true)
	var class_data := ClassRulesScript.get_class_data(str(player_data.get("base_class", "warrior")))
	max_health = int(player_data.get("max_health", class_data.get("max_health", 120)))
	health = clampi(int(player_data.get("health", max_health)), 1, max_health)
	attack_damage = int(player_data.get("attack_damage", class_data.get("attack_damage", 24)))
	basic_skill_id = str(class_data.get("basic_skill", "warrior_cleave"))
	_refresh_attack_feel_profile()
	health_changed.emit(health, max_health)

func export_player_patch() -> Dictionary:
	var patch := player_data.duplicate(true)
	patch["health"] = health
	patch["max_health"] = max_health
	patch["attack_damage"] = attack_damage
	return patch

func _physics_process(delta: float) -> void:
	_tick_attack_feel(delta)
	_tick_damage_feedback(delta)
	update_actor_animation_state(move_vector, attack_phase != "ready")
	tick_actor_animation(delta)
	velocity = move_vector.normalized() * move_speed
	if damage_stagger_remaining > 0.0:
		velocity *= 0.35
	move_and_slide()

func set_move_vector(value: Vector2) -> void:
	move_vector = value
	if move_vector.length_squared() > 0.001:
		last_move_direction = move_vector.normalized()
		facing_direction = last_move_direction
	update_actor_animation_state(move_vector, attack_phase != "ready")

func face_world_position(world_position: Vector2) -> void:
	var direction := world_position - global_position
	if direction.length_squared() > 0.001:
		facing_direction = direction.normalized()

func cast_basic(direction: Vector2) -> Dictionary:
	_refresh_attack_feel_profile()
	if not attack_ready:
		if direction.length_squared() <= 0.001:
			direction = facing_direction
		buffered_attack = true
		buffered_attack_direction = direction.normalized()
		return {
			"skill_id": basic_skill_id,
			"hit_count": 0,
			"cooldown": attack_cooldown_remaining,
			"accepted": false,
			"buffered": true,
			"attack_phase": attack_phase,
			"input_buffer": float(attack_feel_profile.get("input_buffer", 0.0)),
		}
	attack_ready = false
	if direction.length_squared() <= 0.001:
		direction = facing_direction
	var result := Skill2DLibraryScript.cast_basic_skill(self, basic_skill_id, direction, attack_damage)
	_start_attack_feel()
	attack_cooldown_remaining = float(attack_feel_profile.get("cooldown", result.get("cooldown", 0.35)))
	result["cooldown"] = attack_cooldown_remaining
	result["accepted"] = true
	result["buffered"] = false
	result["attack_phase"] = attack_phase
	result["windup"] = float(attack_feel_profile.get("windup", 0.0))
	result["hit_frame"] = float(attack_feel_profile.get("hit_frame", 0.0))
	result["recovery"] = float(attack_feel_profile.get("recovery", 0.0))
	result["input_buffer"] = float(attack_feel_profile.get("input_buffer", 0.0))
	result["hit_stop"] = float(attack_feel_profile.get("hit_stop", 0.0))
	return result

func _refresh_attack_feel_profile() -> void:
	attack_feel_profile = CombatFeelServiceScript.get_basic_attack_feel(basic_skill_id)

func _start_attack_feel() -> void:
	attack_phase = "windup"
	attack_elapsed = 0.0

func _tick_attack_feel(delta: float) -> void:
	if attack_ready:
		attack_phase = "ready"
		return
	attack_elapsed += maxf(0.0, delta)
	attack_cooldown_remaining = maxf(0.0, attack_cooldown_remaining - delta)
	var windup := float(attack_feel_profile.get("windup", 0.08))
	var hit_frame := float(attack_feel_profile.get("hit_frame", 0.12))
	var recovery := float(attack_feel_profile.get("recovery", 0.18))
	var active_end := maxf(hit_frame, windup + 0.04)
	var recovery_start := maxf(windup, active_end)
	var recovery_end := maxf(float(attack_feel_profile.get("cooldown", 0.35)), recovery_start + recovery)
	if attack_elapsed < windup:
		attack_phase = "windup"
	elif attack_elapsed < recovery_start:
		attack_phase = "active"
	elif attack_elapsed < recovery_end and attack_cooldown_remaining > 0.0:
		attack_phase = "recovery"
	else:
		attack_ready = true
		attack_cooldown_remaining = 0.0
		attack_phase = "ready"
		if buffered_attack:
			var buffered_direction := buffered_attack_direction
			buffered_attack = false
			cast_basic(buffered_direction)

func take_damage(amount: int, attacker: Node = null) -> void:
	health = max(0, health - max(0, amount))
	_apply_damage_feedback(amount, attacker)
	health_changed.emit(health, max_health)
	if health <= 0:
		_trigger_death_animation()
		died.emit()

func _apply_damage_feedback(amount: int, attacker: Node = null) -> void:
	var source_direction := Vector2.ZERO
	if is_instance_valid(attacker) and attacker is Node2D:
		source_direction = global_position - (attacker as Node2D).global_position
	last_damage_feedback = DamageFeedbackServiceScript.build_damage_feedback("player", amount, max_health, source_direction)
	damage_stagger_remaining = float(last_damage_feedback.get("stagger_duration", 0.0))
	damage_hit_flash_remaining = float(last_damage_feedback.get("hit_flash_duration", 0.0))
	var knockback_direction: Vector2 = last_damage_feedback.get("source_direction", Vector2.ZERO)
	var knockback_distance := float(last_damage_feedback.get("knockback_distance", 0.0))
	if knockback_direction.length_squared() > 0.001 and knockback_distance > 0.0:
		global_position += knockback_direction.normalized() * knockback_distance

func _tick_damage_feedback(delta: float) -> void:
	var safe_delta := maxf(0.0, delta)
	damage_stagger_remaining = maxf(0.0, damage_stagger_remaining - safe_delta)
	damage_hit_flash_remaining = maxf(0.0, damage_hit_flash_remaining - safe_delta)

func _create_collision() -> void:
	var shape := CircleShape2D.new()
	shape.radius = 20.0
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)

func _create_visuals() -> void:
	_create_actor_visual_asset_slot()

	var shadow := Polygon2D.new()
	shadow.name = "PlayerShadow"
	shadow.z_index = -2
	shadow.polygon = PackedVector2Array([
		Vector2(-24, 12),
		Vector2(-8, 5),
		Vector2(18, 5),
		Vector2(30, 12),
		Vector2(18, 19),
		Vector2(-10, 19),
	])
	shadow.color = Color(0.0, 0.0, 0.0, 0.34)
	add_child(shadow)

	var body := Polygon2D.new()
	body.name = "PlayerBody"
	body.polygon = PackedVector2Array([
		Vector2(24, -7),
		Vector2(10, -25),
		Vector2(-15, -20),
		Vector2(-23, 0),
		Vector2(-12, 23),
		Vector2(12, 22),
		Vector2(28, 5),
	])
	body.color = Color(0.22, 0.62, 0.86, 1.0)
	add_child(body)
	var outline := Line2D.new()
	outline.name = "PlayerBodyOutline"
	outline.width = 3.0
	outline.closed = true
	outline.default_color = Color(0.02, 0.012, 0.01, 1.0)
	outline.points = body.polygon
	add_child(outline)

	var facing_hint := Polygon2D.new()
	facing_hint.name = "PlayerFacingHint"
	facing_hint.polygon = PackedVector2Array([
		Vector2(18, -5),
		Vector2(34, 0),
		Vector2(18, 5),
	])
	facing_hint.color = Color(0.95, 0.88, 0.50, 1.0)
	add_child(facing_hint)

func _create_actor_visual_asset_slot() -> void:
	actor_visual_root = Node2D.new()
	actor_visual_root.name = "ActorVisualRoot"
	actor_visual_root.z_index = 2
	add_child(actor_visual_root)
	actor_sprite = Sprite2D.new()
	actor_sprite.name = "ActorSprite"
	actor_sprite.visible = false
	actor_visual_root.add_child(actor_sprite)

func apply_visual_asset_manifest(manifest: Dictionary) -> void:
	visual_asset_manifest = manifest.duplicate(true)
	if is_instance_valid(actor_sprite):
		actor_sprite.visible = bool(visual_asset_manifest.get("enabled", false))
		actor_sprite.region_enabled = true
		_load_actor_sprite_texture()
	_update_procedural_visual_visibility()
	var animations := Dictionary(visual_asset_manifest.get("animations", {}))
	if animations.has("idle"):
		set_actor_animation("idle", true)

func get_visual_asset_manifest() -> Dictionary:
	return visual_asset_manifest.duplicate(true)

func set_actor_animation(animation_name: String, force_restart: bool = false) -> void:
	var animations := Dictionary(visual_asset_manifest.get("animations", {}))
	if not animations.has(animation_name):
		return
	if actor_animation_name == animation_name and not force_restart:
		return
	actor_animation_name = animation_name
	var animation := Dictionary(animations.get(animation_name, {}))
	actor_animation_frame = int(animation.get("from", 0))
	actor_animation_elapsed = 0.0
	_apply_actor_sprite_region()

func advance_actor_animation() -> void:
	var animation := _get_current_animation_data()
	if animation.is_empty():
		return
	var from_frame := int(animation.get("from", actor_animation_frame))
	var to_frame := int(animation.get("to", from_frame))
	actor_animation_frame += 1
	if actor_animation_frame > to_frame:
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
	_update_actor_animation_presentation()

func get_actor_animation_state() -> Dictionary:
	return {
		"animation": actor_animation_name,
		"frame_index": actor_animation_frame,
		"resolved_frame_index": _get_resolved_actor_frame_index(),
		"frame_size": visual_asset_manifest.get("frame_size", Vector2i.ZERO),
		"sprite_sheet_path": str(visual_asset_manifest.get("sprite_sheet_path", "")),
		"death_animation_triggered": death_animation_triggered,
	}

func update_actor_animation_state(movement: Vector2, attacking: bool) -> void:
	var animations := Dictionary(visual_asset_manifest.get("animations", {}))
	if attacking and animations.has("attack"):
		set_actor_animation("attack")
	elif movement.length_squared() > 0.001 and animations.has("run"):
		set_actor_animation("run")
	elif animations.has("idle"):
		set_actor_animation("idle")
	_update_actor_animation_presentation()

func _update_actor_animation_presentation() -> void:
	if not is_instance_valid(actor_visual_root):
		return
	actor_visual_root.position = Vector2.ZERO
	actor_visual_root.rotation = 0.0
	actor_visual_root.scale = Vector2.ONE
	actor_visual_root.modulate = Color(1, 1, 1, 1)
	footstep_offset_x = 0.0
	if is_instance_valid(actor_sprite):
		actor_sprite.position = Vector2.ZERO
		actor_sprite.flip_h = _should_flip_sprite_for_facing()
	if damage_hit_flash_remaining > 0.0:
		actor_visual_root.modulate = Color(1.35, 1.35, 1.35, 1.0)
	var progress := _get_current_animation_progress()
	match actor_animation_name:
		"idle":
			actor_visual_root.position.y = sin(actor_animation_elapsed * TAU * 0.8) * 1.0
		"run":
			var phase := float(actor_animation_frame - int(_get_current_animation_data().get("from", actor_animation_frame))) * PI * 0.72
			footstep_offset_x = sin(phase) * 2.4
			actor_visual_root.position = Vector2(footstep_offset_x, -2.0 + absf(cos(phase)) * 2.0)
			actor_visual_root.rotation = sin(phase) * 0.025
		"attack":
			var lunge := sin(progress * PI) * 10.0
			actor_visual_root.position = facing_direction.normalized() * lunge
			actor_visual_root.rotation = sin(progress * PI) * 0.05
		"death":
			actor_visual_root.position = Vector2(progress * 7.0, progress * 7.0)
			actor_visual_root.rotation = lerpf(0.0, 0.35, progress)
			actor_visual_root.scale = Vector2(1.0 + progress * 0.10, lerpf(1.0, 0.45, progress))
			actor_visual_root.modulate = Color(1, 1, 1, lerpf(1.0, 0.38, progress))

func _get_current_animation_progress() -> float:
	var animation := _get_current_animation_data()
	if animation.is_empty():
		return 0.0
	var from_frame := int(animation.get("from", actor_animation_frame))
	var to_frame := int(animation.get("to", from_frame))
	if to_frame <= from_frame:
		return 1.0
	return clampf(float(actor_animation_frame - from_frame) / float(to_frame - from_frame), 0.0, 1.0)

func _get_facing_bucket() -> String:
	if facing_direction.x < -0.18:
		return "left"
	if facing_direction.x > 0.18:
		return "right"
	if facing_direction.y < 0.0:
		return "up"
	return "down"

func _should_flip_sprite_for_facing() -> bool:
	var direction_mode := str(visual_asset_manifest.get("direction_mode", "runtime_flip_2dir"))
	if direction_mode == "4dir" or direction_mode == "8dir":
		return false
	return _get_facing_bucket() == "left"

func _get_direction_frame_offset() -> int:
	var direction_mode := str(visual_asset_manifest.get("direction_mode", "runtime_flip_2dir"))
	if direction_mode != "4dir" and direction_mode != "8dir":
		return 0
	var offsets := Dictionary(visual_asset_manifest.get("direction_frame_offsets", {}))
	return int(offsets.get(_get_facing_bucket(), 0))

func _get_resolved_actor_frame_index() -> int:
	return _get_direction_frame_offset() + actor_animation_frame

func _get_current_animation_data() -> Dictionary:
	var animations := Dictionary(visual_asset_manifest.get("animations", {}))
	return Dictionary(animations.get(actor_animation_name, {}))

func _apply_actor_sprite_region() -> void:
	if not is_instance_valid(actor_sprite):
		return
	var frame_size: Vector2i = visual_asset_manifest.get("frame_size", Vector2i.ZERO)
	if frame_size.x <= 0 or frame_size.y <= 0:
		return
	actor_sprite.region_rect = Rect2(Vector2(_get_resolved_actor_frame_index() * frame_size.x, 0), Vector2(frame_size))
	_update_actor_animation_presentation()

func _load_actor_sprite_texture() -> void:
	var path := str(visual_asset_manifest.get("sprite_sheet_path", ""))
	if path == "" or not FileAccess.file_exists(path):
		return
	var image := Image.new()
	if image.load(ProjectSettings.globalize_path(path)) != OK:
		return
	actor_sprite.texture = ImageTexture.create_from_image(image)
	_update_procedural_visual_visibility()

func _trigger_death_animation() -> void:
	var animations := Dictionary(visual_asset_manifest.get("animations", {}))
	if animations.has("death"):
		set_actor_animation("death", true)
	death_animation_triggered = true

func _get_death_animation_duration() -> float:
	var animations := Dictionary(visual_asset_manifest.get("animations", {}))
	if not animations.has("death"):
		return 0.0
	if not bool(visual_asset_manifest.get("enabled", false)):
		return 0.0
	var animation := Dictionary(animations.get("death", {}))
	var from_frame := int(animation.get("from", 0))
	var to_frame := int(animation.get("to", from_frame))
	var fps := float(animation.get("fps", 0.0))
	if fps <= 0.0:
		return 0.0
	return maxf(0.0, float(to_frame - from_frame + 1) / fps)

func _update_procedural_visual_visibility() -> void:
	var should_hide := bool(visual_asset_manifest.get("enabled", false)) and bool(visual_asset_manifest.get("hide_procedural_body", false)) and is_instance_valid(actor_sprite) and actor_sprite.texture != null
	for node_name in PROCEDURAL_VISUAL_NAMES:
		var visual := find_child(node_name, true, false) as CanvasItem
		if is_instance_valid(visual):
			visual.visible = not should_hide

func apply_visual_asset_manifest_for_test(manifest: Dictionary) -> void:
	apply_visual_asset_manifest(manifest)

func get_visual_asset_manifest_for_test() -> Dictionary:
	return get_visual_asset_manifest()

func set_actor_animation_for_test(animation_name: String) -> void:
	set_actor_animation(animation_name)

func advance_actor_animation_for_test() -> void:
	advance_actor_animation()

func get_actor_animation_state_for_test() -> Dictionary:
	return get_actor_animation_state()

func update_actor_animation_state_for_test(movement: Vector2, attacking: bool) -> void:
	update_actor_animation_state(movement, attacking)

func tick_actor_animation_for_test(delta: float) -> void:
	tick_actor_animation(delta)

func get_basic_attack_feel_for_test() -> Dictionary:
	_refresh_attack_feel_profile()
	return attack_feel_profile.duplicate(true)

func get_attack_feel_state_for_test() -> Dictionary:
	return {
		"skill_id": basic_skill_id,
		"phase": attack_phase,
		"elapsed": attack_elapsed,
		"cooldown_remaining": attack_cooldown_remaining,
		"ready": attack_ready,
		"buffered": buffered_attack,
		"windup": float(attack_feel_profile.get("windup", 0.0)),
		"hit_frame": float(attack_feel_profile.get("hit_frame", 0.0)),
		"recovery": float(attack_feel_profile.get("recovery", 0.0)),
		"input_buffer": float(attack_feel_profile.get("input_buffer", 0.0)),
		"hit_stop": float(attack_feel_profile.get("hit_stop", 0.0)),
	}

func tick_attack_feel_for_test(delta: float) -> void:
	_tick_attack_feel(delta)

func get_death_animation_duration_for_test() -> float:
	return _get_death_animation_duration()

func get_damage_feedback_state_for_test() -> Dictionary:
	return _build_damage_feedback_state()

func tick_damage_feedback_for_test(delta: float) -> void:
	_tick_damage_feedback(delta)

func _build_damage_feedback_state() -> Dictionary:
	var feedback := last_damage_feedback.duplicate(true)
	feedback["active"] = damage_stagger_remaining > 0.0 or damage_hit_flash_remaining > 0.0
	feedback["stagger_remaining"] = damage_stagger_remaining
	feedback["hit_flash_remaining"] = damage_hit_flash_remaining
	feedback["knockback_distance"] = float(last_damage_feedback.get("knockback_distance", 0.0))
	return feedback

func get_actor_presentation_state_for_test() -> Dictionary:
	return {
		"animation": actor_animation_name,
		"facing_bucket": _get_facing_bucket(),
		"sprite_flipped_h": actor_sprite.flip_h if is_instance_valid(actor_sprite) else false,
		"direction_mode": str(visual_asset_manifest.get("direction_mode", "runtime_flip_2dir")),
		"resolved_frame_index": _get_resolved_actor_frame_index(),
		"direction_frame_offset": _get_direction_frame_offset(),
		"visual_offset_x": actor_visual_root.position.x if is_instance_valid(actor_visual_root) else 0.0,
		"visual_offset_y": actor_visual_root.position.y if is_instance_valid(actor_visual_root) else 0.0,
		"visual_rotation": actor_visual_root.rotation if is_instance_valid(actor_visual_root) else 0.0,
		"footstep_offset_x": footstep_offset_x,
	}
