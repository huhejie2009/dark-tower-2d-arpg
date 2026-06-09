extends SceneTree

const InventoryDataServiceScript := preload("res://scripts/data/InventoryDataService.gd")
const InventoryItemSchemaServiceScript := preload("res://scripts/data/InventoryItemSchemaService.gd")

var failures: Array[String] = []

func _init() -> void:
	var inventory := {}
	var equipment := {
		"instance_id": "schema_sword",
		"name": "Schema Sword",
		"slot": "weapon",
		"equipment_pool": "warrior",
		"item_level": 7,
		"rarity": "rare",
		"locked": true,
		"affixes": {"attack_damage": 12},
	}
	inventory = InventoryDataServiceScript.add_item(inventory, {
		"id": "schema_sword",
		"name": "Schema Sword",
		"type": "equipment",
		"source": "elite",
		"loot_quality": {"source": "elite", "quality_tag": "sharp", "item_level": 7},
		"equipment": equipment,
	})

	var entry: Dictionary = Dictionary(inventory.get("schema_sword", {}))
	_expect(entry.has("instance_id"), "inventory entry should expose instance_id")
	_expect(str(entry.get("instance_id", "")) == "schema_sword", "entry instance_id should match equipment instance")
	_expect(entry.has("item_power"), "inventory entry should expose item_power")
	_expect(int(entry.get("item_power", 0)) == 7, "item_power should derive from equipment item_level")
	_expect(entry.has("binding_flags"), "inventory entry should expose binding_flags")
	var flags: Dictionary = Dictionary(entry.get("binding_flags", {}))
	_expect(bool(flags.get("locked", false)), "binding_flags should preserve equipment locked state")
	_expect(not bool(flags.get("favorite", true)), "binding_flags should default favorite to false")
	_expect(not bool(flags.get("junk", true)), "binding_flags should default junk to false")
	_expect(bool(flags.get("sellable", false)), "binding_flags should default sellable to true")
	_expect(str(entry.get("icon_id", "")) == "equipment.weapon.rare", "icon_id should provide a stable art hook")
	var source_tags: Array = Array(entry.get("source_tags", []))
	_expect(source_tags.has("source:elite"), "source_tags should include source")
	_expect(source_tags.has("quality:sharp"), "source_tags should include quality tag")
	_expect(source_tags.has("slot:weapon"), "source_tags should include equipment slot")
	_expect(source_tags.has("rarity:rare"), "source_tags should include rarity")

	var normalized := InventoryItemSchemaServiceScript.normalize_item_entry("material_x", {
		"name": "Material X",
		"type": "material",
		"amount": 3,
	})
	_expect(str(normalized.get("icon_id", "")) == "item.material", "non-equipment should still receive icon_id")
	_expect(Array(normalized.get("source_tags", [])).has("type:material"), "non-equipment should receive type source tag")
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_INVENTORY_ITEM_SCHEMA_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

