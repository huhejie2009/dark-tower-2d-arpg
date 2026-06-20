extends SceneTree

const SCREENSHOT_TOOLS := [
	"res://tools/qa_capture_town_screenshot.gd",
	"res://tools/qa_capture_town_facility_screenshot.gd",
	"res://tools/qa_capture_stash_window_screenshot.gd",
]

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for path in SCREENSHOT_TOOLS:
		var absolute_path := ProjectSettings.globalize_path(path)
		_expect(FileAccess.file_exists(path), "%s should exist" % path)
		var source := FileAccess.get_file_as_string(path)
		_expect(source.contains("DisplayServer.get_name() == \"headless\""), "%s should guard against headless viewport capture hangs" % path)
		_expect(source.contains("requires rendered Godot"), "%s should explain that screenshot QA needs rendered Godot" % path)
		_expect(source.contains("quit(2)"), "%s should fail fast instead of hanging in headless mode" % path)
		_expect(absolute_path.ends_with(".gd"), "%s should resolve as a tool script" % path)
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_QA_SCREENSHOT_TOOLS_HEADLESS_GUARD_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
