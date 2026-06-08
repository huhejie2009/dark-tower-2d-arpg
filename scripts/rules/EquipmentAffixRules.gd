extends RefCounted
class_name EquipmentAffixRules

const STARTER_EQUIPMENT := {
	"starter_warrior_sword": {
		"name": "新兵斩剑",
		"slot": "weapon",
		"equipment_pool": "warrior",
		"equipment_type": "sword",
		"affixes": {"attack_damage": 10},
	},
	"starter_ranger_bow": {
		"name": "猎手短弓",
		"slot": "weapon",
		"equipment_pool": "ranger",
		"equipment_type": "bow",
		"affixes": {"attack_damage": 7, "projectile_count": 1},
	},
	"starter_mage_staff": {
		"name": "学徒法杖",
		"slot": "weapon",
		"equipment_pool": "mage",
		"equipment_type": "staff",
		"affixes": {"attack_damage": 6, "mana": 15},
	},
	"starter_acolyte_wand": {
		"name": "骨烛短杖",
		"slot": "weapon",
		"equipment_pool": "acolyte",
		"equipment_type": "wand",
		"affixes": {"attack_damage": 6, "summon_damage": 8},
	},
}

static func build_starter_equipment(template_id: String, instance_id: String = "") -> Dictionary:
	var template: Dictionary = Dictionary(STARTER_EQUIPMENT.get(template_id, STARTER_EQUIPMENT["starter_warrior_sword"])).duplicate(true)
	var resolved_id: String = instance_id if instance_id != "" else template_id
	template["instance_id"] = resolved_id
	template["template_id"] = template_id
	template["item_level"] = 1
	template["rarity"] = "common"
	template["locked"] = false
	return template

static func build_floor_drop(floor: int, base_class: String, index: int) -> Dictionary:
	var safe_floor: int = maxi(1, floor)
	var slot: String = "weapon" if index % 3 == 0 else "armor"
	var pool: String = base_class
	var item_id: String = "eq_floor_%03d_%02d" % [safe_floor, index]
	var affixes: Dictionary = {"attack_damage": 5 + safe_floor}
	if slot == "armor":
		affixes = {"defense": 3 + safe_floor, "max_health": 8 + safe_floor * 2}
	if pool == "ranger" and slot == "weapon":
		affixes["projectile_count"] = 1
	if pool == "mage" and slot == "weapon":
		affixes["mana"] = 10 + safe_floor
	if pool == "acolyte" and slot == "weapon":
		affixes["summon_damage"] = 6 + safe_floor
	return {
		"instance_id": item_id,
		"template_id": "floor_drop",
		"name": "塔层装备 %d" % safe_floor,
		"slot": slot,
		"equipment_pool": pool,
		"equipment_type": "blade" if slot == "weapon" else "armor",
		"item_level": safe_floor,
		"rarity": "magic" if safe_floor % 2 == 0 else "common",
		"locked": false,
		"affixes": affixes,
		"mechanic_affixes": {},
	}

static func build_boss_clear_reward(floor: int, base_class: String) -> Dictionary:
	var safe_floor: int = maxi(1, floor)
	var pool := base_class
	var item_id := "eq_boss_%03d_%s" % [safe_floor, pool]
	var affixes: Dictionary = {
		"attack_damage": 8 + safe_floor,
		"max_health": 12 + safe_floor * 2,
	}
	if pool == "ranger":
		affixes["projectile_count"] = 1
	elif pool == "mage":
		affixes["mana"] = 14 + safe_floor
	elif pool == "acolyte":
		affixes["summon_damage"] = 8 + safe_floor
	return {
		"instance_id": item_id,
		"template_id": "boss_clear_reward",
		"name": "Gatekeeper Trophy %d" % safe_floor,
		"slot": "weapon",
		"equipment_pool": pool,
		"equipment_type": "boss_trophy",
		"item_level": safe_floor,
		"rarity": "magic",
		"locked": false,
		"affixes": affixes,
		"mechanic_affixes": {},
	}
