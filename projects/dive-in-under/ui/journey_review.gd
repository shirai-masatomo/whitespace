extends RefCounted
static func run(game: Control) -> void:
	game.smoke_check(false,"Journey GUI verification is not enabled until the core checkpoint passes")
	game.get_tree().quit(2)
