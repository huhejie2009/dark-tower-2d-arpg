extends SceneTree

const TownFacilityServiceScript := preload("res://scripts/data/TownFacilityService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var expected_ids := ["merchant", "blacksmith", "stash", "training"]
	var configs: Dictionary = TownFacilityServiceScript.get_facility_configs()
	for id in expected_ids:
		_expect(configs.has(id), "facility configs should include %s" % id)
		var config := TownFacilityServiceScript.get_facility_config(id)
		_expect(str(config.get("id", "")) == id, "%s should return stable id" % id)
		_expect(str(config.get("title", "")) != "", "%s should provide title" % id)
		_expect(str(config.get("description", "")) != "", "%s should provide description" % id)
		_expect(Array(config.get("actions", [])).size() > 0, "%s should expose at least one action" % id)
		for action in Array(config.get("actions", [])):
			var action_data := Dictionary(action)
			_expect(str(action_data.get("id", "")) != "", "%s action should provide id" % id)
			_expect(str(action_data.get("label", "")) != "", "%s action should provide label" % id)
			_expect(str(action_data.get("kind", "")) != "", "%s action should provide kind" % id)
	_expect(TownFacilityServiceScript.get_facility_config("missing").is_empty(), "unknown facility should be empty")
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_TOWN_FACILITY_SERVICE_CONTRACT_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
