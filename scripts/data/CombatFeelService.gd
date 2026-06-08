extends RefCounted
class_name CombatFeelService

const SkillRulesScript := preload("res://scripts/rules/SkillRules.gd")

const DEFAULT_BASIC_FEEL := {
	"windup": 0.08,
	"hit_frame": 0.12,
	"recovery": 0.18,
	"input_buffer": 0.14,
	"hit_stop": 0.035,
	"animation_phase": "attack",
}

const BASIC_FEEL_OVERRIDES := {
	"warrior_cleave": {
		"windup": 0.10,
		"hit_frame": 0.15,
		"recovery": 0.20,
		"input_buffer": 0.16,
		"hit_stop": 0.045,
	},
	"ranger_shot": {
		"windup": 0.06,
		"hit_frame": 0.10,
		"recovery": 0.16,
		"input_buffer": 0.13,
		"hit_stop": 0.025,
	},
	"mage_bolt": {
		"windup": 0.11,
		"hit_frame": 0.17,
		"recovery": 0.22,
		"input_buffer": 0.16,
		"hit_stop": 0.03,
	},
	"bone_spike": {
		"windup": 0.09,
		"hit_frame": 0.14,
		"recovery": 0.20,
		"input_buffer": 0.15,
		"hit_stop": 0.035,
	},
}

static func get_basic_attack_feel(skill_id: String) -> Dictionary:
	var profile := DEFAULT_BASIC_FEEL.duplicate(true)
	var overrides: Dictionary = Dictionary(BASIC_FEEL_OVERRIDES.get(skill_id, {}))
	for key in overrides.keys():
		profile[key] = overrides[key]
	var skill := SkillRulesScript.get_skill(skill_id)
	var rules_cooldown := float(skill.get("cooldown", 0.35))
	var minimum_cooldown := float(profile.get("hit_frame", 0.12)) + float(profile.get("recovery", 0.18))
	profile["skill_id"] = skill_id
	profile["cooldown"] = maxf(rules_cooldown, minimum_cooldown)
	profile["animation_phase"] = str(profile.get("animation_phase", "attack"))
	return profile
