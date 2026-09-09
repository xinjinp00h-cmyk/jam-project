class_name BasicEnemy
extends Area2D

signal defeated(enemy: BasicEnemy)

const CELLS := [
	Vector2(-1, -2), Vector2(0, -2), Vector2(1, -2),
	Vector2(-2, -1), Vector2(-1, -1), Vector2(0, -1), Vector2(1, -1), Vector2(2, -1),
	Vector2(-2, 0), Vector2(-1, 0), Vector2(0, 0), Vector2(1, 0), Vector2(2, 0),
	Vector2(-1, 1), Vector2(0, 1), Vector2(1, 1),
	Vector2(-1, 2), Vector2(0, 2), Vector2(1, 2),
]
const DESTROY_ORDER := [10, 9, 11, 5, 12, 8, 6, 4, 13, 14, 15, 3, 2, 16, 1, 17, 0, 7, 18]

var hit_points: float = 1.0
var max_hit_points: float = 1.0
var radius: float = 24.0
var enemy_kind: String = "normal"
var holes: Array[int] = []
var flash: float = 0.0
var label: Label
const PERLER_TEXTURE: Texture2D = preload("res://assets/enemies/perler_blue_slime.png")


func configure(new_hit_points: float, new_kind: String = "normal") -> void:
	hit_points = maxf(1.0, new_hit_points)
	max_hit_points = hit_points
	enemy_kind = new_kind
	radius = 40.0 if enemy_kind == "boss" else (30.0 if enemy_kind == "elite" else 24.0)
	holes.clear()
	if label != null:
		_refresh_label()
		queue_redraw()


func _ready() -> void:
	add_to_group("runner_enemies")
	collision_layer = 16
	collision_mask = 8
	monitoring = true
	var collision := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	collision.shape = circle
	add_child(collision)
	label = Label.new()
	label.position = Vector2(-20.0, -15.0)
	label.size = Vector2(40.0, 30.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", Color("f2f2f2"))
	_refresh_label()
	add_child(label)
	queue_redraw()


func take_damage(damage: float) -> void:
	if hit_points <= 0.0:
		return
	hit_points -= damage
	flash = 0.08
	var destroyed_cells := mini(DESTROY_ORDER.size(), maxi(0, int(max_hit_points - hit_points)))
	holes.clear()
	for index in destroyed_cells:
		holes.append(DESTROY_ORDER[index])
	if hit_points <= 0:
		hit_points = 0.0
		defeated.emit(self)
		queue_free()
		return
	_refresh_label()
	queue_redraw()


func _refresh_label() -> void:
	label.text = str(ceili(hit_points))


func _draw() -> void:
	if PERLER_TEXTURE != null:
		var sprite_size := 112.0 if enemy_kind == "normal" else (136.0 if enemy_kind == "elite" else 164.0)
		var sprite_rect := Rect2(Vector2(-sprite_size * 0.5, -sprite_size * 0.58), Vector2(sprite_size, sprite_size))
		draw_texture_rect(PERLER_TEXTURE, sprite_rect, false, Color("ffffff") if flash <= 0.0 else Color("ffffffcc"))
		return
	var cell_size := 9.0 if enemy_kind == "normal" else (11.0 if enemy_kind == "elite" else 13.0)
	var base_color := Color("2e84d2") if enemy_kind == "normal" else (Color("d28b38") if enemy_kind == "elite" else Color("a84e8e"))
	var outline := Color("102d4c") if enemy_kind == "normal" else Color("4d2512")
	for index in CELLS.size():
		if holes.has(index):
			continue
		var cell: Vector2 = CELLS[index]
		var rect := Rect2(cell * cell_size - Vector2(cell_size * 0.5, cell_size * 0.5), Vector2(cell_size - 1.0, cell_size - 1.0))
		var fill := Color("f6f6f6") if flash > 0.0 else base_color
		draw_rect(rect, fill)
		draw_rect(rect, outline, false, 1.5)
	# Compact face keeps the ZIP reference's readable toy-like silhouette.
	draw_circle(Vector2(-cell_size * 0.55, 0.0), cell_size * 0.25, Color("f2f2f2"))
	draw_circle(Vector2(cell_size * 0.55, 0.0), cell_size * 0.25, Color("f2f2f2"))
	draw_circle(Vector2(-cell_size * 0.55, 0.0), cell_size * 0.1, Color("202020"))
	draw_circle(Vector2(cell_size * 0.55, 0.0), cell_size * 0.1, Color("202020"))
	draw_line(Vector2(-cell_size * 0.55, cell_size * 0.7), Vector2(cell_size * 0.55, cell_size * 0.7), Color("202020"), 2.0)


func _process(delta: float) -> void:
	if flash > 0.0:
		flash = maxf(0.0, flash - delta)
		queue_redraw()
