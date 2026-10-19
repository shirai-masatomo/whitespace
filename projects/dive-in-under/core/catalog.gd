extends RefCounted
## File/validation boundary, separate from the pure combat core.
const PATH := "res://data/v1/balance.json"

static func load_data(path: String = PATH) -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("Invalid data JSON: " + path)
		return {}
	if parsed.has("enemy_pack"):
		if parsed.enemy_pack!="res://data/v1/area1-enemies.json":
			push_error("Unsupported enemy pack"); return {}
		var pack=JSON.parse_string(FileAccess.get_file_as_string(parsed.enemy_pack))
		if not pack is Dictionary or pack.get("schema_version")!=1 or not pack.get("enemies") is Dictionary or not pack.get("drops") is Dictionary:
			push_error("Invalid enemy pack"); return {}
		if not parsed.get("enemies") is Dictionary: push_error("Invalid enemy catalog"); return {}
		for id in pack.enemies:
			if parsed.enemies.has(id): push_error("Enemy pack overwrites existing ID"); return {}
			parsed.enemies[id]=pack.enemies[id]
		parsed.enemy_drops=pack.drops
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
	if not data.rules is Dictionary or not data.enemies is Dictionary or not data.floors is Array or not data.hero_fixture is Dictionary:
		return "Invalid catalog container type"
	for key in ["max_rounds", "hit_chance", "critical_chance", "critical_multiplier", "variance_min", "variance_max", "enemy_growth"]:
		if not data.rules.has(key):
			return "Missing rule: " + key
	for key in ["max_rounds", "hit_chance", "critical_chance", "critical_multiplier", "variance_min", "variance_max"]:
		if not numeric(data.rules[key]):
			return "Nonnumeric rule: " + key
	if data.rules.max_rounds != 50:
		return "COMBAT v0.1 requires a 50-round cap"
	if data.rules.hit_chance < 0 or data.rules.hit_chance > 1 or data.rules.critical_chance < 0 or data.rules.critical_chance > 1:
		return "Probability out of range"
	if data.rules.variance_min <= 0 or data.rules.variance_max < data.rules.variance_min or data.rules.critical_multiplier < 1:
		return "Invalid damage multipliers"
	if not data.rules.enemy_growth is Dictionary:
		return "Invalid growth container"
	for key in ["hp", "atk", "def_interval", "sp_interval", "exp", "gold"]:
		if not data.rules.enemy_growth.has(key) or not numeric(data.rules.enemy_growth[key]) or data.rules.enemy_growth[key] < 0:
			return "Invalid growth field: " + key
	if data.rules.enemy_growth.def_interval < 1 or data.rules.enemy_growth.sp_interval < 1:
		return "Growth intervals must be positive"
	if data.enemies.is_empty():
		return "Empty enemy catalog"
	for id in data.enemies:
		if not data.enemies[id] is Dictionary:
			return "Invalid enemy container"
		for key in ["name", "hp", "atk", "def", "spd", "sp", "exp", "gold"]:
			if not data.enemies[id].has(key):
				return "Missing enemy field: " + str(id) + "." + key
		for key in ["hp", "atk", "def", "spd", "sp", "exp", "gold"]:
			var value = data.enemies[id][key]
			if not numeric(value) or value < 0 or value > 1000000 or value != floorf(value):
				return "Invalid enemy stat: " + str(id) + "." + key
	var expected_floor := 1
	for floor_row in data.floors:
		if not floor_row is Dictionary:
			return "Invalid floor row"
		for key in ["from", "to", "encounters", "enemies", "levels"]:
			if not floor_row.has(key):
				return "Missing floor field: " + key
		if not numeric(floor_row.from) or not numeric(floor_row.to) or floor_row.from != expected_floor or floor_row.to < floor_row.from or floor_row.to > 10:
			return "Floors must cover 1..10 without gaps/overlaps"
		expected_floor = int(floor_row.to) + 1
		if not floor_row.enemies is Dictionary or not floor_row.encounters is Array or floor_row.encounters.size() != 3 or not floor_row.levels is Array or floor_row.levels.size() != 2:
			return "Invalid floor table shape"
		var total := 0
		var encounters := 0
		for weight in floor_row.encounters:
			if not numeric(weight) or weight < 0 or weight != floorf(weight):
				return "Invalid encounter weight"
			encounters += int(weight)
		if encounters != 100:
			return "Encounter weights must sum to 100"
		for id in floor_row.enemies:
			if not data.enemies.has(id):
				return "Unknown floor enemy: " + str(id)
			if not numeric(floor_row.enemies[id]) or floor_row.enemies[id] < 0 or floor_row.enemies[id] != floorf(floor_row.enemies[id]):
				return "Invalid enemy weight"
			total += int(floor_row.enemies[id])
		for level in floor_row.levels:
			if not numeric(level) or level != floorf(level) or level > 100:
				return "Invalid floor level"
		if total != 100 or floor_row.levels[0] < 1 or floor_row.levels[1] < floor_row.levels[0]:
			return "Invalid floor weights/levels"
	if expected_floor != 11:
		return "Floor catalog must end at 10"
	if not data.rules.get("skills",{}) is Dictionary: return "Invalid skills container"
	for id in data.rules.get("skills",{}):
		if not id in ["S102","S103","S104","S105"] or not data.rules.skills[id] is Dictionary: return "Unsupported skill definition"
		var skill: Dictionary=data.rules.skills[id]
		for key in ["sp_cost","duration_own_actions","cooldown_own_actions"]:
			if not numeric(skill.get(key)) or skill[key]<0 or skill[key]!=floorf(skill[key]): return "Invalid skill timing/cost"
		if skill.duration_own_actions<1: return "Invalid skill duration"
		if id=="S105":
			for key in ["hp_threshold","def_bonus"]:
				if not numeric(skill.get(key)) or skill[key]<0: return "Invalid S105 parameter"
			if skill.hp_threshold>1 or skill.duration_own_actions!=1 or skill.cooldown_own_actions!=3 or skill.sp_cost!=3: return "Invalid S105 timing/cost"
		else:
			for key in ["damage_multiplier","apply_chance","potency"]:
				if not numeric(skill.get(key)) or skill[key]<0: return "Invalid status skill parameter"
			if skill.apply_chance>1 or (id=="S103" and skill.potency>1): return "Invalid status probability"
			if skill.get("status_id")!={"S102":"poison","S103":"blind","S104":"paralysis"}[id] or skill.get("stack_rule")!="replace": return "Invalid status contract"
	for id in data.enemies:
		if not data.enemies[id].get("skills",[]) is Array: return "Invalid enemy skills"
		for skill_id in data.enemies[id].get("skills",[]):
			if not data.rules.get("skills",{}).has(skill_id): return "Unknown enemy skill"
	if data.has("legacy_floors"):
		var legacy:=data.duplicate(true)
		legacy.floors=legacy.legacy_floors; legacy.erase("legacy_floors")
		var problem:=validate(legacy)
		if problem!="": return "Invalid legacy floor table: "+problem
	return validate_hero(data.hero_fixture)

static func numeric(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value))

static func validate_hero(hero: Dictionary) -> String:
	for key in ["level", "max_hp", "hp", "atk", "def", "spd", "max_sp", "sp"]:
		if not hero.has(key) or not numeric(hero[key]):
			return "Missing/nonnumeric hero stat: " + key
		if hero[key] < 0 or hero[key] > 1000000 or hero[key] != floorf(hero[key]):
			return "Invalid hero stat: " + key
	if hero.max_hp < 1 or hero.hp > hero.max_hp or hero.sp > hero.max_sp or hero.level < 1:
		return "Invalid hero HP/SP/level range"
	if not hero.get("skills",[]) is Array: return "Invalid hero skills"
	var seen: Array=[]
	for id in hero.get("skills",[]):
		if not id in ["S102","S103","S104","S105"] or id in seen: return "Unsupported/duplicate hero skill"
		seen.append(id)
	return ""
