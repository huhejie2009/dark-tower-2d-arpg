extends SceneTree

const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")
const InventoryDataServiceScript := preload("res://scripts/data/InventoryDataService.gd")
const TownPrepRecommendationServiceScript := preload("res://scripts/data/TownPrepRecommendationService.gd")
const TownPrepSummaryServiceScript := preload("res://scripts/data/TownPrepSummaryService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var inventory := {}
	inventory = InventoryDataServiceScript.add_item(inventory, {"id": "gold", "name": "Gold", "type": "currency", "amount": 120})
	inventory = InventoryDataServiceScript.add_item(inventory, {"id": "crystal_shard", "name": "Crystal", "type": "material", "amount": 14})
	inventory = InventoryDataServiceScript.add_item(inventory, _equipment_payload("sword_a"))
	inventory = InventoryDataServiceScript.add_item(inventory, _equipment_payload("sword_b"))

	var inventory_service := InventoryDataServiceScript.new()
	_expect(inventory_service.has_method("get_default_capacity"), "inventory service should expose default capacity")
	_expect(inventory_service.has_method("get_used_slots"), "inventory service should expose slot usage")
	_expect(inventory_service.has_method("build_capacity_summary"), "inventory service should expose capacity summary")
	if inventory_service.has_method("get_used_slots"):
		_expect(int(inventory_service.call("get_used_slots", inventory)) == 4, "currency/material stacks and equipment instances should use 4 slots")
	if inventory_service.has_method("build_capacity_summary"):
		var capacity: Dictionary = Dictionary(inventory_service.call("build_capacity_summary", inventory))
		_expect(int(capacity.get("used_slots", 0)) == 4, "capacity summary should include used slots")
		_expect(int(capacity.get("capacity", 0)) == 40, "capacity summary should expose default 40 slot cap")
		_expect(str(capacity.get("summary_text", "")).contains("Bag 4/40"), "capacity summary should produce compact UI text")
		_expect(not bool(capacity.get("pressure", true)), "4/40 should not be bag pressure")

	var player := PlayerDataServiceScript.build_starter_player("slot_1", "Capacity", "warrior")
	var pressure_inventory := {}
	for i in range(32):
		pressure_inventory = InventoryDataServiceScript.add_item(pressure_inventory, _equipment_payload("item_%02d" % i))
	player["inventory"] = pressure_inventory
	var prep: Dictionary = TownPrepRecommendationServiceScript.build_recommendations(player)
	var items: Array = Array(prep.get("items", []))
	var bag_item := _find_recommendation(items, "manage_bag")
	_expect(not bag_item.is_empty(), "bag pressure should be based on capacity usage")
	_expect(str(bag_item.get("text", "")).contains("32/40"), "bag pressure text should show used/capacity")
	_expect(int(bag_item.get("used_slots", 0)) == 32, "bag recommendation should expose used slots")
	_expect(int(bag_item.get("capacity", 0)) == 40, "bag recommendation should expose capacity")

	var summary: Dictionary = TownPrepSummaryServiceScript.build_summary(player)
	_expect(str(summary.get("resource_text", "")).contains("Bag 32/40"), "town summary should show bag capacity instead of raw item count")
	_expect(Dictionary(summary.get("inventory_capacity", {})).has("pressure_ratio"), "town summary should expose capacity payload for future UI")
	_finish()

func _equipment_payload(id: String) -> Dictionary:
	return {
		"id": id,
		"name": id,
		"type": "equipment",
		"equipment": {
			"instance_id": id,
			"name": id,
			"slot": "weapon",
			"equipment_pool": "warrior",
			"item_level": 1,
			"rarity": "common",
			"affixes": {"attack_damage": 1},
		},
	}

func _find_recommendation(items: Array, id: String) -> Dictionary:
	for item in items:
		var data: Dictionary = Dictionary(item)
		if str(data.get("id", "")) == id:
			return data
	return {}

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_INVENTORY_CAPACITY_RULES_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
