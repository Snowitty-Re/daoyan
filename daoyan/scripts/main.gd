extends Control

const ELEMENTS: Array[String] = ["金", "木", "水", "火", "土"]
const ELEMENT_TRAITS := {
	"金": "锐化 / 高频 / 秩序",
	"木": "生长 / 修复 / 共鸣",
	"水": "循环 / 变化 / 感知",
	"火": "转化 / 爆发 / 激化",
	"土": "承载 / 镇压 / 积累",
}
const REALMS: Array[String] = ["炼气", "筑基", "金丹", "元婴", "化神", "洞虚", "渡劫"]
const MAX_LOG_LINES := 10

const ROOT_PRESETS := [
	{
		"name": "纯金灵根",
		"type": "纯灵根",
		"elements": {"金": 88, "木": 4, "水": 3, "火": 3, "土": 2},
		"stability": 86,
		"potential": 42,
		"risk": 12,
		"build": "飞剑连锁流",
		"text": "成型快、运转稳定，后期变化有限。"
	},
	{
		"name": "火主木辅灵根",
		"type": "偏灵根",
		"elements": {"金": 4, "木": 28, "水": 5, "火": 58, "土": 5},
		"stability": 68,
		"potential": 64,
		"risk": 24,
		"build": "灵植献祭流",
		"text": "爆发与增殖兼具，容易把心魔一并点燃。"
	},
	{
		"name": "水土偏灵根",
		"type": "偏灵根",
		"elements": {"金": 5, "木": 7, "水": 48, "火": 2, "土": 38},
		"stability": 74,
		"potential": 58,
		"risk": 18,
		"build": "泥沼领域流",
		"text": "擅长循环与镇压，启动慢但抗风险能力较强。"
	},
	{
		"name": "五行杂灵根",
		"type": "杂灵根",
		"elements": {"金": 21, "木": 18, "水": 23, "火": 17, "土": 21},
		"stability": 34,
		"potential": 92,
		"risk": 58,
		"build": "五行循环流",
		"text": "前期冲突严重，若闭环成立，后期潜力极高。"
	},
	{
		"name": "残缺死水灵根",
		"type": "残缺灵根",
		"elements": {"金": 3, "木": 4, "水": 51, "火": 2, "土": 9},
		"stability": 22,
		"potential": 78,
		"risk": 72,
		"build": "因果反噬流",
		"text": "修炼极慢，但能把伤痕、诅咒与残响转成力量。"
	}
]

const ACTIONS := {
	"cultivate": {
		"title": "闭关调息",
		"desc": "稳定增长修为。灵根越稳定，收益越高；高风险灵根更容易出现冲突。",
		"button": "闭关"
	},
	"sect": {
		"title": "处理宗门因果",
		"desc": "参与派系与传承事件，降低孤立风险，也可能背上新的宗门债。",
		"button": "宗门"
	},
	"ruin": {
		"title": "探索灵墟",
		"desc": "获得遗物、残篇或古代真相，同时承受污染、时间残响与因果重复。",
		"button": "灵墟"
	},
	"demon": {
		"title": "观照心魔",
		"desc": "压制或利用心魔。短期可能获益，长期会改变修道者的自我边界。",
		"button": "心魔"
	}
}

var rng := RandomNumberGenerator.new()
var game_started := false
var selected_root_index := 0
var turn := 1
var realm_index := 0
var cultivation := 0
var insight := 0
var stability := 0
var potential := 0
var risk := 0
var pollution := 0
var karma := 0
var heart_demon := 0
var heaven_correction := 0
var sect_trust := 30
var life_resonance := 0
var relics: Array[String] = []
var states: Array[String] = []
var logs: Array[String] = []
var npc_states := {}

var root_data := {}

var root_select: OptionButton
var start_button: Button
var title_label: Label
var subtitle_label: Label
var realm_label: Label
var turn_label: Label
var root_label: Label
var build_label: Label
var doctrine_label: Label
var stats_grid: GridContainer
var meter_labels := {}
var event_title: Label
var event_body: RichTextLabel
var log_box: RichTextLabel
var npc_box: RichTextLabel
var state_box: RichTextLabel
var action_buttons := {}
var breakthrough_button: Button
var restart_button: Button


func _ready() -> void:
	rng.randomize()
	_build_ui()
	_show_intro()


