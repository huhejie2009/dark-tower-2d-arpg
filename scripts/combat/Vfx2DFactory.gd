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

static func spawn_projectile_trail(parent: Node, origin: Vector2, direction: Vector2, distance: float, color: Color = Color(0.62, 0.88, 1.0, 0.88)) -> void:
	if direction.length_squared() <= 0.001:
		direction = Vector2.RIGHT
	direction = direction.normalized()
	var root := Node2D.new()
	root.name = "ProjectileTrailVFX"
	root.set_meta("vfx_role", "projectile_trail")
	parent.add_child(root)
	root.global_position = origin
	root.rotation = direction.angle()
	var trail := Line2D.new()
	trail.name = "ProjectileTrailLine"
	trail.width = 5.0
	trail.default_color = color
	trail.points = PackedVector2Array([Vector2(18, 0), Vector2(maxf(42.0, distance), 0)])
	root.add_child(trail)
	var head := Polygon2D.new()
	head.name = "ProjectileTrailHead"
	var head_x := maxf(42.0, distance)
	head.polygon = PackedVector2Array([Vector2(head_x + 14, 0), Vector2(head_x - 10, -8), Vector2(head_x - 6, 0), Vector2(head_x - 10, 8)])
	head.color = color
	root.add_child(head)
	_fade(parent, root, 0.14)

static func spawn_ice_arrow_trail(parent: Node, origin: Vector2, direction: Vector2, distance: float) -> void:
	_spawn_named_projectile(parent, "IceArrowTrailVFX", "ice_arrow_trail", origin, direction, distance, 7.0, Color(0.36, 0.84, 1.0, 0.90), 0.16)

static func spawn_ice_lance_trail(parent: Node, origin: Vector2, direction: Vector2, distance: float) -> void:
	_spawn_named_projectile(parent, "IceLanceTrailVFX", "ice_lance_trail", origin, direction, distance + 28.0, 3.0, Color(0.78, 0.96, 1.0, 0.96), 0.12)

static func spawn_coc_trigger_flash(parent: Node, position: Vector2) -> void:
	var root := Node2D.new()
	root.name = "CocTriggerFlashVFX"
	root.set_meta("vfx_role", "coc_trigger_flash")
	parent.add_child(root)
	root.global_position = position
	for i in range(8):
		var ray := Line2D.new()
		ray.name = "CocTriggerRay"
		ray.width = 2.0
		ray.default_color = Color(0.58, 0.90, 1.0, 0.86)
		var angle := TAU * float(i) / 8.0
		ray.points = PackedVector2Array([Vector2.ZERO, Vector2(cos(angle), sin(angle)) * 24.0])
		root.add_child(ray)
	_fade(parent, root, 0.12)

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

static func _spawn_named_projectile(parent: Node, node_name: String, role: String, origin: Vector2, direction: Vector2, distance: float, width: float, color: Color, duration: float) -> void:
	if direction.length_squared() <= 0.001:
		direction = Vector2.RIGHT
	direction = direction.normalized()
	var root := Node2D.new()
	root.name = node_name
	root.set_meta("vfx_role", role)
	parent.add_child(root)
	root.global_position = origin
	root.rotation = direction.angle()
	var line := Line2D.new()
	line.name = "%sLine" % node_name
	line.width = width
	line.default_color = color
	line.points = PackedVector2Array([Vector2(16, 0), Vector2(maxf(48.0, distance), 0)])
	root.add_child(line)
	var head := Polygon2D.new()
	head.name = "%sHead" % node_name
	var head_x := maxf(48.0, distance)
	head.polygon = PackedVector2Array([Vector2(head_x + 16, 0), Vector2(head_x - 10, -width * 1.5), Vector2(head_x - 5, 0), Vector2(head_x - 10, width * 1.5)])
	head.color = color
	root.add_child(head)
	_fade(parent, root, duration)

static func _fade(parent: Node, root: Node2D, duration: float) -> void:
	var tween := parent.create_tween()
	tween.set_parallel(true)
	tween.tween_property(root, "scale", Vector2.ONE * 1.35, duration)
	tween.tween_property(root, "modulate:a", 0.0, duration)
	tween.set_parallel(false)
	tween.tween_callback(root.queue_free)
