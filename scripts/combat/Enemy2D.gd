extends CharacterBody2D
class_name Enemy2D

const Vfx2DFactoryScript := preload("res://scripts/combat/Vfx2DFactory.gd")
const DamageFeedbackServiceScript := preload("res://scripts/data/DamageFeedbackService.gd")
const EnemyBehaviorServiceScript := preload("res://scripts/data/EnemyBehaviorService.gd")
const PROCEDURAL_VISUAL_NAMES := ["EnemyBody"]

signal died(enemy: Node)

@export var max_health := 60
@export var move_speed := 105.0
@export var attack_damage := 9
@export var attack_range := 42.0
@export var attack_cooldown := 0.8
@export var uses_projectile := false
@export var projectile_speed := 300.0
@export var boss_skill_cooldown := 3.2
@export var boss_charge_cooldown := 4.6
@export var boss_charge_distance := 135.0
@export var boss_charge_damage := 20

var enemy_type := "rot_melee"
var display_name := "Enemy"
var display_rank := "normal"
var is_elite := false
var is_boss := false
var elite_affixes: Array = []
var boss_skills: Array = []
var nameplate_text := ""
var death_burst := false
var death_burst_damage := 0
var death_burst_radius := 72.0
var health := 60
var target: Node2D
var attack_ready := true
var is_dead := false
var body: Polygon2D
var health_fill: ColorRect
var nameplate_label: Label
var body_color := Color(0.72, 0.18, 0.14, 1.0)
var boss_skill_ready := true
var boss_charge_ready := true
var boss_skill_flip := false
var obstacle_avoidance_side := 1.0
var visual_asset_manifest: Dictionary = {}
var actor_visual_root: Node2D
var actor_sprite: Sprite2D
var attack_arc: Polygon2D
var actor_animation_name := "idle"
var actor_animation_frame := 0
var actor_animation_elapsed := 0.0
var actor_animation_locked_until_end := false
var death_animation_triggered := false
var facing_direction := Vector2.RIGHT
var footstep_offset_x := 0.0
var last_damage_feedback: Dictionary = {}
var damage_stagger_remaining := 0.0
var damage_hit_flash_remaining := 0.0
var behavior_profile: Dictionary = {}
var behavior_intent := "idle"
var attack_windup_remaining := 0.0
var pending_attack_direction := Vector2.ZERO

func _ready() -> void:
	health = max_health
	_refresh_behavior_profile()
	add_to_group("enemies")
	_create_collision()
	_create_visuals()
	if not visual_asset_manifest.is_empty():
		apply_visual_asset_manifest(visual_asset_manifest)
	_update_health_bar()

func _process(delta: float) -> void:
	if is_dead:
		tick_actor_animation(delta)

func _physics_process(delta: float) -> void:
	if is_dead or not is_instance_valid(target):
		_tick_damage_feedback(delta)
		return
	_tick_damage_feedback(delta)
	if damage_stagger_remaining > 0.0:
		velocity = Vector2.ZERO
		update_actor_animation_state(Vector2.ZERO, false)
		tick_actor_animation(delta)
		return
	var to_target := target.global_position - global_position
	var intent := _evaluate_behavior_intent(target.global_position)
	behavior_intent = str(intent.get("intent", "hold"))
	if attack_windup_remaining > 0.0:
		attack_windup_remaining = maxf(0.0, attack_windup_remaining - delta)
		velocity = Vector2.ZERO
		update_actor_animation_state(Vector2.ZERO, true)
		move_and_slide()
		if attack_windup_remaining <= 0.0:
			_perform_ready_attack(pending_attack_direction)
		tick_actor_animation(delta)
		return
	if behavior_intent == "approach" or behavior_intent == "retreat":
		var move_direction: Vector2 = intent.get("move_direction", Vector2.ZERO)
		velocity = _build_chase_velocity(move_direction, get_slide_collision_count() > 0) * float(intent.get("speed_scale", 1.0))
		if velocity.length_squared() > 0.001:
			facing_direction = velocity.normalized()
		update_actor_animation_state(velocity, false)
		move_and_slide()
		return
	velocity = Vector2.ZERO
	if to_target.length_squared() > 0.001:
		facing_direction = to_target.normalized()
	update_actor_animation_state(Vector2.ZERO, false)
	move_and_slide()
	if behavior_intent == "attack" and attack_ready and target.has_method("take_damage"):
		attack_ready = false
		pending_attack_direction = to_target.normalized() if to_target.length_squared() > 0.001 else facing_direction
		attack_windup_remaining = float(intent.get("attack_windup", 0.12))
		update_actor_animation_state(Vector2.ZERO, true)
		if attack_windup_remaining <= 0.0:
			_perform_ready_attack(pending_attack_direction)
		get_tree().create_timer(attack_cooldown + float(intent.get("attack_recovery", 0.0))).timeout.connect(func(): attack_ready = true)
	if is_boss and to_target.length() <= 190.0:
		if boss_skill_flip and boss_charge_ready and boss_skills.has("short_charge"):
			_trigger_gatekeeper_charge(to_target.normalized())
		elif boss_skill_ready and boss_skills.has("gatekeeper_slam"):
			_trigger_gatekeeper_slam(to_target.normalized())
		boss_skill_flip = not boss_skill_flip
	tick_actor_animation(delta)

