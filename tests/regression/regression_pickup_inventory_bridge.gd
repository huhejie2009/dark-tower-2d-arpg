extends SceneTree

const InventoryDataServiceScript := preload("res://scripts/data/InventoryDataService.gd")

var failures: Array[String] = []

func _init() -> void:
	var inventory := {}
	inventory = InventoryDataServiceScript.add_item(inventory, {"id": "gold", "name": "金币", "type": "currency", "amount": 10})
	inventory = InventoryDataServiceScript.add_item(inventory, {"id": "gold", "name": "金币", "type": "currency", "amount": 5})
	_expect(int(Dictionary(inventory["gold"]).get("amount", 0)) == 15, "currency should stack")
	var equipment := {"instance_id": "eq_test", "name": "测试剑", "slot": "weapon", "equipment_pool": "warrior", "affixes": {"attack_damage": 7}}
	inventory = InventoryDataServiceScript.add_item(inventory, {"id": "eq_test", "name": "测试剑", "type": "equipment", "equipment": equipment})
	_expect(Dictionary(inventory["eq_test"]).has("equipment"), "equipment payload should be stored")
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_PICKUP_INVENTORY_BRIDGE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
