class_name FinishLine
extends Area2D

signal reached

var line_size := Vector2(600.0, 42.0)
var text_label: Label


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	monitoring = true

	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = line_size
	collision.shape = rectangle
	add_child(collision)

	text_label = Label.new()
	text_label.position = Vector2(-line_size.x / 2.0, -22.0)
	text_label.size = Vector2(line_size.x, 44.0)
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_label.text = "消失点 · DEAD ZONE"
	text_label.add_theme_font_size_override("font_size", 13)
	text_label.add_theme_color_override("font_color", Color("8da49b"))
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(text_label)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is RunnerPlayer:
		visible = false
		reached.emit()


func _draw() -> void:
	draw_rect(Rect2(-line_size / 2.0, line_size), Color("3c4c49"))
	draw_rect(Rect2(-line_size / 2.0, line_size), Color("536963"), false, 2.0)
