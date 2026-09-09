class_name GameSession
extends Node

var game_config: GameConfig = GameConfig.new()
var run_state: RunState
var current_level_index: int = 0
var unlocked_level_index: int = 0
var random_seed: int = 0
var level_definitions: Array[Dictionary] = []
var shop_offers: Array[String] = []
var shop_free_refreshes: int = 0
var shop_refresh_count: int = 0
var map_offers: Array[Dictionary] = []
var selected_map_offer: Dictionary = {}
var map_selection_pending: bool = false
var shop_completed: bool = false

const SAVE_PATH := "user://run_save.json"
const GATE_PATH_X := -187.0
const MONSTER_PATH_X := 187.0

const LEVEL_DEFINITIONS: Array[Dictionary] = [
	{"id": "normal", "title": "普通波次", "kind": "normal", "distance": 1700.0, "enemy_hp": 2, "enemy_count": 5},
	{"id": "elite", "title": "精英波次", "kind": "elite", "distance": 1900.0, "enemy_hp": 3, "enemy_count": 7},
	{"id": "boss", "title": "精英与首领", "kind": "boss", "distance": 2100.0, "enemy_hp": 5, "enemy_count": 8},
]


func start_new_game(persist: bool = true) -> void:
	game_config = GameConfig.load_runtime()
	run_state = RunState.new(game_config.required_parts, {
		RunState.WARRIOR: game_config.initial_warrior_weight,
		RunState.ARCHER: game_config.initial_archer_weight,
		RunState.SHIELD: game_config.initial_shield_weight,
		RunState.MAGE: game_config.initial_mage_weight,
	}, game_config.initial_team_durability)
	current_level_index = 0
	unlocked_level_index = 0
	random_seed = int(Time.get_unix_time_from_system())
	level_definitions = LEVEL_DEFINITIONS.duplicate(true)
	shop_offers = []
	shop_free_refreshes = 0
	shop_refresh_count = 0
	map_offers = []
	selected_map_offer = _default_map_offer(0)
	map_selection_pending = false
	shop_completed = false
	if persist:
		save_game()


func load_saved_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or not parsed.has("run_state"):
		return false
	game_config = GameConfig.load_runtime()
	run_state = RunState.from_dict(parsed.get("run_state", {}))
	current_level_index = clampi(int(parsed.get("current_level_index", 0)), 0, LEVEL_DEFINITIONS.size() - 1)
	unlocked_level_index = clampi(int(parsed.get("unlocked_level_index", current_level_index)), 0, LEVEL_DEFINITIONS.size() - 1)
	random_seed = int(parsed.get("random_seed", 0))
	level_definitions = LEVEL_DEFINITIONS.duplicate(true)
	shop_offers = []
	for role_id in parsed.get("shop_offers", []):
		if role_id is String and RunState.ROLE_IDS.has(role_id):
			shop_offers.append(role_id)
	shop_free_refreshes = maxi(0, int(parsed.get("shop_free_refreshes", 0)))
	shop_refresh_count = maxi(0, int(parsed.get("shop_refresh_count", 0)))
	map_offers = []
	for map_offer in parsed.get("map_offers", []):
		if map_offer is Dictionary:
			map_offers.append(map_offer.duplicate(true))
	selected_map_offer = parsed.get("selected_map_offer", {}).duplicate(true) if parsed.get("selected_map_offer", {}) is Dictionary else {}
	if selected_map_offer.is_empty():
		selected_map_offer = _default_map_offer(current_level_index)
	map_selection_pending = bool(parsed.get("map_selection_pending", false))
	shop_completed = bool(parsed.get("shop_completed", false))
	if map_selection_pending and map_offers.is_empty():
		_roll_map_offers()
	return true


