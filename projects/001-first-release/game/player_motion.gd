extends CharacterBody3D
## The playable character sweeps a volume against the actual level geometry.
## Model-only route estimates deliberately do not replace this integration path.
const RADIUS := .38
const HEIGHT := 2.1
var world: Node3D
var contacts: Array[Vector3] = []
var contact_bodies: Array[Object] = []


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = RADIUS
	capsule.height = HEIGHT
	shape.shape = capsule
	shape.position.y = HEIGHT * .5
	add_child(shape)


func resolve(model, start: Vector3, destination: Vector3) -> Dictionary:
	world.discoveries.set_enabled(model.config.discovery_enabled)
	world.sync_platforms(model.platforms)
	global_position = start
	contacts.clear()
	contact_bodies.clear()
	var remaining := destination - start
	var ground := -1
	var supported := false
	var walkable_only := true
	var result_velocity: Vector3 = model.velocity
	# Swept movement, not a post-move overlap test: thin walls block fast motion.
	for iteration in range(6):
		if remaining.length_squared() < .00000001:
			break
		var hit := move_and_collide(remaining, false, .002, true, 4)
		if hit == null:
			break
		remaining = hit.get_remainder()
		for contact in range(hit.get_collision_count()):
			var normal := hit.get_normal(contact)
			walkable_only = walkable_only and normal.y > .65
			contacts.append(normal)
			contact_bodies.append(hit.get_collider(contact))
			if normal.y > .65 and model.velocity.y <= 0:
				supported = true
				ground = hit.get_collider(contact).get_meta("platform", -1)
			if remaining.dot(normal) < 0:
				remaining = remaining.slide(normal)
			if result_velocity.dot(normal) < 0:
				result_velocity = result_velocity.slide(normal)
	# Keep walking on shallow slopes without snapping upwards through undersides.
	if model.velocity.y <= 0:
		var support := move_and_collide(Vector3.DOWN * .12, true, .002, false, 4)
		if support != null and support.get_normal().y > .65:
			supported = true
			contacts.append(support.get_normal())
			contact_bodies.append(support.get_collider())
			ground = support.get_collider().get_meta("platform", -1)
			if model.standing:
				move_and_collide(Vector3.DOWN * .12, false, .002)
			result_velocity.y = 0
	# Repeatedly projecting the stored horizontal velocity onto an uphill plane
	# ate the player's input every tick. Keep intent only while walking on ground;
	# any wall/ceiling contact still retains its blocked velocity. Movement itself
	# remains swept against every surface, including the ramp and its edge.
	if supported and model.standing and walkable_only and model.velocity.y <= 0:
		result_velocity = Vector3(model.velocity.x, 0, model.velocity.z)
	return {
		"position": global_position,
		"velocity": result_velocity,
		"grounded": ground,
		"terrain_grounded": supported and ground < 0
	}
