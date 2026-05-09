extends Control

enum ScreenState { CREATE, PROFILE, GAME, BATTLE }

const BG_TEX: Texture2D = preload("res://assets/art/dao_background.svg")
const CULTIVATOR_TEX: Texture2D = preload("res://assets/art/cultivator_silhouette.svg")
const LINGXU_TEX: Texture2D = preload("res://assets/art/lingxu_panel.svg")
const ELEMENT_TEX: Texture2D = preload("res://assets/ui/five_elements.svg")
const BATTLE_TEX: Texture2D = preload("res://assets/art/battle_wound.svg")
const ENEMY_TEX: Texture2D = preload("res://assets/art/enemy_shadow.svg")
const BATTLE_ARENA_SCRIPT: Script = preload("res://scripts/battle_arena.gd")

const ELEMENTS: Array[String] = ["金", "木", "水", "火", "土"]
const REALMS: Array[String] = ["炼气", "筑基", "金丹", "元婴", "化神", "洞虚", "渡劫"]
const MAX_LOG_LINES := 12

const ROOT_PRESETS := [
	{
		"name": "纯金灵根",
		"type": "纯灵根",
		"elements": {"金": 88, "木": 4, "水": 3, "火": 3, "土": 2},
		"stability": 86,
		"potential": 42,
		"risk": 12,
		"build": "飞剑连锁流",
		"text": "成型快、运转稳定，后期变化有限。",
		"state": "金气入骨"
	},
	{
		"name": "火主木辅灵根",
		"type": "偏灵根",
		"elements": {"金": 4, "木": 28, "水": 5, "火": 58, "土": 5},
		"stability": 68,
		"potential": 64,
		"risk": 24,
		"build": "灵植献祭流",
		"text": "爆发与增殖兼具，容易把心魔一并点燃。",
		"state": "木火相燃"
	},
	{
		"name": "水土偏灵根",
		"type": "偏灵根",
		"elements": {"金": 5, "木": 7, "水": 48, "火": 2, "土": 38},
		"stability": 74,
		"potential": 58,
		"risk": 18,
		"build": "泥沼领域流",
		"text": "擅长循环与镇压，启动慢但抗风险能力较强。",
		"state": "水土成域"
	},
	{
		"name": "五行杂灵根",
		"type": "杂灵根",
		"elements": {"金": 21, "木": 18, "水": 23, "火": 17, "土": 21},
		"stability": 34,
		"potential": 92,
		"risk": 58,
		"build": "五行循环流",
		"text": "前期冲突严重，若闭环成立，后期潜力极高。",
		"state": "五行未定"
	},
	{
		"name": "残缺死水灵根",
		"type": "残缺灵根",
		"elements": {"金": 3, "木": 4, "水": 51, "火": 2, "土": 9},
		"stability": 22,
		"potential": 78,
		"risk": 72,
		"build": "因果反噬流",
		"text": "修炼极慢，但能把伤痕、诅咒与残响转成力量。",
		"state": "死水残根"
	}
]

const ORIGIN_PRESETS := [
	{
		"name": "寒门遗孤",
		"sect_name": "玄微宗外门",
		"stability": 0,
		"potential": 5,
		"risk": 6,
		"insight": 4,
		"karma": 14,
		"sect_trust": 18,
		"state": "血亲残债",
		"text": "出身破败凡族，早年亲族卷入修士争斗。你入宗不是被眷顾，而是旧债尚未结清。"
	},
	{
		"name": "宗门弃徒",
		"sect_name": "玄微宗戒律院",
		"stability": -4,
		"potential": 8,
		"risk": 10,
		"insight": 7,
		"karma": 18,
		"sect_trust": -8,
		"state": "戒律旧案",
		"text": "你曾被宗门逐出旁支，又因灵根异动被重新召回。信任很低，但你知道更多内情。"
	},
	{
		"name": "灵墟幸存者",
		"sect_name": "清河散修盟",
		"stability": -8,
		"potential": 12,
		"risk": 14,
		"insight": 8,
		"karma": 10,
		"sect_trust": 6,
		"pollution": 12,
		"state": "灵墟残响",
		"text": "你从一处时间错乱的灵墟中活着出来，记忆缺失，却带回了不属于炼气修士的感知。"
	},
	{
		"name": "丹房杂役",
		"sect_name": "玄微宗丹房",
		"stability": 8,
		"potential": 0,
		"risk": -4,
		"insight": 3,
		"karma": 6,
		"sect_trust": 34,
		"state": "丹火余温",
		"text": "你长期在丹房观火辨气，修为不显，但比同境弟子更懂灵气稳定的价值。"
	}
]

const PATH_PRESETS := [
	{"name": "剑道", "build": "飞剑连锁流", "insight": 2, "risk": 3, "state": "剑心未成", "text": "以锐化、秩序与一念贯通为道。"},
	{"name": "丹道", "build": "灵气调和流", "insight": 4, "risk": -2, "state": "丹理初窥", "text": "以转化、平衡与代价交换为道。"},
	{"name": "因果", "build": "因果反噬流", "insight": 5, "risk": 6, "state": "因果窥痕", "text": "以旧因新果、债与偿为道。"},
	{"name": "长生", "build": "五行循环流", "insight": 1, "risk": 2, "state": "长生执念", "text": "以循环、续命与维持自我为道。"},
	{"name": "无情", "build": "神识断执流", "insight": 6, "risk": 7, "state": "情缘将断", "text": "以斩断牵连、压制心魔为道。"}
]

