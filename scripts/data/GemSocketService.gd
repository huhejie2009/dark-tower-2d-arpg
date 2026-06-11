extends RefCounted
class_name GemSocketService

const GEM_DEFS := {
	"frost_gem": {"name": "寒霜宝石", "stats": {"cold_damage": 6}, "mechanic": false},
	"precision_gem": {"name": "精准宝石", "stats": {"critical_chance": 2}, "mechanic": false},
	"haste_gem": {"name": "迅捷宝石", "stats": {"attack_speed": 4}, "mechanic": false},
	"pierce_gem": {"name": "穿透宝石", "stats": {"ice_lance_pierce": 1}, "mechanic": true},
	"split_gem": {"name": "分裂宝石", "stats": {"ice_lance_split": 1}, "mechanic": true},
}

static func get_socket_limit(slot: String) -> int:
	match slot:
		"weapon", "armor":
			return 2
		"gloves", "ring", "ring_1", "ring_2":
			return 1
		_:
			return 0

static func normalize_socketed_gems(equipment: Dictionary) -> Array:
	var result: Array = []
	for gem_id in Array(equipment.get("socketed_gems", [])):
		var text := str(gem_id)
		if GEM_DEFS.has(text):
			result.append(text)
	return result

static func socket_gem(equipment: Dictionary, gem_id: String) -> Dictionary:
	var result := equipment.duplicate(true)
	if not GEM_DEFS.has(gem_id):
		return {"ok": false, "reason": "unknown_gem", "equipment": result}
	var socketed := normalize_socketed_gems(result)
	var limit := get_socket_limit(str(result.get("slot", "")))
	if socketed.size() >= limit:
		return {"ok": false, "reason": "socket_full", "equipment": result}
	var gem_def: Dictionary = Dictionary(GEM_DEFS[gem_id])
	if bool(gem_def.get("mechanic", false)) and socketed.has(gem_id):
		return {"ok": false, "reason": "duplicate_mechanic_gem", "equipment": result}
	socketed.append(gem_id)
	result["socketed_gems"] = socketed
	return {"ok": true, "gem_id": gem_id, "equipment": result}

static func remove_gem(equipment: Dictionary, gem_id: String) -> Dictionary:
	var result := equipment.duplicate(true)
	var socketed := normalize_socketed_gems(result)
	var removed := false
	var next_socketed: Array = []
	for current in socketed:
		if not removed and str(current) == gem_id:
			removed = true
			continue
		next_socketed.append(current)
	result["socketed_gems"] = next_socketed
	return {"ok": removed, "reason": "removed" if removed else "missing_gem", "equipment": result, "gem_id": gem_id}

static func build_socket_stat_totals(equipment: Dictionary) -> Dictionary:
	var totals: Dictionary = {}
	for gem_id in normalize_socketed_gems(equipment):
		var gem_def: Dictionary = Dictionary(GEM_DEFS[str(gem_id)])
		var stats: Dictionary = Dictionary(gem_def.get("stats", {}))
		for stat_id in stats.keys():
			totals[stat_id] = int(totals.get(stat_id, 0)) + int(stats[stat_id])
	return totals
