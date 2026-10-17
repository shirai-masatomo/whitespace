extends RefCounted
## File/validation boundary, separate from the pure combat core.
const PATH := "res://data/v1/balance.json"

static func load_data(path: String = PATH) -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("Invalid data JSON: " + path)
		return {}
	var problem := validate(parsed)
	if not problem.is_empty():
		push_error(problem)
		return {}
	return parsed

static func validate(data: Dictionary) -> String:
	for key in ["schema_version", "data_version", "config_version", "rules", "enemies", "floors", "hero_fixture"]:
		if not data.has(key):
			return "Missing data field: " + key
	if data.schema_version != 1:
		return "Unsupported schema_version"
	for key in ["max_rounds", "hit_chance", "critical_chance", "critical_multiplier", "variance_min", "variance_max", "enemy_growth"]:
		if not data.rules.has(key):
			return "Missing rule: " + key
	if data.rules.max_rounds != 50:
		return "COMBAT v0.1 requires a 50-round cap"
	if data.rules.hit_chance < 0 or data.rules.hit_chance > 1 or data.rules.critical_chance < 0 or data.rules.critical_chance > 1:
		return "Probability out of range"
	for id in data.enemies:
		for key in ["name", "hp", "atk", "def", "spd", "sp", "exp", "gold"]:
			if not data.enemies[id].has(key):
				return "Missing enemy field: " + str(id) + "." + key
	for floor_row in data.floors:
		var total := 0
		for id in floor_row.enemies:
			if not data.enemies.has(id):
				return "Unknown floor enemy: " + str(id)
			total += int(floor_row.enemies[id])
		if total != 100 or floor_row.levels[0] < 1 or floor_row.levels[1] < floor_row.levels[0]:
			return "Invalid floor weights/levels"
	return ""
