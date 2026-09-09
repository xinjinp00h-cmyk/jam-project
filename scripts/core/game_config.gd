class_name GameConfig
extends RefCounted

const CONFIG_PATH := "res://config/gameplay.cfg"

var auto_attack_interval: float = 1.0
var projectile_speed: float = 520.0
var projectile_damage: int = 1
var warrior_charge_delay: float = 0.25
var warrior_charge_speed: float = 900.0
var required_parts: int = 5
var gate_part_min: int = 2
var gate_part_max: int = 4
var initial_warrior_weight: int = 25
var initial_archer_weight: int = 25
var initial_shield_weight: int = 25
var initial_mage_weight: int = 25
var shop_weight_step: int = 10
var shop_weight_cap: int = 60
var mage_burst_damage: int = 2
var run_duration_seconds: float = 120.0
var wave_duration_seconds: float = 40.0
var initial_team_durability: int = 100
var wave_clear_currency: int = 2
var enemy_kill_currency: int = 1
var barrel_currency: int = 1
var shop_refresh_cost: int = 1
var shop_free_refreshes: int = 1
var map_hp_bonus_min_percent: int = 0
var map_hp_bonus_max_percent: int = 35
var map_currency_bonus_min_percent: int = 0
var map_currency_bonus_max_percent: int = 50


static func load_runtime() -> GameConfig:
	var result := GameConfig.new()
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		return result

	result.auto_attack_interval = maxf(0.05, float(config.get_value("combat", "auto_attack_interval", result.auto_attack_interval)))
	result.projectile_speed = maxf(1.0, float(config.get_value("combat", "projectile_speed", result.projectile_speed)))
	result.projectile_damage = maxi(1, int(config.get_value("combat", "projectile_damage", result.projectile_damage)))
	result.warrior_charge_delay = maxf(0.0, float(config.get_value("warrior", "charge_delay", result.warrior_charge_delay)))
	result.warrior_charge_speed = maxf(1.0, float(config.get_value("warrior", "charge_speed", result.warrior_charge_speed)))
	result.required_parts = maxi(1, int(config.get_value("roles", "required_parts", result.required_parts)))
	result.gate_part_min = maxi(1, int(config.get_value("gates", "part_min", result.gate_part_min)))
	result.gate_part_max = maxi(result.gate_part_min, int(config.get_value("gates", "part_max", result.gate_part_max)))
	result.initial_warrior_weight = maxi(1, int(config.get_value("weights", "warrior", 25)))
	result.initial_archer_weight = maxi(1, int(config.get_value("weights", "archer", 25)))
	result.initial_shield_weight = maxi(1, int(config.get_value("weights", "shield", 25)))
	result.initial_mage_weight = maxi(1, int(config.get_value("weights", "mage", 25)))
	result.shop_weight_step = maxi(1, int(config.get_value("shop", "weight_step", result.shop_weight_step)))
	result.shop_weight_cap = maxi(result.shop_weight_step, int(config.get_value("shop", "weight_cap", result.shop_weight_cap)))
	result.mage_burst_damage = maxi(1, int(config.get_value("mage", "burst_damage", result.mage_burst_damage)))
	result.run_duration_seconds = maxf(1.0, float(config.get_value("run", "duration_seconds", result.run_duration_seconds)))
	result.wave_duration_seconds = maxf(1.0, float(config.get_value("run", "wave_duration_seconds", result.wave_duration_seconds)))
	result.initial_team_durability = maxi(1, int(config.get_value("run", "team_durability", result.initial_team_durability)))
	result.wave_clear_currency = maxi(0, int(config.get_value("currency", "wave_clear", result.wave_clear_currency)))
	result.enemy_kill_currency = maxi(0, int(config.get_value("currency", "enemy_kill", result.enemy_kill_currency)))
	result.barrel_currency = maxi(0, int(config.get_value("currency", "barrel", result.barrel_currency)))
	result.shop_refresh_cost = maxi(1, int(config.get_value("shop", "refresh_cost", result.shop_refresh_cost)))
	result.shop_free_refreshes = maxi(0, int(config.get_value("shop", "free_refreshes", result.shop_free_refreshes)))
	result.map_hp_bonus_min_percent = maxi(0, int(config.get_value("maps", "hp_bonus_min_percent", result.map_hp_bonus_min_percent)))
	result.map_hp_bonus_max_percent = maxi(result.map_hp_bonus_min_percent, int(config.get_value("maps", "hp_bonus_max_percent", result.map_hp_bonus_max_percent)))
	result.map_currency_bonus_min_percent = maxi(0, int(config.get_value("maps", "currency_bonus_min_percent", result.map_currency_bonus_min_percent)))
	result.map_currency_bonus_max_percent = maxi(result.map_currency_bonus_min_percent, int(config.get_value("maps", "currency_bonus_max_percent", result.map_currency_bonus_max_percent)))
	return result