func apply_enemy_data(data: Dictionary) -> void:
	enemy_type = str(data.get("enemy_type", enemy_type))
	_refresh_behavior_profile()
	display_name = str(data.get("name", display_name))
	max_health = int(data.get("max_health", max_health))
	health = max_health
	move_speed = float(data.get("move_speed", move_speed))
	attack_damage = int(data.get("attack_damage", attack_damage))
	attack_range = float(data.get("attack_range", attack_range))
	attack_cooldown = float(data.get("attack_cooldown", attack_cooldown))
	uses_projectile = bool(data.get("uses_projectile", uses_projectile))
	projectile_speed = float(data.get("projectile_speed", projectile_speed))
	boss_skill_cooldown = float(data.get("boss_skill_cooldown", boss_skill_cooldown))
	boss_charge_cooldown = float(data.get("boss_charge_cooldown", boss_charge_cooldown))
	boss_charge_distance = float(data.get("boss_charge_distance", boss_charge_distance))
	boss_charge_damage = int(data.get("boss_charge_damage", boss_charge_damage))
	is_elite = bool(data.get("is_elite", false))
	is_boss = bool(data.get("is_boss", false))
	display_rank = str(data.get("display_rank", "normal"))
	elite_affixes = Array(data.get("elite_affixes", [])) if data.get("elite_affixes", []) is Array else []
	boss_skills = Array(data.get("boss_skills", [])) if data.get("boss_skills", []) is Array else []
	death_burst = bool(data.get("death_burst", false))
	death_burst_damage = int(data.get("death_burst_damage", 0))
	death_burst_radius = float(data.get("death_burst_radius", death_burst_radius))
	body_color = data.get("color", body_color) if data.get("color", null) is Color else body_color
	if is_boss:
		scale = Vector2.ONE * 1.35
	elif is_elite:
		scale = Vector2.ONE * 1.15
	if is_instance_valid(body):
		body.color = body_color
	var manifest: Dictionary = Dictionary(data.get("visual_asset_manifest", {}))
	if not manifest.is_empty():
		apply_visual_asset_manifest(manifest)
	_update_health_bar()
	_refresh_nameplate()

func _refresh_behavior_profile() -> void:
	behavior_profile = EnemyBehaviorServiceScript.get_behavior_profile(enemy_type)

func _evaluate_behavior_intent(target_position: Vector2) -> Dictionary:
	var to_target := target_position - global_position
	return EnemyBehaviorServiceScript.evaluate_intent(behavior_profile, to_target.length(), to_target)

func _perform_ready_attack(direction: Vector2) -> void:
	if not is_instance_valid(target) or not target.has_method("take_damage"):
		return
	if direction.length_squared() <= 0.001:
		direction = facing_direction
	if uses_projectile:
		_spawn_projectile(direction.normalized())
	else:
		target.take_damage(attack_damage, self)
		_spawn_melee_hit_vfx(target.global_position)

func take_damage(amount: int, attacker: Node = null) -> void:
	if is_dead:
		return
	health = max(0, health - max(0, amount))
	_apply_damage_feedback(amount, attacker)
	_update_health_bar()
	if health <= 0:
		is_dead = true
		_trigger_death_animation()
		_disable_collision_shapes()
		set_physics_process(false)
		if death_burst:
			_spawn_death_burst()
		died.emit(self)
		_queue_free_after_death_animation()

