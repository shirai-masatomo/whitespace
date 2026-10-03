extends "res://game/world.gd"
## Isolated rule fixtures: arrange actors/sites instantly to retain existing combat,
## economy and durability coverage. This is NOT the player action entry point.
## test_jobs.gd and visual.gd exercise the real day/night queue and travel rules.
func _init(data: Dictionary = {}, number: int = 17, override_config: Dictionary = {}):
	super(data, number, override_config)
	if campaign.night_ready:
		phase = "prepare"
		keeper.placed = false
		keeper.pos = Vector2i(19, 8)
		jobs.clear()
		keeper_path.clear()

func begin_night():
	if phase != "shop" or paused: return null
	persist_farm()
	var data = campaign.duplicate(true)
	data.night_ready = true
	data.morning_checkpoint = morning_checkpoint.duplicate(true)
	return get_script().new(data, seed_value, config)

func act(kind: String, p: Vector2i = Vector2i.ZERO, animal_id: int = -1) -> bool:
	var accepted = false
	if phase == "prepare":
		if kind == "place" and not keeper.placed and walkable(p) and not live_structure(p) and p not in entries and not field_items.any(func(item): return item.pos == p):
			keeper.pos = p
			keeper.placed = true
			phase = "defend"
			initial_positions = {"keeper": [p.x, p.y], "animals": []}
			accepted = true
	else: accepted = _execute_local(kind, p, animal_id)
	actions.append({"tick": tick, "kind": kind, "pos": [p.x, p.y], "accepted": accepted, "paused": paused, "animal_id": animal_id})
	return accepted

func construction_step():
	# Local completion rule is tested separately from the worker-distance guard.
	for p in structures:
		if structures[p].status == "building": advance_site(p)
