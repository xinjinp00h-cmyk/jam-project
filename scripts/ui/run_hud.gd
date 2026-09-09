class_name RunHud
extends CanvasLayer

const RoleCatalogScript = preload("res://scripts/core/role_catalog.gd")
signal shop_selected(role_id: String)
signal shop_refresh_requested
signal level_selected(level_index: int)

var level_label: Label
var title_label: Label
var subtitle_label: Label
var progress_label: Label
var role_label: Label
var stamp_label: Label
var weight_label: Label
var message_label: Label
var hint_label: Label
var shop_panel: Control
var shop_buttons: Dictionary = {}
var shop_refresh_button: Button
var level_panel: Control
var mobile_left_button: Button
var mobile_right_button: Button
var playfield_frame: Panel
var sidebar: Control
var side_left_button: Button
var side_right_button: Button
var status_body: Label
var feed_body: Label
var team_chip: Label
var life_chip: Label
var kill_chip: Label
var coin_chip: Label


func _ready() -> void:
	layer = 10
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	var top_bar := ColorRect.new()
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_bottom = 184.0
	top_bar.color = Color("0d171a", 0.98)
	overlay.add_child(top_bar)
	playfield_frame = _make_playfield_frame(overlay)
	title_label = _make_label(Vector2(20.0, 10.0), Vector2(500.0, 25.0), 20, Color("e8f0ed"))
	title_label.text = "拇指王数字门玩法演示"
	overlay.add_child(title_label)
	subtitle_label = _make_label(Vector2(20.0, 36.0), Vector2(500.0, 16.0), 10, Color("8ca69d"))
	subtitle_label.text = "THUMB KING · NUMBER GATE DEMO"
	overlay.add_child(subtitle_label)
	level_label = _make_label(Vector2(20.0, 58.0), Vector2(500.0, 26.0), 19, Color("e8f0ed"))
	overlay.add_child(level_label)
	progress_label = _make_label(Vector2(20.0, 86.0), Vector2(500.0, 24.0), 14, Color("a7c0b7"))
	overlay.add_child(progress_label)
	role_label = _make_label(Vector2(330.0, 10.0), Vector2(600.0, 48.0), 18, Color("e8f0ed"))
	role_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	role_label.offset_left = -630.0
	role_label.offset_top = 10.0
	role_label.offset_right = -30.0
	role_label.offset_bottom = 58.0
	role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	overlay.add_child(role_label)
	stamp_label = _make_label(Vector2(330.0, 62.0), Vector2(600.0, 20.0), 13, Color("9fb8ae"))
	stamp_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	stamp_label.offset_left = -630.0
	stamp_label.offset_top = 62.0
	stamp_label.offset_right = -30.0
	stamp_label.offset_bottom = 82.0
	stamp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	overlay.add_child(stamp_label)
	weight_label = _make_label(Vector2(330.0, 86.0), Vector2(600.0, 20.0), 13, Color("9fb8ae"))
	weight_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	weight_label.offset_left = -630.0
	weight_label.offset_top = 86.0
	weight_label.offset_right = -30.0
	weight_label.offset_bottom = 106.0
	weight_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	overlay.add_child(weight_label)
	message_label = _make_label(Vector2(160.0, 145.0), Vector2(640.0, 80.0), 32, Color("f2f2f2"))
	message_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	message_label.offset_left = -320.0
	message_label.offset_top = 145.0
	message_label.offset_right = 320.0
	message_label.offset_bottom = 225.0
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.visible = false
	overlay.add_child(message_label)
	hint_label = _make_label(Vector2(0.0, 500.0), Vector2(960.0, 28.0), 16, Color("bdbdbd"))
	hint_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint_label.offset_left = 0.0
	hint_label.offset_top = -40.0
	hint_label.offset_right = 0.0
	hint_label.offset_bottom = -12.0
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.text = "A / D 或 ← / → 移动　·　核心与驻场职业自动战斗"
	overlay.add_child(hint_label)
	_build_shop(overlay)
	_build_level_select(overlay)
	_build_mobile_controls(overlay)
	_build_wide_console(overlay)
	_build_status_chips(overlay)
	if _is_compact_view():
		_apply_portrait_layout(top_bar)
	else:
		_apply_wide_layout(top_bar)


func _is_compact_view() -> bool:
	var viewport_size := get_viewport().get_visible_rect().size
	return viewport_size.x < 800.0


