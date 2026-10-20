extends RefCounted
## Research values, not final balance. Physical material handling follows in unit 2.
const DESIGNATION_LIMIT = 100
const RETRY_SECONDS = 2.0
const PRIORITY_VERSION = 3
const ORDER = ["build","gather","collect","animal","other","haul"]
const PRIORITIES = {"build":3,"gather":2,"collect":3,"animal":4,"other":4,"haul":4}
const LABELS = {"build":"建築","gather":"採集","collect":"回収","animal":"動物","other":"その他","haul":"運搬"}
const PAGE_SIZE = 10

const CARRY_CAPACITY = 20
const STORAGE_CAPACITY = 40
const SATIETY_MAX = 100.0
const EAT_THRESHOLD = 30.0
const HUNGER_PER_SECOND = 0.2
const MEAL_GAIN = 45.0
const EAT_SECONDS = 2.0
const HUMAN_FOOD = ["stew","egg_meal","roast_meat","roast_mushroom","mushroom","egg","meat","milk"]
const STARTING_FOOD = 4

# One classification for scheduling, saved jobs and the designation list.
static func category(w,j) -> String:
	if w.BUILD.has(j.kind) or j.kind in ["repair","repair_floor","remove","remove_floor","gate"] or j.kind.begins_with("place_"):return "build"
	if j.kind in ["mine","clear_tree"] or (j.kind=="craft" and j.get("recipe")=="grow_mushroom"):return "gather"
	if j.kind=="haul":return "haul"
	if j.kind=="collect":return "gather" if w.natural.has(j.pos) else "collect"
	if j.kind in ["animal_order","milk","equip","slaughter","train"]:return "animal"
	return "other"
