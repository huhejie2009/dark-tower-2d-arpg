extends RefCounted
class_name EquipmentActionHintService

const EquipmentDataServiceScript := preload("res://scripts/data/EquipmentDataService.gd")
const EquipmentCompareSummaryServiceScript := preload("res://scripts/data/EquipmentCompareSummaryService.gd")

static func build_hint(player_data: Dictionary, item_id: String) -> Dictionary:
	var inventory: Dictionary = Dictionary(player_data.get("inventory", {}))
	if item_id == "" or not inventory.has(item_id):
		return _blocked("missing_item", "Missing item", "Unavailable")
	var entry: Dictionary = Dictionary(inventory[item_id])
	if str(entry.get("type", "")) != "equipment":
		return _blocked("not_equipment", "Not equipment", "Use")
	var equipment: Dictionary = Dictionary(entry.get("equipment", {}))
	var equipped := EquipmentDataServiceScript.is_equipped_item(player_data, item_id)
	var compare := EquipmentCompareSummaryServiceScript.build_summary(player_data, item_id, equipment)
	var score_delta := int(compare.get("score_delta", 0))
	var can_equip := EquipmentDataServiceScript.can_equip(player_data, item_id)
	if equipped:
		return {
			"item_id": item_id,
			"slot": str(equipment.get("slot", "")),
			"can_equip": false,
			"equipped": true,
			"upgrade": false,
			"reason": "equipped",
			"score_delta": score_delta,
			"button_text": "Equipped",
			"primary_text": "Currently equipped",
			"detail_text": "This item is already in use.",
		}
	if not bool(can_equip.get("ok", false)):
		var reason := str(can_equip.get("reason", "blocked"))
		return {
			"item_id": item_id,
			"slot": str(equipment.get("slot", "")),
			"can_equip": false,
			"equipped": false,
			"upgrade": false,
			"reason": reason,
			"score_delta": score_delta,
			"button_text": _blocked_button_text(reason),
			"primary_text": _blocked_primary_text(reason),
			"detail_text": _blocked_detail_text(reason),
		}
	var upgrade := score_delta > 0
	return {
		"item_id": item_id,
		"slot": str(equipment.get("slot", "")),
		"can_equip": true,
		"equipped": false,
		"upgrade": upgrade,
		"reason": "ok",
		"score_delta": score_delta,
		"button_text": _equip_button_text(score_delta),
		"primary_text": _equippable_primary_text(score_delta),
		"detail_text": _equippable_detail_text(score_delta),
	}

static func _blocked(reason: String, primary_text: String, button_text: String) -> Dictionary:
	return {
		"can_equip": false,
		"equipped": false,
		"upgrade": false,
		"reason": reason,
		"score_delta": 0,
		"button_text": button_text,
		"primary_text": primary_text,
		"detail_text": primary_text,
	}

static func _equip_button_text(score_delta: int) -> String:
	if score_delta > 0:
		return "Equip +%d" % score_delta
	if score_delta < 0:
		return "Equip %d" % score_delta
	return "Equip"

static func _equippable_primary_text(score_delta: int) -> String:
	if score_delta > 0:
		return "Can equip: Upgrade +%d score" % score_delta
	if score_delta < 0:
		return "Can equip: Lower score %d" % score_delta
	return "Can equip: Sidegrade"

static func _equippable_detail_text(score_delta: int) -> String:
	if score_delta > 0:
		return "Recommended if you want more total gear power."
	if score_delta < 0:
		return "Equippable, but weaker than current gear."
	return "Equippable sidegrade. Compare affixes before swapping."

static func _blocked_button_text(reason: String) -> String:
	match reason:
		"wrong_class":
			return "Class blocked"
		"bad_slot":
			return "Bad slot"
		"missing_item":
			return "Missing"
		_:
			return "Blocked"

static func _blocked_primary_text(reason: String) -> String:
	match reason:
		"wrong_class":
			return "Wrong class: cannot equip"
		"bad_slot":
			return "Invalid slot: cannot equip"
		"missing_item":
			return "Missing item"
		_:
			return "Cannot equip: %s" % reason

static func _blocked_detail_text(reason: String) -> String:
	match reason:
		"wrong_class":
			return "This item belongs to another class pool."
		"bad_slot":
			return "This equipment slot is not supported."
		"missing_item":
			return "The selected item is no longer in inventory."
		_:
			return "Equip action is blocked."
