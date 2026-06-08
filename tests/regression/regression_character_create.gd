extends SceneTree

const SaveSchemaScript := preload("res://scripts/save/SaveSchema.gd")
const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")

var failures: Array[String] = []

func _init() -> void:
	for class_id in ["warrior", "ranger", "mage", "acolyte"]:
		var player := PlayerDataServiceScript.build_starter_player("slot_1", "Test", class_id)
		_expect(str(player.get("base_class", "")) == class_id, "starter class should be %s" % class_id)
		_expect(Dictionary(player.get("inventory", {})).size() > 0, "starter should have inventory item")
		_expect(str(Dictionary(player.get("equipped_items", {})).get("weapon", "")) != "", "starter should equip weapon")
	var save := SaveSchemaScript.default_save()
	_expect(Dictionary(save.get("slots", {})).size() == 3, "default save should have three slots")
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_CHARACTER_CREATE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
