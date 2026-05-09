extends Control

signal battle_finished(victory: bool, result: Dictionary)

const PLAYER_TEX: Texture2D = preload("res://assets/art/combat_player.svg")
const ENEMY_TEX: Texture2D = preload("res://assets/art/combat_enemy.svg")
const SWORD_TEX: Texture2D = preload("res://assets/art/flying_sword.svg")

const ARENA_SIZE := Vector2(920, 540)
const PLAYER_RADIUS := 15.0
const ENEMY_RADIUS := 22.0
const SWORD_RADIUS := 6.0
const ENEMY_BULLET_RADIUS := 7.0

var rng := RandomNumberGenerator.new()
var running := false
var victory_sent := false
var battle_time := 0.0
var player := {
	"pos": Vector2.ZERO,
	"vel": Vector2.ZERO,
	"hp": 100.0,
	"max_hp": 100.0,
	"guard": 0.0,
	"dodge_cd": 0.0,
	"invuln": 0.0,
	"attack_cd": 0.0,
	"sword_cd": 0.0,
	"spell_cd": 0.0,
	"demon_cd": 0.0,
	"hit_flash": 0.0,
	"facing": Vector2.RIGHT,
}
var enemy := {
	"name": "浊灵残影",
	"pos": Vector2.ZERO,
	"hp": 160.0,
	"max_hp": 160.0,
	"pressure": 22.0,
	"phase": 1,
	"touch_cd": 0.0,
	"cast_timer": 2.0,
	"hit_flash": 0.0,
}
var context := {}
var projectiles: Array[Dictionary] = []
var enemy_bullets: Array[Dictionary] = []
var slash_arcs: Array[Dictionary] = []
var afterimages: Array[Dictionary] = []
var floating_text: Array[Dictionary] = []
var logs: Array[String] = []
var qi := {"金": 30.0, "木": 20.0, "水": 20.0, "火": 20.0, "土": 20.0}
var heat := 0.0
var pollution_gain := 0
var heart_gain := 0
var karma_gain := 0
var cultivation_gain := 0
var current_spell := "金"


func _ready() -> void:
	rng.randomize()
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_PASS
	set_process(true)


func start_battle(payload: Dictionary) -> void:
	context = payload.duplicate(true)
	running = true
	victory_sent = false
	battle_time = 0.0
	projectiles.clear()
	enemy_bullets.clear()
	slash_arcs.clear()
	afterimages.clear()
	floating_text.clear()
	logs.clear()
	pollution_gain = 0
	heart_gain = 0
	karma_gain = 0
	cultivation_gain = 0
	var enemy_data: Dictionary = context.get("enemy", {})
	enemy.name = enemy_data.get("name", "浊灵残影")
	enemy.max_hp = float(enemy_data.get("hp", 120)) + float(context.get("realm_index", 0)) * 18.0
	enemy.hp = enemy.max_hp
	enemy.pressure = float(enemy_data.get("pressure", 20)) + float(context.get("pollution", 0)) * 0.08
	enemy.phase = 1
	enemy.touch_cd = 0.0
	enemy.cast_timer = 1.8
	enemy.hit_flash = 0.0
	player.pos = ARENA_SIZE * 0.5 + Vector2(-210, 40)
	player.vel = Vector2.ZERO
	player.hp = 100.0
	player.max_hp = 100.0
	player.guard = clamp(float(context.get("stability", 50)), 0.0, 100.0)
	player.dodge_cd = 0.0
	player.invuln = 0.0
	player.attack_cd = 0.0
	player.sword_cd = 0.0
	player.spell_cd = 0.0
	player.demon_cd = 0.0
	player.hit_flash = 0.0
	player.facing = Vector2.RIGHT
	enemy.pos = ARENA_SIZE * 0.5 + Vector2(220, -20)
	_init_qi()
	heat = float(context.get("risk", 0)) * 0.12
	current_spell = _dominant_element()
	_add_log("进入灵墟战场。WASD移动，空格闪避，左键斩击，右键飞剑，Q切换五行，E施术，R心魔借力。")
	grab_focus()
	queue_redraw()


func _init_qi() -> void:
	var elements: Dictionary = context.get("elements", {})
	for element in ["金", "木", "水", "火", "土"]:
		qi[element] = 22.0 + float(elements.get(element, 0)) * 0.22


