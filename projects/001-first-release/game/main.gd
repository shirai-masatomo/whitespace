extends Node3D

const Model = preload("res://game/dive_model.gd")
const World = preload("res://game/world.gd")
const Hud = preload("res://game/hud.gd")
const Navigation = preload("res://game/navigation.gd")
const Sound = preload("res://game/ocean_audio.gd")
const Motion = preload("res://game/player_motion.gd")
const TUNING = preload("res://game/default_config.tres")

var model = Model.new(TUNING)
var camera: Camera3D
var world: Node3D
var avatar: Node3D
var bubble: MeshInstance3D
var hud: Control
var yaw: float = 0.0
var pitch: float = -0.25
var third_person: bool = true
var started: bool = false
var paused: bool = false
var was_complete: bool = false
var selected_target: int = 1
var ledge_view: float = 0.0
var automated_input: bool = "--smoke-test" in OS.get_cmdline_user_args()
var sound: Node
var motion: CharacterBody3D
var navigation_help := false


func _ready() -> void:
	# GPU test windows start unfocusable; only an ordinary game may take focus.
	if not automated_input and DisplayServer.get_name() != "headless":
		get_window().unfocusable = false
		get_window().grab_focus()
	_setup_inputs()
	sound = Sound.new()
	add_child(sound)
	world = Node3D.new()
	world.set_script(World)
	add_child(world)
	motion = Motion.new()
	motion.world = world
	add_child(motion)
	model.collision_motion = motion.resolve
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
	if "--smoke-test" in OS.get_cmdline_user_args():
		begin()


func _setup_inputs() -> void:
	var bindings := {
		"dive": [KEY_E],
		"ascend": [KEY_SPACE],
		"survey": [KEY_F],
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
	sound.suspend(false)
	if not automated_input:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	hud.sync_buttons()


func restart() -> void:
	model.reset()
	sound.reset(model)
	yaw = 0.0
	pitch = -0.25
	was_complete = false
	selected_target = 1
	navigation_help = false
	ledge_view = 0
	begin()


func toggle_pause() -> void:
	if not started or model.mode == Model.Mode.COMPLETE:
		return
	paused = not paused
	sound.suspend(paused)
	if not automated_input:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if paused else Input.MOUSE_MODE_CAPTURED
	hud.sync_buttons()


func _notification(what: int) -> void:
	if (
		not automated_input
		and what == NOTIFICATION_APPLICATION_FOCUS_OUT
		and started
		and not paused
	):
		if model.mode != Model.Mode.COMPLETE:
			toggle_pause()


func _unhandled_input(event: InputEvent) -> void:
	if automated_input:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			toggle_pause()
		elif event.keycode == KEY_ENTER and (not started or paused):
			begin()
		elif event.keycode == KEY_TAB and started and not paused:
			navigation_help = true
			cycle_target()
		elif event.keycode == KEY_H:
			navigation_help = not navigation_help
		elif event.keycode == KEY_M:
			sound.set_muted(not sound.muted)
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
		advance(delta, axis, Input.get_axis("brake", "dive"), Input.is_action_pressed("ascend"))
	_update_camera(delta)
	hud.queue_redraw()


func advance(delta: float, axis: Vector2, descent: float = 0.0, ascend: bool = false) -> void:
	model.collision_motion = motion.resolve
	var horizontal := Vector3(axis.x, 0.0, axis.y).rotated(Vector3.UP, yaw)
	model.step(delta, Vector2(horizontal.x, horizontal.z), descent, ascend)
	sound.observe(model, delta)
	if model.mode == Model.Mode.COMPLETE and not was_complete:
		was_complete = true
		if not automated_input:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		hud.sync_buttons()


func _update_camera(delta: float = 1.0) -> void:
	world.sync_platforms(model.platforms)
	var focus: Vector3 = model.position + Vector3.UP * 1.4
	var look := Vector3(0, sin(pitch), -cos(pitch)).rotated(Vector3.UP, yaw)
	var desired: Vector3 = focus - look * 7.5 if third_person else focus
	var peek := 0.0
	if third_person and model.grounded >= 0 and model.mode == Model.Mode.DIVING:
		peek = smoothstep(.25, .8, -pitch)
	ledge_view = lerpf(ledge_view, peek, 1.0 - exp(-delta * 9))
	var heading := Vector3.FORWARD.rotated(Vector3.UP, yaw)
	if third_person:
		# Looking down leans over the edge while retaining the diver in frame.
		desired = desired.lerp(focus + heading * 9 + Vector3.UP * 26, ledge_view)
	if third_person:
		var query := PhysicsRayQueryParameters3D.create(focus, desired)
		query.collision_mask = 3
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			desired = hit.position + hit.normal * 0.4
	camera.position = desired
	camera.rotation = Vector3(pitch, yaw, 0)
	if third_person and ledge_view > .001:
		var direction: Vector3 = focus + heading * 11 - desired
		var peek_pitch := atan2(direction.y, Vector2(direction.x, direction.z).length())
		camera.rotation.x = lerpf(pitch, peek_pitch, ledge_view)
		var diver_direction := focus - desired
		var diver_pitch := atan2(diver_direction.y, diver_direction.dot(heading))
		camera.rotation.x = clampf(minf(camera.rotation.x, diver_pitch + .35), -1.48, 1.2)
	if started and Input.is_action_pressed("survey"):
		camera.position = model.position + Vector3.UP * 55
		# Keep the survey camera below the water surface near the starting shelf.
		if model.position.y < -1:
			camera.position.y = minf(camera.position.y, -0.5)
		camera.rotation = Vector3(-PI / 2, yaw, 0)
	world.update_life(model)
	avatar.animate(model)
	avatar.position = model.position
	if Vector2(model.velocity.x, model.velocity.z).length() > 0.3:
		avatar.rotation.y = atan2(-model.velocity.x, -model.velocity.z)
	avatar.visible = (
		(third_person or Input.is_action_pressed("survey")) and model.mode != Model.Mode.RETURNING
	)
	bubble.position = focus
	bubble.visible = model.mode == Model.Mode.RETURNING
	world.update_depth(camera.position.y)


func next_platform() -> int:
	var choices := Navigation.candidates(model)
	if choices.is_empty():
		return 9
	if not choices.has(selected_target):
		selected_target = choices[0]
	return selected_target


func cycle_target() -> void:
	var current := next_platform()
	var choices := Navigation.candidates(model)
	if not choices.is_empty():
		selected_target = choices[(choices.find(current) + 1) % choices.size()]
