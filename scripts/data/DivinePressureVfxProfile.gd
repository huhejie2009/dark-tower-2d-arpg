extends Resource
class_name DivinePressureVfxProfile

@export var interface_id := "divine_pressure_vfx"
@export var interface_version := 1
@export var asset_family := "cold_megastructure_divine_pressure"
@export var warning_role := "enemy_pressure_warning"
@export var impact_role := "enemy_pressure_impact"
@export_file("*.tscn") var warning_scene_path := ""
@export_file("*.tscn") var impact_scene_path := ""
@export var fallback_programmatic := true
@export var authored_asset_required_before_art_lock := true

func is_authored_ready() -> bool:
	return warning_scene_path != "" and impact_scene_path != ""

func to_manifest() -> Dictionary:
	return {
		"interface_id": interface_id,
		"interface_version": interface_version,
		"asset_family": asset_family,
		"warning_role": warning_role,
		"impact_role": impact_role,
		"warning_scene_path": warning_scene_path,
		"impact_scene_path": impact_scene_path,
		"fallback_programmatic": fallback_programmatic,
		"authored_asset_required_before_art_lock": authored_asset_required_before_art_lock,
		"authored_ready": is_authored_ready(),
		"validation": get_validation_report(),
	}

func get_validation_report() -> Dictionary:
	var missing_fields: Array[String] = []
	if warning_scene_path == "":
		missing_fields.append("warning_scene_path")
	if impact_scene_path == "":
		missing_fields.append("impact_scene_path")
	return {
		"authored_ready": is_authored_ready(),
		"missing_fields": missing_fields,
		"fallback_programmatic": fallback_programmatic,
		"can_spawn_with_fallback": fallback_programmatic or is_authored_ready(),
	}