const OBSESSION_PRESETS := [
	{"name": "复仇", "karma": 12, "heart": 8, "state": "复仇执念", "text": "某个名字仍压在你的神识深处。"},
	{"name": "飞升", "karma": 6, "heart": 5, "state": "飞升妄念", "text": "你不相信数百年无人飞升只是巧合。"},
	{"name": "救人", "karma": 8, "heart": 3, "state": "救命之债", "text": "你欠一条命，也可能被另一条命拖入深渊。"},
	{"name": "自证大道", "karma": 4, "heart": 7, "state": "自证执念", "text": "你不愿成为宗门谱系里可替换的一笔。"},
	{"name": "斩断因果", "karma": 10, "heart": 6, "state": "断因之愿", "text": "你想脱离一切关系，但关系不会因此消失。"}
]

const FATE_BY_ROOT := {
	"纯灵根": ["天眷", "道劫"],
	"偏灵根": ["孤命", "天眷"],
	"杂灵根": ["道劫", "残命"],
	"残缺灵根": ["残命", "孤命"],
	"异灵根": ["天煞", "道劫"]
}

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
	},
	"battle": {
		"title": "灵压遭遇",
		"desc": "进入构筑战斗。以五行联动和代价管理破开敌人的灵气结构。",
		"button": "遭遇"
	}
}

const ENCOUNTERS := [
	{
		"name": "浊灵残影",
		"realm": "炼气后期",
		"hp": 88,
		"pressure": 18,
		"element": "水",
		"weak": "土",
		"resist": "火",
		"reward": "浊灵残气",
		"text": "灵墟边缘的死亡残响，仍按旧日周天巡行。"
	},
	{
		"name": "失控剑傀",
		"realm": "筑基残壳",
		"hp": 110,
		"pressure": 24,
		"element": "金",
		"weak": "火",
		"resist": "木",
		"reward": "断剑灵纹",
		"text": "古宗剑阵留下的法宝残肢，只记得切割与秩序。"
	},
	{
		"name": "心魔镜身",
		"realm": "因果异象",
		"hp": 96,
		"pressure": 28,
		"element": "心魔",
		"weak": "水",
		"resist": "金",
		"reward": "镜心裂痕",
		"text": "它借你的记忆成形，招式越像你，越难斩净。"
	}
]

var rng := RandomNumberGenerator.new()
var current_screen: ScreenState = ScreenState.CREATE
var game_started := false
var selected_root_index := 0
var selected_origin_index := 0
var selected_path_index := 0
var selected_obsession_index := 0
var character_name := ""
var character_gender := "未定"
var character_origin := {}
var character_path := {}
var character_obsession := {}
var character_fate := ""
var character_sect := ""
var character_epitaph := ""
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
var battle_logs: Array[String] = []
var npc_states := {}
var root_data := {}
var battle_active := false
var battle_enemy := {}
var battle_result_pending := false

var create_screen: Control
var profile_screen: Control
var game_screen: Control
var battle_screen: Control
var name_edit: LineEdit
var gender_select: OptionButton
var origin_select: OptionButton
var path_select: OptionButton
var obsession_select: OptionButton
var root_select: OptionButton
var preview_title: Label
var preview_body: RichTextLabel
var profile_title: Label
var profile_body: RichTextLabel
var profile_stats: RichTextLabel
var title_label: Label
var subtitle_label: Label
var character_label: Label
var realm_label: Label
var turn_label: Label
var root_label: Label
var build_label: Label
var doctrine_label: Label
var portrait_texture: TextureRect
var meter_labels := {}
var progress_bars := {}
var event_title: Label
var event_body: RichTextLabel
var event_art: TextureRect
var log_box: RichTextLabel
var npc_box: RichTextLabel
var state_box: RichTextLabel
var action_buttons := {}
var breakthrough_button: Button
var restart_button: Button
var change_character_button: Button
var battle_log_box: RichTextLabel
var battle_arena: Control
var battle_status_label: RichTextLabel
var battle_exit_button: Button


func _ready() -> void:
	rng.randomize()
	_build_ui()
	_show_create()


func _process(delta: float) -> void:
	pass


func _build_ui() -> void:
	var background := TextureRect.new()
	background.texture = BG_TEX
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var veil := ColorRect.new()
	veil.color = Color(0.02, 0.025, 0.027, 0.48)
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(veil)

	var outer := MarginContainer.new()
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 22)
	outer.add_theme_constant_override("margin_right", 22)
	outer.add_theme_constant_override("margin_top", 18)
	outer.add_theme_constant_override("margin_bottom", 18)
	add_child(outer)

	var main := VBoxContainer.new()
	main.add_theme_constant_override("separation", 12)
	outer.add_child(main)

	var header := _build_header()
	main.add_child(header)

	var content_stack := Control.new()
	content_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(content_stack)

	create_screen = _build_create_screen()
	profile_screen = _build_profile_screen()
	game_screen = _build_game_screen()
	battle_screen = _build_battle_screen()
	for screen in [create_screen, profile_screen, game_screen, battle_screen]:
		screen.set_anchors_preset(Control.PRESET_FULL_RECT)
		content_stack.add_child(screen)


