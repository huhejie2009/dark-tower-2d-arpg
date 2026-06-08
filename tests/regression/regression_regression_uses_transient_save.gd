extends SceneTree

const SaveManagerScript := preload("res://scripts/save/SaveManager.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_expect(SaveManagerScript.is_transient_save_active(), "regression scripts should use transient save data")
	var save := SaveManagerScript.load_save()
	save["active_slot_id"] = "slot_1"
	var slot: Dictionary = Dictionary(save["slots"]["slot_1"])
	slot["exists"] = true
	slot["highest_floor"] = 77
	save["slots"]["slot_1"] = slot
	SaveManagerScript.save_data(save)

	var loaded := SaveManagerScript.load_save()
	_expect(int(Dictionary(loaded["slots"]["slot_1"]).get("highest_floor", 0)) == 77, "transient save should persist within current regression process")
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_REGRESSION_TRANSIENT_SAVE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
