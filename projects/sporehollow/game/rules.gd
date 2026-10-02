extends RefCounted
## Fixed design values and explicitly provisional tuning. Seconds are converted only at the simulation boundary.
const SHIBA = {"attack_power": 10, "max_hp": 40, "attack_seconds": 1.2, "speed": 2.0, "rescue_multiplier": 1.5, "detection_range": 4}
const BARK = {"cooldown": 6.0, "range": 4, "stop_seconds": 1.0}
const NATURE = {"interval": 4.0, "mushroom_chance": 0.2, "limit": 16, "weed_gold": 1, "mushroom_hp": 5}
const REST = {"seconds": 5.0, "kennel_seconds": 1.0, "nearby": 6, "auto_hp_fraction": 0.5}
const KIDNAPPER = {"max_hp": 50, "attack_power": 5, "object_attack_power": 2,
	"counter_seconds": 1.0, "counter_duration": 4.0, "counter_cooldown": 2.0}
# Gate cost/HP/time, repair coefficient, interruption refund and animal HP are PROVISIONAL.
const BUILD = {"wall": {"cost": 10, "hp": 8, "seconds": 1.0},
	"build_gate": {"cost": 30, "hp": 6, "seconds": 1.0},
	"kennel": {"cost": 30, "hp": 12, "seconds": 2.0}} # Kennel construction values are provisional.
const REPAIR_FACTOR = 1.0
const INTERRUPT_REFUND = 0.5
const DISMANTLE_REFUND = 0.8 # Provisional: floor each facility's remaining-durability refund.
const SOIL_PACK = 50

const LOW_HP_FRACTION = 0.30 # Provisional visual-warning threshold.
# Lv1 prototype only: weights and cadence are tuning, not fixed game rules.
const AI = {"decision_min": 0.6, "decision_max": 1.4, "randomness": 1.0,
	"rescue_randomness": 0.12, "log_limit": 96,
	"dog": {"engage": 0.76, "watch": 0.16, "reposition": 0.08},
	"raider": {"advance": 0.76, "hesitate": 0.10, "detour": 0.14},
	"counter": {"counter": 0.80, "hesitate": 0.10, "resume": 0.10}}