func _build_header() -> Control:
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)

	var title_group := VBoxContainer.new()
	title_group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_group)

	title_label = Label.new()
	title_label.text = "道湮"
	title_label.add_theme_font_size_override("font_size", 36)
	title_label.add_theme_color_override("font_color", Color(0.92, 0.86, 0.68))
	title_group.add_child(title_label)

	subtitle_label = Label.new()
	subtitle_label.text = "残道时代 · 修道者创建"
	subtitle_label.add_theme_color_override("font_color", Color(0.72, 0.78, 0.76))
	title_group.add_child(subtitle_label)

	var seal := TextureRect.new()
	seal.texture = ELEMENT_TEX
	seal.custom_minimum_size = Vector2(310, 76)
	seal.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	seal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header.add_child(seal)
	return header


func _build_create_screen() -> Control:
	var screen := HBoxContainer.new()
	screen.add_theme_constant_override("separation", 14)

	var art_panel := _make_panel("人物剪影", true)
	art_panel.custom_minimum_size = Vector2(360, 0)
	screen.add_child(art_panel)
	var art_body := _panel_body(art_panel)
	portrait_texture = TextureRect.new()
	portrait_texture.texture = CULTIVATOR_TEX
	portrait_texture.size_flags_vertical = Control.SIZE_EXPAND_FILL
	portrait_texture.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
	portrait_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art_body.add_child(portrait_texture)
	var art_note := Label.new()
	art_note.text = "不是天命之子，只是一名即将背上因果的修道者。"
	art_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	art_note.add_theme_color_override("font_color", Color(0.73, 0.76, 0.72))
	art_body.add_child(art_note)

	var form_panel := _make_panel("创建角色", true)
	form_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	screen.add_child(form_panel)
	var form := _panel_body(form_panel)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	form.add_child(grid)

	name_edit = LineEdit.new()
	name_edit.placeholder_text = "无名修士"
	name_edit.text_changed.connect(func(_value: String) -> void: _refresh_create_preview())
	_add_form_row(grid, "姓名", name_edit)

	gender_select = OptionButton.new()
	for item in ["未定", "女", "男"]:
		gender_select.add_item(item)
	gender_select.item_selected.connect(func(_index: int) -> void: _refresh_create_preview())
	_add_form_row(grid, "性别", gender_select)

	origin_select = OptionButton.new()
	for origin in ORIGIN_PRESETS:
		origin_select.add_item(origin.name)
	origin_select.item_selected.connect(func(index: int) -> void:
		selected_origin_index = index
		_refresh_create_preview()
	)
	_add_form_row(grid, "出身", origin_select)

	root_select = OptionButton.new()
	for preset in ROOT_PRESETS:
		root_select.add_item("%s · %s" % [preset.name, preset.type])
	root_select.item_selected.connect(func(index: int) -> void:
		selected_root_index = index
		_refresh_create_preview()
	)
	_add_form_row(grid, "灵根", root_select)

	path_select = OptionButton.new()
	for path in PATH_PRESETS:
		path_select.add_item(path.name)
	path_select.item_selected.connect(func(index: int) -> void:
		selected_path_index = index
		_refresh_create_preview()
	)
	_add_form_row(grid, "道途", path_select)

	obsession_select = OptionButton.new()
	for obsession in OBSESSION_PRESETS:
		obsession_select.add_item(obsession.name)
	obsession_select.item_selected.connect(func(index: int) -> void:
		selected_obsession_index = index
		_refresh_create_preview()
	)
	_add_form_row(grid, "执念", obsession_select)

	var preview_panel := _make_panel("人物预览", false)
	preview_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	form.add_child(preview_panel)
	var preview := _panel_body(preview_panel)
	preview_title = Label.new()
	preview_title.add_theme_font_size_override("font_size", 22)
	preview_title.add_theme_color_override("font_color", Color(0.92, 0.86, 0.68))
	preview.add_child(preview_title)

	preview_body = RichTextLabel.new()
	preview_body.bbcode_enabled = true
	preview_body.fit_content = true
	preview_body.scroll_active = false
	preview_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview.add_child(preview_body)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	form.add_child(actions)
	var random_button := _make_button("随机一名修士")
	random_button.pressed.connect(_randomize_character)
	actions.add_child(random_button)
	var make_profile_button := _make_button("生成人物设定")
	make_profile_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	make_profile_button.pressed.connect(_generate_profile)
	actions.add_child(make_profile_button)
	return screen


