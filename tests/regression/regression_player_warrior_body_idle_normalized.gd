extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var strip_path := "res://assets/generated/actors/candidates/player_warrior_body_down_idle_normalized_v1.png"
	var metrics_path := "res://docs/qa/pixel_actor_trial/player_warrior_body_down_idle_normalized_v1_metrics.json"
	var preview_path := "res://docs/qa/pixel_actor_trial/player_warrior_body_down_idle_normalized_v1_baseline_preview.png"
	var qa_path := "res://docs/qa/pixel_actor_trial/2026-06-13-player-warrior-body-down-idle-normalized-v1-qa.md"
	_expect(FileAccess.file_exists(strip_path), "normalized idle strip should exist")
	_expect(FileAccess.file_exists(metrics_path), "normalized idle metrics should exist")
	_expect(FileAccess.file_exists(preview_path), "normalized idle preview should exist")
	_expect(FileAccess.file_exists(qa_path), "normalized idle QA doc should exist")
	if FileAccess.file_exists(strip_path):
		var image := Image.new()
		_expect(image.load(ProjectSettings.globalize_path(strip_path)) == OK, "normalized idle strip should load")
		_expect(image.get_width() == 192 * 8, "normalized idle strip should be 8 frames wide")
		_expect(image.get_height() == 320, "normalized idle strip should use 320 px frame height")
	if FileAccess.file_exists(metrics_path):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(metrics_path))
		_expect(parsed is Dictionary, "normalized metrics should parse as dictionary")
		if parsed is Dictionary:
			var metrics: Dictionary = parsed
			var frame_size: Dictionary = Dictionary(metrics.get("frame_size", {}))
			_expect(int(metrics.get("frame_count", 0)) == 8, "normalized metrics should describe 8 frames")
			_expect(int(frame_size.get("x", 0)) == 192, "normalized frame width should be 192")
			_expect(int(frame_size.get("y", 0)) == 320, "normalized frame height should be 320")
			_expect(int(metrics.get("anchor_y", -1)) == 288, "normalized anchor y should be 288")
			_expect(int(metrics.get("max_foot_baseline_drift_px", 999)) <= 1, "normalized foot baseline drift should be <= 1 px")
			_expect(float(metrics.get("max_center_drift_px", 999.0)) <= 2.0, "normalized center drift should be <= 2 px")
			_expect(String(metrics.get("weapon_layer_mode", "")) == "body_only_no_weapon", "normalized strip should stay body-only")
			_expect(not bool(metrics.get("runtime_connected", true)), "normalized strip should not be runtime connected yet")
			_expect(not bool(metrics.get("approved_for_manifest_switch", true)), "normalized strip should not be approved for manifest switch yet")
			var frames: Array = Array(metrics.get("frames", []))
			_expect(frames.size() == 8, "normalized metrics should include 8 frame entries")
			for frame_data in frames:
				var frame: Dictionary = Dictionary(frame_data)
				_expect(bool(frame.get("has_pixels", false)), "each normalized frame should contain visible pixels")
				_expect(int(frame.get("max_y", -1)) == 288, "each normalized frame should land on anchor y")
	if FileAccess.file_exists(qa_path):
		var text := FileAccess.get_file_as_string(qa_path)
		_expect(text.contains("frame_size: 192x320"), "QA should record normalized frame size")
		_expect(text.contains("runtime_connected: false"), "QA should record runtime connection status")
		_expect(text.contains("max_foot_baseline_drift_px: 0"), "QA should record foot baseline drift")
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_PLAYER_WARRIOR_BODY_IDLE_NORMALIZED_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
