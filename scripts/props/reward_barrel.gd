class_name RewardBarrel
extends Area2D

signal broken(barrel: RewardBarrel)

var hit_points: int = 1
var role_id: String = "warrior"
var radius: float = 24.0
var flash: float = 0.0


func configure(new_role_id: String) -> void:
	role_id = new_role_id
	queue_redraw()


func _ready() -> void:
	add_to_group("runner_breakables")
	collision_layer = 32
	collision_mask = 8
	monitoring = true
	var collision := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	collision.shape = circle
	add_child(collision)
	queue_redraw()


func take_damage(_damage: float = 1.0) -> void:
	if hit_points <= 0:
		return
	hit_points = 0
	flash = 0.1
	broken.emit(self)
	queue_free()


func _draw() -> void:
	var wood := Color("f0c36a") if flash <= 0.0 else Color("ffffff")
	draw_rect(Rect2(-22.0, -18.0, 44.0, 36.0), Color("5c3823"))
	draw_rect(Rect2(-18.0, -14.0, 36.0, 28.0), wood)
	draw_line(Vector2(-18.0, -14.0), Vector2(18.0, 14.0), Color("8a5b31"), 3.0)
	draw_line(Vector2(18.0, -14.0), Vector2(-18.0, 14.0), Color("8a5b31"), 3.0)
	draw_circle(Vector2.ZERO, 4.0, Color("8a5b31"))