func _apply_damage_feedback(amount: int, attacker: Node = null) -> void:
	var source_direction := Vector2.ZERO
	if is_instance_valid(attacker) and attacker is Node2D:
		source_direction = global_position - (attacker as Node2D).global_position
	last_damage_feedback = DamageFeedbackServiceScript.build_damage_feedback(_get_damage_feedback_target_kind(), amount, max_health, source_direction)
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

func _get_damage_feedback_target_kind() -> String:
	if is_boss:
		return "enemy_boss"
	if is_elite:
		return "enemy_elite"
	return "enemy_normal"

func _create_collision() -> void:
	var shape := CircleShape2D.new()
	shape.radius = 20.0
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	collision.shape = shape
	add_child(collision)

func _build_chase_velocity(to_target: Vector2, obstacle_contact: bool) -> Vector2:
	if to_target.length_squared() <= 0.001:
		return Vector2.ZERO
	var direction := to_target.normalized()
	if obstacle_contact:
		obstacle_avoidance_side *= -1.0
		var side_step := Vector2(-direction.y, direction.x) * obstacle_avoidance_side
		direction = (direction + side_step * 0.62).normalized()
	return direction * move_speed

func _build_chase_velocity_for_test(to_target: Vector2, obstacle_contact: bool) -> Vector2:
	return _build_chase_velocity(to_target, obstacle_contact)

func _create_visuals() -> void:
	_create_actor_visual_asset_slot()

	var shadow := Polygon2D.new()
	shadow.name = "EnemyShadow"
	shadow.z_index = -2
	shadow.polygon = PackedVector2Array([
		Vector2(-23, 12),
		Vector2(-8, 6),
		Vector2(18, 6),
		Vector2(28, 12),
		Vector2(18, 18),
		Vector2(-9, 18),
	])
	shadow.color = Color(0.0, 0.0, 0.0, 0.30)
	add_child(shadow)

	body = Polygon2D.new()
	body.name = "EnemyBody"
	body.polygon = PackedVector2Array([
		Vector2(21, -6),
		Vector2(9, -24),
		Vector2(-13, -22),
		Vector2(-24, -5),
		Vector2(-18, 18),
		Vector2(6, 24),
		Vector2(24, 8),
	])
	body.color = body_color
	add_child(body)
	var health_bar := Node2D.new()
	health_bar.position = Vector2(-24, -34)
	add_child(health_bar)
	var back := ColorRect.new()
	back.size = Vector2(48, 6)
	back.color = Color(0.03, 0.015, 0.01, 0.86)
	health_bar.add_child(back)
	health_fill = ColorRect.new()
	health_fill.position = Vector2(1, 1)
	health_fill.size = Vector2(46, 4)
	health_fill.color = Color(0.86, 0.12, 0.08, 1.0)
	health_bar.add_child(health_fill)
	_refresh_nameplate()

func _create_actor_visual_asset_slot() -> void:
	actor_visual_root = Node2D.new()
	actor_visual_root.name = "ActorVisualRoot"
	actor_visual_root.z_index = 2
	add_child(actor_visual_root)
	actor_sprite = Sprite2D.new()
	actor_sprite.name = "ActorSprite"
	actor_sprite.visible = false
	actor_visual_root.add_child(actor_sprite)
	attack_arc = Polygon2D.new()
	attack_arc.name = "EnemyAttackArc"
	attack_arc.visible = false
	attack_arc.z_index = 4
	attack_arc.polygon = PackedVector2Array([
		Vector2(10, -20),
		Vector2(48, -12),
		Vector2(58, 0),
		Vector2(48, 12),
		Vector2(10, 20),
		Vector2(24, 0),
	])
	attack_arc.color = Color(0.85, 0.95, 1.0, 0.46)
	actor_visual_root.add_child(attack_arc)

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
	_update_actor_animation_presentation()

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
			actor_animation_locked_until_end = actor_animation_name == "death"
		else:
			actor_animation_frame = from_frame
	_apply_actor_sprite_region()
	_update_actor_animation_presentation()

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
	if is_dead or actor_animation_locked_until_end:
		return
	if movement.length_squared() > 0.001:
		facing_direction = movement.normalized()
	elif attacking and is_instance_valid(target):
		var to_target := target.global_position - global_position
		if to_target.length_squared() > 0.001:
			facing_direction = to_target.normalized()
	var animations := Dictionary(visual_asset_manifest.get("animations", {}))
	if attacking and animations.has("attack"):
		set_actor_animation("attack", true, true)
	elif movement.length_squared() > 0.001 and animations.has("run"):
		set_actor_animation("run")
	elif animations.has("idle"):
		set_actor_animation("idle")

