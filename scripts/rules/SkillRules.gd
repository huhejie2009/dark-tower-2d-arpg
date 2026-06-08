extends RefCounted
class_name SkillRules

const SKILLS := {
	"warrior_cleave": {"name": "顺劈斩", "range": 128.0, "cooldown": 0.34, "damage_scale": 1.12},
	"ranger_shot": {"name": "穿刺射击", "range": 280.0, "cooldown": 0.32, "damage_scale": 0.95},
	"mage_bolt": {"name": "奥术弹", "range": 260.0, "cooldown": 0.42, "damage_scale": 1.08},
	"bone_spike": {"name": "骨刺", "range": 230.0, "cooldown": 0.38, "damage_scale": 1.0},
	"whirlwind_core": {"name": "旋风斩", "range": 132.0, "cooldown": 1.2, "mana_cost": 16, "damage_scale": 1.35},
}

static func get_skill(skill_id: String) -> Dictionary:
	return Dictionary(SKILLS.get(skill_id, {})).duplicate(true)

static func get_skill_name(skill_id: String) -> String:
	return str(get_skill(skill_id).get("name", "技能"))
