extends RefCounted
## Research values, not final balance. Physical material handling follows in unit 2.
const DESIGNATION_LIMIT = 32
const RETRY_SECONDS = 2.0
const PRIORITIES = {"build":2,"gather":1,"collect":2,"other":3,"haul":3}
const LABELS = {"build":"建築","gather":"採集","collect":"回収","other":"その他","haul":"運搬"}
const PAGE_SIZE = 10

const CARRY_CAPACITY = 8
const STORAGE_CAPACITY = 40
const SATIETY_MAX = 100.0
const EAT_THRESHOLD = 30.0
const HUNGER_PER_SECOND = 0.2
const MEAL_GAIN = 45.0
const EAT_SECONDS = 2.0
const HUMAN_FOOD = ["mushroom","egg"]
const STARTING_FOOD = 4