func _get_current_animation_data() -> Dictionary:
	var animations := Dictionary(visual_asset_manifest.get("animations", {}))
	return Dictionary(animations.get(actor_animation_name, {}))

func _is_current_animation_one_shot() -> bool:
	var animation := _get_current_animation_data()
	if animation.has("loop"):
		return not bool(animation.get("loop", true))
	return actor_animation_name == "attack" or actor_animation_name == "death"

func _get_current_animation_progress() -> float:
	var animation := _get_current_animation_data()
	if animation.is_empty():
		return 0.0
	var from_frame := int(animation.get("from", actor_animation_frame))
	var to_frame := int(animation.get("to", from_frame))
	if to_frame <= from_frame:
		return 1.0
	return clampf(float(actor_animation_frame - from_frame) / float(to_frame - from_frame), 0.0, 1.0)

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
	if is_instance_valid(attack_arc):
		attack_arc.visible = false
	if damage_hit_flash_remaining > 0.0:
		actor_visual_root.modulate = Color(1.35, 1.35, 1.35, 1.0)
	var progress := _get_current_animation_progress()
	match actor_animation_name:
		"idle":
			actor_visual_root.scale = Vector2(1.0, 1.0 + sin(actor_animation_elapsed * TAU * 0.8) * 0.025)
		"run":
			var phase := float(actor_animation_frame - int(_get_current_animation_data().get("from", actor_animation_frame))) * PI * 0.72
			footstep_offset_x = sin(phase) * 2.2
			actor_visual_root.position = Vector2(footstep_offset_x, -2.5 + absf(cos(phase)) * 2.0)
			actor_visual_root.rotation = sin(phase) * 0.035
		"attack":
			var lunge := sin(progress * PI) * 18.0
			actor_visual_root.position = Vector2(8.0 + lunge, -2.0)
			actor_visual_root.rotation = lerpf(-0.10, 0.13, progress)
			actor_visual_root.scale = Vector2(1.0 + sin(progress * PI) * 0.10, 0.96)
			if is_instance_valid(attack_arc):
				attack_arc.visible = progress < 0.86
				attack_arc.modulate = Color(1, 1, 1, 1.0 - progress * 0.45)
		"death":
			actor_visual_root.position = Vector2(progress * 8.0, progress * 8.0)
			actor_visual_root.rotation = lerpf(0.0, 0.45, progress)
			actor_visual_root.scale = Vector2(1.0 + progress * 0.14, lerpf(1.0, 0.34, progress))
			actor_visual_root.modulate = Color(1, 1, 1, lerpf(1.0, 0.34, progress))

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

func _apply_actor_sprite_region() -> void:
	if not is_instance_valid(actor_sprite):
		return
	var frame_size: Vector2i = visual_asset_manifest.get("frame_size", Vector2i.ZERO)
	if frame_size.x <= 0 or frame_size.y <= 0:
		return
	actor_sprite.region_rect = Rect2(Vector2(_get_resolved_actor_frame_index() * frame_size.x, 0), Vector2(frame_size))

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
		set_actor_animation("death", true, true)
	death_animation_triggered = true
	set_process(true)

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

func _queue_free_after_death_animation() -> void:
	var delay := _get_death_animation_duration()
	if delay <= 0.0 or not is_inside_tree():
		queue_free()
		return
	get_tree().create_timer(delay).timeout.connect(func() -> void:
		if is_instance_valid(self):
			queue_free()
	)

func get_death_animation_duration_for_test() -> float:
	return _get_death_animation_duration()

func _disable_collision_shapes() -> void:
	for child in find_children("*", "CollisionShape2D", true, false):
		var shape := child as CollisionShape2D
		if is_instance_valid(shape):
			shape.disabled = true

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

