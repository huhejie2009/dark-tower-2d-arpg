extends RefCounted
class_name Vfx2DFactory

static func spawn_slash(parent: Node, position: Vector2, direction: Vector2) -> void:
	var root := Node2D.new()
	root.name = "AttackTrailVFX"
	root.set_meta("vfx_role", "attack_trail")
	parent.add_child(root)
	root.global_position = position
	root.rotation = direction.angle()
	var arc := Polygon2D.new()
	arc.name = "AttackTrailShape"
	arc.polygon = PackedVector2Array([Vector2(8, -44), Vector2(112, -18), Vector2(126, 0), Vector2(112, 18), Vector2(8, 44), Vector2(44, 0)])
	arc.color = Color(0.74, 0.90, 1.0, 0.58)
	root.add_child(arc)
	var edge := Line2D.new()
	edge.name = "AttackTrailEdge"
	edge.width = 3.0
	edge.default_color = Color(0.95, 0.98, 1.0, 0.86)
	edge.points = PackedVector2Array([Vector2(16, -34), Vector2(120, 0), Vector2(16, 34)])
	root.add_child(edge)
	_fade(parent, root, 0.16)

static func spawn_hit(parent: Node, position: Vector2) -> void:
	var root := Node2D.new()
	root.name = "HitImpactVFX"
	root.set_meta("vfx_role", "hit_impact")
	parent.add_child(root)
	root.global_position = position
	var ring := Line2D.new()
	ring.name = "HitImpactRing"
	ring.width = 4.0
	ring.closed = true
	ring.default_color = Color(0.82, 0.94, 1.0, 0.86)
	for i in range(16):
		var angle := TAU * float(i) / 16.0
		ring.add_point(Vector2(cos(angle), sin(angle)) * 18.0)
	root.add_child(ring)
	var sparks := Node2D.new()
	sparks.name = "HitImpactSparks"
	root.add_child(sparks)
	for i in range(6):
		var spark := Line2D.new()
		spark.width = 2.0
		spark.default_color = Color(0.96, 0.44, 0.30, 0.82)
		var angle := TAU * float(i) / 6.0
		spark.points = PackedVector2Array([Vector2.ZERO, Vector2(cos(angle), sin(angle)) * 22.0])
		sparks.add_child(spark)
	_fade(parent, root, 0.18)

static func _fade(parent: Node, root: Node2D, duration: float) -> void:
	var tween := parent.create_tween()
	tween.set_parallel(true)
	tween.tween_property(root, "scale", Vector2.ONE * 1.35, duration)
	tween.tween_property(root, "modulate:a", 0.0, duration)
	tween.set_parallel(false)
	tween.tween_callback(root.queue_free)
