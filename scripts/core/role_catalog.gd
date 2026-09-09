class_name RoleCatalog
extends RefCounted

## The white-box keeps role rules in one data source so gates, HUD and runtime
## companions can add a profession without duplicating its identity rules.
const ROLE_IDS := ["warrior", "archer", "shield", "mage"]

const DEFINITIONS := {
	"warrior": {
		"name": "战士", "color": "d85b5b", "action": "charge", "persist": "consumed",
		"base_hp": 1, "skill_multiplier": 3.0,
	},
	"archer": {
		"name": "弓手", "color": "63b77b", "action": "ranged", "persist": "active",
		"base_hp": 2, "skill_multiplier": 1.0,
	},
	"shield": {
		"name": "盾卫", "color": "5e8fc7", "action": "guard", "persist": "active",
		"base_hp": 5, "skill_multiplier": 1.0,
	},
	"mage": {
		"name": "术士", "color": "9a70c7", "action": "burst", "persist": "active",
		"base_hp": 2, "skill_multiplier": 2.0,
	},
}


static func is_valid(role_id: String) -> bool:
	return DEFINITIONS.has(role_id)


static func definition(role_id: String) -> Dictionary:
	return DEFINITIONS.get(role_id, DEFINITIONS["warrior"]).duplicate(true)


static func display_name(role_id: String) -> String:
	return str(definition(role_id).get("name", role_id))


static func color(role_id: String) -> Color:
	return Color(str(definition(role_id).get("color", "ffffff")))