func _build_ui() -> void:
	var style_bg := StyleBoxFlat.new()
	style_bg.bg_color = Color(0.08, 0.085, 0.09)

	var root_panel := PanelContainer.new()
	root_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_panel.add_theme_stylebox_override("panel", style_bg)
	add_child(root_panel)

	var outer := MarginContainer.new()
	outer.add_theme_constant_override("margin_left", 18)
	outer.add_theme_constant_override("margin_right", 18)
	outer.add_theme_constant_override("margin_top", 16)
	outer.add_theme_constant_override("margin_bottom", 16)
	root_panel.add_child(outer)

	var main := VBoxContainer.new()
	main.add_theme_constant_override("separation", 12)
	outer.add_child(main)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	main.add_child(header)

	var title_group := VBoxContainer.new()
	title_group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_group)

	title_label = Label.new()
	title_label.text = "道湮"
	title_label.add_theme_font_size_override("font_size", 34)
	title_group.add_child(title_label)

	subtitle_label = Label.new()
	subtitle_label.text = "残道时代修道原型"
	subtitle_label.add_theme_color_override("font_color", Color(0.72, 0.75, 0.76))
	title_group.add_child(subtitle_label)

	var setup_box := VBoxContainer.new()
	setup_box.custom_minimum_size = Vector2(260, 0)
	header.add_child(setup_box)

	root_select = OptionButton.new()
	for preset in ROOT_PRESETS:
		root_select.add_item("%s · %s" % [preset.name, preset.type])
	root_select.item_selected.connect(func(_index: int) -> void: _update_identity_preview())
	setup_box.add_child(root_select)

	start_button = Button.new()
	start_button.text = "入道"
	start_button.pressed.connect(_start_game)
	setup_box.add_child(start_button)

	var content := HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	main.add_child(content)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(300, 0)
	left.add_theme_constant_override("separation", 10)
	content.add_child(left)

	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.add_theme_constant_override("separation", 10)
	content.add_child(center)

	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(320, 0)
	right.add_theme_constant_override("separation", 10)
	content.add_child(right)

	var identity_panel := _make_panel("修士")
	left.add_child(identity_panel)
	var identity_body := _panel_body(identity_panel)
	var identity := VBoxContainer.new()
	identity.add_theme_constant_override("separation", 5)
	identity_body.add_child(identity)

	turn_label = Label.new()
	realm_label = Label.new()
	root_label = Label.new()
	build_label = Label.new()
	doctrine_label = Label.new()
	doctrine_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for label in [turn_label, realm_label, root_label, build_label, doctrine_label]:
		identity.add_child(label)

	var stats_panel := _make_panel("状态")
	left.add_child(stats_panel)
	var stats_body := _panel_body(stats_panel)
	stats_grid = GridContainer.new()
	stats_grid.columns = 2
	stats_grid.add_theme_constant_override("h_separation", 8)
	stats_grid.add_theme_constant_override("v_separation", 7)
	stats_body.add_child(stats_grid)

	for key in ["修为", "悟性", "稳定", "潜力", "风险", "污染", "因果", "心魔", "天道修正", "宗门信任"]:
		var name_label := Label.new()
		name_label.text = key
		name_label.add_theme_color_override("font_color", Color(0.7, 0.74, 0.75))
		stats_grid.add_child(name_label)
		var value_label := Label.new()
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		stats_grid.add_child(value_label)
		meter_labels[key] = value_label

	var states_panel := _make_panel("因果状态")
	left.add_child(states_panel)
	var states_body := _panel_body(states_panel)
	state_box = RichTextLabel.new()
	state_box.custom_minimum_size = Vector2(0, 120)
	state_box.fit_content = true
	state_box.scroll_active = false
	states_body.add_child(state_box)

	var event_panel := _make_panel("当前抉择")
	event_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.add_child(event_panel)
	var event_body_container := _panel_body(event_panel)
	var event_content := VBoxContainer.new()
	event_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	event_content.add_theme_constant_override("separation", 10)
	event_body_container.add_child(event_content)

	event_title = Label.new()
	event_title.add_theme_font_size_override("font_size", 22)
	event_content.add_child(event_title)

	event_body = RichTextLabel.new()
	event_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	event_body.bbcode_enabled = true
	event_body.fit_content = false
	event_body.scroll_active = true
	event_content.add_child(event_body)

	var action_grid := GridContainer.new()
	action_grid.columns = 2
	action_grid.add_theme_constant_override("h_separation", 8)
	action_grid.add_theme_constant_override("v_separation", 8)
	event_content.add_child(action_grid)

	for action_id in ["cultivate", "sect", "ruin", "demon"]:
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 44)
		button.text = ACTIONS[action_id].button
		button.pressed.connect(func() -> void: _take_action(action_id))
		action_grid.add_child(button)
		action_buttons[action_id] = button

	breakthrough_button = Button.new()
	breakthrough_button.text = "尝试突破"
	breakthrough_button.custom_minimum_size = Vector2(0, 46)
	breakthrough_button.pressed.connect(_attempt_breakthrough)
	event_content.add_child(breakthrough_button)

	restart_button = Button.new()
	restart_button.text = "因果重开"
	restart_button.pressed.connect(_reset_to_intro)
	restart_button.visible = false
	event_content.add_child(restart_button)

	var npc_panel := _make_panel("NPC自行演化")
	right.add_child(npc_panel)
	var npc_body := _panel_body(npc_panel)
	npc_box = RichTextLabel.new()
	npc_box.custom_minimum_size = Vector2(0, 210)
	npc_box.bbcode_enabled = true
	npc_box.fit_content = true
	npc_box.scroll_active = false
	npc_body.add_child(npc_box)

	var log_panel := _make_panel("残响日志")
	log_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(log_panel)
	var log_body := _panel_body(log_panel)
	log_box = RichTextLabel.new()
	log_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_box.bbcode_enabled = true
	log_box.scroll_active = true
	log_body.add_child(log_box)


