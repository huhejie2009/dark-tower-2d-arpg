extends SceneTree

const GameConstantsScript := preload("res://scripts/app/GameConstants.gd")
const SceneRouterScript := preload("res://scripts/app/SceneRouter.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var expected_scene := "res://scenes/prototypes/Prototype2_5DCombatRoom.tscn"
	_expect(GameConstantsScript.ACTIVE_GAME_SCENE == expected_scene, "active game scene should point to 2.5D prototype")
	_expect(GameConstantsScript.PROTOTYPE_2_5D_COMBAT_SCENE == expected_scene, "2.5D prototype constant should be explicit")
	_expect(GameConstantsScript.GAME_2D_SCENE == "res://scenes/Game2D.tscn", "legacy 2D combat scene should remain available")
	_expect(SceneRouterScript.get_active_game_scene_for_test() == expected_scene, "game router should use active game scene")

	var packed := load(expected_scene)
	_expect(packed is PackedScene, "active 2.5D game scene should load")
	if packed is PackedScene:
		var scene: Node = packed.instantiate()
		root.add_child(scene)
		await process_frame
		_expect(scene.has_method("build_prototype_snapshot_for_test"), "active 2.5D scene should expose prototype snapshot")
		scene.queue_free()
		await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_ACTIVE_GAME_MODE_2_5D_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
