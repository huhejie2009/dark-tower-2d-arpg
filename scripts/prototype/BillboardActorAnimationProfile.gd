extends Resource

@export var actor_id: String = ""
@export var actor_render_mode: String = "sprite3d_billboard"
@export var asset_pipeline: String = "image2"
@export var pose_variation_version: String = "production_dark_armor_v3"
@export var art_family: String = "dark_high_res_pixel_actor"
@export var environment_pairing: String = "painterly_brutalist_tower"
@export var texture_filter: String = "nearest"
@export var directional_target: String = "runtime_flip_2dir_first"
@export var direction_mode: String = "runtime_flip_2dir"
@export var animation_pipeline: String = "action_separated"
@export var weapon_layer_mode: String = "external_attach"
@export var body_sprites_must_exclude_weapon: bool = true
@export var combat_vfx_separated: bool = true
@export var enabled: bool = true
@export var hide_procedural_body: bool = true
@export var sprite_sheet_path: String = ""
@export var frame_size: Vector2i = Vector2i.ZERO
@export var directions: PackedStringArray = PackedStringArray(["down", "left", "right", "up"])
@export var actions: PackedStringArray = PackedStringArray(["idle", "run", "attack", "death"])
@export var direction_frame_offsets: Dictionary = {
	"down": 0,
	"left": 0,
	"right": 0,
	"up": 0,
}
@export var animations: Dictionary = {
	"idle": {"from": 0, "to": 3, "fps": 6, "loop": true},
	"run": {"from": 4, "to": 9, "fps": 9, "loop": true},
	"attack": {"from": 10, "to": 15, "fps": 10, "loop": false},
	"death": {"from": 16, "to": 19, "fps": 6, "loop": false},
}

func is_valid_for_trial() -> bool:
	if actor_id == "" or sprite_sheet_path == "" or frame_size.x <= 0 or frame_size.y <= 0:
		return false
	if directions.size() < 4 or actions.size() < 4:
		return false
	for action_name in actions:
		if not animations.has(str(action_name)):
			return false
	return true

func to_visual_asset_manifest() -> Dictionary:
	return {
		"actor_id": actor_id,
		"actor_render_mode": actor_render_mode,
		"asset_pipeline": asset_pipeline,
		"pose_variation_version": pose_variation_version,
		"art_family": art_family,
		"environment_pairing": environment_pairing,
		"texture_filter": texture_filter,
		"directional_target": directional_target,
		"direction_mode": direction_mode,
		"animation_pipeline": animation_pipeline,
		"weapon_layer_mode": weapon_layer_mode,
		"body_sprites_must_exclude_weapon": body_sprites_must_exclude_weapon,
		"combat_vfx_separated": combat_vfx_separated,
		"separate_combat_vfx": combat_vfx_separated,
		"enabled": enabled,
		"hide_procedural_body": hide_procedural_body,
		"sprite_sheet_path": sprite_sheet_path,
		"frame_size": frame_size,
		"directions": Array(directions),
		"actions": Array(actions),
		"direction_frame_offsets": direction_frame_offsets.duplicate(true),
		"animations": animations.duplicate(true),
	}

func build_manifest_snapshot() -> Dictionary:
	return {
		"actor_id": actor_id,
		"actor_render_mode": actor_render_mode,
		"asset_pipeline": asset_pipeline,
		"pose_variation_version": pose_variation_version,
		"art_family": art_family,
		"environment_pairing": environment_pairing,
		"texture_filter": texture_filter,
		"directional_target": directional_target,
		"direction_mode": direction_mode,
		"animation_pipeline": animation_pipeline,
		"weapon_layer_mode": weapon_layer_mode,
		"body_sprites_must_exclude_weapon": body_sprites_must_exclude_weapon,
		"combat_vfx_separated": combat_vfx_separated,
		"enabled": enabled,
		"hide_procedural_body": hide_procedural_body,
		"sprite_sheet_path": sprite_sheet_path,
		"frame_size": frame_size,
		"directions": Array(directions),
		"actions": Array(actions),
		"direction_frame_offsets": direction_frame_offsets.duplicate(true),
		"animations": animations.duplicate(true),
		"direction_count": directions.size(),
		"action_count": actions.size(),
		"valid_for_trial": is_valid_for_trial(),
	}
