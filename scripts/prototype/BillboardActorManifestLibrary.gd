extends RefCounted

const PLAYER_WARRIOR_SHEET := "res://assets/generated/actors/player_warrior_sheet_v3.png"
const ROT_MELEE_SHEET := "res://assets/generated/actors/enemy_rot_melee_sheet_v3.png"
const SHADOW_ARCHER_SHEET := "res://assets/generated/actors/enemy_shadow_archer_sheet_v3.png"

static func make_player_warrior_v3() -> Dictionary:
	return _make_manifest(
		"player_warrior_v3",
		PLAYER_WARRIOR_SHEET,
		Vector2i(160, 160),
		{"idle": 6, "run": 9, "attack": 10, "death": 6}
	)

static func make_rot_melee_v3() -> Dictionary:
	return _make_manifest(
		"enemy_rot_melee_v3",
		ROT_MELEE_SHEET,
		Vector2i(128, 128),
		{"idle": 7, "run": 9, "attack": 11, "death": 7}
	)

static func make_shadow_archer_v3() -> Dictionary:
	return _make_manifest(
		"enemy_shadow_archer_v3",
		SHADOW_ARCHER_SHEET,
		Vector2i(128, 128),
		{"idle": 6, "run": 8, "attack": 10, "death": 6}
	)

static func _make_manifest(actor_id: String, sprite_sheet_path: String, frame_size: Vector2i, fps_by_name: Dictionary) -> Dictionary:
	return {
		"actor_id": actor_id,
		"asset_pipeline": "image2",
		"pose_variation_version": "production_dark_armor_v3",
		"art_family": "dark_high_res_pixel_actor",
		"environment_pairing": "painterly_brutalist_tower",
		"texture_filter": "nearest",
		"directional_target": "runtime_flip_2dir_first",
		"animation_pipeline": "action_separated",
		"weapon_layer_mode": "external_attach",
		"body_sprites_must_exclude_weapon": true,
		"separate_combat_vfx": true,
		"combat_vfx_separated": true,
		"contact_shadow": {
			"required": true,
			"style": "soft_grounded_cold_ambient",
		},
		"direction_mode": "runtime_flip_2dir",
		"enabled": true,
		"hide_procedural_body": true,
		"sprite_sheet_path": sprite_sheet_path,
		"frame_size": frame_size,
		"direction_frame_offsets": {
			"down": 0,
			"left": 0,
			"right": 0,
			"up": 0,
		},
		"animations": {
			"idle": {"from": 0, "to": 3, "fps": int(fps_by_name.get("idle", 6)), "loop": true},
			"run": {"from": 4, "to": 9, "fps": int(fps_by_name.get("run", 9)), "loop": true},
			"attack": {"from": 10, "to": 15, "fps": int(fps_by_name.get("attack", 10)), "loop": false},
			"death": {"from": 16, "to": 19, "fps": int(fps_by_name.get("death", 6)), "loop": false},
		},
	}
