extends RefCounted
class_name Skill2DLibrary

const SkillRulesScript := preload("res://scripts/rules/SkillRules.gd")
const Vfx2DFactoryScript := preload("res://scripts/combat/Vfx2DFactory.gd")

static func cast_basic_skill(caster: Node2D, skill_id: String, direction: Vector2, damage: int) -> Dictionary:
	if direction.length_squared() <= 0.001:
		direction = Vector2.RIGHT.rotated(caster.rotation)
	direction = direction.normalized()
	var profile := SkillRulesScript.get_skill(skill_id)
	var skill_range := float(profile.get("range", 120.0))
	var scale := float(profile.get("damage_scale", 1.0))
	var cast_style := str(profile.get("cast_style", "melee_arc"))
	var parent := caster.get_parent()
	if is_instance_valid(parent) and cast_style == "melee_arc":
		Vfx2DFactoryScript.spawn_slash(parent, caster.global_position + direction * 28.0, direction)
	var hit_count := 0
	var first_hit_distance := skill_range
	for enemy in caster.get_tree().get_nodes_in_group("enemies"):
		var enemy_2d := enemy as Node2D
		if not is_instance_valid(enemy_2d) or not enemy.has_method("take_damage"):
			continue
		var to_enemy := enemy_2d.global_position - caster.global_position
		if to_enemy.length() > skill_range or to_enemy.length_squared() <= 0.001:
			continue
		if direction.dot(to_enemy.normalized()) < 0.36:
			continue
		enemy.take_damage(int(round(float(damage) * scale)), caster)
		hit_count += 1
		first_hit_distance = minf(first_hit_distance, to_enemy.length())
		if is_instance_valid(parent):
			Vfx2DFactoryScript.spawn_hit(parent, enemy_2d.global_position)
	if is_instance_valid(parent) and cast_style == "projectile":
		Vfx2DFactoryScript.spawn_projectile_trail(parent, caster.global_position + direction * 24.0, direction, first_hit_distance)
	return {"skill_id": skill_id, "hit_count": hit_count, "cooldown": float(profile.get("cooldown", 0.35)), "cast_style": cast_style}

static func cast_triggered_skill(caster: Node2D, skill_id: String, direction: Vector2, damage: int) -> Dictionary:
	return cast_basic_skill(caster, skill_id, direction, damage)