func _build_profile_screen() -> Control:
	var screen := HBoxContainer.new()
	screen.add_theme_constant_override("separation", 14)

	var summary_panel := _make_panel("人物设定", true)
	summary_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	screen.add_child(summary_panel)
	var summary := _panel_body(summary_panel)

	profile_title = Label.new()
	profile_title.add_theme_font_size_override("font_size", 28)
	profile_title.add_theme_color_override("font_color", Color(0.94, 0.86, 0.64))
	summary.add_child(profile_title)

	profile_body = RichTextLabel.new()
	profile_body.bbcode_enabled = true
	profile_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	profile_body.scroll_active = true
	summary.add_child(profile_body)

	var side_panel := _make_panel("入道前评估", true)
	side_panel.custom_minimum_size = Vector2(360, 0)
	screen.add_child(side_panel)
	var side := _panel_body(side_panel)

	var portrait := TextureRect.new()
	portrait.texture = CULTIVATOR_TEX
	portrait.custom_minimum_size = Vector2(0, 260)
	portrait.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	side.add_child(portrait)

	profile_stats = RichTextLabel.new()
	profile_stats.bbcode_enabled = true
	profile_stats.fit_content = true
	profile_stats.scroll_active = false
	side.add_child(profile_stats)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	side.add_child(actions)
	var back_button := _make_button("重选")
	back_button.pressed.connect(_show_create)
	actions.add_child(back_button)
	var enter_button := _make_button("入道")
	enter_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	enter_button.pressed.connect(_start_game)
	actions.add_child(enter_button)
	return screen


func _build_game_screen() -> Control:
	var screen := HBoxContainer.new()
	screen.add_theme_constant_override("separation", 12)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(320, 0)
	left.add_theme_constant_override("separation", 10)
	screen.add_child(left)

	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.add_theme_constant_override("separation", 10)
	screen.add_child(center)

	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(340, 0)
	right.add_theme_constant_override("separation", 10)
	screen.add_child(right)

	var identity_panel := _make_panel("修士", false)
	left.add_child(identity_panel)
	var identity := _panel_body(identity_panel)
	character_label = Label.new()
	character_label.add_theme_font_size_override("font_size", 20)
	character_label.add_theme_color_override("font_color", Color(0.94, 0.86, 0.64))
	identity.add_child(character_label)
	turn_label = Label.new()
	realm_label = Label.new()
	root_label = Label.new()
	build_label = Label.new()
	doctrine_label = Label.new()
	doctrine_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for label in [turn_label, realm_label, root_label, build_label, doctrine_label]:
		label.add_theme_color_override("font_color", Color(0.78, 0.82, 0.8))
		identity.add_child(label)

	var stats_panel := _make_panel("状态", false)
	left.add_child(stats_panel)
	var stats := _panel_body(stats_panel)
	for key in ["修为", "悟性", "稳定", "潜力", "风险", "污染", "因果", "心魔", "天道修正", "宗门信任"]:
		_add_meter(stats, key)

	var states_panel := _make_panel("因果状态", false)
	states_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(states_panel)
	state_box = RichTextLabel.new()
	state_box.bbcode_enabled = true
	state_box.fit_content = false
	state_box.scroll_active = true
	state_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_panel_body(states_panel).add_child(state_box)

	var event_panel := _make_panel("当前抉择", true)
	event_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.add_child(event_panel)
	var event_content := _panel_body(event_panel)

	event_art = TextureRect.new()
	event_art.texture = LINGXU_TEX
	event_art.custom_minimum_size = Vector2(0, 170)
	event_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	event_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	event_content.add_child(event_art)

	event_title = Label.new()
	event_title.add_theme_font_size_override("font_size", 24)
	event_title.add_theme_color_override("font_color", Color(0.94, 0.86, 0.64))
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
	for action_id in ["cultivate", "sect", "ruin", "demon", "battle"]:
		var button := _make_button(ACTIONS[action_id].button)
		button.custom_minimum_size = Vector2(0, 44)
		button.pressed.connect(func() -> void: _take_action(action_id))
		action_grid.add_child(button)
		action_buttons[action_id] = button

	breakthrough_button = _make_button("尝试突破")
	breakthrough_button.custom_minimum_size = Vector2(0, 46)
	breakthrough_button.pressed.connect(_attempt_breakthrough)
	event_content.add_child(breakthrough_button)

	var bottom_actions := HBoxContainer.new()
	bottom_actions.add_theme_constant_override("separation", 8)
	event_content.add_child(bottom_actions)
	restart_button = _make_button("因果重开")
	restart_button.pressed.connect(_reset_to_profile)
	restart_button.visible = false
	bottom_actions.add_child(restart_button)
	change_character_button = _make_button("重建角色")
	change_character_button.pressed.connect(_show_create)
	bottom_actions.add_child(change_character_button)

	var npc_panel := _make_panel("NPC自行演化", false)
	right.add_child(npc_panel)
	npc_box = RichTextLabel.new()
	npc_box.custom_minimum_size = Vector2(0, 230)
	npc_box.bbcode_enabled = true
	npc_box.fit_content = true
	npc_box.scroll_active = false
	_panel_body(npc_panel).add_child(npc_box)

	var log_panel := _make_panel("残响日志", false)
	log_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(log_panel)
	log_box = RichTextLabel.new()
	log_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_box.bbcode_enabled = true
	log_box.scroll_active = true
	_panel_body(log_panel).add_child(log_box)
	return screen