func _apply_portrait_layout(top_bar: ColorRect) -> void:
	top_bar.offset_bottom = 184.0
	level_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	level_label.offset_left = 20.0
	level_label.offset_top = 10.0
	level_label.offset_right = -20.0
	level_label.offset_bottom = 38.0
	progress_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	progress_label.offset_left = 20.0
	progress_label.offset_top = 42.0
	progress_label.offset_right = -20.0
	progress_label.offset_bottom = 66.0
	role_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	role_label.offset_left = 16.0
	role_label.offset_top = 72.0
	role_label.offset_right = -16.0
	role_label.offset_bottom = 98.0
	role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	role_label.add_theme_font_size_override("font_size", 14)
	stamp_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	stamp_label.offset_left = 16.0
	stamp_label.offset_top = 102.0
	stamp_label.offset_right = -16.0
	stamp_label.offset_bottom = 126.0
	stamp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stamp_label.add_theme_font_size_override("font_size", 12)
	weight_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	weight_label.offset_left = 16.0
	weight_label.offset_top = 130.0
	weight_label.offset_right = -16.0
	weight_label.offset_bottom = 154.0
	weight_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	weight_label.add_theme_font_size_override("font_size", 12)
	title_label.visible = true
	subtitle_label.visible = true
	playfield_frame.visible = false
	message_label.offset_top = 220.0
	message_label.offset_bottom = 292.0
	message_label.add_theme_font_size_override("font_size", 28)
	hint_label.add_theme_font_size_override("font_size", 14)
	hint_label.text = "← / → 移动　·　自动战斗"
	title_label.offset_top = 10.0
	title_label.offset_bottom = 34.0
	subtitle_label.offset_top = 36.0
	subtitle_label.offset_bottom = 52.0
	level_label.offset_top = 58.0
	level_label.offset_bottom = 84.0
	progress_label.offset_top = 86.0
	progress_label.offset_bottom = 110.0
	if sidebar != null:
		sidebar.visible = false
	_set_status_chips_visible(false)


func _apply_wide_layout(top_bar: ColorRect) -> void:
	top_bar.offset_bottom = 96.0
	title_label.position = Vector2(80.0, 14.0)
	title_label.size = Vector2(420.0, 28.0)
	title_label.add_theme_font_size_override("font_size", 20)
	subtitle_label.position = Vector2(80.0, 43.0)
	subtitle_label.size = Vector2(420.0, 18.0)
	level_label.position = Vector2(80.0, 68.0)
	level_label.size = Vector2(420.0, 22.0)
	level_label.add_theme_font_size_override("font_size", 13)
	progress_label.position = Vector2(510.0, 69.0)
	progress_label.size = Vector2(90.0, 22.0)
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	progress_label.add_theme_font_size_override("font_size", 13)
	role_label.visible = false
	stamp_label.visible = false
	weight_label.visible = false
	playfield_frame.set_anchors_preset(Control.PRESET_TOP_LEFT)
	playfield_frame.position = Vector2(80.0, 112.0)
	playfield_frame.size = Vector2(560.0, 720.0)
	message_label.offset_top = 280.0
	message_label.offset_bottom = 350.0
	hint_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	hint_label.position = Vector2(80.0, 842.0)
	hint_label.size = Vector2(560.0, 28.0)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 13)
	_set_mobile_controls_position_wide()
	if sidebar != null:
		sidebar.visible = false
	_set_status_chips_visible(true)


func _set_mobile_controls_position_wide() -> void:
	mobile_left_button.set_anchors_preset(Control.PRESET_TOP_LEFT)
	mobile_left_button.position = Vector2(700.0, 112.0)
	mobile_left_button.size = Vector2(320.0, 56.0)
	mobile_left_button.text = "◀  左移"
	mobile_left_button.add_theme_font_size_override("font_size", 18)
	mobile_right_button.set_anchors_preset(Control.PRESET_TOP_LEFT)
	mobile_right_button.position = Vector2(700.0, 178.0)
	mobile_right_button.size = Vector2(320.0, 56.0)
	mobile_right_button.text = "右移  ▶"
	mobile_right_button.add_theme_font_size_override("font_size", 18)
	_style_console_button(mobile_left_button)
	_style_console_button(mobile_right_button)


func _style_console_button(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("1d443e")
	normal.border_color = Color("4e8b79")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(8)
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("28594e")
	button.add_theme_stylebox_override("hover", hover)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("16332f")
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color("e4f0eb"))