func _process(delta: float) -> void:
	if not running:
		queue_redraw()
		return
	battle_time += delta
	_update_cooldowns(delta)
	_update_player(delta)
	_update_enemy(delta)
	_update_projectiles(delta)
	_update_effects(delta)
	_regenerate_qi(delta)
	_apply_pressure(delta)
	_check_end()
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if not running:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_melee_attack()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_cast_flying_sword()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE:
				_dodge()
			KEY_Q:
				_cycle_spell()
			KEY_E:
				_cast_element_spell()
			KEY_R:
				_demon_burst()


func _update_cooldowns(delta: float) -> void:
	for key in ["dodge_cd", "invuln", "attack_cd", "sword_cd", "spell_cd", "demon_cd", "hit_flash"]:
		player[key] = max(0.0, float(player[key]) - delta)
	enemy.touch_cd = max(0.0, float(enemy.touch_cd) - delta)
	enemy.cast_timer = max(0.0, float(enemy.cast_timer) - delta)
	enemy.hit_flash = max(0.0, float(enemy.hit_flash) - delta)


func _update_player(delta: float) -> void:
	var move := Vector2.ZERO
	if Input.is_key_pressed(KEY_A):
		move.x -= 1
	if Input.is_key_pressed(KEY_D):
		move.x += 1
	if Input.is_key_pressed(KEY_W):
		move.y -= 1
	if Input.is_key_pressed(KEY_S):
		move.y += 1
	if move.length() > 0.0:
		move = move.normalized()
		player.facing = move
	var speed: float = 235.0
	player.vel = move * speed
	player.pos += player.vel * delta
	player.pos = _clamp_to_arena(player.pos, PLAYER_RADIUS)


func _update_enemy(delta: float) -> void:
	var to_player: Vector2 = player.pos - enemy.pos
	var dist: float = max(1.0, to_player.length())
	var dir: Vector2 = to_player / dist
	var desired_dist: float = 115.0 if enemy.phase == 1 else 85.0
	var speed: float = 105.0 + float(enemy.phase) * 25.0
	if dist > desired_dist:
		enemy.pos += dir * speed * delta
	else:
		enemy.pos -= dir * speed * 0.45 * delta
	enemy.pos = _clamp_to_arena(enemy.pos, ENEMY_RADIUS)
	if dist < PLAYER_RADIUS + ENEMY_RADIUS + 8.0 and float(enemy.touch_cd) <= 0.0:
		_damage_player(10.0 + float(enemy.phase) * 4.0, "浊灵触体")
		enemy.touch_cd = 0.7
	if float(enemy.cast_timer) <= 0.0:
		_enemy_cast(dir)
		enemy.cast_timer = max(0.75, 2.1 - float(enemy.phase) * 0.28 - float(enemy.pressure) * 0.015)
	if enemy.hp < enemy.max_hp * 0.45:
		enemy.phase = 2


func _enemy_cast(dir: Vector2) -> void:
	var spread := 0.28 if enemy.phase == 1 else 0.46
	var count := 3 if enemy.phase == 1 else 5
	for i in count:
		var offset := float(i - count / 2) * spread
		var shot_dir := dir.rotated(offset).normalized()
		enemy_bullets.append({
			"pos": enemy.pos + shot_dir * 28.0,
			"vel": shot_dir * (190.0 + float(enemy.pressure) * 1.4),
			"life": 3.0,
			"damage": 8.0 + float(enemy.phase) * 2.0,
		})
	_add_log("%s释放浊灵压迫。" % enemy.name)


func _update_projectiles(delta: float) -> void:
	for projectile in projectiles:
		projectile.pos += projectile.vel * delta
		projectile.life -= delta
		if projectile.pos.distance_to(enemy.pos) <= ENEMY_RADIUS + float(projectile.radius):
			_damage_enemy(float(projectile.damage), projectile.element)
			projectile.life = 0.0
	for bullet in enemy_bullets:
		bullet.pos += bullet.vel * delta
		bullet.life -= delta
		if bullet.pos.distance_to(player.pos) <= PLAYER_RADIUS + ENEMY_BULLET_RADIUS:
			_damage_player(float(bullet.damage), "浊灵弹")
			bullet.life = 0.0
	projectiles = projectiles.filter(func(item: Dictionary) -> bool: return float(item.life) > 0.0 and _inside_arena(item.pos, 32.0))
	enemy_bullets = enemy_bullets.filter(func(item: Dictionary) -> bool: return float(item.life) > 0.0 and _inside_arena(item.pos, 32.0))


