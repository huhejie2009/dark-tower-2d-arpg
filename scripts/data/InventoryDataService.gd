extends RefCounted
class_name InventoryDataService

const InventoryItemSchemaServiceScript := preload("res://scripts/data/InventoryItemSchemaService.gd")

const DEFAULT_CAPACITY := 40
const PRESSURE_RATIO := 0.80
const FULL_RATIO := 1.0

static func normalize_inventory(inventory: Variant) -> Dictionary:
	if inventory is Dictionary:
		return Dictionary(inventory).duplicate(true)
	return {}

static func add_item(inventory: Dictionary, payload: Dictionary) -> Dictionary:
	var result := normalize_inventory(inventory)
	var item_id := str(payload.get("id", payload.get("name", "item")))
	if item_id == "":
		item_id = "item"
	var item_type := str(payload.get("type", "item"))
	var amount := maxi(1, int(payload.get("amount", 1)))
	if item_type == "equipment":
		amount = 1
	var entry: Dictionary = Dictionary(result.get(item_id, {}))
	if entry.is_empty():
		entry = {"id": item_id, "name": str(payload.get("name", item_id)), "type": item_type, "amount": 0}
	entry["name"] = str(payload.get("name", entry.get("name", item_id)))
	entry["type"] = item_type
	entry["amount"] = int(entry.get("amount", 0)) + amount
	if payload.has("source"):
		entry["source"] = str(payload.get("source", entry.get("source", "normal")))
	if payload.has("loot_quality"):
		entry["loot_quality"] = Dictionary(payload.get("loot_quality", {})).duplicate(true)
	if payload.has("binding_flags"):
		entry["binding_flags"] = Dictionary(payload.get("binding_flags", {})).duplicate(true)
	if payload.has("icon_id"):
		entry["icon_id"] = str(payload.get("icon_id", ""))
	if payload.has("source_tags"):
		entry["source_tags"] = Array(payload.get("source_tags", [])).duplicate(true)
	if payload.has("item_power"):
		entry["item_power"] = int(payload.get("item_power", 0))
	if item_type == "equipment":
		entry["equipment"] = Dictionary(payload.get("equipment", {})).duplicate(true)
	result[item_id] = InventoryItemSchemaServiceScript.normalize_item_entry(item_id, entry)
	return result

static func get_total_items(inventory: Dictionary) -> int:
	var total := 0
	for item_id in inventory.keys():
		total += int(Dictionary(inventory[item_id]).get("amount", 0))
	return total

static func get_default_capacity() -> int:
	return DEFAULT_CAPACITY

static func get_used_slots(inventory: Dictionary) -> int:
	var normalized := normalize_inventory(inventory)
	var used := 0
	for item_id in normalized.keys():
		var entry: Dictionary = Dictionary(normalized[item_id])
		if int(entry.get("amount", 0)) <= 0:
			continue
		used += 1
	return used

static func build_capacity_summary(inventory: Dictionary, capacity: int = DEFAULT_CAPACITY) -> Dictionary:
	var safe_capacity := maxi(1, capacity)
	var used_slots := clampi(get_used_slots(inventory), 0, safe_capacity)
	var ratio := float(used_slots) / float(safe_capacity)
	return {
		"used_slots": used_slots,
		"capacity": safe_capacity,
		"free_slots": maxi(0, safe_capacity - used_slots),
		"pressure_ratio": ratio,
		"pressure": ratio >= PRESSURE_RATIO,
		"full": ratio >= FULL_RATIO,
		"summary_text": "Bag %d/%d" % [used_slots, safe_capacity],
	}
