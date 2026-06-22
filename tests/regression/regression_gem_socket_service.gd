extends SceneTree

const GemSocketServiceScript := preload("res://scripts/data/GemSocketService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var weapon := {"slot": "weapon", "socketed_gems": []}
	var frost: Dictionary = GemSocketServiceScript.socket_gem(weapon, "frost_gem")
	_expect(bool(frost.get("ok", false)), "weapon should accept frost gem")
	weapon = Dictionary(frost.get("equipment", weapon))
	var pierce: Dictionary = GemSocketServiceScript.socket_gem(weapon, "pierce_gem")
	_expect(bool(pierce.get("ok", false)), "weapon should accept pierce gem")
	weapon = Dictionary(pierce.get("equipment", weapon))
	var duplicate: Dictionary = GemSocketServiceScript.socket_gem(weapon, "pierce_gem")
	_expect(not bool(duplicate.get("ok", true)), "duplicate mechanic gem should be rejected")
	var totals: Dictionary = GemSocketServiceScript.build_socket_stat_totals(weapon)
	_expect(int(totals.get("cold_damage", 0)) == 6, "frost gem should add cold damage")
	_expect(int(totals.get("ice_lance_pierce", 0)) == 1, "pierce gem should add pierce")
	var removed: Dictionary = GemSocketServiceScript.remove_gem(weapon, "frost_gem")
	_expect(bool(removed.get("ok", false)), "remove gem should succeed")
	var after_remove: Dictionary = GemSocketServiceScript.build_socket_stat_totals(Dictionary(removed.get("equipment", {})))
	_expect(int(after_remove.get("cold_damage", 0)) == 0, "removed frost gem should stop adding cold damage")
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_GEM_SOCKET_SERVICE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
