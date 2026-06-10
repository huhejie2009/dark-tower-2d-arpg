extends RefCounted
class_name TownFacilityService

const FACILITY_CONFIGS := {
	"merchant": {
		"id": "merchant",
		"title": "Merchant",
		"subtitle": "Trade goods and clean up your bag.",
		"description": "Use this stop to inspect loot, sell marked junk, and prepare room for the next climb.",
		"actions": [
			{"id": "open_inventory", "label": "Open Bag", "kind": "inventory_filter", "filter_mode": "all", "primary": true},
			{"id": "sell_junk", "label": "Sell Junk", "kind": "inventory_action", "inventory_action": "sell_junk"},
		],
	},
	"blacksmith": {
		"id": "blacksmith",
		"title": "Blacksmith",
		"subtitle": "Break down unwanted gear into materials.",
		"description": "Salvage marked junk here. Upgrade crafting and reforging can attach to this panel later.",
		"actions": [
			{"id": "open_equipment", "label": "Inspect Gear", "kind": "inventory_filter", "filter_mode": "equipment", "primary": true},
			{"id": "salvage_junk", "label": "Salvage Junk", "kind": "inventory_action", "inventory_action": "salvage_junk"},
		],
	},
	"stash": {
		"id": "stash",
		"title": "Stash",
		"subtitle": "Shared storage for gear and materials.",
		"description": "Move items between your bag and stash. Stashed items keep their instance data and do not consume bag slots.",
		"actions": [
			{"id": "open_stash", "label": "Open Stash", "kind": "stash_window", "primary": true},
			{"id": "open_inventory", "label": "Review Bag", "kind": "inventory_filter", "filter_mode": "all"},
		],
	},
	"training": {
		"id": "training",
		"title": "Training",
		"subtitle": "Spend skill points before entering the tower.",
		"description": "Open the skill section and review current growth pressure before the next run.",
		"actions": [
			{"id": "open_skills", "label": "Open Skills", "kind": "skill_panel", "filter_mode": "all", "primary": true},
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
