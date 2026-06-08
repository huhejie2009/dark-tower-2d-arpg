extends RefCounted
class_name DamageFeedbackService

const IMPACT_PROFILES := {
	"light": {
		"stagger_duration": 0.08,
		"knockback_distance": 8.0,
		"hit_flash_duration": 0.10,
		"camera_shake": 0.02,
	},
	"medium": {
		"stagger_duration": 0.13,
		"knockback_distance": 14.0,
		"hit_flash_duration": 0.13,
		"camera_shake": 0.04,
	},
	"heavy": {
		"stagger_duration": 0.20,
		"knockback_distance": 22.0,
		"hit_flash_duration": 0.18,
		"camera_shake": 0.07,
	},
	"lethal": {
		"stagger_duration": 0.0,
		"knockback_distance": 10.0,
		"hit_flash_duration": 0.08,
		"camera_shake": 0.09,
	},
}

const TARGET_MULTIPLIERS := {
	"player": {
		"stagger": 0.55,
		"knockback": 0.45,
		"camera": 1.0,
	},
	"enemy_normal": {
		"stagger": 1.0,
		"knockback": 1.0,
		"camera": 0.25,
	},
	"enemy_elite": {
		"stagger": 0.72,
		"knockback": 0.62,
		"camera": 0.35,
	},
	"enemy_boss": {
		"stagger": 0.36,
		"knockback": 0.22,
		"camera": 0.55,
	},
}

static func build_damage_feedback(target_kind: String, amount: int, max_health: int, source_direction: Vector2 = Vector2.ZERO) -> Dictionary:
	var impact_level := _classify_impact(amount, max_health)
	var profile: Dictionary = Dictionary(IMPACT_PROFILES.get(impact_level, IMPACT_PROFILES["light"])).duplicate(true)
	var multipliers: Dictionary = Dictionary(TARGET_MULTIPLIERS.get(target_kind, TARGET_MULTIPLIERS["enemy_normal"]))
	var direction := source_direction.normalized() if source_direction.length_squared() > 0.001 else Vector2.ZERO
	return {
		"target_kind": target_kind,
		"amount": max(0, amount),
		"impact_level": impact_level,
		"stagger_duration": float(profile.get("stagger_duration", 0.0)) * float(multipliers.get("stagger", 1.0)),
		"knockback_distance": float(profile.get("knockback_distance", 0.0)) * float(multipliers.get("knockback", 1.0)),
		"hit_flash_duration": float(profile.get("hit_flash_duration", 0.0)),
		"camera_shake": float(profile.get("camera_shake", 0.0)) * float(multipliers.get("camera", 1.0)),
		"damage_number": amount > 0,
		"vfx_event": "hit_impact",
		"audio_event": "hit_%s" % impact_level,
		"source_direction": direction,
	}

static func _classify_impact(amount: int, max_health: int) -> String:
	if amount >= max(1, max_health):
		return "lethal"
	var ratio := float(max(0, amount)) / float(max(1, max_health))
	if ratio >= 0.30:
		return "heavy"
	if ratio >= 0.15:
		return "medium"
	return "light"
