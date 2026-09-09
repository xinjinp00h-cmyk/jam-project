extends SceneTree

var failures := 0
var enemy: BasicEnemy
var projectile: RunnerProjectile


func _init() -> void:
	var world := Node2D.new()
	root.add_child(world)
	enemy = BasicEnemy.new()
	enemy.position = Vector2(0.0, -100.0)
	enemy.configure(3.0)
	world.add_child(enemy)
	projectile = RunnerProjectile.new()
	world.add_child(projectile)
	projectile.setup(Vector2.ZERO, 300.0, 1.0, "core")
	_verify_after_physics()


func _verify_after_physics() -> void:
	await create_timer(0.6).timeout
	_expect(is_instance_valid(enemy), "enemy remains after non-lethal hit")
	if is_instance_valid(enemy):
		_expect(is_equal_approx(enemy.hit_points, 2.0), "projectile applies one point of damage")
	_expect(not is_instance_valid(projectile), "projectile is consumed after hit")
	quit(failures)


func _expect(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("FAILED: " + description)
