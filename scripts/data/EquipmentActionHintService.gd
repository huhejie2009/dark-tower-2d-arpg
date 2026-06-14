extends RefCounted
class_name EquipmentActionHintService

const EquipmentDataServiceScript := preload("res://scripts/data/EquipmentDataService.gd")
const EquipmentCompareSummaryServiceScript := preload("res://scripts/data/EquipmentCompareSummaryService.gd")

static func build_hint(player_data: Dictionary, item_id: String) -> Dictionary:
	var inventory: Dictionary = Dictionary(player_data.get("inventory", {}))
	if item_id == "" or not inventory.has(item_id):
		return _blocked("missing_item", "物品不存在", "不可用")
	var entry: Dictionary = Dictionary(inventory[item_id])
	if str(entry.get("type", "")) != "equipment":
		return _blocked("not_equipment", "不是装备", "使用")
	var equipment: Dictionary = Dictionary(entry.get("equipment", {}))
	var equipped := EquipmentDataServiceScript.is_equipped_item(player_data, item_id)
	var compare := EquipmentCompareSummaryServiceScript.build_summary(player_data, item_id, equipment)
	var score_delta := int(compare.get("score_delta", 0))
	var can_equip := EquipmentDataServiceScript.can_equip(player_data, item_id)
	if equipped:
		return {
			"item_id": item_id,
			"slot": str(compare.get("slot", equipment.get("slot", ""))),
			"can_equip": false,
			"equipped": true,
			"upgrade": false,
			"reason": "equipped",
			"score_delta": score_delta,
			"button_text": "已装备",
			"primary_text": "当前已装备",
			"detail_text": "这件物品已经在使用中。",
		}
	if not bool(can_equip.get("ok", false)):
		var reason := str(can_equip.get("reason", "blocked"))
		return {
			"item_id": item_id,
			"slot": str(compare.get("slot", equipment.get("slot", ""))),
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
		"slot": str(compare.get("slot", equipment.get("slot", ""))),
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
		return "装备 +%d" % score_delta
	if score_delta < 0:
		return "装备 %d" % score_delta
	return "装备"

static func _equippable_primary_text(score_delta: int) -> String:
	if score_delta > 0:
		return "可装备：评分提升 +%d" % score_delta
	if score_delta < 0:
		return "可装备：评分降低 %d" % score_delta
	return "可装备：平替"

static func _equippable_detail_text(score_delta: int) -> String:
	if score_delta > 0:
		return "如果想提升总装备强度，建议更换。"
	if score_delta < 0:
		return "可以装备，但整体弱于当前装备。"
	return "可作为平替。更换前建议对比词条。"

static func _blocked_button_text(reason: String) -> String:
	match reason:
		"wrong_class":
			return "职业不符"
		"bad_slot":
			return "槽位错误"
		"missing_item":
			return "缺失"
		_:
			return "不可装备"

static func _blocked_primary_text(reason: String) -> String:
	match reason:
		"wrong_class":
			return "职业不符：无法装备"
		"bad_slot":
			return "槽位无效：无法装备"
		"missing_item":
			return "物品不存在"
		_:
			return "无法装备：%s" % reason

static func _blocked_detail_text(reason: String) -> String:
	match reason:
		"wrong_class":
			return "这件物品属于其他职业装备池。"
		"bad_slot":
			return "当前装备槽位暂不支持。"
		"missing_item":
			return "所选物品已不在背包中。"
		_:
			return "装备操作被阻止。"
