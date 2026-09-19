extends Node3D

const Model = preload("res://game/dive_model.gd")
const World = preload("res://game/world.gd")
const Hud = preload("res://game/hud.gd")
const TUNING = preload("res://game/default_config.tres")

var model = Model.new(TUNING)
var camera: Camera3D
var world: Node3D
var avatar: Node3D
var bubble: MeshInstance3D
var hud: Control
var yaw: float = 0.0
var pitch: float = -0.65
var third_person: bool = true
var started: bool = false
var paused: bool = false
var was_complete: bool = false


func _ready() -> void:
	_setup_inputs()
	world = Node3D.new()
	world.set_script(World)
	add_child(world)
	avatar = world.make_avatar()
	bubble = world.make_bubble()
	camera = Camera3D.new()
	camera.far = 1400.0
	camera.fov = 76.0
	add_child(camera)
	camera.current = true
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
		"brake": [KEY_Q],
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
	yaw = 0.0
	pitch = -0.65
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
		elif event.physical_keycode == KEY_V or event.keycode == KEY_V:
			third_person = not third_person
	if (
		event is InputEventMouseMotion
		and started
		and not paused
		and model.mode != Model.Mode.COMPLETE
	):
		yaw -= event.relative.x * 0.0025
		pitch = clampf(pitch - event.relative.y * 0.0025, -1.35, 1.2)


func _physics_process(delta: float) -> void:
	if started and not paused:
		var axis := Input.get_vector("left", "right", "forward", "back")
		advance(delta, axis, Input.get_axis("brake", "dive"))
	_update_camera()
	hud.queue_redraw()


func advance(delta: float, axis: Vector2, descent: float = 0.0) -> void:
	var horizontal := Vector3(axis.x, 0.0, axis.y).rotated(Vector3.UP, yaw)
	model.step(delta, Vector2(horizontal.x, horizontal.z), descent)
	if model.mode == Model.Mode.COMPLETE and not was_complete:
		was_complete = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		hud.sync_buttons()


func _update_camera() -> void:
	var focus: Vector3 = model.position + Vector3.UP * 1.4
	var look := Vector3(0, sin(pitch), -cos(pitch)).rotated(Vector3.UP, yaw)
	var desired: Vector3 = focus - look * 16.0 if third_person else focus
	if third_person:
		var query := PhysicsRayQueryParameters3D.create(focus, desired)
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			desired = hit.position + hit.normal * 0.4
	camera.position = desired
	camera.rotation = Vector3(pitch, yaw, 0)
	avatar.position = model.position
	if Vector2(model.velocity.x, model.velocity.z).length() > 0.3:
		avatar.rotation.y = atan2(-model.velocity.x, -model.velocity.z)
	avatar.visible = third_person and model.mode != Model.Mode.RETURNING
	bubble.position = focus
	bubble.visible = model.mode == Model.Mode.RETURNING
	world.update_depth(model.depth)


func next_platform() -> int:
	for index in range(model.platforms.size()):
		if -model.platforms[index].position.y > model.depth + 0.5:
			return index
	return model.platforms.size() - 1
