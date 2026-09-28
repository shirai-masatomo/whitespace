extends Node
## Physical and sensory landmarks share the editor-authored positions.

var game: Node2D
var solids: Dictionary = {}
var stage := 0
var chest_open := false
var tentacle_contact := false


func _ready() -> void:
	for marker in game.markers():
		if marker.kind not in ["rock", "jelly"]:
			continue
		var body := AnimatableBody2D.new()
		body.sync_to_physics = false
		var collision := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = marker.extent * 2
		collision.shape = box
		body.add_child(collision)
		body.transform = marker.global_transform
		game.add_child(body)
		solids[marker] = body


func update(time: float) -> void:
	for marker in game.markers("chest"):
		if game.player.position.distance_to(marker.global_position) < 96:
			if not chest_open:
				game.say("玉手箱から、星のような泡があふれた")
			chest_open = true
	for marker in solids:
		solids[marker].transform = marker.global_transform
		if marker.kind == "jelly":
			solids[marker].position += marker.travel * sin(time * 0.7)
	var depth: int = game.depth()
	if depth > 590:
		stage = maxi(stage, 1)
	if depth > 616:
		stage = maxi(stage, 2)
	if depth > 650:
		stage = maxi(stage, 3)


func current_at(point: Vector2) -> Vector2:
	var total := Vector2.ZERO
	for marker in game.markers("current"):
		var local: Vector2 = marker.to_local(point)
		if Rect2(-marker.extent, marker.extent * 2).has_point(local):
			var strength := 1.0 - 0.35 * absf(local.x / marker.extent.x)
			total += marker.global_transform.basis_xform(marker.flow) * strength
	# A passing arm makes a readable, brief surge; it does not trap or damage.
	tentacle_contact = false
	if stage >= 2:
		var octopus = game.markers("octopus")[0]
		var arm: Vector2 = octopus.global_position + Vector2(-260, -170 + sin(game.clock) * 40)
		if point.distance_to(arm) < 95:
			total += Vector2(-65, -28)
			tentacle_contact = true
	return total


func air_at(point: Vector2) -> bool:
	for marker in game.markers("air"):
		if Rect2(-marker.extent, marker.extent * 2).has_point(marker.to_local(point)):
			return true
	return false


func position_of(marker: Node2D) -> Vector2:
	if solids.has(marker):
		return solids[marker].global_position
	return marker.global_position