func _build_battle_screen() -> Control:
	var screen := HBoxContainer.new()
	screen.add_theme_constant_override("separation", 12)

	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.add_theme_constant_override("separation", 10)
	screen.add_child(center)

	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(310, 0)
	right.add_theme_constant_override("separation", 10)
	screen.add_child(right)

	var field_panel := _make_panel("灵墟战斗房间", true)
	field_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.add_child(field_panel)
	var field_body := _panel_body(field_panel)
	battle_arena = Control.new()
	battle_arena.custom_minimum_size = Vector2(920, 540)
	battle_arena.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	battle_arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
	battle_arena.set_script(BATTLE_ARENA_SCRIPT)
	battle_arena.battle_finished.connect(_on_arena_battle_finished)
	field_body.add_child(battle_arena)

	var guide_panel := _make_panel("操作", false)
	right.add_child(guide_panel)
	var guide := RichTextLabel.new()
	guide.bbcode_enabled = true
	guide.fit_content = true
	guide.scroll_active = false
	guide.text = "[b]动作战斗[/b]\nWASD 移动\n空格 闪避\n左键 近身斩击\n右键 飞剑\nQ 切换五行\nE 释放当前五行术式\nR 心魔借力\n\n战斗不再由按钮结算。敌人会追击、触体、释放浊灵弹幕；五行灵气按灵根持续恢复。"
	_panel_body(guide_panel).add_child(guide)

	battle_status_label = RichTextLabel.new()
	battle_status_label.bbcode_enabled = true
	battle_status_label.fit_content = true
	battle_status_label.scroll_active = false
	_panel_body(guide_panel).add_child(battle_status_label)

	battle_exit_button = _make_button("强行脱离")
	battle_exit_button.pressed.connect(_force_exit_arena)
	_panel_body(guide_panel).add_child(battle_exit_button)

	var log_panel := _make_panel("战斗残响", true)
	log_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(log_panel)
	battle_log_box = RichTextLabel.new()
	battle_log_box.bbcode_enabled = true
	battle_log_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	battle_log_box.scroll_active = true
	_panel_body(log_panel).add_child(battle_log_box)
	return screen


func _add_form_row(grid: GridContainer, label_text: String, input: Control) -> void:
	var label := Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", Color(0.74, 0.79, 0.77))
	grid.add_child(label)
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(input)


func _add_meter(parent: VBoxContainer, key: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var label := Label.new()
	label.text = key
	label.custom_minimum_size = Vector2(76, 0)
	label.add_theme_color_override("font_color", Color(0.7, 0.76, 0.74))
	row.add_child(label)

	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.show_percentage = false
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(bar)
	progress_bars[key] = bar

	var value := Label.new()
	value.custom_minimum_size = Vector2(58, 0)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value)
	meter_labels[key] = value


func _make_panel(title: String, expand: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	if expand:
		panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.075, 0.09, 0.095, 0.88)
	style.border_color = Color(0.48, 0.43, 0.28, 0.58)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	var label := Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.9, 0.84, 0.62))
	box.add_child(label)
	return panel


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.18, 0.22, 0.22, 0.95)
	normal.border_color = Color(0.55, 0.48, 0.3, 0.75)
	normal.set_border_width_all(1)
	normal.corner_radius_top_left = 5
	normal.corner_radius_top_right = 5
	normal.corner_radius_bottom_left = 5
	normal.corner_radius_bottom_right = 5
	var hover := normal.duplicate()
	hover.bg_color = Color(0.28, 0.31, 0.28, 0.98)
	var pressed := normal.duplicate()
	pressed.bg_color = Color(0.12, 0.15, 0.15, 1)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color(0.92, 0.89, 0.76))
	return button


func _panel_body(panel: PanelContainer) -> VBoxContainer:
	return panel.get_child(0) as VBoxContainer


func _show_create() -> void:
	current_screen = ScreenState.CREATE
	game_started = false
	subtitle_label.text = "残道时代 · 修道者创建"
	_set_screen_visibility()
	_refresh_create_preview()


func _show_profile() -> void:
	current_screen = ScreenState.PROFILE
	subtitle_label.text = "残道时代 · 人物设定"
	_set_screen_visibility()


func _show_game() -> void:
	current_screen = ScreenState.GAME
	subtitle_label.text = "残道时代 · 因果运转"
	_set_screen_visibility()


func _show_battle() -> void:
	current_screen = ScreenState.BATTLE
	subtitle_label.text = "残道时代 · 构筑战斗"
	_set_screen_visibility()


func _set_screen_visibility() -> void:
	create_screen.visible = current_screen == ScreenState.CREATE
	profile_screen.visible = current_screen == ScreenState.PROFILE
	game_screen.visible = current_screen == ScreenState.GAME
	battle_screen.visible = current_screen == ScreenState.BATTLE


func _refresh_create_preview() -> void:
	var root: Dictionary = ROOT_PRESETS[root_select.selected]
	var origin: Dictionary = ORIGIN_PRESETS[origin_select.selected]
	var path: Dictionary = PATH_PRESETS[path_select.selected]
	var obsession: Dictionary = OBSESSION_PRESETS[obsession_select.selected]
	var preview_name := _clean_character_name()
	preview_title.text = "%s · %s" % [preview_name, root.name]
	preview_body.text = "[b]出身[/b] %s\n%s\n\n[b]道途[/b] %s：%s\n\n[b]执念[/b] %s：%s\n\n[b]构筑倾向[/b] %s\n[b]灵根评估[/b] %s" % [
		origin.name,
		origin.text,
		path.name,
		path.text,
		obsession.name,
		obsession.text,
		root.build,
		root.text
	]


