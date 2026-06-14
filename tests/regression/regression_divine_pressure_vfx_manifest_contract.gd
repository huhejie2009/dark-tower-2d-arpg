extends SceneTree

const DivinePressureServiceScript := preload("res://scripts/data/DivinePressureService.gd")
const GameScene := preload("res://scenes/Game2D.tscn")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	await _check_service_manifest()
	await _check_game2d_warning_manifest()
	_finish()

func _check_service_manifest() -> void:
	var config := DivinePressureServiceScript.build_event_config("elite_defeated", 6)
	var manifest: Dictionary = Dictionary(config.get("vfx_manifest", {}))
	_expect(not manifest.is_empty(), "divine pressure config should include a VFX manifest")
	_expect(str(manifest.get("interface_id", "")) == "divine_pressure_vfx", "VFX manifest should expose a stable interface id")
	_expect(int(manifest.get("interface_version", 0)) == 1, "VFX manifest should expose interface version 1")
	_expect(bool(manifest.get("fallback_programmatic", false)), "VFX manifest should keep programmatic fallback enabled until authored assets exist")
	_expect(str(manifest.get("warning_role", "")) == "enemy_pressure_warning", "warning role should match combat readability color family")
	_expect(str(manifest.get("impact_role", "")) == "enemy_pressure_impact", "impact role should be distinct from warning role")
	_expect(str(manifest.get("warning_scene_path", "")) == "", "warning authored scene path should be empty until real asset is approved")
	_expect(str(manifest.get("impact_scene_path", "")) == "", "impact authored scene path should be empty until real asset is approved")

func _check_game2d_warning_manifest() -> void:
	var scene := GameScene.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	scene.call("trigger_divine_pressure_for_test", Vector2.ZERO, "elite_defeated")
	await process_frame
	var state: Dictionary = scene.call("get_divine_pressure_state_for_test")
	var state_manifest: Dictionary = Dictionary(state.get("vfx_manifest", {}))
	var warning := scene.get_node_or_null("ArenaRoot/DivinePressureWarning")
	_expect(is_instance_valid(warning), "Game2D should spawn divine pressure warning node")
	if is_instance_valid(warning):
		_expect(warning.has_meta("vfx_manifest"), "warning VFX node should carry the VFX manifest")
		var node_manifest: Dictionary = Dictionary(warning.get_meta("vfx_manifest")) if warning.has_meta("vfx_manifest") else {}
		_expect(str(node_manifest.get("interface_id", "")) == str(state_manifest.get("interface_id", "missing")), "warning node manifest should match state manifest")
		_expect(bool(warning.get_meta("fallback_programmatic")) if warning.has_meta("fallback_programmatic") else false, "warning node should mark programmatic fallback usage")
	scene.queue_free()
	await process_frame

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_DIVINE_PRESSURE_VFX_MANIFEST_CONTRACT_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