func _update_effects(delta: float) -> void:
	for arc in slash_arcs:
		arc.life -= delta
	for image in afterimages:
		image.life -= delta
	for text in floating_text:
		text.life -= delta
		text.pos.y -= 22.0 * delta
	slash_arcs = slash_arcs.filter(func(item: Dictionary) -> bool: return float(item.life) > 0.0)
	afterimages = afterimages.filter(func(item: Dictionary) -> bool: return float(item.life) > 0.0)
	floating_text = floating_text.filter(func(item: Dictionary) -> bool: return float(item.life) > 0.0)


func _regenerate_qi(delta: float) -> void:
	var elements: Dictionary = context.get("elements", {})
	for element in ["金", "木", "水", "火", "土"]:
		var flow: float = 3.0 + float(elements.get(element, 0)) * 0.045
		qi[element] = clamp(float(qi[element]) + flow * delta, 0.0, 100.0)
	heat = max(0.0, heat - 4.0 * delta)


func _apply_pressure(delta: float) -> void:
	enemy.pressure = min(100.0, float(enemy.pressure) + 1.6 * delta)
	var pressure_damage: float = max(0.0, float(enemy.pressure) - float(player.guard) * 0.7) * 0.018 * delta
	if pressure_damage > 0.0:
		player.hp -= pressure_damage
	if heat > 70.0:
		player.hp -= (heat - 70.0) * 0.025 * delta
		pollution_gain += int((heat - 70.0) * delta * 0.015)


func _melee_attack() -> void:
	if float(player.attack_cd) > 0.0:
		return
	player.attack_cd = 0.32
	var target_dir: Vector2 = _aim_direction()
	player.facing = target_dir
	var reach: float = 72.0
	var angle_ok: bool = abs(target_dir.angle_to(enemy.pos - player.pos)) < 0.95
	slash_arcs.append({"pos": player.pos, "dir": target_dir, "life": 0.16, "reach": reach})
	if player.pos.distance_to(enemy.pos) < reach + ENEMY_RADIUS and angle_ok:
		_damage_enemy(13.0 + _affinity("金") * 0.06, "金")
		_gain_qi("金", 5.0)


func _cast_flying_sword() -> void:
	if float(player.sword_cd) > 0.0 or float(qi["金"]) < 14.0:
		return
	player.sword_cd = 0.65
	qi["金"] = float(qi["金"]) - 14.0
	var dir := _aim_direction()
	player.facing = dir
	projectiles.append({
		"pos": player.pos + dir * 24.0,
		"vel": dir * 520.0,
		"life": 1.4,
		"damage": 21.0 + _affinity("金") * 0.1,
		"radius": SWORD_RADIUS,
		"element": "金",
	})
	heat += 4.0


func _cast_element_spell() -> void:
	if float(player.spell_cd) > 0.0:
		return
	var cost := 18.0
	if float(qi[current_spell]) < cost:
		_float_text(player.pos, "%s气不足" % current_spell, Color(0.8, 0.8, 0.75))
		return
	player.spell_cd = 1.15
	qi[current_spell] = float(qi[current_spell]) - cost
	match current_spell:
		"木":
			player.hp = min(float(player.max_hp), float(player.hp) + 14.0 + _affinity("木") * 0.05)
			player.guard = min(100.0, float(player.guard) + 8.0)
			_damage_enemy(9.0, "木")
			_float_text(player.pos, "灵种回身", Color(0.66, 0.88, 0.6))
		"水":
			enemy.pressure = max(0.0, float(enemy.pressure) - 16.0)
			player.guard = min(100.0, float(player.guard) + 4.0)
			_float_text(enemy.pos, "灵压回流", Color(0.6, 0.86, 0.94))
		"火":
			_damage_enemy(34.0 + _affinity("火") * 0.12, "火")
			heat += 22.0
			heart_gain += 1
		"土":
			player.guard = min(100.0, float(player.guard) + 28.0)
			enemy.pressure = max(0.0, float(enemy.pressure) - 6.0)
			_float_text(player.pos, "镇域", Color(0.86, 0.78, 0.48))
		_:
			_damage_enemy(20.0 + _affinity(current_spell) * 0.1, current_spell)


