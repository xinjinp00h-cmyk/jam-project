extends SceneTree

const GameSessionScript = preload("res://scripts/core/game_session.gd")

var failures := 0


func _init() -> void:
	var session = GameSessionScript.new()
	session.start_new_game(false)
	_expect(session.current_level_index == 0 and session.unlocked_level_index == 0, "new game starts at first locked node")
	_expect(session.level_count() == 3, "run is split into three waves")
	_expect(session.level_definitions[0].get("kind") == "normal" and session.level_definitions[1].get("kind") == "elite" and session.level_definitions[2].get("kind") == "boss", "waves escalate normal, elite, boss")
	_expect(is_equal_approx(session.game_config.run_duration_seconds, session.game_config.wave_duration_seconds * session.level_count()), "three waves fill the configured two-minute run")
	session.complete_current_level()
	_expect(session.current_level_index == 1 and session.unlocked_level_index == 1, "completing node unlocks the next node")
	_expect(session.map_selection_pending and session.map_offers.size() == 3 and not session.shop_completed, "completed node rolls three maps before shop choice")
	for offer in session.map_offers:
		_expect(int(offer.get("hp_bonus_percent", -1)) >= session.game_config.map_hp_bonus_min_percent and int(offer.get("hp_bonus_percent", -1)) <= session.game_config.map_hp_bonus_max_percent, "map hp modifier stays in configured range")
		_expect(int(offer.get("currency_bonus_percent", -1)) >= session.game_config.map_currency_bonus_min_percent and int(offer.get("currency_bonus_percent", -1)) <= session.game_config.map_currency_bonus_max_percent, "map currency modifier stays in configured range")
	_expect(not session.select_map(0, false), "map cannot be selected before shop is completed")
	session.begin_shop()
	session.mark_shop_completed()
	_expect(session.select_map(0, false), "shop completion unlocks map selection")
	var selected_definition := session.current_level_definition()
	_expect(selected_definition.get("hp_bonus_percent") == session.selected_map_offer.get("hp_bonus_percent"), "selected map hp modifier enters level definition")
	_expect(session.currency_amount(2) >= 2, "selected map currency modifier scales rewards")
	session.select_level(0, false)
	_expect(session.current_level_index == 0, "unlocked node can be selected")
	var gate_rows: Array[Dictionary] = session.build_gate_rows()
	_expect(gate_rows.size() == 4, "level builds the tutorial row plus three encounter rows")
	var lane_xs: Array[float] = []
	for option in gate_rows[0].get("options", []):
		lane_xs.append(float(option.get("x", 999.0)))
	_expect(lane_xs == [-187.0], "tutorial gate stays on the left gate path")
	for row in gate_rows:
		_expect(row.get("options", []).size() == 1, "every gate row has one left-path gate")
	session.begin_shop()
	_expect(session.shop_offers.size() == 3, "shop rolls three profession emblems")
	var currency_before: int = session.run_state.currency
	session.run_state.add_currency(1)
	var free_before: int = session.shop_free_refreshes
	_expect(session.refresh_shop(), "free shop refresh succeeds")
	_expect(session.shop_free_refreshes == maxi(0, free_before - 1), "free refresh is consumed before currency")
	_expect(session.run_state.currency == currency_before + 1, "free refresh does not spend currency")
	var serialized: Dictionary = session.run_state.to_dict()
	var restored = session.run_state.from_dict(JSON.parse_string(JSON.stringify(serialized)))
	_expect(restored.required_parts == session.run_state.required_parts and restored.weight_for("mage") == session.run_state.weight_for("mage"), "session state survives JSON round trip")
	session.free()
	quit(failures)


func _expect(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("FAILED: " + description)