func _build_wide_console(overlay: Control) -> void:
	sidebar = Control.new()
	sidebar.set_anchors_preset(Control.PRESET_TOP_LEFT)
	sidebar.position = Vector2(700.0, 112.0)
	sidebar.size = Vector2(320.0, 720.0)
	sidebar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(sidebar)
	var control_card := _make_card(sidebar, Vector2(0.0, 140.0), Vector2(320.0, 126.0), "角色控制", "左右移动选择职业门\n靠近门时自动结算部件")
	control_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var status_card := _make_card(sidebar, Vector2(0.0, 282.0), Vector2(320.0, 154.0), "战斗状态", "等待战斗数据")
	status_body = status_card.get_node("Body") as Label
	var feed_card := _make_card(sidebar, Vector2(0.0, 456.0), Vector2(320.0, 242.0), "前线电报", "暂无战报")
	feed_body = feed_card.get_node("Body") as Label


func _build_status_chips(overlay: Control) -> void:
	team_chip = _make_chip(overlay, Vector2(600.0, 16.0), Vector2(154.0, 40.0), "队伍已满 · 4 个角色")
	life_chip = _make_chip(overlay, Vector2(762.0, 16.0), Vector2(98.0, 40.0), "生命 100")
	kill_chip = _make_chip(overlay, Vector2(868.0, 16.0), Vector2(88.0, 40.0), "击杀 0")
	coin_chip = _make_chip(overlay, Vector2(964.0, 16.0), Vector2(78.0, 40.0), "金币 0")


func _make_chip(parent: Control, chip_position: Vector2, chip_size: Vector2, text: String) -> Label:
	var panel := Panel.new()
	panel.position = chip_position
	panel.size = chip_size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("18272a")
	style.border_color = Color("35534d")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	var label := _make_label(Vector2(8.0, 8.0), chip_size - Vector2(16.0, 16.0), 13, Color("d5e4de"))
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(label)
	return label


func _make_card(parent: Control, card_position: Vector2, card_size: Vector2, title: String, body: String) -> Panel:
	var panel := Panel.new()
	panel.position = card_position
	panel.size = card_size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("142226")
	style.border_color = Color("35534d")
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	var title_label_local := _make_label(Vector2(16.0, 12.0), Vector2(card_size.x - 32.0, 24.0), 16, Color("e5eee9"))
	title_label_local.text = title
	panel.add_child(title_label_local)
	var body_label := _make_label(Vector2(16.0, 43.0), Vector2(card_size.x - 32.0, card_size.y - 54.0), 13, Color("9bb5aa"))
	body_label.name = "Body"
	body_label.text = body
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(body_label)
	return panel


func _set_status_chips_visible(is_visible: bool) -> void:
	for chip in [team_chip, life_chip, kill_chip, coin_chip]:
		if chip != null and chip.get_parent() != null:
			chip.get_parent().visible = is_visible


func _build_mobile_controls(overlay: Control) -> void:
	mobile_left_button = _make_button(Vector2.ZERO, "←")
	mobile_left_button.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	mobile_left_button.offset_left = 24.0
	mobile_left_button.offset_top = -92.0
	mobile_left_button.offset_right = 140.0
	mobile_left_button.offset_bottom = -24.0
	mobile_left_button.add_theme_font_size_override("font_size", 30)
	mobile_left_button.button_down.connect(_on_mobile_button_down.bind("move_left"))
	mobile_left_button.button_up.connect(_on_mobile_button_up.bind("move_left"))
	overlay.add_child(mobile_left_button)
	mobile_right_button = _make_button(Vector2.ZERO, "→")
	mobile_right_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	mobile_right_button.offset_left = -140.0
	mobile_right_button.offset_top = -92.0
	mobile_right_button.offset_right = -24.0
	mobile_right_button.offset_bottom = -24.0
	mobile_right_button.add_theme_font_size_override("font_size", 30)
	mobile_right_button.button_down.connect(_on_mobile_button_down.bind("move_right"))
	mobile_right_button.button_up.connect(_on_mobile_button_up.bind("move_right"))
	overlay.add_child(mobile_right_button)


func _make_playfield_frame(overlay: Control) -> Panel:
	var frame := Panel.new()
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.offset_left = 16.0
	frame.offset_top = 194.0
	frame.offset_right = -16.0
	frame.offset_bottom = -112.0
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.04, 0.045, 0.18)
	style.border_color = Color("52736b")
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	frame.add_theme_stylebox_override("panel", style)
	overlay.add_child(frame)
	return frame


func _on_mobile_button_down(action_name: String) -> void:
	Input.action_press(action_name)


func _on_mobile_button_up(action_name: String) -> void:
	Input.action_release(action_name)


