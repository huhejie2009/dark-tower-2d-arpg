extends RefCounted
class_name InventoryItemSchemaService

static func normalize_item_entry(item_id: String, payload: Dictionary) -> Dictionary:
	var resolved_id := str(payload.get("id", item_id))
	if resolved_id == "":
		resolved_id = "item"
	var item_type := str(payload.get("type", "item"))
	var entry := payload.duplicate(true)
	entry["id"] = resolved_id
	entry["type"] = item_type
	entry["name"] = str(entry.get("name", resolved_id))
	entry["amount"] = maxi(1, int(entry.get("amount", 1)))
	if item_type == "equipment":
		entry["amount"] = 1
	entry["instance_id"] = _resolve_instance_id(resolved_id, entry)
	entry["item_power"] = _resolve_item_power(entry)
	entry["binding_flags"] = _normalize_binding_flags(entry)
	entry["icon_id"] = _resolve_icon_id(entry)
	entry["source_tags"] = _build_source_tags(entry)
	return entry

static func _resolve_instance_id(item_id: String, entry: Dictionary) -> String:
	if str(entry.get("instance_id", "")) != "":
		return str(entry.get("instance_id", ""))
	var equipment: Dictionary = Dictionary(entry.get("equipment", {}))
	if str(equipment.get("instance_id", "")) != "":
		return str(equipment.get("instance_id", ""))
	return item_id

static func _resolve_item_power(entry: Dictionary) -> int:
	if entry.has("item_power"):
		return maxi(0, int(entry.get("item_power", 0)))
	var equipment: Dictionary = Dictionary(entry.get("equipment", {}))
	if equipment.has("item_power"):
		return maxi(0, int(equipment.get("item_power", 0)))
	if equipment.has("item_level"):
		return maxi(0, int(equipment.get("item_level", 0)))
	var quality: Dictionary = Dictionary(entry.get("loot_quality", {}))
	if quality.has("item_level"):
		return maxi(0, int(quality.get("item_level", 0)))
	return 0

static func _normalize_binding_flags(entry: Dictionary) -> Dictionary:
	var incoming: Dictionary = Dictionary(entry.get("binding_flags", {}))
	var equipment: Dictionary = Dictionary(entry.get("equipment", {}))
	var locked := bool(incoming.get("locked", entry.get("locked", equipment.get("locked", false))))
	var favorite := bool(incoming.get("favorite", entry.get("favorite", false)))
	var junk := bool(incoming.get("junk", entry.get("junk", false)))
	var sellable := bool(incoming.get("sellable", entry.get("sellable", true)))
	return {
		"locked": locked,
		"favorite": favorite,
		"junk": junk,
		"sellable": sellable,
	}

static func _resolve_icon_id(entry: Dictionary) -> String:
	if str(entry.get("icon_id", "")) != "":
		return str(entry.get("icon_id", ""))
	var item_type := str(entry.get("type", "item"))
	if item_type == "equipment":
		var equipment: Dictionary = Dictionary(entry.get("equipment", {}))
		var slot := str(equipment.get("slot", "unknown"))
		var rarity := str(equipment.get("rarity", "common"))
		return "equipment.%s.%s" % [slot, rarity]
	return "item.%s" % item_type

static func _build_source_tags(entry: Dictionary) -> Array[String]:
	var tags: Array[String] = []
	_add_tag(tags, "type:%s" % str(entry.get("type", "item")))
	if str(entry.get("source", "")) != "":
		_add_tag(tags, "source:%s" % str(entry.get("source", "")))
	var quality: Dictionary = Dictionary(entry.get("loot_quality", {}))
	if str(quality.get("source", "")) != "":
		_add_tag(tags, "source:%s" % str(quality.get("source", "")))
	if str(quality.get("quality_tag", "")) != "":
		_add_tag(tags, "quality:%s" % str(quality.get("quality_tag", "")))
	var equipment: Dictionary = Dictionary(entry.get("equipment", {}))
	if not equipment.is_empty():
		_add_tag(tags, "slot:%s" % str(equipment.get("slot", "unknown")))
		_add_tag(tags, "rarity:%s" % str(equipment.get("rarity", "common")))
		if str(equipment.get("equipment_pool", "")) != "":
			_add_tag(tags, "class:%s" % str(equipment.get("equipment_pool", "")))
	return tags

static func _add_tag(tags: Array[String], tag: String) -> void:
	if tag == "" or tags.has(tag):
		return
	tags.append(tag)

