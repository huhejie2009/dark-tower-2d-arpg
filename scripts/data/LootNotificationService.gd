extends RefCounted
class_name LootNotificationService

const EquipmentDataServiceScript := preload("res://scripts/data/EquipmentDataService.gd")
const EquipmentRecommendationServiceScript := preload("res://scripts/data/EquipmentRecommendationService.gd")

static func build_pickup_notification(player_data: Dictionary, payload: Dictionary, source: String = "drop") -> Dictionary:
	var item_type := str(payload.get("type", "item"))
	var item_name := str(payload.get("name", payload.get("id", "物品")))
	var amount := maxi(1, int(payload.get("amount", 1)))
	var payload_source := str(Dictionary(payload.get("loot_quality", {})).get("source", payload.get("source", "normal")))
	var notification := {
		"source": source,
		"loot_source": payload_source,
		"item_id": str(payload.get("id", "")),
		"item_name": item_name,
		"item_type": item_type,
		"quantity": amount,
		"quantity_text": "x%d" % amount,
		"rarity": _get_payload_rarity(payload),
		"score": 0,
		"upgrade": false,
		"boss_reward": source == "boss_reward",
		"source_label": _source_label(source, payload_source),
		"quality_tag": str(Dictionary(payload.get("loot_quality", {})).get("quality_tag", "")),
		"short_tag": "",
		"score_delta": 0,
		"equipped_score": 0,
		"recommendation_rank": "none",
		"recommendation_text": "",
		"headline": "获得战利品",
		"log_text": "拾取：%s" % item_name,
		"accent_color": "#9ca3af",
	}
	if item_type == "equipment":
		var equipment: Dictionary = Dictionary(payload.get("equipment", {}))
		var candidate_data := player_data.duplicate(true)
		var inventory: Dictionary = Dictionary(candidate_data.get("inventory", {})).duplicate(true)
		inventory[str(payload.get("id", ""))] = {
			"id": str(payload.get("id", "")),
			"name": item_name,
			"type": "equipment",
			"amount": 1,
			"equipment": equipment,
		}
		candidate_data["inventory"] = inventory
		var score := EquipmentDataServiceScript.get_equipment_score(equipment)
		var upgrade := EquipmentDataServiceScript.is_upgrade_candidate(candidate_data, str(payload.get("id", "")))
		var recommendation := EquipmentRecommendationServiceScript.build_recommendation(player_data, equipment, Dictionary(payload.get("loot_quality", {})))
		notification["score"] = score
		notification["upgrade"] = upgrade
		notification["equipped_score"] = int(recommendation.get("equipped_score", 0))
		notification["score_delta"] = int(recommendation.get("score_delta", 0))
		notification["recommendation_rank"] = str(recommendation.get("recommendation_rank", "none"))
		notification["recommendation_text"] = str(recommendation.get("recommendation_text", ""))
		notification["source_label"] = str(recommendation.get("source_label", notification.get("source_label", "掉落"))) if source != "boss_reward" else "Boss 奖励"
		notification["headline"] = "Boss 奖励" if source == "boss_reward" else ("发现提升装备" if upgrade else "获得装备")
		notification["short_tag"] = _build_short_tag(notification)
		notification["log_text"] = "%s：%s | %s | 评分 %d%s" % [
			str(notification["headline"]),
			item_name,
			_rarity_label(str(notification["rarity"])),
			score,
			" | 提升" if upgrade else "",
		]
	else:
		if item_type == "gem":
			notification["headline"] = "获得宝石"
		else:
			notification["headline"] = "获得货币" if item_type == "currency" else "获得材料"
		notification["short_tag"] = str(notification.get("source_label", "掉落"))
		notification["log_text"] = "%s：%s %s" % [str(notification["headline"]), item_name, str(notification["quantity_text"])]
	notification["accent_color"] = _rarity_color_hex(str(notification.get("rarity", "common")))
	return notification

static func _source_label(notification_source: String, loot_source: String) -> String:
	if notification_source == "boss_reward" or loot_source == "boss":
		return "Boss 奖励"
	if loot_source == "elite":
		return "精英掉落"
	return "掉落"

static func _rarity_label(rarity: String) -> String:
	match rarity:
		"magic":
			return "魔法"
		"rare":
			return "稀有"
		"legendary":
			return "传奇"
		"currency":
			return "货币"
		"material":
			return "材料"
		"gem":
			return "宝石"
		_:
			return "普通"

static func _build_short_tag(notification: Dictionary) -> String:
	var tags: Array[String] = []
	var source_label := str(notification.get("source_label", ""))
	if source_label != "":
		tags.append(source_label)
	var recommendation := str(notification.get("recommendation_text", ""))
	if recommendation != "":
		tags.append(recommendation)
	return " | ".join(tags)

static func _get_payload_rarity(payload: Dictionary) -> String:
	if str(payload.get("type", "")) == "equipment":
		return str(Dictionary(payload.get("equipment", {})).get("rarity", "common"))
	var item_type := str(payload.get("type", "item"))
	if item_type == "currency":
		return "currency"
	if item_type == "material":
		return "material"
	if item_type == "gem":
		return "gem"
	return "common"

static func _rarity_color_hex(rarity: String) -> String:
	match rarity:
		"magic":
			return "#4fa3ff"
		"rare":
			return "#d5b94f"
		"legendary":
			return "#d9763c"
		"currency":
			return "#c7a34a"
		"material":
			return "#8b949e"
		"gem":
			return "#72d7ff"
		_:
			return "#9ca3af"
