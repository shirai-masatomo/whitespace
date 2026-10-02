extends RefCounted
## Fixed design values and explicitly provisional tuning. Seconds are converted only at the simulation boundary.
const SHIBA = {"attack_power": 10, "max_hp": 40, "attack_seconds": 1.2, "speed": 2.0, "rescue_multiplier": 1.5}
const KIDNAPPER = {"max_hp": 50, "attack_power": 5, "object_attack_power": 2,
	"counter_seconds": 0.5, "counter_duration": 4.0, "counter_cooldown": 2.0}
# Gate cost/HP/time, repair coefficient, interruption refund and animal HP are PROVISIONAL.
const BUILD = {"wall": {"cost": 20, "hp": 8, "seconds": 1.0},
	"build_gate": {"cost": 30, "hp": 6, "seconds": 1.0}}
const REPAIR_FACTOR = 1.0
const INTERRUPT_REFUND = 0.5
const SOIL_PACK = 50
