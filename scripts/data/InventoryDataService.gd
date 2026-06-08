extends RefCounted
class_name InventoryDataService

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
	if item_type == "equipment":
		entry["equipment"] = Dictionary(payload.get("equipment", {})).duplicate(true)
	result[item_id] = entry
	return result

static func get_total_items(inventory: Dictionary) -> int:
	var total := 0
	for item_id in inventory.keys():
		total += int(Dictionary(inventory[item_id]).get("amount", 0))
	return total
