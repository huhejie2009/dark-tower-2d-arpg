extends SceneTree

const DivinePressureServiceScript := preload("res://scripts/data/DivinePressureService.gd")

const PROFILE_PATH := "res://assets/vfx/divine_pressure/default_divine_pressure_vfx_profile.tres"

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_expect(ResourceLoader.exists(PROFILE_PATH), "default divine pressure VFX profile resource should exist")
	var profile := load(PROFILE_PATH)
	_expect(profile != null, "default divine pressure VFX profile should load")
	if profile != null:
		_expect(profile.has_method("to_manifest"), "default profile should export manifest")
		_expect(profile.has_method("get_validation_report"), "default profile should expose validation report")
		var manifest: Dictionary = Dictionary(profile.call("to_manifest"))
		var report: Dictionary = Dictionary(profile.call("get_validation_report"))
		_expect(str(manifest.get("interface_id", "")) == "divine_pressure_vfx", "default profile should use divine pressure interface")
		_expect(str(manifest.get("warning_scene_path", "not-empty")) == "", "default warning scene path should stay empty until authored VFX exists")
		_expect(str(manifest.get("impact_scene_path", "not-empty")) == "", "default impact scene path should stay empty until authored VFX exists")
		_expect(bool(manifest.get("fallback_programmatic", false)), "default profile should keep fallback enabled")
		_expect(not bool(manifest.get("authored_ready", true)), "default profile should not claim authored readiness")
		_expect(bool(report.get("can_spawn_with_fallback", false)), "default profile should be spawnable through fallback")
		var service_manifest: Dictionary = DivinePressureServiceScript.build_vfx_manifest(profile)
		_expect(str(service_manifest.get("interface_id", "")) == "divine_pressure_vfx", "service should consume default profile manifest")
		_expect(bool(service_manifest.get("fallback_programmatic", false)), "service manifest should preserve fallback flag")
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_DEFAULT_DIVINE_PRESSURE_VFX_PROFILE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
