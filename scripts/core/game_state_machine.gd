class_name GameStateMachine
extends Node

signal state_changed(previous_state: State, next_state: State)

enum State {
	READY,
	PLAYING,
	LEVEL_COMPLETE,
	GAME_COMPLETE,
	FAILED,
}

var current_state: State = State.READY


func transition_to(next_state: State) -> void:
	if current_state == next_state:
		return
	var previous_state := current_state
	current_state = next_state
	state_changed.emit(previous_state, next_state)


func is_in(state: State) -> bool:
	return current_state == state
