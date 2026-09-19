extends Node3D

const Model = preload("res://game/dive_model.gd")
const World = preload("res://game/world.gd")
const Hud = preload("res://game/hud.gd")
const TUNING = preload("res://game/default_config.tres")

var model = Model.new(TUNING)
var camera: Camera3D
var hud: Control
var swimmer := Vector3(0.0, 0.0, 8.0)
var yaw: float = 0.0
var pitch: float = -0.42
var started: bool = false
var paused: bool = false
var was_complete: bool = false


func _ready() -> void:
	_setup_inputs()
	var world := Node3D.new()
	world.set_script(World)
	add_child(world)
	camera = Camera3D.new()
	camera.far = 160.0
	camera.fov = 78.0
	add_child(camera)
	camera.current = true
	var light := OmniLight3D.new()
	light.light_color = Color(0.45, 0.9, 1.0)
	light.light_energy = 2.0
	light.omni_range = 24.0
	camera.add_child(light)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	hud = Control.new()
	hud.set_script(Hud)
	hud.game = self
	canvas.add_child(hud)
	_update_camera()


func _setup_inputs() -> void:
	var bindings := {
		"dive": [KEY_E],
		"rise": [KEY_Q],
		"surge": [KEY_SHIFT],
		"forward": [KEY_W, KEY_UP],
		"back": [KEY_S, KEY_DOWN],
		"left": [KEY_A, KEY_LEFT],
		"right": [KEY_D, KEY_RIGHT]
	}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			for key in bindings[action]:
				var event := InputEventKey.new()
				event.physical_keycode = key
				InputMap.action_add_event(action, event)


func begin() -> void:
	started = true
	paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	hud.sync_buttons()


func restart() -> void:
	model.reset()
	swimmer = Vector3(0.0, 0.0, 8.0)
	yaw = 0.0
	pitch = -0.42
	was_complete = false
	begin()


func toggle_pause() -> void:
	if not started or model.mode == Model.Mode.COMPLETE:
		return
	paused = not paused
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if paused else Input.MOUSE_MODE_CAPTURED
	hud.sync_buttons()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and started and not paused:
		if model.mode != Model.Mode.COMPLETE:
			toggle_pause()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			toggle_pause()
		elif event.keycode == KEY_ENTER and (not started or paused):
			begin()
	if (
		event is InputEventMouseMotion
		and started
		and not paused
		and model.mode != Model.Mode.COMPLETE
	):
		yaw -= event.relative.x * 0.0025
		pitch = clampf(pitch - event.relative.y * 0.0025, -1.4, 1.35)


func _physics_process(delta: float) -> void:
	if started and not paused:
		var axis := Input.get_vector("left", "right", "forward", "back")
		advance(delta, axis, Input.get_axis("rise", "dive"), Input.is_action_pressed("surge"))
	_update_camera()
	hud.queue_redraw()


func advance(delta: float, axis: Vector2, vertical: float, sprint: bool) -> void:
	model.step(delta, vertical, sprint)
	if model.mode != Model.Mode.COMPLETE:
		var horizontal := Vector3(axis.x, 0.0, axis.y).rotated(Vector3.UP, yaw)
		swimmer += horizontal.limit_length() * TUNING.horizontal_speed * delta
		var position_2d := Vector2(swimmer.x, swimmer.z).limit_length(TUNING.stage_radius)
		swimmer.x = position_2d.x
		swimmer.z = position_2d.y
	swimmer.y = -model.depth
	if model.mode == Model.Mode.COMPLETE and not was_complete:
		was_complete = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		hud.sync_buttons()


func _update_camera() -> void:
	camera.position = swimmer
	camera.rotation = Vector3(pitch, yaw, 0.0)
