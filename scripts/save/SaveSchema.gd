extends RefCounted
class_name SaveSchema

const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")

const SAVE_VERSION := 1
const SLOT_IDS := ["slot_1", "slot_2", "slot_3"]

static func default_save() -> Dictionary:
	var slots := {}
	for slot_id in SLOT_IDS:
		slots[slot_id] = empty_slot(slot_id)
	return {"save_version": SAVE_VERSION, "active_slot_id": "slot_1", "slots": slots}

static func empty_slot(slot_id: String) -> Dictionary:
	return {
		"slot_id": slot_id,
		"exists": false,
		"character_name": "",
		"base_class": "",
		"advanced_class": "",
		"player_level": 1,
		"highest_floor": 1,
		"player": {},
		"stash": {},
		"vendor_buyback": [],
		"currencies": {"gold": 0, "crystal": 0},
		"pending_rewards": {"gold": 0, "crystal": 0},
	}

static func normalize_save(data: Variant) -> Dictionary:
	var result := default_save()
	if not (data is Dictionary):
		return result
	var input: Dictionary = data
	result["save_version"] = SAVE_VERSION
	result["active_slot_id"] = str(input.get("active_slot_id", "slot_1"))
	for slot_id in SLOT_IDS:
		var slot: Dictionary = Dictionary(Dictionary(input.get("slots", {})).get(slot_id, {}))
		if slot.is_empty():
			continue
		result["slots"][slot_id] = normalize_slot(slot_id, slot)
	if not SLOT_IDS.has(str(result["active_slot_id"])):
		result["active_slot_id"] = "slot_1"
	return result

static func normalize_slot(slot_id: String, slot: Dictionary) -> Dictionary:
	var result := empty_slot(slot_id)
	for key in slot.keys():
		result[key] = slot[key]
	result["slot_id"] = slot_id
	result["exists"] = bool(result.get("exists", false))
	if result["exists"]:
		result["player"] = PlayerDataServiceScript.normalize_player_data(result.get("player", {}))
		result["character_name"] = str(result["player"].get("character_name", result.get("character_name", "")))
		result["base_class"] = str(result["player"].get("base_class", result.get("base_class", "warrior")))
		result["player_level"] = int(result["player"].get("player_level", result.get("player_level", 1)))
		result["highest_floor"] = maxi(1, int(result.get("highest_floor", result["player"].get("highest_floor", 1))))
	if not (result.get("currencies", {}) is Dictionary):
		result["currencies"] = {"gold": 0, "crystal": 0}
	if not (result.get("pending_rewards", {}) is Dictionary):
		result["pending_rewards"] = {"gold": 0, "crystal": 0}
	if not (result.get("stash", {}) is Dictionary):
		result["stash"] = {}
	if not (result.get("vendor_buyback", []) is Array):
		result["vendor_buyback"] = []
	return result
