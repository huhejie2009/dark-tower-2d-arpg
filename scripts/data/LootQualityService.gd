extends RefCounted
class_name LootQualityService

const SOURCE_BONUS := {
	"normal": {
		"equipment": 0.0,
		"rare": 0.0,
		"legendary": 0.0,
		"level": 0,
	},
	"elite": {
		"equipment": 0.12,
		"rare": 0.16,
		"legendary": 0.03,
		"level": 1,
	},
	"boss": {
		"equipment": 1.0,
		"rare": 0.30,
		"legendary": 0.10,
		"level": 2,
	},
}

static func build_quality_profile(floor: int, source: String = "normal", kill_index: int = 1) -> Dictionary:
	var safe_floor := maxi(1, floor)
	var safe_source := source if SOURCE_BONUS.has(source) else "normal"
	var bonus: Dictionary = Dictionary(SOURCE_BONUS[safe_source])
	var floor_band := int((safe_floor - 1) / 3)
	var equipment_chance := clampf(0.30 + safe_floor * 0.018 + float(bonus.get("equipment", 0.0)), 0.0, 1.0)
	var magic_chance := clampf(0.28 + safe_floor * 0.018, 0.0, 0.82)
	var rare_chance := clampf(0.04 + floor_band * 0.035 + float(bonus.get("rare", 0.0)), 0.0, 0.70)
	var legendary_chance := clampf(0.005 + floor_band * 0.01 + float(bonus.get("legendary", 0.0)), 0.0, 0.35)
	return {
		"source": safe_source,
		"floor": safe_floor,
		"kill_index": maxi(1, kill_index),
		"item_level": safe_floor + int(bonus.get("level", 0)),
		"equipment_chance": equipment_chance,
		"magic_chance": magic_chance,
		"rare_chance": rare_chance,
		"legendary_chance": legendary_chance,
		"guaranteed_equipment": safe_source == "boss",
		"quality_tag": _build_quality_tag(safe_floor, safe_source),
	}

static func choose_drop_kind(profile: Dictionary, kill_index: int) -> String:
	if bool(profile.get("guaranteed_equipment", false)):
		return "equipment"
	var safe_kill := maxi(1, kill_index)
	if safe_kill % 3 == 0:
		return "equipment"
	if safe_kill % 2 == 0:
		return "material"
	return "currency"

static func choose_rarity(profile: Dictionary, salt: int = 0) -> String:
	if bool(profile.get("guaranteed_equipment", false)):
		if _roll01(profile, salt) < float(profile.get("legendary_chance", 0.0)):
			return "legendary"
		return "rare"
	if str(profile.get("source", "normal")) == "elite" and salt % 3 == 0:
		return "rare"
	var roll := _roll01(profile, salt)
	if roll < float(profile.get("legendary_chance", 0.0)):
		return "legendary"
	if roll < float(profile.get("rare_chance", 0.0)):
		return "rare"
	if roll < float(profile.get("magic_chance", 0.0)):
		return "magic"
	if str(profile.get("source", "normal")) == "elite":
		return "magic"
	return "common"

static func _roll01(profile: Dictionary, salt: int) -> float:
	var seed := int(profile.get("floor", 1)) * 110351 + int(profile.get("kill_index", 1)) * 9176 + salt * 131
	return float(abs(seed) % 1000) / 1000.0

static func _build_quality_tag(floor: int, source: String) -> String:
	if source == "boss":
		return "boss_floor_%02d" % floor
	if source == "elite":
		return "elite_floor_%02d" % floor
	return "floor_%02d" % floor
