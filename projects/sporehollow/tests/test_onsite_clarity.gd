extends SceneTree
func _initialize():call_deferred("run")
func run():
	var review=load("res://game/onsite_clarity_review.gd").new()
	root.add_child(review)
	await review.run()
