extends Node2D

var session: GameSession
var state_machine: GameStateMachine
var level: RunnerLevel
var hud: RunHud
var choosing_level: bool = false


func _ready() -> void:
	_setup_input()
	session = GameSession.new()
	add_child(session)
	state_machine = GameStateMachine.new()
	add_child(state_machine)
	level = RunnerLevel.new()
	level.name = "RunnerLevel"
	add_child(level)
	level.completed.connect(_on_level_completed)
	level.failed.connect(_on_level_failed)
	hud = RunHud.new()
	add_child(hud)
	hud.shop_selected.connect(_on_shop_selected)
	hud.shop_refresh_requested.connect(_on_shop_refresh_requested)
	hud.level_selected.connect(_on_level_selected)
	hud.map_selected.connect(_on_map_selected)
	level.run_state_changed.connect(_on_run_state_changed)
	if session.load_saved_game():
		choosing_level = true
		level.visible = false
		state_machine.transition_to(GameStateMachine.State.LEVEL_COMPLETE if session.map_selection_pending else GameStateMachine.State.READY)
		if session.map_selection_pending:
			if not session.shop_completed and session.shop_offers.is_empty():
				session.begin_shop()
			if session.shop_completed:
				hud.show_map_select(session.map_offers)
			else:
				hud.show_shop(session.run_state, session.game_config, session.shop_offers, session.shop_free_refreshes)
		else:
			hud.show_level_select(session.unlocked_level_index, session.level_definitions)
	else:
		session.start_new_game()
		_start_current_level()


func _process(_delta: float) -> void:
	if level == null or hud == null or session.run_state == null or choosing_level:
		return
	hud.update_run(
		session.level_number(), session.level_count(), str(session.current_level_definition().get("title", "")),
		level.progress(), session.run_state
	)


func _start_current_level() -> void:
	choosing_level = false
	level.visible = true
	level.load_definition(session.current_level_definition(), session.run_state, session.game_config, session.build_gate_rows())
	state_machine.transition_to(GameStateMachine.State.PLAYING)
	hud.show_running()


func _on_level_completed() -> void:
	if not state_machine.is_in(GameStateMachine.State.PLAYING):
		return
	level.stop_run()
	session.run_state.add_currency(session.currency_amount(session.game_config.wave_clear_currency))
	if session.has_next_level():
		session.complete_current_level()
		session.begin_shop()
		state_machine.transition_to(GameStateMachine.State.LEVEL_COMPLETE)
		hud.show_shop(session.run_state, session.game_config, session.shop_offers, session.shop_free_refreshes)
	else:
		state_machine.transition_to(GameStateMachine.State.GAME_COMPLETE)
		session.save_game()
		hud.show_game_complete()


func _on_shop_selected(role_id: String) -> void:
	if not state_machine.is_in(GameStateMachine.State.LEVEL_COMPLETE):
		return
	if not session.is_shop_offer(role_id):
		return
	session.run_state.increase_weight(role_id, session.game_config.shop_weight_step, session.game_config.shop_weight_cap)
	session.mark_shop_completed()
	hud.show_map_select(session.map_offers)


func _on_shop_refresh_requested() -> void:
	if not state_machine.is_in(GameStateMachine.State.LEVEL_COMPLETE):
		return
	if session.refresh_shop():
		hud.show_shop(session.run_state, session.game_config, session.shop_offers, session.shop_free_refreshes)


func _on_level_failed() -> void:
	if not state_machine.is_in(GameStateMachine.State.PLAYING):
		return
	state_machine.transition_to(GameStateMachine.State.FAILED)
	level.stop_run()
	session.save_game()
	hud.show_run_failed()


func _on_level_selected(level_index: int) -> void:
	if not choosing_level or session.map_selection_pending:
		return
	session.select_level(level_index)
	_start_current_level()


func _on_map_selected(map_index: int) -> void:
	if not state_machine.is_in(GameStateMachine.State.LEVEL_COMPLETE):
		return
	if session.select_map(map_index):
		_start_current_level()


func _on_run_state_changed() -> void:
	session.save_game()


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if not state_machine.is_in(GameStateMachine.State.GAME_COMPLETE) and not state_machine.is_in(GameStateMachine.State.FAILED):
		return
	var key_event := event as InputEventKey
	if key_event.keycode == KEY_R or key_event.keycode == KEY_ENTER:
		session.start_new_game()
		_start_current_level()


func _setup_input() -> void:
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])


func _add_key_action(action_name: StringName, keys: Array[Key]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for key in keys:
		var key_event := InputEventKey.new()
		key_event.keycode = key
		InputMap.action_add_event(action_name, key_event)
