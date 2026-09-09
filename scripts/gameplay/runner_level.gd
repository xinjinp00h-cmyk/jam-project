class_name RunnerLevel
extends Node2D

signal completed
signal failed
signal run_state_changed

const PLAYER_START_Y := 500.0
const TRACK_HALF_WIDTH := 280.0
const TRACK_FAR_HALF_WIDTH := 165.0
const PLAYER_LANE_HALF_WIDTH := 250.0
const GATE_PATH_X := -187.0
const MONSTER_PATH_X := 187.0
const PERSPECTIVE_FAR_DISTANCE := 900.0
const LANE_COMPRESSION_FAR := 0.58

var player: RunnerPlayer
var finish_line: FinishLine
var total_distance: float = 1.0
var run_state: RunState
var game_config: GameConfig
var camera: Camera2D
var warrior_charge_queue: int = 0
var processing_warrior_charges: bool = false
var elapsed_seconds: float = 0.0
var wave_duration_seconds: float = 40.0
var travel_speed: float = 45.0
var run_finished: bool = false


func load_definition(definition: Dictionary, new_run_state: RunState, runtime_config: GameConfig, gate_rows: Array[Dictionary]) -> void:
	_clear_runtime_nodes()
	warrior_charge_queue = 0
	elapsed_seconds = 0.0
	run_finished = false
	run_state = new_run_state
	game_config = runtime_config
	total_distance = float(definition.get("distance", 1800.0))
	wave_duration_seconds = maxf(1.0, game_config.wave_duration_seconds)
	travel_speed = total_distance / wave_duration_seconds
	player = RunnerPlayer.new()
	add_child(player)
	player.attack_requested.connect(_on_attack_requested)
	player.lane_half_width = PLAYER_LANE_HALF_WIDTH
	player.reset_run(Vector2(0.0, PLAYER_START_Y), game_config.auto_attack_interval)
	player.set_active_roles(run_state)

	for gate_row in gate_rows:
		_spawn_gate_row(gate_row)
	_spawn_enemies(definition)
	_spawn_barrels()

	camera = Camera2D.new()
	camera.enabled = true
	camera.anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	camera.position = Vector2(180.0, 0.0)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	player.add_child(camera)
	camera.make_current()
	queue_redraw()


func _process(delta: float) -> void:
	if player == null or run_finished:
		return
	_move_world_towards_player(delta)
	elapsed_seconds += delta
	# Perspective is part of the live presentation: entities must continuously
	# converge toward the vanishing point while they travel toward the player.
	_update_perspective()
	if elapsed_seconds >= wave_duration_seconds:
		_finish_wave()
	queue_redraw()


func _move_world_towards_player(delta: float) -> void:
	for child in get_children():
		if child is ProfessionGate or child is BasicEnemy or child is RewardBarrel:
			child.position.y += travel_speed * delta
			if child is BasicEnemy and child.position.y >= PLAYER_START_Y + 80.0:
				_on_enemy_reached_bottom(child as BasicEnemy)
			elif child is ProfessionGate and child.position.y >= PLAYER_START_Y + 100.0:
				child.queue_free()
			elif child is RewardBarrel and child.position.y >= PLAYER_START_Y + 100.0:
				child.queue_free()


func _update_perspective() -> void:
	if player == null:
		return
	for child in get_children():
		if not child is BasicEnemy and not child is ProfessionGate and not child is RewardBarrel:
			continue
		var distance := maxf(0.0, player.global_position.y - child.global_position.y)
		var depth := clampf(distance / PERSPECTIVE_FAR_DISTANCE, 0.0, 1.0)
		var perspective_scale := lerpf(1.0, 0.46, depth)
		var base_lane_x := float(child.get_meta("base_lane_x", child.position.x))
		var track_depth := clampf((child.global_position.y - camera.global_position.y + 338.0) / 720.0, 0.0, 1.0)
		var lane_compression := lerpf(LANE_COMPRESSION_FAR, 1.0, track_depth)
		child.position.x = base_lane_x * lane_compression
		child.scale = Vector2.ONE * perspective_scale
		child.modulate = Color(1.0, 1.0, 1.0, lerpf(1.0, 0.68, depth))
		# Keep every entity above the camera-locked trapezoid. Using raw world Y
		# made distant (negative-Y) gates render underneath the track polygon.
		child.z_index = 1000 + clampi(roundi(child.position.y / 10.0), -900, 900)


