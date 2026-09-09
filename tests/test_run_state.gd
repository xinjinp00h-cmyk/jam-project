extends SceneTree

const RunStateScript = preload("res://scripts/core/run_state.gd")

var failures := 0


func _init() -> void:
	var state = RunStateScript.new(5, {"warrior": 25, "archer": 25, "shield": 25, "mage": 25})
	_expect(state.apply_gate("warrior", 3).get("completed") == 0, "warrior partial progress")
	var warrior_result: Dictionary = state.apply_gate("warrior", 8)
	_expect(warrior_result.get("completed") == 2 and state.part_count("warrior") == 1, "positive overflow creates roles and remainder")
	_expect(state.stamp_count("warrior") == 2 and state.pending_warrior_charges == 2, "warrior completion persists stamps and queues charges")
	state.apply_gate("warrior", -9)
	_expect(state.part_count("warrior") == 0 and state.stamp_count("warrior") == 2, "negative gate only removes unfinished parts")
	state.apply_gate("archer", 5)
	_expect(state.active_count("archer") == 1 and state.stamp_count("archer") == 1, "archer completion persists active archer")
	var preview: Dictionary = state.preview_gate("archer", 9)
	_expect(preview.get("completed") == 1 and preview.get("remainder") == 4, "gate preview uses current role progress")
	state.increase_weight("warrior", 10, 60)
	_expect(state.weight_for("warrior") == 35 and state.weight_for("archer") == 25, "profession weight persists independently")
	_expect(state.consume_warrior_charge() and state.pending_warrior_charges == 1, "warrior charges consume one at a time")
	state.apply_gate("shield", 5)
	_expect(state.active_count("shield") == 1 and _active_hp(state, "shield") == 5, "shield completion creates durable active role")
	state.apply_gate("shield", -2)
	_expect(_active_hp(state, "shield") == 3, "negative gate damages active role after parts")
	state.apply_gate("mage", 10)
	_expect(state.active_count("mage") == 2 and state.stamp_count("mage") == 2, "mage overflow creates multiple active roles")
	state.apply_gate("warrior", 10)
	_expect(is_equal_approx(state.damage_multiplier("warrior"), 1.69), "four warrior stamps use two independent 30 percent bond layers")
	_expect(is_equal_approx(state.damage_for("mage", 10.0), 13.0), "two mage stamps use one multiplicative bond layer")
	var restored = RunStateScript.from_dict(state.to_dict())
	_expect(restored.stamp_count("mage") == 2 and restored.active_count("shield") == 1, "run state serializes and restores")
	state.add_currency(3)
	_expect(state.spend_currency(2) and state.currency == 1, "currency can be spent for shop refresh")
	state.apply_enemy_leak(4)
	_expect(state.team_durability == 96 and not state.is_defeated(), "enemy leak reduces team durability")
	state.apply_enemy_leak(200)
	_expect(state.team_durability == 0 and state.is_defeated(), "durability reaches defeat at zero")
	quit(failures)


func _expect(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("FAILED: " + description)


func _active_hp(state: RunState, role_id: String) -> int:
	for active_role in state.active_roles:
		if active_role.get("role_id", "") == role_id:
			return int(active_role.get("hp", 0))
	return 0
