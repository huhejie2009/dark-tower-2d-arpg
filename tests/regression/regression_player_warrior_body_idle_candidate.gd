extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var green_path := "res://docs/concepts/pixel_actor_trial/player_warrior_body_down_idle_candidate_v1_green.png"
	var alpha_path := "res://assets/generated/actors/candidates/player_warrior_body_down_idle_candidate_v1.png"
	var qa_path := "res://docs/qa/pixel_actor_trial/2026-06-13-player-warrior-body-down-idle-candidate-v1-qa.md"
	_expect(FileAccess.file_exists(green_path), "body down idle green source should exist")
	_expect(FileAccess.file_exists(alpha_path), "body down idle alpha candidate should exist")
	_expect(FileAccess.file_exists(qa_path), "body down idle candidate should have QA notes")
	if FileAccess.file_exists(alpha_path):
		var image := Image.new()
		var load_result := image.load(ProjectSettings.globalize_path(alpha_path))
		_expect(load_result == OK, "body down idle alpha candidate should load as image")
		_expect(image.get_width() > image.get_height(), "body down idle candidate should be a horizontal strip")
		_expect(image.get_width() >= 1000, "body down idle candidate should be wide enough for 8 cells")
		_expect(image.detect_alpha() != Image.ALPHA_NONE, "body down idle candidate should preserve transparency")
	if FileAccess.file_exists(qa_path):
		var text := FileAccess.get_file_as_string(qa_path)
		_expect(text.contains("candidate_action: idle"), "QA should mark idle action")
		_expect(text.contains("candidate_frame_count: 8"), "QA should mark 8-frame idle strip")
		_expect(text.contains("body_sprites_exclude_weapon: true"), "QA should confirm body sprite excludes weapon")
		_expect(text.contains("runtime_connected: false"), "QA should state candidate is not runtime connected")
		_expect(text.contains("没有混入 run、attack、death"), "QA should confirm action separation")
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_PLAYER_WARRIOR_BODY_IDLE_CANDIDATE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
