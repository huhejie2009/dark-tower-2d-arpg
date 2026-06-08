extends SceneTree

const SCENES := [
	"res://scenes/MainMenu.tscn",
	"res://scenes/CharacterSelect.tscn",
	"res://scenes/Town.tscn",
	"res://scenes/Game2D.tscn",
]

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for scene_path in SCENES:
		var packed := load(scene_path)
		_expect(packed is PackedScene, "%s should load" % scene_path)
		if not packed is PackedScene:
			continue
		var scene: Node = packed.instantiate()
		if scene_path == "res://scenes/Game2D.tscn":
			scene.set("player_data", {})
		root.add_child(scene)
		await process_frame
		print("SCENE_BOOT_OK %s" % scene_path)
		scene.queue_free()
		await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_SCENE_BOOT_ALL_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
