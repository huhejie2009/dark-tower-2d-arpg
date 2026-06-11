extends RefCounted
class_name SkillRules

const SKILLS := {
	"warrior_cleave": {"name": "顺劈斩", "range": 128.0, "cooldown": 0.34, "damage_scale": 1.12},
	"ranger_shot": {"name": "穿刺射击", "range": 280.0, "cooldown": 0.32, "damage_scale": 0.95},
	"ranger_ice_shot": {
		"name": "寒冰射击",
		"range": 300.0,
		"cooldown": 0.34,
		"damage_scale": 0.95,
		"physical_to_cold_ratio": 0.60,
		"tags": ["attack", "ranger", "bow", "projectile", "cold"],
		"coc_trigger_skill_id": "ice_lance",
	},
	"ice_lance": {
		"name": "冰矛",
		"range": 340.0,
		"cooldown": 0.0,
		"damage_scale": 0.70,
		"triggered_by": "coc",
		"trigger_cooldown": 0.30,
		"tags": ["spell", "triggered", "projectile", "cold"],
	},
	"mage_bolt": {"name": "奥术弹", "range": 260.0, "cooldown": 0.42, "damage_scale": 1.08},
	"bone_spike": {"name": "骨刺", "range": 230.0, "cooldown": 0.38, "damage_scale": 1.0},
	"whirlwind_core": {"name": "旋风斩", "range": 132.0, "cooldown": 1.2, "mana_cost": 16, "damage_scale": 1.35},
}

static func get_skill(skill_id: String) -> Dictionary:
	return Dictionary(SKILLS.get(skill_id, {})).duplicate(true)

static func get_skill_name(skill_id: String) -> String:
	return str(get_skill(skill_id).get("name", "技能"))
