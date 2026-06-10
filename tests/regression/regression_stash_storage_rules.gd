extends SceneTree

const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")
const InventoryDataServiceScript := preload("res://scripts/data/InventoryDataService.gd")
const StashStorageServiceScript := preload("res://scripts/data/StashStorageService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := PlayerDataServiceScript.build_starter_player("slot_1", "Stash", "warrior")
	player["inventory"] = InventoryDataServiceScript.add_item(Dictionary(player.get("inventory", {})), {
		"id": "crystal_shard",
		"name": "Crystal Shard",
		"type": "material",
		"amount": 7,
	})
	var starter_weapon_id := str(Dictionary(player.get("equipped_items", {})).get("weapon", ""))
	var deposit_result := StashStorageServiceScript.deposit_item(player, {}, "crystal_shard")
	_expect(bool(deposit_result.get("ok", false)), "depositing a bag material should succeed")
	var after_deposit_player: Dictionary = Dictionary(deposit_result.get("player_data", {}))
	var stash: Dictionary = Dictionary(deposit_result.get("stash", {}))
	_expect(not Dictionary(after_deposit_player.get("inventory", {})).has("crystal_shard"), "deposit should remove item from bag")
	_expect(Dictionary(stash).has("crystal_shard"), "deposit should add item to stash")
	_expect(int(Dictionary(stash.get("crystal_shard", {})).get("amount", 0)) == 7, "deposit should preserve stack amount")

	var equipped_result := StashStorageServiceScript.deposit_item(player, {}, starter_weapon_id)
	_expect(not bool(equipped_result.get("ok", true)), "equipped item should not be deposited")
	_expect(str(equipped_result.get("reason", "")) == "equipped_item", "equipped deposit should explain reason")

	var full_player := after_deposit_player.duplicate(true)
	var full_inventory := {}
	for i in range(InventoryDataServiceScript.get_default_capacity()):
		full_inventory = InventoryDataServiceScript.add_item(full_inventory, _equipment_payload("full_%02d" % i))
	full_player["inventory"] = full_inventory
	var blocked_withdraw := StashStorageServiceScript.withdraw_item(full_player, stash, "crystal_shard")
	_expect(not bool(blocked_withdraw.get("ok", true)), "withdraw should fail when bag is full")
	_expect(str(blocked_withdraw.get("reason", "")) == "bag_full", "full bag withdraw should explain reason")
	_expect(Dictionary(blocked_withdraw.get("stash", {})).has("crystal_shard"), "blocked withdraw should not remove stash item")

	var withdraw_result := StashStorageServiceScript.withdraw_item(after_deposit_player, stash, "crystal_shard")
	_expect(bool(withdraw_result.get("ok", false)), "withdraw should succeed when bag has space")
	var after_withdraw_player: Dictionary = Dictionary(withdraw_result.get("player_data", {}))
	_expect(Dictionary(after_withdraw_player.get("inventory", {})).has("crystal_shard"), "withdraw should return item to bag")
	_expect(not Dictionary(withdraw_result.get("stash", {})).has("crystal_shard"), "withdraw should remove item from stash")
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

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_STASH_STORAGE_RULES_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