func _randomize_character() -> void:
	var names := ["沈疏雨", "陆听尘", "许照微", "林烬", "秦问水", "顾青崖", "闻人砚"]
	name_edit.text = names[rng.randi_range(0, names.size() - 1)]
	gender_select.select(rng.randi_range(0, 2))
	origin_select.select(rng.randi_range(0, ORIGIN_PRESETS.size() - 1))
	root_select.select(rng.randi_range(0, ROOT_PRESETS.size() - 1))
	path_select.select(rng.randi_range(0, PATH_PRESETS.size() - 1))
	obsession_select.select(rng.randi_range(0, OBSESSION_PRESETS.size() - 1))
	selected_origin_index = origin_select.selected
	selected_root_index = root_select.selected
	selected_path_index = path_select.selected
	selected_obsession_index = obsession_select.selected
	_refresh_create_preview()


func _generate_profile() -> void:
	selected_origin_index = origin_select.selected
	selected_root_index = root_select.selected
	selected_path_index = path_select.selected
	selected_obsession_index = obsession_select.selected
	character_name = _clean_character_name()
	character_gender = gender_select.get_item_text(gender_select.selected)
	character_origin = ORIGIN_PRESETS[selected_origin_index].duplicate(true)
	character_path = PATH_PRESETS[selected_path_index].duplicate(true)
	character_obsession = OBSESSION_PRESETS[selected_obsession_index].duplicate(true)
	root_data = ROOT_PRESETS[selected_root_index].duplicate(true)
	character_fate = _roll_fate(root_data.type)
	character_sect = character_origin.get("sect_name", "玄微宗外门")
	character_epitaph = _compose_character_epitaph()
	_update_profile_screen()
	_show_profile()


func _clean_character_name() -> String:
	var cleaned := name_edit.text.strip_edges()
	if cleaned.is_empty():
		return "无名修士"
	return cleaned


func _roll_fate(root_type: String) -> String:
	var options: Array = FATE_BY_ROOT.get(root_type, ["残命", "道劫"])
	return options[rng.randi_range(0, options.size() - 1)]


func _compose_character_epitaph() -> String:
	var sentence := ""
	sentence += "%s出身于%s，身具%s。" % [character_name, character_origin.name, root_data.name]
	sentence += "其道途偏向%s，执念为%s。" % [character_path.name, character_obsession.name]
	sentence += "命格显%s之象，初入%s时，天道残缺的裂纹尚未完全显露。" % [character_fate, character_sect]
	return sentence


func _update_profile_screen() -> void:
	profile_title.text = "%s · %s命格" % [character_name, character_fate]
	profile_body.text = "[b]人物短传[/b]\n%s\n\n[b]出身[/b]\n%s\n\n[b]灵根[/b]\n%s · %s\n%s\n\n[b]道途[/b]\n%s\n\n[b]执念[/b]\n%s\n\n[b]初始因果[/b]\n%s、%s、%s" % [
		character_epitaph,
		character_origin.text,
		root_data.name,
		root_data.type,
		root_data.text,
		character_path.text,
		character_obsession.text,
		character_origin.state,
		character_path.state,
		character_obsession.state
	]
	var stat_preview := _get_initial_stat_preview()
	profile_stats.text = "[b]初始评估[/b]\n修为 10 / 100\n悟性 %d\n稳定 %d\n潜力 %d\n风险 %d\n污染 %d\n因果 %d\n心魔 %d\n宗门信任 %d\n\n[b]建议构筑[/b]\n%s" % [
		stat_preview.insight,
		stat_preview.stability,
		stat_preview.potential,
		stat_preview.risk,
		stat_preview.pollution,
		stat_preview.karma,
		stat_preview.heart,
		stat_preview.sect,
		_get_effective_build()
	]


func _get_initial_stat_preview() -> Dictionary:
	return {
		"insight": 5 + int(character_origin.get("insight", 0)) + int(character_path.get("insight", 0)),
		"stability": clamp(int(root_data.stability) + int(character_origin.get("stability", 0)), 0, 100),
		"potential": clamp(int(root_data.potential) + int(character_origin.get("potential", 0)), 0, 100),
		"risk": clamp(int(root_data.risk) + int(character_origin.get("risk", 0)) + int(character_path.get("risk", 0)), 0, 100),
		"pollution": int(character_origin.get("pollution", 0)),
		"karma": int(character_origin.get("karma", 0)) + int(character_obsession.get("karma", 0)),
		"heart": int(character_obsession.get("heart", 0)),
		"sect": clamp(30 + int(character_origin.get("sect_trust", 0)), -50, 100)
	}


func _get_effective_build() -> String:
	if character_path.has("build"):
		return "%s / %s" % [root_data.build, character_path.build]
	return root_data.build


