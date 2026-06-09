extends RefCounted
class_name InventoryQueryService

const InventoryDataServiceScript := preload("res://scripts/data/InventoryDataService.gd")
const EquipmentDataServiceScript := preload("res://scripts/data/EquipmentDataService.gd")

const FILTER_MODES := ["all", "equipment", "material", "upgrade", "locked", "favorite", "junk"]
const SORT_MODES := ["type", "power", "name"]

static func normalize_filter_mode(mode: String) -> String:
	return mode if FILTER_MODES.has(mode) else "all"

static func normalize_sort_mode(mode: String) -> String:
	return mode if SORT_MODES.has(mode) else "type"

static func query_item_ids(player_data: Dictionary, options: Dictionary = {}) -> Array[String]:
	var inventory: Dictionary = InventoryDataServiceScript.normalize_inventory(player_data.get("inventory", {}))
	var filter_mode := normalize_filter_mode(str(options.get("filter_mode", "all")))
	var sort_mode := normalize_sort_mode(str(options.get("sort_mode", "type")))
	var item_ids: Array[String] = []
	for item_id in inventory.keys():
		var id := str(item_id)
		var entry: Dictionary = Dictionary(inventory[item_id])
		if _entry_matches_filter(player_data, id, entry, filter_mode):
			item_ids.append(id)
	item_ids.sort_custom(func(a: String, b: String) -> bool:
		return _sort_item_ids(player_data, inventory, a, b, sort_mode)
	)
	return item_ids

static func _entry_matches_filter(player_data: Dictionary, item_id: String, entry: Dictionary, filter_mode: String) -> bool:
	if filter_mode == "all":
		return true
	var item_type := str(entry.get("type", "item"))
	if filter_mode == "equipment":
		return item_type == "equipment"
	if filter_mode == "material":
		return item_type == "material" or item_type == "currency"
	if filter_mode == "upgrade":
		return EquipmentDataServiceScript.is_upgrade_candidate(player_data, item_id)
	var flags := _binding_flags(entry)
	if filter_mode == "locked":
		return bool(flags.get("locked", false))
	if filter_mode == "favorite":
		return bool(flags.get("favorite", false))
	if filter_mode == "junk":
		return bool(flags.get("junk", false))
	return true

static func _sort_item_ids(player_data: Dictionary, inventory: Dictionary, a: String, b: String, sort_mode: String) -> bool:
	var entry_a: Dictionary = Dictionary(inventory.get(a, {}))
	var entry_b: Dictionary = Dictionary(inventory.get(b, {}))
	var locked_a := bool(_binding_flags(entry_a).get("locked", false))
	var locked_b := bool(_binding_flags(entry_b).get("locked", false))
	if locked_a != locked_b:
		return locked_a
	if sort_mode == "name":
		return str(entry_a.get("name", a)).naturalnocasecmp_to(str(entry_b.get("name", b))) < 0
	if sort_mode == "power":
		var score_a := _get_entry_score(player_data, a, entry_a)
		var score_b := _get_entry_score(player_data, b, entry_b)
		if score_a != score_b:
			return score_a > score_b
	var type_a := str(entry_a.get("type", "item"))
	var type_b := str(entry_b.get("type", "item"))
	if type_a != type_b:
		return type_a < type_b
	return str(entry_a.get("name", a)).naturalnocasecmp_to(str(entry_b.get("name", b))) < 0

static func _get_entry_score(player_data: Dictionary, item_id: String, entry: Dictionary) -> int:
	if str(entry.get("type", "")) != "equipment":
		return 0
	return EquipmentDataServiceScript.get_item_score(player_data, item_id)

static func _binding_flags(entry: Dictionary) -> Dictionary:
	var flags: Dictionary = Dictionary(entry.get("binding_flags", {}))
	if entry.has("locked"):
		flags["locked"] = bool(entry.get("locked", false))
	if entry.has("favorite"):
		flags["favorite"] = bool(entry.get("favorite", false))
	if entry.has("junk"):
		flags["junk"] = bool(entry.get("junk", false))
	return flags

