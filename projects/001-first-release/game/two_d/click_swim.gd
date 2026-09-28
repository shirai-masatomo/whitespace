extends RefCounted
## Local click steering uses the same collision/oxygen step as keyboard swimming.
var active := false
var target := Vector2.ZERO
var best_distance := INF
var stalled := 0.0


func request(point: Vector2) -> void:
	target = point
	active = true
	best_distance = INF
	stalled = 0.0


func drive(game: Node2D, delta: float) -> void:
	if game.paused or game.complete or game.rescuing:
		active = false
		game.step(delta, 0, false, false)
		return
	var difference: Vector2 = target - game.player.position
	var distance := difference.length()
	if distance < 12:
		active = false
		game.step(delta, 0, false, false)
		return
	if distance < best_distance - 1:
		best_distance = distance
		stalled = 0
	else:
		stalled += delta
	if stalled > 0.9:
		active = false
		game.say("行き止まり。壁を避けて、次の場所をクリックしよう")
		game.step(delta, 0, false, false)
		return
	var vertical := clampf(difference.y * 3, -game.ASCEND, game.SINK)
	game.step(
		delta, clampf(difference.x * 4 / game.SWIM, -1, 1), difference.y < -18, false, vertical
	)
