extends SceneTree

const DivinePressureServiceScript := preload("res://scripts/data/DivinePressureService.gd")
const DivinePressureVfxProfileScript := preload("res://scripts/data/DivinePressureVfxProfile.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var profile := DivinePressureVfxProfileScript.new()
	var default_manifest: Dictionary = profile.to_manifest()
	var default_report: Dictionary = profile.get_validation_report()
	_expect(str(default_manifest.get("interface_id", "")) == "divine_pressure_vfx", "profile should export stable interface id")
	_expect(int(default_manifest.get("interface_version", 0)) == 1, "profile should export interface version")
	_expect(bool(default_manifest.get("fallback_programmatic", false)), "empty profile should keep programmatic fallback enabled")
	_expect(not bool(default_manifest.get("authored_ready", true)), "empty profile should not be authored-ready")
	_expect(Array(default_report.get("missing_fields", [])).has("warning_scene_path"), "empty profile should report missing warning scene")
	_expect(Array(default_report.get("missing_fields", [])).has("impact_scene_path"), "empty profile should report missing impact scene")
	_expect(bool(default_report.get("can_spawn_with_fallback", false)), "empty profile should still spawn with fallback")

	profile.warning_scene_path = "res://assets/vfx/divine_pressure_warning.tscn"
	profile.impact_scene_path = "res://assets/vfx/divine_pressure_impact.tscn"
	profile.fallback_programmatic = false
	var authored_manifest: Dictionary = profile.to_manifest()
	var service_manifest: Dictionary = DivinePressureServiceScript.build_vfx_manifest(profile)
	_expect(bool(authored_manifest.get("authored_ready", false)), "profile with both scene paths should be authored-ready")
	_expect(not bool(authored_manifest.get("fallback_programmatic", true)), "profile should allow disabling fallback once authored paths exist")
	_expect(str(service_manifest.get("warning_scene_path", "")) == profile.warning_scene_path, "service should copy warning scene path from profile")
	_expect(str(service_manifest.get("impact_scene_path", "")) == profile.impact_scene_path, "service should copy impact scene path from profile")
	_expect(bool(service_manifest.get("authored_ready", false)), "service manifest should preserve authored-ready state")
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_DIVINE_PRESSURE_VFX_PROFILE_RESOURCE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
