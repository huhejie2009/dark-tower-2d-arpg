extends SceneTree

const LootRulesScript := preload("res://scripts/rules/LootRules.gd")
const LootNotificationServiceScript := preload("res://scripts/data/LootNotificationService.gd")
const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")
const InventoryDataServiceScript := preload("res://scripts/data/InventoryDataService.gd")
const DropItem2DScript := preload("res://scripts/combat/DropItem2D.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var early_drop: Dictionary = LootRulesScript.generate_enemy_drop(1, "ranger", 7)
	_expect(str(early_drop.get("type", "")) == "gem", "seventh kill should produce a gem")
	_expect(["frost_gem", "precision_gem", "haste_gem"].has(str(early_drop.get("gem_id", ""))), "early ranger gem should use the simple stat pool")
	_expect(int(early_drop.get("amount", 0)) == 1, "gem drops should use one inventory item")
	_expect(Dictionary(early_drop.get("loot_quality", {})).has("item_level"), "gem drop should preserve loot quality metadata")

	var mid_drop: Dictionary = LootRulesScript.generate_enemy_drop(4, "ranger", 14)
	_expect(str(mid_drop.get("gem_id", "")) == "pierce_gem", "floor four ranger cadence should introduce pierce")

	var late_drop: Dictionary = LootRulesScript.generate_enemy_drop(7, "ranger", 21)
	_expect(str(late_drop.get("gem_id", "")) == "split_gem", "floor seven ranger cadence should introduce split")

	var warrior_drop: Dictionary = LootRulesScript.generate_enemy_drop(7, "warrior", 7)
	_expect(["precision_gem", "haste_gem"].has(str(warrior_drop.get("gem_id", ""))), "non-ranger drops should stay in their generic gem pool")

	var player := PlayerDataServiceScript.build_starter_player("slot_1", "Gem Loot", "ranger")
	var notification := LootNotificationServiceScript.build_pickup_notification(player, early_drop)
	_expect(str(notification.get("headline", "")) == "获得宝石", "gem pickup should use a distinct headline")
	_expect(str(notification.get("rarity", "")) == "gem", "gem pickup should use gem presentation rarity")
	_expect(str(notification.get("log_text", "")).contains(str(early_drop.get("name", ""))), "gem log should include its name")

	var inventory := InventoryDataServiceScript.add_item({}, early_drop)
	var gem_entry: Dictionary = Dictionary(inventory.get(str(early_drop.get("id", "")), {}))
	_expect(str(gem_entry.get("gem_id", "")) == str(early_drop.get("gem_id", "")), "inventory should preserve gem identity")

	var drop := DropItem2DScript.new()
	drop.set_payload(early_drop)
	root.add_child(drop)
	await process_frame
	var visual := drop.find_child("DropGem", true, false) as Polygon2D
	var label := drop.find_child("DropLabel", true, false) as Label
	_expect(visual != null and visual.color.b > visual.color.r, "gem drop should use a cool blue visual")
	_expect(label != null and str(label.text) == str(early_drop.get("name", "")), "gem drop label should show gem name")
	drop.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_GEM_LOOT_RULES_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