func _make_panel(title: String) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.125, 0.13, 0.135)
	style.border_color = Color(0.28, 0.3, 0.31)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	panel.add_child(box)

	var label := Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.9, 0.88, 0.8))
	box.add_child(label)
	return panel


func _panel_body(panel: PanelContainer) -> VBoxContainer:
	return panel.get_child(0) as VBoxContainer


func _show_intro() -> void:
	event_title.text = "选择灵根，进入残道时代"
	event_body.text = "当前原型不包含战斗。你将通过回合抉择验证《道湮》的基础闭环：修炼会增长力量，也会留下污染、心魔与因果。\n\n每个重要行动都会推动NPC自行演化。NPC可能突破、结仇、堕化或死亡。你的目标不是刷满数值，而是在突破之前让自己的修炼体系仍然成立。"
	for button in action_buttons.values():
		button.disabled = true
	breakthrough_button.disabled = true
	restart_button.visible = false
	_update_identity_preview()
	_update_labels()


func _start_game() -> void:
	selected_root_index = root_select.selected
	root_data = ROOT_PRESETS[selected_root_index].duplicate(true)
	game_started = true
	turn = 1
	realm_index = 0
	cultivation = 10
	insight = 5
	stability = root_data.stability
	potential = root_data.potential
	risk = root_data.risk
	pollution = 0
	karma = 0
	heart_demon = 0
	heaven_correction = 0
	sect_trust = 30
	life_resonance = 0
	relics.clear()
	states.clear()
	logs.clear()
	npc_states = {
		"沈砚秋": {"realm": "筑基", "path": "剑道", "state": "闭关", "demon": 18, "alive": true},
		"陆青梧": {"realm": "炼气", "path": "丹道", "state": "采药", "demon": 8, "alive": true},
		"韩照夜": {"realm": "金丹", "path": "因果", "state": "追查灵墟", "demon": 26, "alive": true},
	}
	_add_log("你以%s入道，初定%s。" % [root_data.name, root_data.build])
	_add_state("初入残道")
	for button in action_buttons.values():
		button.disabled = false
	breakthrough_button.disabled = false
	restart_button.visible = false
	_present_turn()


func _reset_to_intro() -> void:
	game_started = false
	root_data.clear()
	_show_intro()


func _update_identity_preview() -> void:
	var preset = ROOT_PRESETS[root_select.selected]
	turn_label.text = "回合：未入道"
	realm_label.text = "境界：炼气"
	root_label.text = "灵根：%s" % preset.name
	build_label.text = "构筑倾向：%s" % preset.build
	doctrine_label.text = "灵根评估：%s" % preset.text