func _clear_runtime_nodes() -> void:
	for child in get_children():
		child.free()
	player = null
	finish_line = null
	camera = null


func _spawn_gate_row(gate_row: Dictionary) -> void:
	var row_y := PLAYER_START_Y - float(gate_row.get("distance", 0.0))
	for option in gate_row.get("options", []):
		var role_id := str(option.get("role_id", RunState.WARRIOR))
		var part_value := int(option.get("part_value", 1))
		var gate := ProfessionGate.new()
		gate.position = Vector2(float(option.get("x", 0.0)), row_y)
		gate.set_meta("base_lane_x", gate.position.x)
		gate.configure(role_id, part_value, run_state.preview_gate(role_id, part_value))
		gate.activated.connect(_on_gate_activated)
		add_child(gate)


func _spawn_enemies(definition: Dictionary) -> void:
	var enemy_count := int(definition.get("enemy_count", 4))
	var enemy_hp := int(definition.get("enemy_hp", 2))
	var enemy_kind := str(definition.get("kind", "normal"))
	for index in enemy_count:
		var enemy := BasicEnemy.new()
		enemy.position = Vector2(MONSTER_PATH_X, PLAYER_START_Y - 650.0 - float(index) * 190.0)
		enemy.set_meta("base_lane_x", enemy.position.x)
		enemy.configure(enemy_hp + (2 if enemy_kind == "boss" and index == enemy_count - 1 else 0), enemy_kind if index == enemy_count - 1 else ("elite" if enemy_kind != "normal" else "normal"))
		enemy.defeated.connect(_on_enemy_defeated)
		add_child(enemy)


func _spawn_barrels() -> void:
	var barrel_roles := [RunState.WARRIOR, RunState.ARCHER, RunState.SHIELD]
	for index in 3:
		var barrel := RewardBarrel.new()
		barrel.position = Vector2(MONSTER_PATH_X, PLAYER_START_Y - 980.0 - float(index) * 560.0)
		barrel.set_meta("base_lane_x", barrel.position.x)
		barrel.configure(barrel_roles[index % barrel_roles.size()])
		barrel.broken.connect(_on_barrel_broken)
		add_child(barrel)


func _on_enemy_defeated(_enemy: BasicEnemy) -> void:
	if run_state == null:
		return
	run_state.add_currency(game_config.enemy_kill_currency)
	run_state_changed.emit()


func _on_enemy_reached_bottom(enemy: BasicEnemy) -> void:
	if not is_instance_valid(enemy):
		return
	var damage := ceili(enemy.hit_points)
	run_state.apply_enemy_leak(damage)
	enemy.queue_free()
	run_state_changed.emit()
	if run_state.is_defeated():
		_fail_run()


func _on_barrel_broken(barrel: RewardBarrel) -> void:
	if run_state == null:
		return
	run_state.add_currency(game_config.barrel_currency)
	# Barrels restore one part of the role they display, then award a star.
	run_state.apply_gate(barrel.role_id, 1)
	player.set_active_roles(run_state)
	run_state_changed.emit()


func _finish_wave() -> void:
	if run_finished:
		return
	run_finished = true
	player.stop()
	completed.emit()


func _fail_run() -> void:
	if run_finished:
		return
	run_finished = true
	player.stop()
	failed.emit()


func _on_gate_activated(role_id: String, part_value: int) -> void:
	var result := run_state.apply_gate(role_id, part_value)
	for completed_role in result.get("completed_roles", []):
		_spawn_completion_action(str(completed_role))
	player.set_active_roles(run_state)
	queue_redraw()
	run_state_changed.emit()


func _spawn_completion_action(role_id: String) -> void:
	if role_id == RunState.WARRIOR:
		warrior_charge_queue += 1
		_process_warrior_charges()
	elif role_id == RunState.MAGE:
		_spawn_projectile(player.global_position + Vector2(0.0, -40.0), run_state.damage_for(RunState.MAGE, game_config.mage_burst_damage), "mage")