func _demon_burst() -> void:
	if float(player.demon_cd) > 0.0:
		return
	player.demon_cd = 5.5
	heart_gain += 5
	karma_gain += 2
	heat += 30.0
	var dist: float = player.pos.distance_to(enemy.pos)
	if dist < 160.0:
		_damage_enemy(45.0 + float(context.get("heart_demon", 0)) * 0.18, "心魔")
	enemy.pressure += 8.0
	_float_text(player.pos, "心魔借力", Color(0.92, 0.42, 0.5))


func _dodge() -> void:
	if float(player.dodge_cd) > 0.0:
		return
	player.dodge_cd = 0.95
	player.invuln = 0.28
	var dir: Vector2 = player.facing
	if dir.length() <= 0.0:
		dir = Vector2.RIGHT
	afterimages.append({"pos": player.pos, "facing": player.facing, "life": 0.24})
	player.pos = _clamp_to_arena(player.pos + dir.normalized() * 92.0, PLAYER_RADIUS)


func _cycle_spell() -> void:
	var index := ["金", "木", "水", "火", "土"].find(current_spell)
	current_spell = ["金", "木", "水", "火", "土"][(index + 1) % 5]
	_float_text(player.pos, "当前术式：%s" % current_spell, Color(0.9, 0.84, 0.62))


func _damage_enemy(amount: float, element: String) -> void:
	var final := amount
	var enemy_data: Dictionary = context.get("enemy", {})
	if element == String(enemy_data.get("weak", "")):
		final *= 1.3
	elif element == String(enemy_data.get("resist", "")):
		final *= 0.65
	enemy.hp -= final
	enemy.hit_flash = 0.12
	cultivation_gain += int(final * 0.04)
	_float_text(enemy.pos + Vector2(rng.randf_range(-12, 12), -26), str(int(final)), _element_color(element))


func _damage_player(amount: float, source: String) -> void:
	if float(player.invuln) > 0.0:
		_float_text(player.pos, "避", Color(0.86, 0.9, 0.9))
		return
	var guarded: float = min(amount * 0.7, float(player.guard) * 0.2)
	player.guard = max(0.0, float(player.guard) - guarded)
	var final: float = max(1.0, amount - guarded)
	player.hp -= final
	player.hit_flash = 0.16
	_float_text(player.pos + Vector2(0, -30), "%s -%d" % [source, int(final)], Color(0.95, 0.45, 0.42))


func _check_end() -> void:
	if victory_sent:
		return
	if float(enemy.hp) <= 0.0:
		victory_sent = true
		running = false
		battle_finished.emit(true, _result_payload())
	elif float(player.hp) <= 0.0:
		victory_sent = true
		running = false
		battle_finished.emit(false, _result_payload())


func force_finish(victory: bool) -> void:
	if victory_sent:
		return
	victory_sent = true
	running = false
	battle_finished.emit(victory, _result_payload())


func _result_payload() -> Dictionary:
	return {
		"time": battle_time,
		"enemy": enemy.name,
		"pollution": pollution_gain + int(max(0.0, heat - 60.0) * 0.04),
		"heart": heart_gain,
		"karma": karma_gain,
		"cultivation": cultivation_gain,
		"stability_loss": int(max(0.0, float(player.max_hp) - float(player.hp)) * 0.16),
		"reward": context.get("enemy", {}).get("reward", "灵气残屑"),
	}


func _aim_direction() -> Vector2:
	var local_mouse: Vector2 = get_local_mouse_position()
	var dir: Vector2 = local_mouse - player.pos
	if dir.length() < 4.0:
		dir = player.facing
	return dir.normalized()


func _gain_qi(element: String, amount: float) -> void:
	qi[element] = clamp(float(qi[element]) + amount, 0.0, 100.0)


func _affinity(element: String) -> float:
	var elements: Dictionary = context.get("elements", {})
	return float(elements.get(element, 0))