func _present_turn() -> void:
	if _check_game_over():
		return
	event_title.text = "第%d回合：%s境" % [turn, REALMS[realm_index]]
	event_body.text = _compose_turn_text()
	_update_labels()


func _compose_turn_text() -> String:
	var text := ""
	text += "[b]天道残响[/b]\n"
	text += "灵气仍可运转，但每一次借用都会改变你与世界的关系。\n\n"
	text += "[b]当前判断[/b]\n"
	text += "- 修为达到100可尝试突破。\n"
	text += "- 污染、因果、心魔与天道修正越高，突破越危险。\n"
	text += "- 稳定降低到0，修炼体系会崩坏。\n\n"
	text += "[b]可选行动[/b]\n"
	for action_id in ["cultivate", "sect", "ruin", "demon"]:
		text += "- %s：%s\n" % [ACTIONS[action_id].title, ACTIONS[action_id].desc]
	return text


func _take_action(action_id: String) -> void:
	if not game_started:
		return
	match action_id:
		"cultivate":
			_action_cultivate()
		"sect":
			_action_sect()
		"ruin":
			_action_ruin()
		"demon":
			_action_demon()
	_advance_world()
	turn += 1
	_present_turn()


func _action_cultivate() -> void:
	var gain: int = 14 + int(stability * 0.11) + int(potential * 0.06) + rng.randi_range(-3, 5)
	var conflict: int = max(0, risk + pollution - stability)
	cultivation += gain
	insight += rng.randi_range(1, 4)
	heaven_correction += 2 + int(cultivation / 60)
	if conflict > 35 or rng.randi_range(1, 100) < risk:
		stability -= rng.randi_range(4, 10)
		heart_demon += rng.randi_range(3, 8)
		_add_log("闭关时五行相冲，经脉出现逆流。")
	else:
		stability += rng.randi_range(1, 4)
		_add_log("你完成一次周天运转，修为增长%d。" % gain)
	_clamp_core()


func _action_sect() -> void:
	var roll := rng.randi_range(1, 100)
	sect_trust += rng.randi_range(6, 13)
	karma += rng.randi_range(3, 9)
	insight += rng.randi_range(2, 5)
	if roll < 35:
		_add_state("宗门债")
		_add_log("你替宗门接下一桩旧债，因果缠身。")
	elif roll < 70:
		stability += rng.randi_range(3, 8)
		_add_log("长老指点功法冲突，体系稍稳。")
	else:
		sect_trust -= rng.randi_range(8, 15)
		karma += rng.randi_range(8, 14)
		_add_state("派系疑云")
		_add_log("你卷入长老派系争执，宗门信任开始摇晃。")
	_clamp_core()


func _action_ruin() -> void:
	var gain := rng.randi_range(8, 18)
	cultivation += gain
	insight += rng.randi_range(4, 10)
	pollution += rng.randi_range(8, 16)
	karma += rng.randi_range(4, 12)
	heaven_correction += rng.randi_range(4, 9)
	var roll := rng.randi_range(1, 100)
	if roll < 35:
		var relic := _random_relic()
		if not relics.has(relic):
			relics.append(relic)
		potential += rng.randi_range(3, 8)
		_add_log("灵墟时间残响中，你取得遗物：%s。" % relic)
	elif roll < 65:
		_add_state("灵墟污染")
		stability -= rng.randi_range(5, 13)
		_add_log("灵墟内五行逆转，你的灵根被污染。")
	else:
		life_resonance += 1
		_add_state("古代真相碎片")
		_add_log("你看见湮灭时代的残缺记忆，但无法确认其真伪。")
	_clamp_core()


func _action_demon() -> void:
	var roll := rng.randi_range(1, 100)
	if roll + insight > 82:
		heart_demon = max(0, heart_demon - rng.randi_range(8, 16))
		insight += rng.randi_range(3, 7)
		_add_log("你观照执念，暂时压下心魔。")
	elif roll > 45:
		heart_demon += rng.randi_range(5, 12)
		cultivation += rng.randi_range(8, 15)
		potential += rng.randi_range(2, 6)
		_add_state("心魔借力")
		_add_log("你借用心魔之力，修为暴涨，但自我边界变得模糊。")
	else:
		heart_demon += rng.randi_range(10, 20)
		stability -= rng.randi_range(6, 14)
		_add_state("心魔低语")
		_add_log("心魔模拟故人记忆，你的道心出现裂纹。")
	heaven_correction += rng.randi_range(2, 6)
	_clamp_core()