func _on_attack_requested(origin: Vector2) -> void:
	_spawn_projectile(origin, game_config.projectile_damage, "core")
	var archer_count := run_state.active_count(RunState.ARCHER)
	for index in archer_count:
		var offset := (float(index) - float(archer_count - 1) / 2.0) * 20.0
		_spawn_projectile(origin + Vector2(offset, 0.0), run_state.damage_for(RunState.ARCHER, game_config.projectile_damage), "archer")


func _process_warrior_charges() -> void:
	if processing_warrior_charges:
		return
	processing_warrior_charges = true
	while warrior_charge_queue > 0:
		warrior_charge_queue -= 1
		await get_tree().create_timer(game_config.warrior_charge_delay).timeout
		if player == null or not player.can_move or not run_state.consume_warrior_charge():
			continue
		_spawn_projectile(player.global_position + Vector2(0.0, -38.0), run_state.damage_for(RunState.WARRIOR, 10.0), "warrior")
		await get_tree().create_timer(0.15).timeout
	processing_warrior_charges = false


func _spawn_projectile(origin: Vector2, damage: float, style: String) -> void:
	if player == null or not player.can_move:
		return
	var projectile := RunnerProjectile.new()
	add_child(projectile)
	var speed := game_config.warrior_charge_speed if style == "warrior" else game_config.projectile_speed
	projectile.setup(origin, speed, damage, style)


func stop_run() -> void:
	run_finished = true
	if player != null:
		player.stop()


func progress() -> float:
	if player == null:
		return 0.0
	return clampf(elapsed_seconds / wave_duration_seconds, 0.0, 1.0)


func _on_finish_reached() -> void:
	if player == null or not player.can_move:
		return
	player.stop()
	completed.emit()


func _draw() -> void:
	if camera == null:
		return
	# The track is a camera-locked presentation layer. Gameplay entities remain in
	# world space, so advancing a long level no longer drags a flat floor through
	# the viewport.
	var track_center := camera.global_position
	var top := track_center.y - 338.0
	var bottom := track_center.y + 382.0
	var lane_center := track_center.x - 180.0
	var near_boundaries := PackedFloat32Array([-TRACK_HALF_WIDTH, -93.3333, 93.3333, TRACK_HALF_WIDTH])
	var far_boundaries := PackedFloat32Array([-TRACK_FAR_HALF_WIDTH, -55.0, 55.0, TRACK_FAR_HALF_WIDTH])
	for lane_index in 3:
		var lane_start_far := lane_center + far_boundaries[lane_index]
		var lane_end_far := lane_center + far_boundaries[lane_index + 1]
		var lane_start_near := lane_center + near_boundaries[lane_index]
		var lane_end_near := lane_center + near_boundaries[lane_index + 1]
		var lane_color := Color("354541") if lane_index % 2 == 0 else Color("30403d")
		var lane_polygon := PackedVector2Array([
			Vector2(lane_start_far, top), Vector2(lane_end_far, top),
			Vector2(lane_end_near, bottom), Vector2(lane_start_near, bottom)
		])
		draw_colored_polygon(lane_polygon, lane_color)
	var near_left := lane_center - TRACK_HALF_WIDTH
	var near_right := lane_center + TRACK_HALF_WIDTH
	var far_left := lane_center - TRACK_FAR_HALF_WIDTH
	var far_right := lane_center + TRACK_FAR_HALF_WIDTH
	draw_line(Vector2(far_left, top), Vector2(near_left, bottom), Color("80958c"), 4.0)
	draw_line(Vector2(far_right, top), Vector2(near_right, bottom), Color("80958c"), 4.0)
	for divider_index in 1: 
		var divider_far := lane_center + far_boundaries[divider_index]
		var divider_near := lane_center + near_boundaries[divider_index]
		draw_line(Vector2(divider_far, top), Vector2(divider_near, bottom), Color("b88b50", 0.72), 2.0)
	for y in range(int(top), int(bottom), 120):
		var row_ratio := clampf(inverse_lerp(top, bottom, float(y)), 0.0, 1.0)
		var row_half_width := lerpf(TRACK_FAR_HALF_WIDTH, TRACK_HALF_WIDTH, row_ratio)
		draw_line(Vector2(lane_center - row_half_width, y), Vector2(lane_center + row_half_width, y), Color("52645e"), 2.0)
