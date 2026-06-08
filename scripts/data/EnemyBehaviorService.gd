extends RefCounted
class_name EnemyBehaviorService

const DEFAULT_PROFILE := {
	"archetype": "melee_rusher",
	"preferred_distance": 34.0,
	"retreat_distance": 0.0,
	"commit_distance": 46.0,
	"attack_windup": 0.12,
	"attack_recovery": 0.18,
	"speed_scale": 1.0,
}

const PROFILES := {
	"rot_melee": {
		"archetype": "melee_rusher",
		"preferred_distance": 32.0,
		"retreat_distance": 0.0,
		"commit_distance": 48.0,
		"attack_windup": 0.10,
		"attack_recovery": 0.16,
		"speed_scale": 1.0,
	},
	"shadow_archer": {
		"archetype": "ranged_kiter",
		"preferred_distance": 180.0,
		"retreat_distance": 112.0,
		"commit_distance": 220.0,
		"attack_windup": 0.22,
		"attack_recovery": 0.24,
		"speed_scale": 0.92,
	},
	"tower_guardian": {
		"archetype": "guard_committer",
		"preferred_distance": 44.0,
		"retreat_distance": 0.0,
		"commit_distance": 72.0,
		"attack_windup": 0.20,
		"attack_recovery": 0.26,
		"speed_scale": 0.85,
	},
	"tower_gatekeeper": {
		"archetype": "boss_committer",
		"preferred_distance": 56.0,
		"retreat_distance": 0.0,
		"commit_distance": 92.0,
		"attack_windup": 0.24,
		"attack_recovery": 0.30,
		"speed_scale": 0.82,
	},
}

static func get_behavior_profile(enemy_type: String) -> Dictionary:
	var profile := DEFAULT_PROFILE.duplicate(true)
	var overrides: Dictionary = Dictionary(PROFILES.get(enemy_type, {}))
	for key in overrides.keys():
		profile[key] = overrides[key]
	profile["enemy_type"] = enemy_type
	return profile

static func evaluate_intent(profile: Dictionary, distance_to_target: float, direction_to_target: Vector2) -> Dictionary:
	var safe_distance := maxf(0.0, distance_to_target)
	var direction := direction_to_target.normalized() if direction_to_target.length_squared() > 0.001 else Vector2.ZERO
	var retreat_distance := float(profile.get("retreat_distance", 0.0))
	var commit_distance := float(profile.get("commit_distance", 46.0))
	var preferred_distance := float(profile.get("preferred_distance", commit_distance))
	var intent := "hold"
	var move_direction := Vector2.ZERO
	if retreat_distance > 0.0 and safe_distance < retreat_distance:
		intent = "retreat"
		move_direction = -direction
	elif safe_distance > commit_distance:
		intent = "approach"
		move_direction = direction
	elif safe_distance <= maxf(commit_distance, preferred_distance + 12.0):
		intent = "attack"
	return {
		"intent": intent,
		"move_direction": move_direction,
		"distance": safe_distance,
		"preferred_distance": preferred_distance,
		"retreat_distance": retreat_distance,
		"commit_distance": commit_distance,
		"attack_windup": float(profile.get("attack_windup", 0.12)),
		"attack_recovery": float(profile.get("attack_recovery", 0.18)),
		"speed_scale": float(profile.get("speed_scale", 1.0)),
	}
