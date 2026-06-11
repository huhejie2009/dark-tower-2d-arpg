extends RefCounted
class_name AutoCombatController

static func build_intent(player_position: Vector2, enemies: Array, attack_range: float) -> Dictionary:
	var best_position := Vector2.ZERO
	var best_distance := INF
	for entry in enemies:
		var data: Dictionary = Dictionary(entry)
		if not bool(data.get("alive", true)):
			continue
		var position: Vector2 = data.get("position", Vector2.ZERO)
		var distance := player_position.distance_to(position)
		if distance < best_distance:
			best_distance = distance
			best_position = position
	if best_distance == INF:
		return {
			"has_target": false,
			"should_attack": false,
			"move_vector": Vector2.ZERO,
			"attack_direction": Vector2.RIGHT,
		}
	var to_target := best_position - player_position
	var direction := to_target.normalized() if to_target.length_squared() > 0.001 else Vector2.RIGHT
	return {
		"has_target": true,
		"target_position": best_position,
		"target_distance": best_distance,
		"should_attack": best_distance <= attack_range,
		"move_vector": Vector2.ZERO if best_distance <= attack_range * 0.72 else direction,
		"attack_direction": direction,
	}
