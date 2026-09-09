class_name RunState
extends RefCounted

const RoleCatalogScript = preload("res://scripts/core/role_catalog.gd")
const WARRIOR := "warrior"
const ARCHER := "archer"
const SHIELD := "shield"
const MAGE := "mage"
const ROLE_IDS := [WARRIOR, ARCHER, SHIELD, MAGE]

var required_parts: int
var parts: Dictionary = {}
var stamps: Dictionary = {}
var weights: Dictionary = {}
var active_roles: Array[Dictionary] = []
var pending_warrior_charges: int = 0
var currency: int = 0
var max_team_durability: int = 100
var team_durability: int = 100

const BOND_DAMAGE_STEP := 1.30


func _init(new_required_parts: int = 5, initial_weights: Dictionary = {}, initial_durability: int = 100) -> void:
	required_parts = maxi(1, new_required_parts)
	max_team_durability = maxi(1, initial_durability)
	team_durability = max_team_durability
	for role_id in ROLE_IDS:
		parts[role_id] = 0
		stamps[role_id] = 0
		weights[role_id] = maxi(1, int(initial_weights.get(role_id, 25)))


func apply_gate(role_id: String, part_change: int) -> Dictionary:
	if not RoleCatalogScript.is_valid(role_id):
		return {"completed": 0, "remainder": 0, "accepted": false, "completed_roles": [], "removed_roles": []}
	if part_change < 0:
		return _apply_damage_gate(role_id, -part_change)
	var total := part_count(role_id) + part_change
	var completed := int(total / required_parts)
	parts[role_id] = total % required_parts
	stamps[role_id] = stamp_count(role_id) + completed
	if role_id == WARRIOR:
		pending_warrior_charges += completed
	else:
		for _index in completed:
			_add_active_role(role_id)
	return {"completed": completed, "remainder": parts[role_id], "accepted": true, "completed_roles": _repeat_role(role_id, completed), "removed_roles": []}


func _apply_damage_gate(role_id: String, damage: int) -> Dictionary:
	var remaining_damage := damage
	var removed_parts := mini(part_count(role_id), remaining_damage)
	parts[role_id] = part_count(role_id) - removed_parts
	remaining_damage -= removed_parts
	var removed_roles: Array[String] = []
	if remaining_damage > 0 and RoleCatalogScript.definition(role_id).get("persist", "active") == "active":
		for index in range(active_roles.size() - 1, -1, -1):
			if remaining_damage <= 0:
				break
			var active_role := active_roles[index]
			if str(active_role.get("role_id", "")) != role_id:
				continue
			var hp := int(active_role.get("hp", 1))
			var absorbed := mini(hp, remaining_damage)
			hp -= absorbed
			remaining_damage -= absorbed
			if hp <= 0:
				removed_roles.append(role_id)
				active_roles.remove_at(index)
			else:
				active_roles[index]["hp"] = hp
	return {"completed": 0, "remainder": part_count(role_id), "accepted": true, "removed_parts": removed_parts, "removed_roles": removed_roles}


func _add_active_role(role_id: String) -> void:
	var definition: Dictionary = RoleCatalogScript.definition(role_id)
	active_roles.append({"role_id": role_id, "hp": int(definition.get("base_hp", 1)), "max_hp": int(definition.get("base_hp", 1))})


func preview_gate(role_id: String, part_change: int) -> Dictionary:
	if not RoleCatalogScript.is_valid(role_id):
		return {"completed": 0, "remainder": 0, "removed_parts": 0}
	if part_change < 0:
		return {"completed": 0, "remainder": maxi(0, part_count(role_id) + part_change), "removed_parts": mini(part_count(role_id), -part_change)}
	var total := part_count(role_id) + part_change
	return {"completed": int(total / required_parts), "remainder": total % required_parts, "removed_parts": 0}


func _repeat_role(role_id: String, count: int) -> Array[String]:
	var result: Array[String] = []
	for _index in count:
		result.append(role_id)
	return result


func consume_warrior_charge() -> bool:
	if pending_warrior_charges <= 0:
		return false
	pending_warrior_charges -= 1
	return true


func add_currency(amount: int) -> void:
	currency = maxi(0, currency + amount)


func spend_currency(amount: int) -> bool:
	var cost := maxi(0, amount)
	if currency < cost:
		return false
	currency -= cost
	return true


func apply_enemy_leak(damage: int) -> int:
	var applied := mini(maxi(0, damage), team_durability)
	team_durability = maxi(0, team_durability - applied)
	return applied


func is_defeated() -> bool:
	return team_durability <= 0


func increase_weight(role_id: String, step: int, cap: int) -> bool:
	if not RoleCatalogScript.is_valid(role_id):
		return false
	weights[role_id] = mini(cap, weight_for(role_id) + maxi(0, step))
	return true


func part_count(role_id: String) -> int:
	return int(parts.get(role_id, 0))


func stamp_count(role_id: String) -> int:
	return int(stamps.get(role_id, 0))


func weight_for(role_id: String) -> int:
	return int(weights.get(role_id, 0))


func weight_percent(role_id: String) -> int:
	var total := 0
	for candidate in ROLE_IDS:
		total += weight_for(candidate)
	if total <= 0:
		return 0
	return roundi(float(weight_for(role_id)) / float(total) * 100.0)


func active_count(role_id: String) -> int:
	var count := 0
	for active_role in active_roles:
		if active_role.get("role_id", "") == role_id:
			count += 1
	return count


func bond_level(role_id: String) -> int:
	var count := stamp_count(role_id)
	if count >= 6:
		return 3
	if count >= 4:
		return 2
	if count >= 2:
		return 1
	return 0


func damage_multiplier(role_id: String) -> float:
	return pow(BOND_DAMAGE_STEP, bond_level(role_id))


func damage_for(role_id: String, base_damage: float) -> float:
	return base_damage * damage_multiplier(role_id)


func to_dict() -> Dictionary:
	return {
		"required_parts": required_parts,
		"parts": parts.duplicate(true),
		"stamps": stamps.duplicate(true),
		"weights": weights.duplicate(true),
		"active_roles": active_roles.duplicate(true),
		"pending_warrior_charges": pending_warrior_charges,
		"currency": currency,
		"max_team_durability": max_team_durability,
		"team_durability": team_durability,
	}


static func from_dict(data: Dictionary) -> RunState:
	var state := RunState.new(int(data.get("required_parts", 5)), data.get("weights", {}), int(data.get("max_team_durability", 100)))
	for role_id in ROLE_IDS:
		state.parts[role_id] = maxi(0, int(data.get("parts", {}).get(role_id, 0)))
		state.stamps[role_id] = maxi(0, int(data.get("stamps", {}).get(role_id, 0)))
	state.active_roles = []
	for active_role in data.get("active_roles", []):
		if active_role is Dictionary and RoleCatalogScript.is_valid(str(active_role.get("role_id", ""))):
			state.active_roles.append(active_role.duplicate(true))
	state.pending_warrior_charges = maxi(0, int(data.get("pending_warrior_charges", 0)))
	state.currency = maxi(0, int(data.get("currency", 0)))
	state.team_durability = clampi(int(data.get("team_durability", state.max_team_durability)), 0, state.max_team_durability)
	return state
