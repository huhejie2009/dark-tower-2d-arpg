extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var green_path := "res://docs/concepts/pixel_actor_trial/player_warrior_down_pixel_strip_candidate_v1_green.png"
	var alpha_path := "res://assets/generated/actors/candidates/player_warrior_down_pixel_strip_candidate_v1.png"
	var qa_path := "res://docs/qa/pixel_actor_trial/2026-06-13-player-warrior-down-strip-candidate-v1-qa.md"
	_expect(FileAccess.file_exists(green_path), "player warrior down strip green source should exist")
	_expect(FileAccess.file_exists(alpha_path), "player warrior down strip alpha candidate should exist")
	_expect(FileAccess.file_exists(qa_path), "player warrior down strip candidate should have QA notes")
	if FileAccess.file_exists(alpha_path):
		var image := Image.new()
		var load_result := image.load(ProjectSettings.globalize_path(alpha_path))
		_expect(load_result == OK, "alpha candidate should load as an image")
		_expect(image.get_width() > image.get_height(), "alpha candidate should be a horizontal strip")
		_expect(image.get_width() >= 1200, "alpha candidate should be wide enough for 20 cells")
		_expect(image.get_format() == Image.FORMAT_RGBA8 or image.detect_alpha() != Image.ALPHA_NONE, "alpha candidate should preserve transparency")
	if FileAccess.file_exists(qa_path):
		var text := FileAccess.get_file_as_string(qa_path)
		_expect(text.contains("status: candidate_cutting_ready"), "QA should mark the down strip as cutting-ready candidate")
		_expect(text.contains("runtime_connected: false"), "QA should state the candidate is not runtime connected")
		_expect(text.contains("candidate_direction: down"), "QA should mark candidate direction")
		_expect(text.contains("candidate_frame_count: 20"), "QA should mark expected frame count")
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_PLAYER_WARRIOR_DOWN_STRIP_CANDIDATE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