func _dominant_element() -> String:
	var elements: Dictionary = context.get("elements", {})
	var best := "金"
	var best_value := -1.0
	for element in ["金", "木", "水", "火", "土"]:
		var value := float(elements.get(element, 0))
		if value > best_value:
			best = element
			best_value = value
	return best


func _clamp_to_arena(pos: Vector2, radius: float) -> Vector2:
	return Vector2(clamp(pos.x, radius, ARENA_SIZE.x - radius), clamp(pos.y, radius, ARENA_SIZE.y - radius))


func _inside_arena(pos: Vector2, margin: float) -> bool:
	return pos.x >= -margin and pos.y >= -margin and pos.x <= ARENA_SIZE.x + margin and pos.y <= ARENA_SIZE.y + margin


func _float_text(pos: Vector2, text: String, color: Color) -> void:
	floating_text.append({"pos": pos, "text": text, "color": color, "life": 0.8})


func _add_log(text: String) -> void:
	logs.push_front(text)
	if logs.size() > 6:
		logs.resize(6)


func _element_color(element: String) -> Color:
	match element:
		"金":
			return Color(0.86, 0.88, 0.82)
		"木":
			return Color(0.55, 0.86, 0.48)
		"水":
			return Color(0.52, 0.82, 0.95)
		"火":
			return Color(0.95, 0.42, 0.3)
		"土":
			return Color(0.86, 0.72, 0.38)
		_:
			return Color(0.9, 0.36, 0.55)


func _draw() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color(0.055, 0.07, 0.073, 0.96), true)
	var scale: float = min(size.x / ARENA_SIZE.x, size.y / ARENA_SIZE.y)
	var offset: Vector2 = (size - ARENA_SIZE * scale) * 0.5
	draw_set_transform(offset, 0.0, Vector2(scale, scale))
	_draw_arena()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_arena() -> void:
	draw_rect(Rect2(Vector2.ZERO, ARENA_SIZE), Color(0.08, 0.1, 0.095), true)
	for i in 7:
		var t := float(i) / 6.0
		draw_line(Vector2(0, ARENA_SIZE.y * t), Vector2(ARENA_SIZE.x, ARENA_SIZE.y * t), Color(0.35, 0.32, 0.22, 0.16), 1.0)
	for i in 11:
		var t := float(i) / 10.0
		draw_line(Vector2(ARENA_SIZE.x * t, 0), Vector2(ARENA_SIZE.x * t, ARENA_SIZE.y), Color(0.35, 0.32, 0.22, 0.12), 1.0)
	draw_circle(ARENA_SIZE * 0.5, 190.0, Color(0.62, 0.53, 0.28, 0.08))
	draw_arc(ARENA_SIZE * 0.5, 190.0, 0.0, TAU, 96, Color(0.78, 0.68, 0.38, 0.22), 2.0)
	_draw_entities()
	_draw_hud()


