extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var metrics_path := "res://docs/qa/pixel_actor_trial/player_warrior_body_down_idle_candidate_v1_metrics.json"
	var preview_path := "res://docs/qa/pixel_actor_trial/player_warrior_body_down_idle_candidate_v1_baseline_preview.png"
	var qa_path := "res://docs/qa/pixel_actor_trial/2026-06-13-player-warrior-body-down-idle-candidate-v1-qa.md"
	_expect(FileAccess.file_exists(metrics_path), "idle candidate metrics JSON should exist")
	_expect(FileAccess.file_exists(preview_path), "idle candidate baseline preview should exist")
	if FileAccess.file_exists(metrics_path):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(metrics_path))
		_expect(parsed is Dictionary, "idle metrics should parse as dictionary")
		if parsed is Dictionary:
			var metrics: Dictionary = parsed
			_expect(int(metrics.get("frame_count", 0)) == 8, "idle metrics should describe 8 frames")
			_expect(int(metrics.get("cell_width", 0)) > 0, "idle metrics should include cell width")
			_expect(int(metrics.get("max_foot_baseline_drift_px", 999)) <= 3, "idle foot baseline drift should be <= 3 px")
			_expect(not bool(metrics.get("runtime_connected", true)), "idle metrics should state not runtime connected")
			_expect(not bool(metrics.get("approved_for_manifest_switch", true)), "idle metrics should block manifest switch")
			var frames: Array = Array(metrics.get("frames", []))
			_expect(frames.size() == 8, "idle metrics should include 8 frame entries")
			for frame_data in frames:
				var frame: Dictionary = Dictionary(frame_data)
				_expect(bool(frame.get("has_pixels", false)), "each idle frame should contain visible pixels")
	if FileAccess.file_exists(preview_path):
		var image := Image.new()
		_expect(image.load(ProjectSettings.globalize_path(preview_path)) == OK, "baseline preview should load")
	if FileAccess.file_exists(qa_path):
		var text := FileAccess.get_file_as_string(qa_path)
		_expect(text.contains("max_foot_baseline_drift_px: 2"), "QA should record baseline drift")
		_expect(text.contains("需要归一化后才允许进入运行时测试"), "QA should require normalization before runtime test")
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_PLAYER_WARRIOR_BODY_IDLE_ANCHOR_METRICS_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