func get_actor_presentation_state_for_test() -> Dictionary:
	return {
		"animation": actor_animation_name,
		"visual_offset_x": actor_visual_root.position.x if is_instance_valid(actor_visual_root) else 0.0,
		"visual_offset_y": actor_visual_root.position.y if is_instance_valid(actor_visual_root) else 0.0,
		"visual_lunge_x": maxf(0.0, actor_visual_root.position.x) if is_instance_valid(actor_visual_root) else 0.0,
		"visual_rotation": actor_visual_root.rotation if is_instance_valid(actor_visual_root) else 0.0,
		"visual_scale_y": actor_visual_root.scale.y if is_instance_valid(actor_visual_root) else 1.0,
		"visual_alpha": actor_visual_root.modulate.a if is_instance_valid(actor_visual_root) else 1.0,
		"attack_arc_visible": is_instance_valid(attack_arc) and attack_arc.visible,
		"facing_bucket": _get_facing_bucket(),
		"sprite_flipped_h": actor_sprite.flip_h if is_instance_valid(actor_sprite) else false,
		"direction_mode": str(visual_asset_manifest.get("direction_mode", "runtime_flip_2dir")),
		"resolved_frame_index": _get_resolved_actor_frame_index(),
		"direction_frame_offset": _get_direction_frame_offset(),
		"footstep_offset_x": footstep_offset_x,
	}

func update_actor_animation_state_for_test(movement: Vector2, attacking: bool) -> void:
	update_actor_animation_state(movement, attacking)

func tick_actor_animation_for_test(delta: float) -> void:
	tick_actor_animation(delta)

func get_behavior_profile_for_test() -> Dictionary:
	_refresh_behavior_profile()
	return behavior_profile.duplicate(true)

func evaluate_behavior_intent_for_test(target_position: Vector2) -> Dictionary:
	_refresh_behavior_profile()
	return _evaluate_behavior_intent(target_position)

func get_behavior_state_for_test() -> Dictionary:
	return {
		"enemy_type": enemy_type,
		"archetype": str(behavior_profile.get("archetype", "")),
		"intent": behavior_intent,
		"attack_windup_remaining": attack_windup_remaining,
		"preferred_distance": float(behavior_profile.get("preferred_distance", 0.0)),
		"retreat_distance": float(behavior_profile.get("retreat_distance", 0.0)),
		"commit_distance": float(behavior_profile.get("commit_distance", 0.0)),
	}

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

func _update_health_bar() -> void:
	if is_instance_valid(health_fill):
		health_fill.size.x = 46.0 * clampf(float(health) / float(max_health), 0.0, 1.0)

func _refresh_nameplate() -> void:
	nameplate_text = _build_nameplate_text()
	if nameplate_text == "":
		if is_instance_valid(nameplate_label):
			nameplate_label.queue_free()
			nameplate_label = null
		return
	if not is_instance_valid(nameplate_label):
		nameplate_label = Label.new()
		nameplate_label.name = "EnemyNameplate"
		nameplate_label.position = Vector2(-85, -70)
		nameplate_label.size = Vector2(170, 42)
		nameplate_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nameplate_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		nameplate_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nameplate_label.add_theme_font_size_override("font_size", 11)
		add_child(nameplate_label)
	nameplate_label.text = nameplate_text
	nameplate_label.add_theme_color_override("font_color", Color(1.0, 0.58, 0.2) if is_boss else Color(0.95, 0.86, 0.35))

func _build_nameplate_text() -> String:
	if not is_boss and not is_elite:
		return ""
	var lines: Array[String] = []
	var rank := "Boss" if is_boss else "Elite"
	lines.append("%s %s" % [rank, display_name])
	if is_boss and not boss_skills.is_empty():
		lines.append("Skills: %s" % ", ".join(_stringify_array(boss_skills)))
	elif is_elite and not elite_affixes.is_empty():
		lines.append("Affixes: %s" % ", ".join(_stringify_array(elite_affixes)))
	return "\n".join(lines)

func _stringify_array(values: Array) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		result.append(str(value))
	return result