func _draw_entities() -> void:
	for bullet in enemy_bullets:
		draw_circle(bullet.pos, ENEMY_BULLET_RADIUS, Color(0.68, 0.18, 0.24, 0.88))
	for projectile in projectiles:
		var sword_size := Vector2(58, 16)
		draw_set_transform(projectile.pos, projectile.vel.angle(), Vector2.ONE)
		draw_texture_rect(SWORD_TEX, Rect2(-sword_size * 0.5, sword_size), false, _element_color(projectile.element))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_line(projectile.pos - projectile.vel.normalized() * 28.0, projectile.pos, _element_color(projectile.element), 2.0)
	for arc in slash_arcs:
		var color := Color(0.92, 0.88, 0.7, max(0.0, float(arc.life) / 0.16))
		draw_arc(arc.pos, float(arc.reach), arc.dir.angle() - 0.7, arc.dir.angle() + 0.7, 18, color, 5.0)
	for image in afterimages:
		var alpha: float = max(0.0, float(image.life) / 0.24) * 0.42
		var image_size := Vector2(72, 72)
		draw_texture_rect(PLAYER_TEX, Rect2(image.pos - image_size * 0.5, image_size), false, Color(0.82, 0.92, 0.9, alpha))
	draw_circle(enemy.pos, ENEMY_RADIUS + 12.0, Color(0.55, 0.16, 0.2, 0.18))
	var enemy_size := Vector2(86, 86) * (1.0 + 0.04 * sin(battle_time * 7.0))
	var enemy_mod := Color(1.0, 0.72, 0.68, 1.0) if float(enemy.hit_flash) > 0.0 else Color.WHITE
	draw_texture_rect(ENEMY_TEX, Rect2(enemy.pos - enemy_size * 0.5, enemy_size), false, enemy_mod)
	draw_arc(enemy.pos, ENEMY_RADIUS + 8.0, 0.0, TAU, 42, Color(0.82, 0.35, 0.32, 0.65), 2.0)
	draw_circle(player.pos, PLAYER_RADIUS + float(player.guard) * 0.09, Color(0.68, 0.64, 0.38, 0.16))
	var player_size := Vector2(72, 72) * (1.0 + 0.03 * sin(battle_time * 10.0))
	var player_mod := Color.WHITE
	if float(player.hit_flash) > 0.0:
		player_mod = Color(1.0, 0.74, 0.68, 1.0)
	elif float(player.invuln) > 0.0:
		player_mod = Color(0.82, 0.96, 0.94, 0.78)
	draw_texture_rect(PLAYER_TEX, Rect2(player.pos - player_size * 0.5, player_size), false, player_mod)
	draw_line(player.pos, player.pos + player.facing.normalized() * 28.0, Color(0.94, 0.86, 0.62), 3.0)
	for item in floating_text:
		draw_string(ThemeDB.fallback_font, item.pos, item.text, HORIZONTAL_ALIGNMENT_CENTER, -1, 15, item.color)


func _draw_hud() -> void:
	_draw_bar(Vector2(26, 24), Vector2(260, 14), float(player.hp) / float(player.max_hp), Color(0.64, 0.84, 0.72), "道基")
	_draw_bar(Vector2(26, 44), Vector2(260, 10), float(player.guard) / 100.0, Color(0.78, 0.68, 0.38), "守势")
	_draw_bar(Vector2(ARENA_SIZE.x - 306, 24), Vector2(280, 14), float(enemy.hp) / float(enemy.max_hp), Color(0.82, 0.32, 0.28), enemy.name)
	_draw_bar(Vector2(ARENA_SIZE.x - 306, 44), Vector2(280, 10), float(enemy.pressure) / 100.0, Color(0.75, 0.24, 0.4), "灵压")
	var x := 28.0
	for element in ["金", "木", "水", "火", "土"]:
		_draw_bar(Vector2(x, ARENA_SIZE.y - 34), Vector2(88, 9), float(qi[element]) / 100.0, _element_color(element), element)
		x += 100.0
	_draw_bar(Vector2(ARENA_SIZE.x - 214, ARENA_SIZE.y - 34), Vector2(188, 9), heat / 100.0, Color(0.9, 0.42, 0.28), "失衡")
	var log_y := 82.0
	for line in logs:
		draw_string(ThemeDB.fallback_font, Vector2(28, log_y), line, HORIZONTAL_ALIGNMENT_LEFT, 560, 14, Color(0.82, 0.82, 0.74, 0.82))
		log_y += 18.0
	draw_string(ThemeDB.fallback_font, Vector2(28, ARENA_SIZE.y - 56), "Q切换:%s  E施术  左键斩击  右键飞剑  空格闪避  R心魔" % current_spell, HORIZONTAL_ALIGNMENT_LEFT, 620, 15, Color(0.9, 0.86, 0.68))


func _draw_bar(pos: Vector2, bar_size: Vector2, ratio: float, color: Color, label: String) -> void:
	draw_rect(Rect2(pos, bar_size), Color(0.02, 0.025, 0.026, 0.82), true)
	draw_rect(Rect2(pos, Vector2(bar_size.x * clamp(ratio, 0.0, 1.0), bar_size.y)), color, true)
	draw_rect(Rect2(pos, bar_size), Color(0.72, 0.66, 0.42, 0.42), false, 1.0)
	draw_string(ThemeDB.fallback_font, pos + Vector2(0, -3), label, HORIZONTAL_ALIGNMENT_LEFT, bar_size.x, 12, Color(0.82, 0.8, 0.68))
