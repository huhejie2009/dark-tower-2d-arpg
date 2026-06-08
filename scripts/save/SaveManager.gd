extends RefCounted
class_name SaveManager

const SaveSchemaScript := preload("res://scripts/save/SaveSchema.gd")
const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")
const TowerProgressServiceScript := preload("res://scripts/data/TowerProgressService.gd")

const SAVE_PATH := "user://dark_tower_2d_save.json"

static var transient_save_data: Dictionary = {}

static func load_save() -> Dictionary:
	if is_transient_save_active():
		if transient_save_data.is_empty():
			transient_save_data = SaveSchemaScript.default_save()
		return SaveSchemaScript.normalize_save(transient_save_data)
	if not FileAccess.file_exists(SAVE_PATH):
		var data := SaveSchemaScript.default_save()
		save_data(data)
		return data
	var text := FileAccess.get_file_as_string(SAVE_PATH)
	var parsed = JSON.parse_string(text)
	return SaveSchemaScript.normalize_save(parsed if parsed is Dictionary else {})

static func save_data(data: Dictionary) -> void:
	var normalized := SaveSchemaScript.normalize_save(data)
	if is_transient_save_active():
		transient_save_data = normalized
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(normalized))
	file.flush()

static func is_transient_save_active() -> bool:
	for arg in OS.get_cmdline_args():
		var text := str(arg)
		if text.contains("tests/regression") or text.contains("tests\\regression") or text.begins_with("regression_"):
			return true
	for arg in OS.get_cmdline_user_args():
		var text := str(arg)
		if text.contains("tests/regression") or text.contains("tests\\regression") or text.begins_with("regression_"):
			return true
	return false

static func set_active_slot_in_data(data: Dictionary, slot_id: String) -> Dictionary:
	var result := SaveSchemaScript.normalize_save(data)
	var normalized_slot := slot_id if SaveSchemaScript.SLOT_IDS.has(slot_id) else "slot_1"
	result["active_slot_id"] = normalized_slot
	return result

static func set_active_slot(slot_id: String) -> Dictionary:
	var data := load_save()
	data = set_active_slot_in_data(data, slot_id)
	save_data(data)
	return data

static func create_character(slot_id: String, character_name: String, base_class: String) -> Dictionary:
	var data := load_save()
	if not SaveSchemaScript.SLOT_IDS.has(slot_id):
		slot_id = "slot_1"
	var player := PlayerDataServiceScript.build_starter_player(slot_id, character_name, base_class)
	var slot: Dictionary = data["slots"][slot_id]
	slot["exists"] = true
	slot["character_name"] = str(player.get("character_name", "新角色"))
	slot["base_class"] = str(player.get("base_class", "warrior"))
	slot["player_level"] = int(player.get("player_level", 1))
	slot["highest_floor"] = 1
	slot["player"] = player
	data["active_slot_id"] = slot_id
	save_data(data)
	return player

static func get_active_slot(data: Dictionary) -> Dictionary:
	var normalized := SaveSchemaScript.normalize_save(data)
	var slot_id := str(normalized.get("active_slot_id", "slot_1"))
	return Dictionary(normalized["slots"].get(slot_id, SaveSchemaScript.empty_slot(slot_id)))

static func get_active_player_data() -> Dictionary:
	var data := load_save()
	var slot := get_active_slot(data)
	if not bool(slot.get("exists", false)):
		return create_character(str(data.get("active_slot_id", "slot_1")), "新角色", "warrior")
	return PlayerDataServiceScript.normalize_player_data(slot.get("player", {}))

static func save_active_player_data(player_data: Dictionary, highest_floor: int = 1) -> void:
	var data := load_save()
	var slot_id := str(data.get("active_slot_id", "slot_1"))
	var slot: Dictionary = data["slots"][slot_id]
	var player := PlayerDataServiceScript.normalize_player_data(player_data)
	slot["exists"] = true
	slot["player"] = player
	slot["character_name"] = str(player.get("character_name", "新角色"))
	slot["base_class"] = str(player.get("base_class", "warrior"))
	slot["player_level"] = int(player.get("player_level", 1))
	slot["highest_floor"] = maxi(int(slot.get("highest_floor", 1)), highest_floor)
	save_data(data)

static func apply_floor_clear(floor: int, rewards: Dictionary, player_data: Dictionary) -> void:
	var data := load_save()
	var slot_id := str(data.get("active_slot_id", "slot_1"))
	var slot: Dictionary = data["slots"][slot_id]
	var pending: Dictionary = Dictionary(slot.get("pending_rewards", {}))
	pending["gold"] = int(pending.get("gold", 0)) + int(rewards.get("gold", 0))
	pending["crystal"] = int(pending.get("crystal", 0)) + int(rewards.get("crystal", 0))
	slot["pending_rewards"] = pending
	slot["highest_floor"] = maxi(int(slot.get("highest_floor", 1)), TowerProgressServiceScript.next_floor_after_clear(floor))
	slot["player"] = PlayerDataServiceScript.normalize_player_data(player_data)
	save_data(data)