func _start_game() -> void:
	if character_name.is_empty():
		_generate_profile()
		return
	var initial := _get_initial_stat_preview()
	game_started = true
	turn = 1
	realm_index = 0
	cultivation = 10
	insight = initial.insight
	stability = initial.stability
	potential = initial.potential
	risk = initial.risk
	pollution = initial.pollution
	karma = initial.karma
	heart_demon = initial.heart
	heaven_correction = 0
	sect_trust = initial.sect
	life_resonance = 0
	relics.clear()
	states.clear()
	logs.clear()
	npc_states = {
		"沈砚秋": {"realm": "筑基", "path": "剑道", "state": "闭关", "demon": 18, "alive": true},
		"陆青梧": {"realm": "炼气", "path": "丹道", "state": "采药", "demon": 8, "alive": true},
		"韩照夜": {"realm": "金丹", "path": "因果", "state": "追查灵墟", "demon": 26, "alive": true},
	}
	_add_state("初入残道")
	_add_state(root_data.state)
	_add_state(character_origin.state)
	_add_state(character_path.state)
	_add_state(character_obsession.state)
	_add_log("%s入%s，以%s立道。" % [character_name, character_sect, _get_effective_build()])
	for button in action_buttons.values():
		button.disabled = false
	breakthrough_button.disabled = false
	restart_button.visible = false
	_show_game()
	_present_turn()


func _reset_to_profile() -> void:
	game_started = false
	_update_profile_screen()
	_show_profile()


func _present_turn() -> void:
	if _check_game_over():
		return
	event_title.text = "第%d回合：%s境" % [turn, REALMS[realm_index]]
	event_body.text = _compose_turn_text()
	_update_labels()


func _compose_turn_text() -> String:
	var text := ""
	text += "[b]天道残响[/b]\n"
	text += "%s的灵气仍可运转，但每一次借用都会改变自身与世界的关系。\n\n" % character_name
	text += "[b]当前判断[/b]\n"
	text += "- 修为达到100可尝试突破。\n"
	text += "- 污染、因果、心魔与天道修正越高，突破越危险。\n"
	text += "- 稳定降低到0，修炼体系会崩坏。\n\n"
	text += "[b]可选行动[/b]\n"
	for action_id in ["cultivate", "sect", "ruin", "demon", "battle"]:
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
		"battle":
			_start_battle()
			return
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
		_add_log("完成一次周天运转，修为增长%d。" % gain)
	_clamp_core()


func _action_sect() -> void:
	var roll: int = rng.randi_range(1, 100)
	sect_trust += rng.randi_range(6, 13)
	karma += rng.randi_range(3, 9)
	insight += rng.randi_range(2, 5)
	if roll < 35:
		_add_state("宗门债")
		_add_log("替%s接下一桩旧债，因果缠身。" % character_sect)
	elif roll < 70:
		stability += rng.randi_range(3, 8)
		_add_log("长老指点功法冲突，体系稍稳。")
	else:
		sect_trust -= rng.randi_range(8, 15)
		karma += rng.randi_range(8, 14)
		_add_state("派系疑云")
		_add_log("卷入长老派系争执，宗门信任开始摇晃。")
	_clamp_core()


func _action_ruin() -> void:
	var gain: int = rng.randi_range(8, 18)
	cultivation += gain
	insight += rng.randi_range(4, 10)
	pollution += rng.randi_range(8, 16)
	karma += rng.randi_range(4, 12)
	heaven_correction += rng.randi_range(4, 9)
	var roll: int = rng.randi_range(1, 100)
	if roll < 35:
		var relic := _random_relic()
		if not relics.has(relic):
			relics.append(relic)
		potential += rng.randi_range(3, 8)
		_add_log("灵墟时间残响中取得遗物：%s。" % relic)
	elif roll < 65:
		_add_state("灵墟污染")
		stability -= rng.randi_range(5, 13)
		_add_log("灵墟内五行逆转，灵根被污染。")
	else:
		life_resonance += 1
		_add_state("古代真相碎片")
		_add_log("看见湮灭时代的残缺记忆，但无法确认其真伪。")
	_clamp_core()


func _action_demon() -> void:
	var roll: int = rng.randi_range(1, 100)
	if roll + insight > 82:
		heart_demon = max(0, heart_demon - rng.randi_range(8, 16))
		insight += rng.randi_range(3, 7)
		_add_log("观照执念，暂时压下心魔。")
	elif roll > 45:
		heart_demon += rng.randi_range(5, 12)
		cultivation += rng.randi_range(8, 15)
		potential += rng.randi_range(2, 6)
		_add_state("心魔借力")
		_add_log("借用心魔之力，修为暴涨，但自我边界变得模糊。")
	else:
		heart_demon += rng.randi_range(10, 20)
		stability -= rng.randi_range(6, 14)
		_add_state("心魔低语")
		_add_log("心魔模拟故人记忆，道心出现裂纹。")
	heaven_correction += rng.randi_range(2, 6)
	_clamp_core()


func _start_battle() -> void:
	battle_enemy = ENCOUNTERS[rng.randi_range(0, ENCOUNTERS.size() - 1)].duplicate(true)
	battle_active = true
	battle_result_pending = false
	battle_logs.clear()
	_show_battle()
	battle_status_label.text = "[b]%s[/b]\n%s\n\n构筑：%s" % [battle_enemy.name, battle_enemy.text, _get_effective_build()]
	battle_log_box.text = "进入灵墟战斗房间。"
	var payload := {
		"enemy": battle_enemy,
		"realm_index": realm_index,
		"pollution": pollution,
		"risk": risk,
		"stability": stability,
		"heart_demon": heart_demon,
		"elements": root_data.elements,
	}
	battle_arena.call("start_battle", payload)


