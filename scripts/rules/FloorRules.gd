extends RefCounted
class_name FloorRules

const ENEMY_TYPES := {
	"rot_melee": {
		"name": "Rot Melee",
		"max_health": 58,
		"move_speed": 112.0,
		"attack_damage": 9,
		"attack_range": 42.0,
		"attack_cooldown": 0.82,
		"uses_projectile": false,
		"color": Color(0.72, 0.18, 0.14, 1.0),
	},
	"shadow_archer": {
		"name": "Shadow Archer",
		"max_health": 42,
		"move_speed": 92.0,
		"attack_damage": 7,
		"attack_range": 230.0,
		"attack_cooldown": 1.15,
		"uses_projectile": true,
		"projectile_speed": 330.0,
		"color": Color(0.28, 0.28, 0.72, 1.0),
	},
	"tower_guardian": {
		"name": "Tower Guardian",
		"max_health": 104,
		"move_speed": 68.0,
		"attack_damage": 14,
		"attack_range": 48.0,
		"attack_cooldown": 1.05,
		"uses_projectile": false,
		"color": Color(0.58, 0.42, 0.22, 1.0),
	},
	"tower_gatekeeper": {
		"name": "Tower Gatekeeper",
		"max_health": 190,
		"move_speed": 64.0,
		"attack_damage": 18,
		"attack_range": 58.0,
		"attack_cooldown": 0.95,
		"uses_projectile": false,
		"color": Color(0.76, 0.18, 0.55, 1.0),
	},
}

const TEMPLATE_SEQUENCE := ["standard_clear", "dense_room", "ranged_pressure", "guardian_mix", "elite_preview"]

const ROT_MELEE_IMAGE2_MANIFEST := {
	"asset_pipeline": "image2",
	"pose_variation_version": "production_dark_armor_v3",
	"direction_mode": "runtime_flip_2dir",
	"enabled": true,
	"hide_procedural_body": true,
	"sprite_sheet_path": "res://assets/generated/actors/enemy_rot_melee_sheet_v3.png",
	"frame_size": Vector2i(128, 128),
	"animations": {
		"idle": {"from": 0, "to": 3, "fps": 7},
		"run": {"from": 4, "to": 9, "fps": 9},
		"attack": {"from": 10, "to": 15, "fps": 11},
		"death": {"from": 16, "to": 19, "fps": 7},
	},
}

const SHADOW_ARCHER_IMAGE2_MANIFEST := {
	"asset_pipeline": "image2",
	"pose_variation_version": "production_dark_armor_v3",
	"direction_mode": "runtime_flip_2dir",
	"enabled": true,
	"hide_procedural_body": true,
	"sprite_sheet_path": "res://assets/generated/actors/enemy_shadow_archer_sheet_v3.png",
	"frame_size": Vector2i(128, 128),
	"animations": {
		"idle": {"from": 0, "to": 3, "fps": 6},
		"run": {"from": 4, "to": 9, "fps": 8},
		"attack": {"from": 10, "to": 15, "fps": 10},
		"death": {"from": 16, "to": 19, "fps": 6},
	},
}

const TOWER_GUARDIAN_IMAGE2_MANIFEST := {
	"asset_pipeline": "image2",
	"pose_variation_version": "production_dark_armor_v3",
	"direction_mode": "runtime_flip_2dir",
	"enabled": true,
	"hide_procedural_body": true,
	"sprite_sheet_path": "res://assets/generated/actors/enemy_tower_guardian_sheet_v3.png",
	"frame_size": Vector2i(128, 128),
	"animations": {
		"idle": {"from": 0, "to": 3, "fps": 6},
		"run": {"from": 4, "to": 9, "fps": 8},
		"attack": {"from": 10, "to": 15, "fps": 10},
		"death": {"from": 16, "to": 19, "fps": 6},
	},
}

const TOWER_GATEKEEPER_IMAGE2_MANIFEST := {
	"asset_pipeline": "image2",
	"pose_variation_version": "production_dark_armor_v3",
	"direction_mode": "runtime_flip_2dir",
	"enabled": true,
	"hide_procedural_body": true,
	"sprite_sheet_path": "res://assets/generated/actors/boss_tower_gatekeeper_sheet_v3.png",
	"frame_size": Vector2i(192, 192),
	"animations": {
		"idle": {"from": 0, "to": 3, "fps": 5},
		"run": {"from": 4, "to": 9, "fps": 7},
		"attack": {"from": 10, "to": 15, "fps": 8, "loop": false},
		"death": {"from": 16, "to": 19, "fps": 5, "loop": false},
	},
}

