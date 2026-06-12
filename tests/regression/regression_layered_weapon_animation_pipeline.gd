extends SceneTree

const Game2DScene := preload("res://scenes/Game2D.tscn")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := Game2DScene.instantiate()
	root.add_child(scene)
	await process_frame
	_assert_player_manifest(scene)
	_assert_pipeline_document()
	scene.queue_free()
	await process_frame
	_finish()

func _assert_player_manifest(scene: Node) -> void:
	_expect(scene.has_method("_get_default_actor_art_contract_for_test"), "Game2D should expose default actor art contract")
	if not scene.has_method("_get_default_actor_art_contract_for_test"):
		return
	var contract: Dictionary = scene.call("_get_default_actor_art_contract_for_test")
	_expect(str(contract.get("actor_animation_pipeline", "")) == "action_separated", "player manifest should require separated action generation")
	_expect(str(contract.get("weapon_layer_mode", "")) == "external_attach", "player manifest should reserve external weapon attach layer")
	_expect(bool(contract.get("body_sprites_must_exclude_weapon", false)), "player body sprites should exclude baked weapons")
	var smooth: Dictionary = Dictionary(contract.get("smooth_animation_requirements", {}))
	_expect(int(smooth.get("idle_min_frames", 0)) >= 6, "idle should have enough frames for smooth breathing")
	_expect(int(smooth.get("run_min_frames", 0)) >= 8, "run should have enough frames for smooth footwork")
	_expect(int(smooth.get("attack_min_frames", 0)) >= 8, "attack should have enough frames for windup/strike/recovery")
	_expect(int(smooth.get("death_min_frames", 0)) >= 6, "death should have enough frames for readable collapse")

func _assert_pipeline_document() -> void:
	var path := "res://docs/content/2026-06-13-layered-weapon-action-separated-pipeline.md"
	_expect(FileAccess.file_exists(path), "layered weapon action-separated pipeline doc should exist")
	if not FileAccess.file_exists(path):
		return
	var text := FileAccess.get_file_as_string(path)
	_expect(text.contains("action_separated"), "pipeline doc should name the action_separated pipeline")
	_expect(text.contains("external_attach"), "pipeline doc should name the external weapon attach mode")
	_expect(text.contains("body sprites must not include baked weapons"), "pipeline doc should forbid baked weapons in player body sprites")
	_expect(text.contains("idle, run, attack, and death are generated separately"), "pipeline doc should require separate action generation")
	_expect(text.contains("run_min_frames: 8"), "pipeline doc should require smooth run frame count")
	_expect(text.contains("weapon_anchor_tracks"), "pipeline doc should reserve weapon anchor tracks")

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_LAYERED_WEAPON_ANIMATION_PIPELINE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
