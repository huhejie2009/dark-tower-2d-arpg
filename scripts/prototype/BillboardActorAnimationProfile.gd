extends Resource

@export var actor_id: String = ""
@export var actor_render_mode: String = "sprite3d_billboard"
@export var art_family: String = "dark_high_res_pixel_actor"
@export var directional_target: String = "4dir_first"
@export var animation_pipeline: String = "action_separated"
@export var weapon_layer_mode: String = "external_attach"
@export var body_sprites_must_exclude_weapon: bool = true
@export var combat_vfx_separated: bool = true
@export var sprite_sheet_path: String = ""
@export var frame_size: Vector2i = Vector2i.ZERO
@export var directions: PackedStringArray = PackedStringArray(["down", "left", "right", "up"])
@export var actions: PackedStringArray = PackedStringArray(["idle", "run", "attack", "death"])

func is_valid_for_trial() -> bool:
	return actor_id != "" and sprite_sheet_path != "" and frame_size.x > 0 and frame_size.y > 0 and directions.size() >= 4 and actions.size() >= 4

func build_manifest_snapshot() -> Dictionary:
	return {
		"actor_id": actor_id,
		"actor_render_mode": actor_render_mode,
		"art_family": art_family,
		"directional_target": directional_target,
		"animation_pipeline": animation_pipeline,
		"weapon_layer_mode": weapon_layer_mode,
		"body_sprites_must_exclude_weapon": body_sprites_must_exclude_weapon,
		"combat_vfx_separated": combat_vfx_separated,
		"sprite_sheet_path": sprite_sheet_path,
		"frame_size": frame_size,
		"directions": Array(directions),
		"actions": Array(actions),
		"direction_count": directions.size(),
		"action_count": actions.size(),
		"valid_for_trial": is_valid_for_trial(),
	}
