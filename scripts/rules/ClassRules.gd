extends RefCounted
class_name ClassRules

const CLASSES := {
	"warrior": {
		"name": "战士",
		"max_health": 130,
		"max_mana": 45,
		"attack_damage": 30,
		"starter_weapon": "starter_warrior_sword",
		"basic_skill": "warrior_cleave",
	},
	"ranger": {
		"name": "游侠",
		"max_health": 105,
		"max_mana": 55,
		"attack_damage": 24,
		"starter_weapon": "starter_ranger_bow",
		"basic_skill": "ranger_shot",
	},
	"mage": {
		"name": "法师",
		"max_health": 92,
		"max_mana": 85,
		"attack_damage": 22,
		"starter_weapon": "starter_mage_staff",
		"basic_skill": "mage_bolt",
	},
	"acolyte": {
		"name": "侍僧",
		"max_health": 112,
		"max_mana": 65,
		"attack_damage": 23,
		"starter_weapon": "starter_acolyte_wand",
		"basic_skill": "bone_spike",
	},
}

static func normalize_class(base_class: String) -> String:
	return base_class if CLASSES.has(base_class) else "warrior"

static func get_class_data(base_class: String) -> Dictionary:
	return Dictionary(CLASSES[normalize_class(base_class)]).duplicate(true)

static func get_class_name(base_class: String) -> String:
	return str(get_class_data(base_class).get("name", "战士"))