func _attempt_breakthrough() -> void:
	if not game_started:
		return
	if cultivation < 100:
		_add_log("修为未满，强行突破只会损伤道基。")
		stability -= 6
		heart_demon += 5
		_update_labels()
		if not _check_game_over():
			event_title.text = "突破失败"
			event_body.text = "你的周天尚未圆满。残缺天道没有回应，只有经脉中的滞涩感逐渐扩大。"
		return

	var pressure: int = pollution + karma + heart_demon + heaven_correction + risk - stability - int(insight * 0.45)
	var chance: int = clamp(74 - pressure, 12, 88)
	var roll: int = rng.randi_range(1, 100)
	heaven_correction += 10
	if roll <= chance:
		var old_realm := REALMS[realm_index]
		realm_index = min(realm_index + 1, REALMS.size() - 1)
		cultivation = 12 + int(potential * 0.12)
		stability = max(18, stability - rng.randi_range(5, 12))
		karma += rng.randi_range(5, 12)
		heart_demon += rng.randi_range(2, 8)
		_add_state("%s破境" % old_realm)
		_add_log("你突破至%s，生命形态开始偏离凡俗。" % REALMS[realm_index])
		event_title.text = "破境成功"
		event_body.text = "天道修正没有放过你。突破带来新的上限，也让你的因果重量明显增加。"
	else:
		var damage := rng.randi_range(16, 30)
		stability -= damage
		heart_demon += rng.randi_range(10, 22)
		pollution += rng.randi_range(6, 14)
		_add_state("道基受损")
		_add_log("突破失败，道基受损%d，心魔趁隙而入。" % damage)
		event_title.text = "突破失败"
		event_body.text = "这不是数值不足的失败，而是你的修炼体系无法承受自身因果。"
	_clamp_core()
	_update_labels()
	_check_game_over()


func _advance_world() -> void:
	for npc_name in npc_states.keys():
		var npc = npc_states[npc_name]
		if not npc.alive:
			continue
		var roll := rng.randi_range(1, 100)
		npc.demon += rng.randi_range(0, 4)
		if roll < 9 and npc.demon > 30:
			npc.state = "心魔侵蚀"
			_add_log("%s的%s道途出现裂痕。" % [npc_name, npc.path])
		elif roll < 15 and npc.demon > 44:
			npc.alive = false
			npc.state = "陨落"
			karma += 8
			_add_state("%s残响" % npc_name)
			_add_log("%s在无人见证处陨落，只余因果残响。" % npc_name)
		elif roll > 88:
			npc.state = "破境边缘"
			npc.demon += 5
			_add_log("%s接近突破，天道修正也随之逼近。" % npc_name)
		elif roll > 74:
			npc.state = "卷入宗门争道"
		npc_states[npc_name] = npc

	if pollution > 45 and not states.has("浊灵入脉"):
		_add_state("浊灵入脉")
		_add_log("浊灵气开始影响你的经脉。")
	if karma > 50 and not states.has("因果缠身"):
		_add_state("因果缠身")
		_add_log("旧因未结，新果已生。")
	if heart_demon > 50 and not states.has("心魔共生征兆"):
		_add_state("心魔共生征兆")
		_add_log("心魔不再只是低语，它开始回应你的念头。")


func _check_game_over() -> bool:
	if not game_started:
		return false
	var ended := false
	var ending := ""
	if stability <= 0:
		ended = true
		ending = "你的五行循环彻底崩坏，道基化为残响。"
	elif heart_demon >= 100:
		ended = true
		ending = "心魔吞没自我。你仍在行走，但已经不再完全是你。"
	elif pollution >= 100:
		ended = true
		ending = "灵根被浊灵重塑，你成为一处移动的灵墟裂隙。"
	elif realm_index >= REALMS.size() - 1 and cultivation >= 100:
		ended = true
		ending = "你抵达渡劫尽头，却只看见飞升后的未知空白。"

	if ended:
		for button in action_buttons.values():
			button.disabled = true
		breakthrough_button.disabled = true
		restart_button.visible = true
		event_title.text = "本轮因果结算"
		event_body.text = "%s\n\n死亡不是结束。若继续原型，下一轮可把这些状态作为残响继承：%s" % [ending, _format_state_inline()]
		_add_log("本轮结束：%s" % ending)
		_update_labels()
	return ended


