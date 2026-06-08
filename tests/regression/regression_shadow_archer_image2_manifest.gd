extends SceneTree

const Enemy2DScript := preload("res://scripts/combat/Enemy2D.gd")
const FloorRulesScript := preload("res://scripts/rules/FloorRules.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var data: Dictionary = FloorRulesScript.get_enemy_type_data("shadow_archer", 3)
	var manifest: Dictionary = Dictionary(data.get("visual_asset_manifest", {}))
	_expect(not manifest.is_empty(), "shadow archer should expose a default IMAGE2 visual manifest")
	_expect(str(manifest.get("asset_pipeline", "")) == "image2", "shadow archer manifest should use IMAGE2 pipeline")
	_expect(str(manifest.get("pose_variation_version", "")) == "production_dark_armor_v3", "shadow archer manifest should use production dark armor pose variation sheets")
	_expect(bool(manifest.get("enabled", false)), "shadow archer manifest should be enabled")
	_expect(bool(manifest.get("hide_procedural_body", false)), "shadow archer manifest should hide procedural body")
	_expect(str(manifest.get("sprite_sheet_path", "")).ends_with("enemy_shadow_archer_sheet_v3.png"), "shadow archer should reference generated production spritesheet")
	_expect(manifest.get("frame_size", Vector2i.ZERO) == Vector2i(128, 128), "shadow archer frame size should be 128x128")
	var animations: Dictionary = Dictionary(manifest.get("animations", {}))
	for animation_name in ["idle", "run", "attack", "death"]:
		_expect(animations.has(animation_name), "shadow archer manifest should include %s animation" % animation_name)

	var enemy := Enemy2DScript.new()
	enemy.name = "ShadowArcherForManifestTest"
	root.add_child(enemy)
	await process_frame
	enemy.apply_enemy_data(data)
	var actor_sprite := enemy.find_child("ActorSprite", true, false) as Sprite2D
	_expect(actor_sprite != null and actor_sprite.texture != null, "shadow archer ActorSprite should load generated spritesheet from enemy data")
	var body := enemy.find_child("EnemyBody", true, false) as CanvasItem
	_expect(body != null and not body.visible, "shadow archer procedural body should hide after spritesheet loads")
	var state: Dictionary = enemy.call("get_actor_animation_state_for_test")
	_expect(str(state.get("animation", "")) == "idle", "shadow archer should start at idle animation")
	_expect(int(state.get("frame_index", -1)) == 0, "shadow archer idle should start at frame 0")

	enemy.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_SHADOW_ARCHER_IMAGE2_MANIFEST_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
