class_name ProfessionGate
extends Area2D

const RoleCatalogScript = preload("res://scripts/core/role_catalog.gd")
signal activated(role_id: String, part_value: int)

var role_id: String = RunState.WARRIOR
var part_value: int = 1
var was_used: bool = false
var gate_size := Vector2(150.0, 68.0)
var text_label: Label
var preview_data: Dictionary = {}


func configure(new_role_id: String, new_part_value: int, preview: Dictionary) -> void:
	role_id = new_role_id
	part_value = new_part_value
	preview_data = preview
	if is_inside_tree():
		_refresh_label(preview_data)
		queue_redraw()


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	monitoring = true
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = gate_size
	collision.shape = rectangle
	add_child(collision)
	text_label = Label.new()
	text_label.position = Vector2(-gate_size.x / 2.0, -30.0)
	text_label.size = Vector2(gate_size.x, 60.0)
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_label.add_theme_font_size_override("font_size", 15)
	text_label.add_theme_color_override("font_color", Color("202020"))
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(text_label)
	body_entered.connect(_on_body_entered)
	_refresh_label(preview_data)
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if was_used or not body is RunnerPlayer:
		return
	was_used = true
	_refresh_label({})
	queue_redraw()
	activated.emit(role_id, part_value)


func _refresh_label(preview: Dictionary) -> void:
	if text_label == null:
		return
	if was_used:
		text_label.text = "已通过"
		return
	var role_name := RoleCatalogScript.display_name(role_id)
	var sign := "+" if part_value > 0 else ""
	var completed := int(preview.get("completed", 0))
	var suffix := ""
	if completed > 0:
		suffix = "  -> %d个%s" % [completed, role_name]
	if part_value < 0:
		suffix = "  (损坏部件)"
	text_label.text = "%s %s%d件%s" % [role_name, sign, part_value, suffix]


func _draw() -> void:
	var fill := Color("777777") if was_used else (RoleCatalogScript.color(role_id).lightened(0.35) if part_value > 0 else Color("d6d6d6"))
	draw_rect(Rect2(-gate_size / 2.0, gate_size), fill)
	draw_rect(Rect2(-gate_size / 2.0, gate_size), Color("202020"), false, 3.0)
