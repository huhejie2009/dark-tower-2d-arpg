extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var candidate_path := "res://docs/concepts/pixel_actor_trial/player_warrior_4dir_pixel_sheet_candidate_v1.png"
	var qa_path := "res://docs/qa/pixel_actor_trial/2026-06-13-player-warrior-4dir-candidate-v1-qa.md"
	_expect(FileAccess.file_exists(candidate_path), "player warrior pixel candidate image should be archived")
	_expect(FileAccess.file_exists(qa_path), "player warrior pixel candidate should have QA notes")
	if FileAccess.file_exists(qa_path):
		var text := FileAccess.get_file_as_string(qa_path)
		_expect(text.contains("status: candidate_reference_only"), "QA should mark candidate as reference only")
		_expect(text.contains("runtime_connected: false"), "QA should state the candidate is not runtime connected")
		_expect(text.contains("approved_for_cutting: false"), "QA should state candidate is not approved for cutting")
		_expect(text.contains("每行不足 20 帧"), "QA should record the frame-count failure")
		_expect(text.contains("先只生成单方向 20 帧小条验证"), "QA should recommend next single-direction strip validation")
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_PLAYER_WARRIOR_PIXEL_CANDIDATE_QA_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