static func build_floor_template(floor: int) -> Dictionary:
	var safe_floor := maxi(1, floor)
	if safe_floor % 5 == 0:
		return {
			"floor": safe_floor,
			"template_id": "boss_gatekeeper",
			"objective": "defeat_boss",
			"enemies": [
				_spawn("tower_gatekeeper", Vector2(0, -80), {"boss": true}),
				_spawn("rot_melee", Vector2(260, 130)),
				_spawn("rot_melee", Vector2(-260, 130)),
			],
		}
	var non_boss_index := (safe_floor - 1) - int((safe_floor - 1) / 5)
	var template_id: String = TEMPLATE_SEQUENCE[non_boss_index % TEMPLATE_SEQUENCE.size()]
	var enemies: Array[Dictionary] = []
	match template_id:
		"standard_clear":
			enemies = [
				_spawn("rot_melee", Vector2(260, -70)),
				_spawn("rot_melee", Vector2(-270, 80)),
				_spawn("rot_melee", Vector2(320, 110)),
			]
		"dense_room":
			enemies = [
				_spawn("rot_melee", Vector2(150, -70)),
				_spawn("rot_melee", Vector2(190, 70)),
				_spawn("rot_melee", Vector2(-160, 70)),
				_spawn("rot_melee", Vector2(-190, -80)),
			]
		"ranged_pressure":
			enemies = [
				_spawn("shadow_archer", Vector2(360, -150)),
				_spawn("shadow_archer", Vector2(-360, 150)),
				_spawn("rot_melee", Vector2(120, 80)),
			]
		"guardian_mix":
			enemies = [
				_spawn("tower_guardian", Vector2(260, 0)),
				_spawn("rot_melee", Vector2(-260, -110)),
				_spawn("shadow_archer", Vector2(-320, 150)),
			]
		"elite_preview":
			enemies = [
				_spawn("tower_guardian", Vector2(0, -160), {"elite_affixes": ["tough", "death_burst"]}),
				_spawn("rot_melee", Vector2(260, 120)),
				_spawn("shadow_archer", Vector2(-280, 130)),
			]
	return {
		"floor": safe_floor,
		"template_id": template_id,
		"objective": "clear_all",
		"enemies": enemies,
	}

static func get_enemy_type_data(enemy_type: String, floor: int = 1, modifiers: Dictionary = {}) -> Dictionary:
	var safe_type := enemy_type if ENEMY_TYPES.has(enemy_type) else "rot_melee"
	var safe_floor := maxi(1, floor)
	var data: Dictionary = Dictionary(ENEMY_TYPES[safe_type]).duplicate(true)
	data["enemy_type"] = safe_type
	match safe_type:
		"rot_melee":
			data["visual_asset_manifest"] = ROT_MELEE_IMAGE2_MANIFEST.duplicate(true)
		"shadow_archer":
			data["visual_asset_manifest"] = SHADOW_ARCHER_IMAGE2_MANIFEST.duplicate(true)
		"tower_guardian":
			data["visual_asset_manifest"] = TOWER_GUARDIAN_IMAGE2_MANIFEST.duplicate(true)
		"tower_gatekeeper":
			data["visual_asset_manifest"] = TOWER_GATEKEEPER_IMAGE2_MANIFEST.duplicate(true)
	data["max_health"] = int(data.get("max_health", 50)) + safe_floor * 7
	data["attack_damage"] = int(data.get("attack_damage", 8)) + int(safe_floor / 2)
	var affixes: Array = Array(modifiers.get("elite_affixes", [])) if modifiers.get("elite_affixes", []) is Array else []
	if bool(modifiers.get("elite", false)) and affixes.is_empty():
		affixes = ["tough"]
	if bool(modifiers.get("boss", false)):
		data["is_boss"] = true
		data["is_elite"] = true
		data["max_health"] = int(data["max_health"]) + 90 + safe_floor * 10
		data["attack_damage"] = int(data["attack_damage"]) + 7
		data["elite_affixes"] = ["tough"]
		data["display_rank"] = "boss"
		data["boss_skills"] = ["gatekeeper_slam", "short_charge"]
		data["boss_charge_cooldown"] = 4.6
		data["boss_charge_distance"] = 135.0
		data["boss_charge_damage"] = int(data["attack_damage"]) + 5
		return data
	data["is_boss"] = false
	if not affixes.is_empty():
		data["is_elite"] = true
		data["elite_affixes"] = affixes.duplicate(true)
		data["display_rank"] = "elite"
		_apply_elite_affixes(data, affixes, safe_floor)
	else:
		data["is_elite"] = false
		data["elite_affixes"] = []
		data["display_rank"] = "normal"
	return data

static func _spawn(enemy_type: String, position: Vector2, modifiers: Dictionary = {}) -> Dictionary:
	return {"enemy_type": enemy_type, "position": position, "modifiers": modifiers}

static func _apply_elite_affixes(data: Dictionary, affixes: Array, floor: int) -> void:
	for affix in affixes:
		match str(affix):
			"fast":
				data["move_speed"] = float(data.get("move_speed", 90.0)) * 1.28
				data["attack_cooldown"] = maxf(0.35, float(data.get("attack_cooldown", 0.9)) * 0.86)
			"tough":
				data["max_health"] = int(data.get("max_health", 50)) + 50 + floor * 5
			"death_burst":
				data["death_burst"] = true
				data["death_burst_damage"] = 10 + floor
				data["death_burst_radius"] = 76.0
