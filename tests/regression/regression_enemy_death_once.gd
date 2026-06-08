extends SceneTree

const Enemy2DScript := preload("res://scripts/combat/Enemy2D.gd")

var failures: Array[String] = []
var death_count := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var enemy := Enemy2DScript.new()
	enemy.max_health = 10
	enemy.died.connect(func(_enemy): death_count += 1)
	root.add_child(enemy)
	await process_frame
	enemy.take_damage(999)
	enemy.take_damage(999)
	await process_frame
	_expect(death_count == 1, "enemy should die once")
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_ENEMY_DEATH_ONCE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
