extends SceneTree

const SaveManagerScript := preload("res://scripts/save/SaveManager.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var manager := SaveManagerScript.new()
	_expect(manager.has_method("should_use_transient_save_for_args_for_test"), "SaveManager should expose transient-save arg classifier for QA safety")
	if manager.has_method("should_use_transient_save_for_args_for_test"):
		_expect(
			bool(manager.call("should_use_transient_save_for_args_for_test", ["res://tools/qa_capture_stash_window_screenshot.gd"], [])),
			"QA screenshot tools should use transient save data"
		)
		_expect(
			bool(manager.call("should_use_transient_save_for_args_for_test", ["res://tests/regression/regression_stash_window_contract.gd"], [])),
			"regression tests should keep using transient save data"
		)
		_expect(
			not bool(manager.call("should_use_transient_save_for_args_for_test", ["res://scenes/MainMenu.tscn"], [])),
			"normal game entry should keep persistent save data"
		)
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_QA_TOOLS_USE_TRANSIENT_SAVE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
