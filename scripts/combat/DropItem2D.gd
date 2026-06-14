extends Area2D
class_name DropItem2D

signal collected(payload: Dictionary)

var payload: Dictionary = {}
var is_collected := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_create_collision()
	_create_visuals()

func set_payload(value: Dictionary) -> void:
	payload = value.duplicate(true)

func _on_body_entered(body: Node) -> void:
	if is_collected:
		return
	if body.name == "Player2D":
		is_collected = true
		collected.emit(payload)
		queue_free()

func _create_collision() -> void:
	var shape := CircleShape2D.new()
	shape.radius = 18.0
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)

func _create_visuals() -> void:
	var gem := Polygon2D.new()
	gem.name = "DropGem"
	gem.polygon = PackedVector2Array([Vector2(0, -16), Vector2(16, 0), Vector2(0, 16), Vector2(-16, 0)])
	gem.color = _get_drop_color()
	add_child(gem)
	var label := Label.new()
	label.name = "DropLabel"
	label.text = str(payload.get("name", "掉落"))
	label.position = Vector2(-34, 18)
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", gem.color.lightened(0.25))
	add_child(label)

func _get_drop_color() -> Color:
	match str(payload.get("type", "item")):
		"gem":
			return Color(0.28, 0.78, 1.0, 1.0)
		"currency":
			return Color(0.95, 0.72, 0.2, 1.0)
		"material":
			return Color(0.52, 0.66, 0.72, 1.0)
		"equipment":
			return Color(0.72, 0.48, 0.95, 1.0)
		_:
			return Color(0.78, 0.78, 0.78, 1.0)
