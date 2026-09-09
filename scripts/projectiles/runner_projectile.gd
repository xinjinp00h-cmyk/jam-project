class_name RunnerProjectile
extends Area2D

var speed: float = 520.0
var damage: float = 1.0
var radius: float = 9.0
var style: String = "core"
var collision_shape: CollisionShape2D
var hit_target: bool = false


func setup(start_position: Vector2, new_speed: float, new_damage: float, new_style: String = "core") -> void:
	position = start_position
	speed = new_speed
	damage = new_damage
	style = new_style
	if style == "warrior":
		radius = 34.0
	elif style == "mage":
		radius = 24.0
	elif style == "archer":
		radius = 7.0
	_update_collision_radius()
	queue_redraw()


func _ready() -> void:
	collision_layer = 8
	collision_mask = 16 | 32
	monitoring = true
	collision_shape = CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	collision_shape.shape = circle
	# A projectile can be spawned from Area2D.body_entered while Godot is
	# flushing physics queries. Defer adding the shape until that flush ends.
	call_deferred("_attach_collision_shape")
	area_entered.connect(_on_area_entered)
	queue_redraw()


func _attach_collision_shape() -> void:
	if not is_inside_tree() or collision_shape == null or collision_shape.get_parent() != null:
		return
	add_child(collision_shape)
	_update_collision_radius()


func _physics_process(delta: float) -> void:
	if hit_target:
		return
	var previous_position := global_position
	position.y -= speed * delta
	_check_segment_hit(previous_position, global_position)
	if position.y < -5000.0:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area is BasicEnemy:
		_apply_hit(area as BasicEnemy)
	elif area is RewardBarrel:
		_apply_breakable_hit(area as RewardBarrel)


func _check_segment_hit(segment_start: Vector2, segment_end: Vector2) -> void:
	var segment := segment_end - segment_start
	var segment_length_squared := segment.length_squared()
	for candidate in get_tree().get_nodes_in_group("runner_enemies"):
		if not candidate is BasicEnemy or not is_instance_valid(candidate):
			continue
		var enemy := candidate as BasicEnemy
		var ratio := 0.0
		if segment_length_squared > 0.0:
			ratio = clampf((enemy.global_position - segment_start).dot(segment) / segment_length_squared, 0.0, 1.0)
		var closest_point := segment_start + segment * ratio
		var hit_distance := radius + enemy.radius
		var base_lane_x := float(enemy.get_meta("base_lane_x", enemy.global_position.x))
		var lane_aligned := absf(base_lane_x - global_position.x) <= 120.0
		var collision_position := Vector2(base_lane_x, enemy.global_position.y)
		if lane_aligned and closest_point.distance_squared_to(collision_position) <= hit_distance * hit_distance:
			_apply_hit(enemy)
			return
	for candidate in get_tree().get_nodes_in_group("runner_breakables"):
		if not candidate is RewardBarrel or not is_instance_valid(candidate):
			continue
		var barrel := candidate as RewardBarrel
		var ratio := 0.0
		if segment_length_squared > 0.0:
			ratio = clampf((barrel.global_position - segment_start).dot(segment) / segment_length_squared, 0.0, 1.0)
		var closest_point := segment_start + segment * ratio
		var hit_distance := radius + barrel.radius
		if closest_point.distance_squared_to(barrel.global_position) <= hit_distance * hit_distance:
			_apply_breakable_hit(barrel)
			return


func _apply_hit(enemy: BasicEnemy) -> void:
	if hit_target or not is_instance_valid(enemy):
		return
	hit_target = true
	enemy.take_damage(damage)
	queue_free()


func _apply_breakable_hit(barrel: RewardBarrel) -> void:
	if hit_target or not is_instance_valid(barrel):
		return
	hit_target = true
	barrel.take_damage(damage)
	queue_free()


func _update_collision_radius() -> void:
	if collision_shape == null:
		return
	var circle := collision_shape.shape as CircleShape2D
	if circle != null:
		circle.radius = radius


func _draw() -> void:
	var fill := Color("202020") if style == "warrior" else (Color("9a70c7") if style == "mage" else Color("f2f2f2"))
	draw_circle(Vector2.ZERO, radius, fill)
	draw_circle(Vector2.ZERO, radius, Color("202020"), false, 2.0)
