extends SceneTree

var failures := 0
var level: RunnerLevel


func _init() -> void:
	InputMap.add_action("move_left")
	InputMap.add_action("move_right")
	level = RunnerLevel.new()
	root.add_child(level)
	var state := RunState.new(5, {"warrior": 25, "archer": 25, "shield": 25, "mage": 25})
	var config := GameConfig.new()
	call_deferred("_start_level", state, config)


func _start_level(state: RunState, config: GameConfig) -> void:
	level.load_definition({"distance": 1700.0, "enemy_hp": 3, "enemy_count": 4}, state, config, [{"distance": 820.0, "options": [{"x": -187.0, "role_id": "archer", "part_value": 2}]}])
	_verify_after_attacks()


func _verify_after_attacks() -> void:
	var lane_seen := {}
	var gate: ProfessionGate
	for candidate in get_nodes_in_group("runner_enemies"):
		if candidate is BasicEnemy:
			lane_seen[roundi(float(candidate.get_meta("base_lane_x", 999.0)))] = true
	_expect(lane_seen.size() == 1 and lane_seen.has(187), "runner enemies spawn on the right monster path")
	for candidate in level.get_children():
		if candidate is ProfessionGate:
			gate = candidate
	_expect(gate != null and is_equal_approx(gate.scale.x, 1.0), "gate starts at full scale before travel")
	level.player.position.x = 187.0
	await create_timer(0.2).timeout
	_expect(gate != null and gate.scale.x < 1.0, "live travel updates entity perspective")
	await create_timer(3.8).timeout
	var enemy_count := 0
	var damaged_enemy := false
	for candidate in get_nodes_in_group("runner_enemies"):
		if candidate is BasicEnemy:
			enemy_count += 1
			if (candidate as BasicEnemy).hit_points < 3.0:
				damaged_enemy = true
	_expect(damaged_enemy or enemy_count < 4, "runner level auto attack damages or defeats the aligned enemy")
	quit(failures)


func _expect(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("FAILED: " + description)
