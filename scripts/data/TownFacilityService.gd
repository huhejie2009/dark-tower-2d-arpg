extends RefCounted
class_name TownFacilityService

const FACILITY_CONFIGS := {
	"merchant": {
		"id": "merchant",
		"title": "商人",
		"subtitle": "交易物资并整理背包。",
		"description": "在这里查看战利品、出售已标记废品，并为下一次爬塔腾出空间。",
		"actions": [
			{"id": "open_inventory", "label": "打开背包", "kind": "inventory_filter", "filter_mode": "all", "primary": true},
			{"id": "sell_junk", "label": "出售废品", "kind": "inventory_action", "inventory_action": "sell_junk"},
		],
	},
	"blacksmith": {
		"id": "blacksmith",
		"title": "铁匠",
		"subtitle": "将不需要的装备分解成材料。",
		"description": "在这里分解已标记废品。后续强化、打造和重铸系统可以接入此面板。",
		"actions": [
			{"id": "open_equipment", "label": "查看装备", "kind": "inventory_filter", "filter_mode": "equipment", "primary": true},
			{"id": "salvage_junk", "label": "分解废品", "kind": "inventory_action", "inventory_action": "salvage_junk"},
		],
	},
	"stash": {
		"id": "stash",
		"title": "仓库",
		"subtitle": "装备与材料的长期存储。",
		"description": "在背包与仓库之间转移物品。入库物品会保留实例数据，并且不占用背包格子。",
		"actions": [
			{"id": "open_stash", "label": "打开仓库", "kind": "stash_window", "primary": true},
			{"id": "open_inventory", "label": "查看背包", "kind": "inventory_filter", "filter_mode": "all"},
		],
	},
	"training": {
		"id": "training",
		"title": "训练场",
		"subtitle": "进塔前分配技能点。",
		"description": "打开技能区域，在下一次挑战前检查当前成长压力。",
		"actions": [
			{"id": "open_skills", "label": "打开技能", "kind": "skill_panel", "filter_mode": "all", "primary": true},
		],
	},
}

static func get_facility_configs() -> Dictionary:
	return FACILITY_CONFIGS.duplicate(true)

static func get_facility_config(id: String) -> Dictionary:
	if not FACILITY_CONFIGS.has(id):
		return {}
	return Dictionary(FACILITY_CONFIGS[id]).duplicate(true)

static func get_action_config(facility_id: String, action_id: String) -> Dictionary:
	var facility := get_facility_config(facility_id)
	for action in Array(facility.get("actions", [])):
		var action_data := Dictionary(action)
		if str(action_data.get("id", "")) == action_id:
			return action_data.duplicate(true)
	return {}