func save_game() -> void:
	if run_state == null:
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"run_state": run_state.to_dict(),
		"current_level_index": current_level_index,
		"unlocked_level_index": unlocked_level_index,
		"random_seed": random_seed,
		"shop_offers": shop_offers.duplicate(),
		"shop_free_refreshes": shop_free_refreshes,
		"shop_refresh_count": shop_refresh_count,
		"map_offers": map_offers.duplicate(true),
		"selected_map_offer": selected_map_offer.duplicate(true),
		"map_selection_pending": map_selection_pending,
		"shop_completed": shop_completed,
	}))


func has_saved_game() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func select_level(level_index: int, persist: bool = true) -> void:
	current_level_index = clampi(level_index, 0, unlocked_level_index)
	if persist:
		save_game()


func current_level_definition() -> Dictionary:
	var definition: Dictionary = level_definitions[current_level_index].duplicate(true)
	if not selected_map_offer.is_empty() and int(selected_map_offer.get("stage_index", current_level_index)) == current_level_index:
		definition["title"] = str(selected_map_offer.get("title", definition.get("title", "地图")))
		var hp_bonus := int(selected_map_offer.get("hp_bonus_percent", 0))
		definition["enemy_hp"] = maxi(1, roundi(float(definition.get("enemy_hp", 1)) * (1.0 + float(hp_bonus) / 100.0)))
		definition["hp_bonus_percent"] = hp_bonus
		definition["currency_bonus_percent"] = int(selected_map_offer.get("currency_bonus_percent", 0))
	return definition


func level_number() -> int:
	return current_level_index + 1


func level_count() -> int:
	return level_definitions.size()


func has_next_level() -> bool:
	return current_level_index + 1 < level_definitions.size()


func complete_current_level() -> void:
	if has_next_level():
		current_level_index += 1
		unlocked_level_index = maxi(unlocked_level_index, current_level_index)
		selected_map_offer = {}
		map_selection_pending = true
		shop_completed = false
		_roll_map_offers()
	save_game()


func _default_map_offer(stage_index: int) -> Dictionary:
	var definition: Dictionary = LEVEL_DEFINITIONS[clampi(stage_index, 0, LEVEL_DEFINITIONS.size() - 1)]
	return {
		"map_id": "%s_default" % str(definition.get("id", "stage")),
		"stage_index": clampi(stage_index, 0, LEVEL_DEFINITIONS.size() - 1),
		"title": str(definition.get("title", "地图")),
		"kind": str(definition.get("kind", "normal")),
		"hp_bonus_percent": 0,
		"currency_bonus_percent": 0,
	}


func _roll_map_offers() -> void:
	map_offers = []
	var rng := RandomNumberGenerator.new()
	rng.seed = random_seed + current_level_index * 1543 + 9176
	var definition: Dictionary = LEVEL_DEFINITIONS[current_level_index]
	var map_names := ["晨雾回廊", "蓝晶矿道", "风暴高地", "熔岩祭坛", "星辉庭院"]
	for index in 3:
		var hp_bonus := rng.randi_range(game_config.map_hp_bonus_min_percent, game_config.map_hp_bonus_max_percent)
		var currency_bonus := rng.randi_range(game_config.map_currency_bonus_min_percent, game_config.map_currency_bonus_max_percent)
		map_offers.append({
			"map_id": "%s_%d_%d" % [str(definition.get("id", "stage")), current_level_index, index],
			"stage_index": current_level_index,
			"title": "%s · %s" % [str(definition.get("title", "地图")), map_names[(current_level_index + index) % map_names.size()]],
			"kind": str(definition.get("kind", "normal")),
			"hp_bonus_percent": hp_bonus,
			"currency_bonus_percent": currency_bonus,
		})


func has_map_selection() -> bool:
	return map_selection_pending and shop_completed and not map_offers.is_empty()


func mark_shop_completed() -> void:
	if not map_selection_pending:
		return
	shop_completed = true
	save_game()


