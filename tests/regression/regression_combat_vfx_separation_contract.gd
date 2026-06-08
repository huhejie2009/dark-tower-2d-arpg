extends SceneTree

const Player2DScript := preload("res://scripts/combat/Player2D.gd")
const Enemy2DScript := preload("res://scripts/combat/Enemy2D.gd")
const Skill2DLibraryScript := preload("res://scripts/combat/Skill2DLibrary.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var host := Node2D.new()
	root.add_child(host)
	var player := Player2DScript.new()
	player.name = "Player2D"
	host.add_child(player)
	var enemy := Enemy2DScript.new()
	enemy.name = "Enemy2D"
	host.add_child(enemy)
	await process_frame

	player.global_position = Vector2.ZERO
	enemy.global_position = Vector2(72, 0)
	var result := Skill2DLibraryScript.cast_basic_skill(player, "warrior_cleave", Vector2.RIGHT, 25)
	_expect(int(result.get("hit_count", 0)) == 1, "basic attack should hit test enemy")

	var trail := host.find_child("AttackTrailVFX", true, false)
	var hit := host.find_child("HitImpactVFX", true, false)
	_expect(trail != null, "basic attack should spawn a separate attack trail VFX node")
	_expect(hit != null, "basic attack should spawn a separate hit impact VFX node")
	if trail != null:
		_expect(str(trail.get_meta("vfx_role", "")) == "attack_trail", "attack trail should be classified as VFX, not actor animation")
	if hit != null:
		_expect(str(hit.get_meta("vfx_role", "")) == "hit_impact", "hit impact should be classified as VFX, not actor animation")

	var actor_sprite := player.find_child("ActorSprite", true, false)
	_expect(actor_sprite != null and actor_sprite.find_child("HitImpactVFX", true, false) == null, "hit VFX should not be parented inside player spritesheet node")

	host.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_COMBAT_VFX_SEPARATION_CONTRACT_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