func _on_arena_battle_finished(victory: bool, result: Dictionary) -> void:
	if battle_result_pending:
		return
	battle_result_pending = true
	battle_active = false
	pollution += int(result.get("pollution", 0))
	heart_demon += int(result.get("heart", 0))
	karma += int(result.get("karma", 0))
	cultivation += int(result.get("cultivation", 0))
	stability -= int(result.get("stability_loss", 0))
	if victory:
		var reward := String(result.get("reward", "灵气残屑"))
		if not relics.has(reward):
			relics.append(reward)
		insight += rng.randi_range(2, 5)
		heaven_correction += rng.randi_range(2, 5)
		_add_state("战胜%s" % result.get("enemy", "灵墟敌影"))
		_add_log("在动作战斗中击破%s，取得%s。" % [result.get("enemy", "灵墟敌影"), reward])
		battle_log_box.text = "战斗胜利。耗时 %.1f 息。\n回到修道后，因果与污染已经写入本轮。" % float(result.get("time", 0.0))
	else:
		stability -= rng.randi_range(8, 14)
		pollution += rng.randi_range(4, 9)
		heart_demon += rng.randi_range(3, 8)
		_add_state("败退残伤")
		_add_log("在动作战斗中败退，道基留下暗伤。")
		battle_log_box.text = "战斗失败。你被迫斩断战场因果，污染和心魔回流。"
	_advance_world()
	turn += 1
	_clamp_core()
	battle_status_label.text = "[b]战斗已结算[/b]\n污染 %d / 因果 %d / 心魔 %d / 稳定 %d" % [pollution, karma, heart_demon, stability]


func _force_exit_arena() -> void:
	if battle_active:
		battle_arena.call("force_finish", false)
		return
	_show_game()
	_present_turn()



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
			event_body.text = "周天尚未圆满。残缺天道没有回应，只有经脉中的滞涩感逐渐扩大。"
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
		_add_log("突破至%s，生命形态开始偏离凡俗。" % REALMS[realm_index])
		event_title.text = "破境成功"
		event_body.text = "天道修正没有放过你。突破带来新的上限，也让你的因果重量明显增加。"
	else:
		var damage: int = rng.randi_range(16, 30)
		stability -= damage
		heart_demon += rng.randi_range(10, 22)
		pollution += rng.randi_range(6, 14)
		_add_state("道基受损")
		_add_log("突破失败，道基受损%d，心魔趁隙而入。" % damage)
		event_title.text = "突破失败"
		event_body.text = "这不是数值不足的失败，而是修炼体系无法承受自身因果。"
	_clamp_core()
	_update_labels()
	_check_game_over()


func _advance_world() -> void:
	for npc_name in npc_states.keys():
		var npc: Dictionary = npc_states[npc_name]
		if not npc.alive:
			continue
		var roll: int = rng.randi_range(1, 100)
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
		_add_log("浊灵气开始影响经脉。")
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
		ending = "五行循环彻底崩坏，道基化为残响。"
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
		event_body.text = "%s\n\n死亡不是结束。下一轮可把这些状态作为残响继承：%s" % [ending, _format_state_inline()]
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
	character_label.text = "%s · %s · %s" % [character_name, character_gender, character_fate]
	turn_label.text = "回合：%d" % turn
	realm_label.text = "境界：%s" % REALMS[realm_index]
	root_label.text = "灵根：%s · %s" % [root_data.name, root_data.type]
	build_label.text = "构筑：%s" % _get_effective_build()
	doctrine_label.text = "宗门：%s\n出身：%s\n五行：%s" % [character_sect, character_origin.name, _format_elements()]

	_set_meter("修为", cultivation, 100, "%d / 100" % cultivation)
	_set_meter("悟性", insight, 100, str(insight))
	_set_meter("稳定", stability, 100, str(stability))
	_set_meter("潜力", potential, 100, str(potential))
	_set_meter("风险", risk, 100, str(risk))
	_set_meter("污染", pollution, 100, str(pollution))
	_set_meter("因果", karma, 100, str(karma))
	_set_meter("心魔", heart_demon, 100, str(heart_demon))
	_set_meter("天道修正", heaven_correction, 100, str(heaven_correction))
	_set_meter("宗门信任", sect_trust + 50, 150, str(sect_trust))

	state_box.text = _format_states()
	npc_box.text = _format_npcs()
	log_box.text = _format_logs()


func _set_meter(key: String, value: int, max_value: int, display: String) -> void:
	var bar: ProgressBar = progress_bars[key]
	bar.max_value = max_value
	bar.value = clamp(value, 0, max_value)
	meter_labels[key].text = display


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
		lines.append("\n[b]遗物[/b]：%s" % "、".join(relics))
	return "\n".join(lines)


func _format_state_inline() -> String:
	if states.is_empty():
		return "无"
	return "、".join(states)


func _format_npcs() -> String:
	var lines: Array[String] = []
	for npc_name in npc_states.keys():
		var npc: Dictionary = npc_states[npc_name]
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