func select_map(map_index: int, persist: bool = true) -> bool:
	if not has_map_selection() or map_index < 0 or map_index >= map_offers.size():
		return false
	selected_map_offer = map_offers[map_index].duplicate(true)
	map_selection_pending = false
	shop_completed = false
	if persist:
		save_game()
	return true


func currency_amount(base_amount: int) -> int:
	var bonus := int(selected_map_offer.get("currency_bonus_percent", 0))
	return maxi(0, roundi(float(base_amount) * (1.0 + float(bonus) / 100.0)))


func build_gate_rows() -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = random_seed + current_level_index * 1009
	var rows: Array[Dictionary] = []
	if current_level_index == 0:
		rows.append(_row(420.0, [
			_gate(GATE_PATH_X, RunState.WARRIOR, game_config.required_parts - 1),
		]))
	for distance in [820.0, 1220.0, 1580.0]:
		rows.append(_random_row(float(distance), rng))
	return rows


func _random_row(distance: float, rng: RandomNumberGenerator) -> Dictionary:
	var options: Array[Dictionary] = []
	var used_roles: Array[String] = []
	var role_id := _weighted_unused_role(used_roles, rng)
	var part_value := _random_part_value(rng)
	options.append(_gate(GATE_PATH_X, role_id, part_value))
	return _row(distance, options)


func begin_shop() -> void:
	shop_refresh_count = 0
	shop_free_refreshes = game_config.shop_free_refreshes
	shop_completed = false
	_roll_shop_offers()
	save_game()


func refresh_shop() -> bool:
	if shop_free_refreshes > 0:
		shop_free_refreshes -= 1
	else:
		if not run_state.spend_currency(game_config.shop_refresh_cost):
			return false
	shop_refresh_count += 1
	_roll_shop_offers()
	save_game()
	return true


func _roll_shop_offers() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = random_seed + current_level_index * 1009 + shop_refresh_count * 7919 + int(Time.get_ticks_msec())
	shop_offers = []
	var used: Array[String] = []
	for _index in 3:
		var role_id := _weighted_unused_role(used, rng)
		used.append(role_id)
		shop_offers.append(role_id)


func is_shop_offer(role_id: String) -> bool:
	return shop_offers.has(role_id)


func _weighted_unused_role(used_roles: Array[String], rng: RandomNumberGenerator) -> String:
	var candidates: Array[String] = []
	for role_id in RunState.ROLE_IDS:
		if not used_roles.has(role_id):
			candidates.append(role_id)
	if candidates.is_empty():
		return _weighted_role(rng)
	var total := 0
	for role_id in candidates:
		total += run_state.weight_for(role_id)
	var roll := rng.randi_range(1, maxi(1, total))
	for role_id in candidates:
		roll -= run_state.weight_for(role_id)
		if roll <= 0:
			return role_id
	return candidates.back()


func _different_role(excluded_role: String, rng: RandomNumberGenerator) -> String:
	var candidates: Array[String] = []
	for role_id in RunState.ROLE_IDS:
		if role_id != excluded_role:
			candidates.append(role_id)
	return candidates[rng.randi_range(0, candidates.size() - 1)]


func _weighted_role(rng: RandomNumberGenerator) -> String:
	var total := 0
	for role_id in RunState.ROLE_IDS:
		total += run_state.weight_for(role_id)
	var roll := rng.randi_range(1, maxi(1, total))
	for role_id in RunState.ROLE_IDS:
		roll -= run_state.weight_for(role_id)
		if roll <= 0:
			return role_id
	return RunState.WARRIOR


func _random_part_value(rng: RandomNumberGenerator) -> int:
	var value := rng.randi_range(game_config.gate_part_min, game_config.gate_part_max)
	return -value if rng.randf() < 0.25 else value


func _row(distance: float, options: Array) -> Dictionary:
	return {"distance": distance, "options": options}


func _gate(x: float, role_id: String, part_value: int) -> Dictionary:
	return {"x": x, "role_id": role_id, "part_value": part_value}