func _spawn_projectile(direction: Vector2) -> void:
	if direction.length_squared() <= 0.001:
		return
	var projectile := Area2D.new()
	projectile.name = "EnemyProjectile"
	projectile.global_position = global_position + direction.normalized() * 22.0
	projectile.set_meta("damage", attack_damage)
	projectile.set_meta("velocity", direction.normalized() * projectile_speed)
	var parent := get_parent()
	if not is_instance_valid(parent):
		parent = get_tree().current_scene
	if not is_instance_valid(parent):
		parent = get_tree().root
	parent.add_child(projectile)

	var shape := CircleShape2D.new()
	shape.radius = 7.0
	var collision := CollisionShape2D.new()
	collision.shape = shape
	projectile.add_child(collision)

	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([Vector2(12, 0), Vector2(-6, -6), Vector2(-4, 0), Vector2(-6, 6)])
	visual.color = Color(0.45, 0.58, 1.0, 0.9)
	visual.rotation = direction.angle()
	projectile.add_child(visual)

	projectile.body_entered.connect(func(body_node: Node) -> void:
		if body_node == target and body_node.has_method("take_damage"):
			body_node.take_damage(int(projectile.get_meta("damage", attack_damage)))
			_spawn_melee_hit_vfx(body_node.global_position)
			projectile.queue_free()
	)
	var mover := projectile.create_tween()
	mover.tween_method(func(value: float) -> void:
		if is_instance_valid(projectile):
			projectile.global_position += Vector2(projectile.get_meta("velocity")) * value
	, 0.0, 0.016, 1.3)
	mover.tween_callback(projectile.queue_free)

func _spawn_melee_hit_vfx(position: Vector2) -> void:
	var parent := get_parent()
	if not is_instance_valid(parent):
		return
	Vfx2DFactoryScript.spawn_hit(parent, position)

func _spawn_death_burst() -> void:
	var parent := get_parent()
	if not is_instance_valid(parent):
		parent = get_tree().current_scene
	if not is_instance_valid(parent):
		return
	var burst := Area2D.new()
	burst.name = "DeathBurstArea"
	burst.global_position = global_position
	burst.set_meta("damage", death_burst_damage)
	parent.add_child(burst)

	var shape := CircleShape2D.new()
	shape.radius = death_burst_radius
	var collision := CollisionShape2D.new()
	collision.shape = shape
	burst.add_child(collision)

	var ring := Line2D.new()
	ring.width = 5.0
	ring.closed = true
	ring.default_color = Color(0.95, 0.22, 0.16, 0.9)
	for i in range(28):
		var angle := TAU * float(i) / 28.0
		ring.add_point(Vector2(cos(angle), sin(angle)) * death_burst_radius)
	burst.add_child(ring)

	burst.body_entered.connect(func(body_node: Node) -> void:
		if body_node == target and body_node.has_method("take_damage"):
			body_node.take_damage(int(burst.get_meta("damage", death_burst_damage)))
	)
	var tween := burst.create_tween()
	tween.tween_property(burst, "modulate:a", 0.0, 0.24)
	tween.tween_callback(burst.queue_free)

func trigger_boss_skill_for_test() -> void:
	_trigger_gatekeeper_slam(Vector2.RIGHT)

func trigger_boss_charge_for_test() -> void:
	_trigger_gatekeeper_charge(Vector2.RIGHT)

func _trigger_gatekeeper_slam(direction: Vector2) -> void:
	if not is_boss or not boss_skill_ready:
		return
	if direction.length_squared() <= 0.001:
		direction = Vector2.RIGHT
	boss_skill_ready = false
	_spawn_gatekeeper_slam_warning(direction.normalized())
	get_tree().create_timer(0.32).timeout.connect(func() -> void:
		if is_instance_valid(self) and not is_dead:
			_spawn_gatekeeper_slam_area(direction.normalized())
	)
	get_tree().create_timer(boss_skill_cooldown).timeout.connect(func() -> void:
		if is_instance_valid(self):
			boss_skill_ready = true
	)

func _spawn_gatekeeper_slam_warning(direction: Vector2) -> void:
	var parent := get_parent()
	if not is_instance_valid(parent):
		return
	var warning := Polygon2D.new()
	warning.name = "GatekeeperSlamWarning"
	warning.global_position = global_position
	warning.rotation = direction.angle()
	warning.polygon = PackedVector2Array([
		Vector2.ZERO,
		Vector2(150, -60),
		Vector2(175, 0),
		Vector2(150, 60),
	])
	warning.color = Color(1.0, 0.32, 0.12, 0.34)
	parent.add_child(warning)
	var tween := warning.create_tween()
	tween.tween_property(warning, "modulate:a", 0.0, 0.36)
	tween.tween_callback(warning.queue_free)

