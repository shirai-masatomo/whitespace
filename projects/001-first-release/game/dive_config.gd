extends Resource
## Tuning data, not a fixed specification. Units: metres, seconds, pressure points.

@export var goal_depth: float = 300.0
@export var descend_speed: float = 14.0
@export var ascend_speed: float = 10.0
@export var horizontal_speed: float = 9.0
@export var sprint_multiplier: float = 1.65
@export var acceleration: float = 24.0
@export var pressure_per_metre: float = 0.9
@export var speed_penalty: float = 0.035
@export var recovery_per_second: float = 13.0
@export var pressure_limit: float = 100.0
@export var warning_pressure: float = 70.0
@export var setback_metres: float = 55.0
@export var forced_ascent_speed: float = 20.0
@export var recovery_pressure: float = 20.0
@export var stage_radius: float = 23.0
