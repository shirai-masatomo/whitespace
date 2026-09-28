extends Node2D

const Terrain = preload("res://game/two_d/terrain.gd")
const Art = preload("res://game/two_d/art.gd")
const Encounters = preload("res://game/two_d/encounters.gd")
const Sound = preload("res://game/two_d/sound.gd")
const Interface = preload("res://game/two_d/interface.gd")
const SINK := 70.0
const DIVE := 190.0
const ASCEND := 130.0
const SWIM := 170.0
const OXYGEN_SECONDS := 65.0

var terrain: RefCounted
var layout: Node2D
var encounters: Node
var sound: Node
var player: CharacterBody2D
var camera: Camera2D
var art: Node2D
var rows: Dictionary = {}
var started := false
var paused := false
var complete := false
var automated := "--smoke-test" in OS.get_cmdline_user_args()
var oxygen := 100.0
var checkpoint := Terrain.SPAWN
var rescuing := false
var rescue_path: Array[Vector2] = []
var breadcrumbs: Array[Vector2] = []
var collected: Dictionary = {}
var stones := 0
var clock := 0.0
var mining_cooldown := 0.0
var facing := 1.0
var message := "岸から右へ進んで、海へ飛び込もう"
var message_time := 5.0


func _ready() -> void:
	get_window().title = "DIVE DIVE"
	layout = get_node("OceanLayout")
	terrain = Terrain.new(layout)
	if not automated and DisplayServer.get_name() != "headless":
		get_window().unfocusable = false
		get_window().grab_focus()
	for row in range(Terrain.HEIGHT):
		rebuild_row(row)
	player = CharacterBody2D.new()
	player.position = Terrain.SPAWN
	player.safe_margin = 0.2
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(14, 26)
	shape.shape = box
	player.add_child(shape)
	add_child(player)
	camera = Camera2D.new()
	camera.position = player.position + Vector2(0, 80)
	camera.zoom = Vector2(1.25, 1.25)
	camera.limit_left = 0
	camera.limit_right = Terrain.WIDTH * Terrain.TILE
	camera.limit_top = -220
	camera.limit_bottom = Terrain.HEIGHT * Terrain.TILE
	add_child(camera)
	art = Node2D.new()
	art.set_script(Art)
	art.game = self
	add_child(art)
	encounters = Encounters.new()
	encounters.game = self
	add_child(encounters)
	sound = Sound.new()
	add_child(sound)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var interface := Control.new()
	interface.set_script(Interface)
	interface.game = self
	canvas.add_child(interface)
	if automated:
		begin()
		print("DIVE DIVE 2D ready")


func rebuild_row(y: int) -> void:
	if rows.has(y):
		remove_child(rows[y])
		rows[y].queue_free()
	var body := StaticBody2D.new()
	rows[y] = body
	add_child(body)
	var x := 0
	while x < Terrain.WIDTH:
		if terrain.get_cell(Vector2i(x, y)) == 0:
			x += 1
			continue
		var first := x
		while x < Terrain.WIDTH and terrain.get_cell(Vector2i(x, y)) != 0:
			x += 1
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = Vector2((x - first) * Terrain.TILE, Terrain.TILE)
		shape.shape = box
		shape.position = Vector2((first + x) * Terrain.TILE * 0.5, (y + 0.5) * Terrain.TILE)
		body.add_child(shape)


func begin() -> void:
	started = true
	paused = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and started and not automated:
		paused = true


func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event.keycode == KEY_ENTER and not started:
		begin()
	elif event.keycode == KEY_ESCAPE and started:
		paused = not paused
	elif event.keycode == KEY_M:
		sound.muted = not sound.muted
	elif event.keycode == KEY_R and (paused or complete):
		get_tree().reload_current_scene()


func _physics_process(delta: float) -> void:
	if not paused:
		clock += delta
		encounters.update(clock)
	message_time = maxf(0, message_time - delta)
	mining_cooldown = maxf(0, mining_cooldown - delta)
	if started and not paused and not complete and not automated:
		var horizontal := float(Input.is_physical_key_pressed(KEY_D))
		horizontal += float(Input.is_physical_key_pressed(KEY_RIGHT))
		horizontal -= float(Input.is_physical_key_pressed(KEY_A))
		horizontal -= float(Input.is_physical_key_pressed(KEY_LEFT))
		step(
			delta,
			clampf(horizontal, -1, 1),
			Input.is_physical_key_pressed(KEY_SPACE),
			Input.is_physical_key_pressed(KEY_E)
		)
		if mining_cooldown <= 0 and not rescuing:
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				edit_tile(get_global_mouse_position(), false)
			elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
				edit_tile(get_global_mouse_position(), true)
	camera.position = camera.position.lerp(player.position + Vector2(0, 85), 1 - exp(-delta * 5))
	art.queue_redraw()
	sound.observe(self, delta)