func _spawn_gatekeeper_slam_area(direction: Vector2) -> void:
	var parent := get_parent()
	if not is_instance_valid(parent):
		return
	var area := Area2D.new()
	area.name = "GatekeeperSlamArea"
	area.global_position = global_position + direction * 88.0
	area.rotation = direction.angle()
	area.set_meta("damage", attack_damage + 8)
	parent.add_child(area)

	var shape := RectangleShape2D.new()
	shape.size = Vector2(150, 96)
	var collision := CollisionShape2D.new()
	collision.position = Vector2(35, 0)
	collision.shape = shape
	area.add_child(collision)

	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([
		Vector2(-35, -48),
		Vector2(115, -38),
		Vector2(130, 0),
		Vector2(115, 38),
		Vector2(-35, 48),
	])
	visual.color = Color(1.0, 0.48, 0.16, 0.72)
	area.add_child(visual)

	area.body_entered.connect(func(body_node: Node) -> void:
		if body_node == target and body_node.has_method("take_damage"):
			body_node.take_damage(int(area.get_meta("damage", attack_damage + 8)))
	)
	var tween := area.create_tween()
	tween.tween_property(area, "modulate:a", 0.0, 0.22)
	tween.tween_callback(area.queue_free)

func _trigger_gatekeeper_charge(direction: Vector2) -> void:
	if not is_boss or not boss_charge_ready:
		return
	if direction.length_squared() <= 0.001:
		direction = Vector2.RIGHT
	boss_charge_ready = false
	var normalized := direction.normalized()
	_spawn_gatekeeper_charge_warning(normalized)
	get_tree().create_timer(0.24).timeout.connect(func() -> void:
		if is_instance_valid(self) and not is_dead:
			global_position += normalized * boss_charge_distance
			_spawn_gatekeeper_charge_area(normalized)
	)
	get_tree().create_timer(boss_charge_cooldown).timeout.connect(func() -> void:
		if is_instance_valid(self):
			boss_charge_ready = true
	)

func _spawn_gatekeeper_charge_warning(direction: Vector2) -> void:
	var parent := get_parent()
	if not is_instance_valid(parent):
		return
	var warning := Polygon2D.new()
	warning.name = "GatekeeperChargeWarning"
	warning.global_position = global_position
	warning.rotation = direction.angle()
	warning.polygon = PackedVector2Array([
		Vector2(0, -18),
		Vector2(boss_charge_distance + 42.0, -18),
		Vector2(boss_charge_distance + 42.0, 18),
		Vector2(0, 18),
	])
	warning.color = Color(0.35, 0.75, 1.0, 0.28)
	parent.add_child(warning)
	var tween := warning.create_tween()
	tween.tween_property(warning, "modulate:a", 0.0, 0.30)
	tween.tween_callback(warning.queue_free)

func _spawn_gatekeeper_charge_area(direction: Vector2) -> void:
	var parent := get_parent()
	if not is_instance_valid(parent):
		return
	var area := Area2D.new()
	area.name = "GatekeeperChargeArea"
	area.global_position = global_position - direction * 34.0
	area.rotation = direction.angle()
	area.set_meta("damage", boss_charge_damage)
	parent.add_child(area)

	var shape := RectangleShape2D.new()
	shape.size = Vector2(120, 54)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	area.add_child(collision)

	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([
		Vector2(-60, -27),
		Vector2(60, -27),
		Vector2(76, 0),
		Vector2(60, 27),
		Vector2(-60, 27),
	])
	visual.color = Color(0.35, 0.75, 1.0, 0.58)
	area.add_child(visual)

	area.body_entered.connect(func(body_node: Node) -> void:
		if body_node == target and body_node.has_method("take_damage"):
			body_node.take_damage(int(area.get_meta("damage", boss_charge_damage)))
	)
	var tween := area.create_tween()
	tween.tween_property(area, "modulate:a", 0.0, 0.22)
	tween.tween_callback(area.queue_free)