func _random_relic() -> String:
	var options := ["裂丹残片", "逆金剑丸", "死水玉简", "堕仙骨符", "五行残环", "无名道种"]
	return options[rng.randi_range(0, options.size() - 1)]


func _add_state(state_name: String) -> void:
	if not states.has(state_name):
		states.append(state_name)


func _add_log(line: String) -> void:
	logs.push_front("第%d回合：%s" % [turn, line])
	if logs.size() > MAX_LOG_LINES:
		logs.resize(MAX_LOG_LINES)


func _clamp_core() -> void:
	cultivation = clamp(cultivation, 0, 140)
	insight = clamp(insight, 0, 100)
	stability = clamp(stability, -10, 100)
	potential = clamp(potential, 0, 100)
	risk = clamp(risk, 0, 100)
	pollution = clamp(pollution, 0, 120)
	karma = clamp(karma, 0, 120)
	heart_demon = clamp(heart_demon, 0, 120)
	heaven_correction = clamp(heaven_correction, 0, 140)
	sect_trust = clamp(sect_trust, -50, 100)


func _update_labels() -> void:
	if not game_started:
		meter_labels["修为"].text = "0 / 100"
		meter_labels["悟性"].text = "0"
		meter_labels["稳定"].text = str(ROOT_PRESETS[root_select.selected].stability)
		meter_labels["潜力"].text = str(ROOT_PRESETS[root_select.selected].potential)
		meter_labels["风险"].text = str(ROOT_PRESETS[root_select.selected].risk)
		for key in ["污染", "因果", "心魔", "天道修正"]:
			meter_labels[key].text = "0"
		meter_labels["宗门信任"].text = "未入宗"
		state_box.text = "尚无因果。"
		npc_box.text = "入道后，重要NPC会自行推进。"
		log_box.text = "等待入道。"
		return

	turn_label.text = "回合：%d" % turn
	realm_label.text = "境界：%s" % REALMS[realm_index]
	root_label.text = "灵根：%s · %s" % [root_data.name, root_data.type]
	build_label.text = "构筑倾向：%s" % root_data.build
	doctrine_label.text = "五行：%s\n%s" % [_format_elements(), root_data.text]

	meter_labels["修为"].text = "%d / 100" % cultivation
	meter_labels["悟性"].text = str(insight)
	meter_labels["稳定"].text = str(stability)
	meter_labels["潜力"].text = str(potential)
	meter_labels["风险"].text = str(risk)
	meter_labels["污染"].text = str(pollution)
	meter_labels["因果"].text = str(karma)
	meter_labels["心魔"].text = str(heart_demon)
	meter_labels["天道修正"].text = str(heaven_correction)
	meter_labels["宗门信任"].text = str(sect_trust)

	state_box.text = _format_states()
	npc_box.text = _format_npcs()
	log_box.text = _format_logs()


func _format_elements() -> String:
	var parts: Array[String] = []
	for element in ELEMENTS:
		var value: int = root_data.elements.get(element, 0)
		if value > 0:
			parts.append("%s%d" % [element, value])
	return " / ".join(parts)


func _format_states() -> String:
	if states.is_empty():
		return "尚无明确因果。"
	var lines: Array[String] = []
	for state in states:
		lines.append("- %s" % state)
	if not relics.is_empty():
		lines.append("\n遗物：%s" % "、".join(relics))
	return "\n".join(lines)


func _format_state_inline() -> String:
	if states.is_empty():
		return "无"
	return "、".join(states)


func _format_npcs() -> String:
	var lines: Array[String] = []
	for npc_name in npc_states.keys():
		var npc = npc_states[npc_name]
		var alive_text := "存活" if npc.alive else "陨落"
		lines.append("[b]%s[/b] · %s · %s\n%s / 心魔%d / %s" % [
			npc_name,
			npc.realm,
			npc.path,
			npc.state,
			npc.demon,
			alive_text
		])
	return "\n\n".join(lines)


func _format_logs() -> String:
	if logs.is_empty():
		return "暂无残响。"
	return "\n".join(logs)