func step(delta: float, horizontal: float, ascend: bool, dive: bool) -> void:
	if complete or paused:
		return
	if rescuing:
		advance_rescue(delta)
		return
	var underwater: bool = (
		player.position.y > Terrain.SURFACE + 8 and not encounters.air_at(player.position)
	)
	var target_y := SINK
	if ascend:
		target_y = -ASCEND
	elif dive:
		target_y = DIVE
	if underwater:
		player.velocity.y = move_toward(player.velocity.y, target_y, 550 * delta)
	else:
		player.velocity.y += 650 * delta
		if ascend and player.is_on_floor():
			player.velocity.y = -260
	player.velocity.x = move_toward(player.velocity.x, horizontal * SWIM, 800 * delta)
	if absf(horizontal) > 0.1:
		facing = signf(horizontal)
	var flow: Vector2 = encounters.current_at(player.position) if underwater else Vector2.ZERO
	player.velocity += flow
	player.move_and_slide()
	# The current is a field, not cumulative acceleration.
	player.velocity -= flow
	if underwater:
		oxygen -= 100.0 / OXYGEN_SECONDS * delta * (2.5 if dive and not ascend else 1.0)
	else:
		oxygen = 100
		checkpoint = player.position
		breadcrumbs.clear()
	if breadcrumbs.is_empty() or breadcrumbs.back().distance_to(player.position) > 22:
		breadcrumbs.append(player.position)
	for garden in markers():
		if garden.kind not in ["algae", "orb", "bubble"]:
			continue
		var point: Vector2 = garden.global_position
		var refill_radius: float = garden.extent.x if garden.kind == "bubble" else 40.0
		if player.position.distance_to(point) < refill_radius:
			if oxygen < 92:
				say("酸素が満タンになった。ここからもう少し深くへ")
			oxygen = 100
			checkpoint = point
			breadcrumbs.clear()
	for index in range(markers("relic").size()):
		if not collected.has(index):
			if player.position.distance_to(markers("relic")[index].global_position) < 35:
				collected[index] = true
				say("海の記憶を発見！  %d / 3" % collected.size())
	if oxygen <= 0:
		start_rescue()
	if player.position.distance_to(goal_position()) < 55:
		complete = true


func start_rescue() -> void:
	rescuing = true
	oxygen = 0
	rescue_path.assign(breadcrumbs)
	say("酸素切れ！ 泡になって、最後の酸素藻へ戻ります")


func advance_rescue(delta: float) -> void:
	# Retrace the actual travelled passage, rather than crossing a cave wall.
	var travel := 650.0 * delta
	while travel > 0:
		var target: Vector2 = rescue_path.back() if not rescue_path.is_empty() else checkpoint
		var distance := player.position.distance_to(target)
		if distance > travel:
			player.position = player.position.move_toward(target, travel)
			return
		player.position = target
		travel -= distance
		if not rescue_path.is_empty():
			rescue_path.pop_back()
		else:
			rescuing = false
			oxygen = 100
			player.velocity = Vector2.ZERO
			breadcrumbs.clear()
			say("酸素回復。そのまま再挑戦できます")
			return


func edit_tile(point: Vector2, placing: bool) -> bool:
	if rescuing or complete or paused:
		return false
	var at: Vector2i = terrain.tile_at(point)
	var center := (Vector2(at) + Vector2(0.5, 0.5)) * Terrain.TILE
	if player.position.distance_to(center) > 115:
		return false
	if not terrain.visible_from(player.position, center, at):
		return false
	var value: int = terrain.get_cell(at)
	if placing:
		if value != 0 or stones <= 0 or not safe_to_place(center):
			return false
		terrain.set_cell(at, 2)
		stones -= 1
	else:
		if value < 2:
			if value == 1:
				say("硬い岩盤は掘れません。下へ続く隙間を探そう")
				mining_cooldown = 0.4
			return false
		terrain.set_cell(at, 0)
		stones += 1
	rebuild_row(at.y)
	mining_cooldown = 0.18
	return true


func safe_to_place(center: Vector2) -> bool:
	if center.distance_to(player.position) < 38 or center.distance_to(goal_position()) < 60:
		return false
	for garden in markers():
		if (
			garden.kind in ["algae", "orb", "air", "bubble"]
			and center.distance_to(garden.global_position) < 60
		):
			return false
	for crumb in breadcrumbs:
		if center.distance_to(crumb) < 32:
			return false
	return true


func say(text: String) -> void:
	message = text
	message_time = 4


func depth() -> int:
	return maxi(0, int((player.position.y - Terrain.SURFACE) / 12))


func markers(kind: String = "") -> Array:
	var result: Array = []
	for marker in layout.get_node("Landmarks").get_children():
		if kind.is_empty() or marker.kind == kind:
			result.append(marker)
	return result


func goal_position() -> Vector2:
	return markers("goal")[0].global_position
