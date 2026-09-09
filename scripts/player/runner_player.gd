class_name RunnerPlayer
extends CharacterBody2D

const RoleCatalogScript = preload("res://scripts/core/role_catalog.gd")
signal attack_requested(origin: Vector2)

@export var lateral_speed: float = 520.0
@export var forward_speed: float = 180.0
@export var lane_half_width: float = 340.0

var can_move: bool = true
var attack_interval: float = 1.0
var attack_elapsed: float = 0.0
var active_role_counts: Dictionary = {}
var touch_axis: float = 0.0

const ROLE_TEXTURES := {
	"warrior": preload("res://assets/roles/warrior.png"),
	"archer": preload("res://assets/roles/archer.png"),
	"shield": preload("res://assets/roles/shield.png"),
	"mage": preload("res://assets/roles/mage.png"),
}


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var collision := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 22.0
	collision.shape = circle
	add_child(collision)
	queue_redraw()


func reset_run(start_position: Vector2, new_attack_interval: float) -> void:
	position = start_position
	can_move = true
	attack_interval = maxf(0.05, new_attack_interval)
	attack_elapsed = attack_interval


func stop() -> void:
	can_move = false
	velocity = Vector2.ZERO


func set_active_roles(run_state: RunState) -> void:
	for role_id in RoleCatalogScript.ROLE_IDS:
		active_role_counts[role_id] = run_state.active_count(role_id)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO
		return
	var horizontal := Input.get_axis("move_left", "move_right")
	if is_zero_approx(horizontal):
		horizontal = touch_axis
	# The player stays at the bottom of the camera while gates and monsters
	# advance toward it, matching the reference's fixed-lane runner framing.
	velocity = Vector2(horizontal * lateral_speed, 0.0)
	move_and_slide()
	position.x = clampf(position.x, -lane_half_width, lane_half_width)
	attack_elapsed += delta
	if attack_elapsed >= attack_interval:
		attack_elapsed = 0.0
		attack_requested.emit(global_position + Vector2(0.0, -32.0))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		touch_axis = _touch_axis(touch.position.x) if touch.pressed else 0.0
	elif event is InputEventScreenDrag:
		touch_axis = _touch_axis((event as InputEventScreenDrag).position.x)


func _touch_axis(screen_x: float) -> float:
	var viewport_width := get_viewport_rect().size.x
	return -1.0 if screen_x < viewport_width * 0.5 else 1.0


func _draw() -> void:
	draw_circle(Vector2.ZERO, 24.0, Color("f2f2f2"))
	draw_circle(Vector2.ZERO, 24.0, Color("202020"), false, 3.0)
	draw_line(Vector2(-8.0, -3.0), Vector2(8.0, -3.0), Color("202020"), 3.0)
	draw_line(Vector2(-6.0, 7.0), Vector2(6.0, 7.0), Color("202020"), 3.0)
	var slot := 0
	for role_id in RoleCatalogScript.ROLE_IDS:
		for _index in int(active_role_counts.get(role_id, 0)):
			var row := slot / 7
			var column := slot % 7
			var companion_position := Vector2(-90.0 + column * 30.0, 42.0 + row * 28.0)
			var role_texture: Texture2D = ROLE_TEXTURES.get(role_id)
			if role_texture != null:
				var sprite_size := Vector2(30.0, 38.0)
				draw_texture_rect(role_texture, Rect2(companion_position - Vector2(sprite_size.x * 0.5, 6.0), sprite_size), false)
			else:
				draw_circle(companion_position, 10.0, RoleCatalogScript.color(role_id))
				draw_circle(companion_position, 10.0, Color("202020"), false, 2.0)
			slot += 1