func _build_shop(overlay: Control) -> void:
	shop_panel = Control.new()
	shop_panel.set_anchors_preset(Control.PRESET_CENTER)
	shop_panel.offset_left = -260.0
	shop_panel.offset_top = -40.0
	shop_panel.offset_right = 260.0
	shop_panel.offset_bottom = 150.0
	shop_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(shop_panel)
	var backdrop := ColorRect.new()
	backdrop.position = Vector2(-14.0, -12.0)
	backdrop.size = Vector2(548.0, 214.0)
	backdrop.color = Color("202020", 0.97)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shop_panel.add_child(backdrop)
	var title := _make_label(Vector2.ZERO, Vector2(520.0, 30.0), 23, Color("f2f2f2"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = "节点商店"
	shop_panel.add_child(title)
	for index in RoleCatalogScript.ROLE_IDS.size():
		var role_id: String = RoleCatalogScript.ROLE_IDS[index]
		var button := _make_button(Vector2(18.0 + index * 168.0, 48.0), "招募倾向")
		button.size = Vector2(158.0, 48.0)
		button.visible = false
		button.pressed.connect(_on_shop_button_pressed.bind(role_id))
		shop_panel.add_child(button)
		shop_buttons[role_id] = button
	shop_refresh_button = _make_button(Vector2(148.0, 112.0), "刷新")
	shop_refresh_button.size = Vector2(224.0, 42.0)
	shop_refresh_button.pressed.connect(_on_shop_refresh_pressed)
	shop_panel.add_child(shop_refresh_button)
	shop_panel.visible = false


func _on_shop_button_pressed(role_id: String) -> void:
	shop_selected.emit(role_id)


func _on_shop_refresh_pressed() -> void:
	shop_refresh_requested.emit()


func _build_level_select(overlay: Control) -> void:
	level_panel = Control.new()
	level_panel.set_anchors_preset(Control.PRESET_CENTER)
	level_panel.offset_left = -240.0
	level_panel.offset_top = -90.0
	level_panel.offset_right = 240.0
	level_panel.offset_bottom = 130.0
	level_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(level_panel)
	var backdrop := ColorRect.new()
	backdrop.position = Vector2(-14.0, -14.0)
	backdrop.size = Vector2(508.0, 248.0)
	backdrop.color = Color("202020", 0.97)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_panel.add_child(backdrop)
	var title := _make_label(Vector2.ZERO, Vector2(480.0, 36.0), 27, Color("f2f2f2"))
	title.text = "选择节点"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_panel.add_child(title)


func show_level_select(unlocked_index: int, definitions: Array[Dictionary]) -> void:
	message_label.visible = false
	hint_label.visible = false
	shop_panel.visible = false
	level_panel.visible = true
	playfield_frame.visible = false
	if sidebar != null:
		sidebar.visible = false
	_set_status_chips_visible(false)
	_set_mobile_controls_visible(false)
	for child in level_panel.get_children():
		if child is Button:
			child.queue_free()
	for index in definitions.size():
		var button := _make_button(Vector2(30.0 + index * 150.0, 70.0), str(definitions[index].get("title", "节点")))
		button.size = Vector2(130.0, 52.0)
		button.disabled = index > unlocked_index
		button.pressed.connect(_on_level_button_pressed.bind(index))
		level_panel.add_child(button)


func _on_level_button_pressed(level_index: int) -> void:
	level_selected.emit(level_index)


func _make_label(label_position: Vector2, label_size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = label_position
	label.size = label_size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _make_button(button_position: Vector2, button_text: String) -> Button:
	var button := Button.new()
	button.position = button_position
	button.size = Vector2(210.0, 48.0)
	button.text = button_text
	button.add_theme_font_size_override("font_size", 18)
	return button


func update_run(level_number: int, level_count: int, title: String, run_progress: float, run_state: RunState) -> void:
	level_label.text = "地图 %d / %d　%s" % [level_number, level_count, title]
	progress_label.text = "前进：%d%%" % roundi(run_progress * 100.0)
	var progress_parts: Array[String] = []
	var stamp_parts: Array[String] = []
	var weight_parts: Array[String] = []
	for role_id in RoleCatalogScript.ROLE_IDS:
		progress_parts.append("%s %d/%d(%d)" % [RoleCatalogScript.display_name(role_id), run_state.part_count(role_id), run_state.required_parts, run_state.active_count(role_id)])
		stamp_parts.append("%s %d(L%d)" % [RoleCatalogScript.display_name(role_id), run_state.stamp_count(role_id), run_state.bond_level(role_id)])
		weight_parts.append("%s %d%%" % [RoleCatalogScript.display_name(role_id), run_state.weight_percent(role_id)])
	role_label.text = "　".join(progress_parts)
	stamp_label.text = "印记 " + " / ".join(stamp_parts)
	weight_label.text = "权重 " + " / ".join(weight_parts)
	if team_chip != null:
		var total_active := 0
		for role_id in RoleCatalogScript.ROLE_IDS:
			total_active += run_state.active_count(role_id)
		team_chip.text = "队伍已满 · %d 个角色" % total_active
	if life_chip != null:
		life_chip.text = "耐久 %d" % run_state.team_durability
	if coin_chip != null:
		coin_chip.text = "星币 %d" % run_state.currency
	if status_body != null:
		var total_stamps := 0
		var total_weight := 0
		for role_id in RoleCatalogScript.ROLE_IDS:
			total_stamps += run_state.stamp_count(role_id)
			total_weight += run_state.weight_for(role_id)
		status_body.text = "当前节点：%s\n前进：%d%%\n印记：%d　权重：%d" % [title, roundi(run_progress * 100.0), total_stamps, total_weight]
	if feed_body != null:
		feed_body.text = "14:00　第 %d 节点进入战斗\n14:00　核心单位已部署\n14:00　职业门等待接触\n14:00　远端敌群接近中" % level_number


func show_running() -> void:
	message_label.visible = false
	hint_label.visible = _is_compact_view()
	shop_panel.visible = false
	level_panel.visible = false
	playfield_frame.visible = true
	if sidebar != null:
		sidebar.visible = true
	_set_status_chips_visible(true)
	_set_mobile_controls_visible(true)


func show_shop(run_state: RunState, game_config: GameConfig, offers: Array[String], free_refreshes: int = 0) -> void:
	message_label.text = "波次完成 · 选择职业纹章"
	message_label.visible = true
	hint_label.visible = false
	for role_id in RoleCatalogScript.ROLE_IDS:
		var button: Button = shop_buttons[role_id]
		button.visible = offers.has(role_id)
		button.disabled = not offers.has(role_id)
		if offers.has(role_id):
			button.text = "%s  %d%% → %d%%" % [RoleCatalogScript.display_name(role_id), run_state.weight_percent(role_id), _preview_weight_percent(run_state, role_id, game_config)]
	if shop_refresh_button != null:
		shop_refresh_button.text = "免费刷新（剩余 %d）" % free_refreshes if free_refreshes > 0 else "刷新（-%d 星币）" % game_config.shop_refresh_cost
		shop_refresh_button.disabled = free_refreshes <= 0 and run_state.currency < game_config.shop_refresh_cost
	shop_panel.visible = true
	level_panel.visible = false
	playfield_frame.visible = true
	if sidebar != null:
		sidebar.visible = true
	_set_status_chips_visible(true)
	_set_mobile_controls_visible(false)


func _preview_weight_percent(run_state: RunState, role_id: String, game_config: GameConfig) -> int:
	var total := 0
	for candidate in RoleCatalogScript.ROLE_IDS:
		total += run_state.weight_for(candidate)
	total += mini(game_config.shop_weight_step, game_config.shop_weight_cap - run_state.weight_for(role_id))
	if total <= 0:
		return 0
	return roundi(float(run_state.weight_for(role_id) + mini(game_config.shop_weight_step, game_config.shop_weight_cap - run_state.weight_for(role_id))) / float(total) * 100.0)


func show_game_complete() -> void:
	message_label.text = "整局完成\n按 R 或 Enter 重新开始"
	message_label.visible = true
	hint_label.visible = false
	shop_panel.visible = false
	level_panel.visible = false
	playfield_frame.visible = false
	if sidebar != null:
		sidebar.visible = false
	_set_status_chips_visible(false)
	_set_mobile_controls_visible(false)


func show_run_failed() -> void:
	message_label.text = "队伍溃败\n按 R 或 Enter 重新开始"
	message_label.visible = true
	hint_label.visible = false
	shop_panel.visible = false
	level_panel.visible = false
	playfield_frame.visible = false
	if sidebar != null:
		sidebar.visible = false
	_set_status_chips_visible(false)
	_set_mobile_controls_visible(false)


func _set_mobile_controls_visible(is_visible: bool) -> void:
	if mobile_left_button != null:
		mobile_left_button.visible = is_visible
	if mobile_right_button != null:
		mobile_right_button.visible = is_visible
