extends RefCounted

static func build_snapshot(scene_snapshot: Dictionary, actor_snapshots: Array[Dictionary]) -> Dictionary:
	var actor_contracts_valid := not actor_snapshots.is_empty()
	for actor_snapshot in actor_snapshots:
		actor_contracts_valid = actor_contracts_valid and str(actor_snapshot.get("actor_render_mode", "")) == "sprite3d_billboard"
		actor_contracts_valid = actor_contracts_valid and str(actor_snapshot.get("plane", "")) == "xz"
	return {
		"qa_id": "prototype_2_5d_visual_readability",
		"camera_has_readable_angle": bool(scene_snapshot.get("camera_orthographic", false)) and bool(scene_snapshot.get("has_camera_3d", false)),
		"room_has_boundaries": int(scene_snapshot.get("wall_count", 0)) >= 4,
		"actors_have_billboard_contract": actor_contracts_valid,
		"columns_have_collision_footprint": int(scene_snapshot.get("column_count", 0)) >= 2,
		"main_flow_untouched": bool(scene_snapshot.get("isolated_from_main_flow", false)),
		"acceptance_summary": "camera room actors columns isolation",
	}
