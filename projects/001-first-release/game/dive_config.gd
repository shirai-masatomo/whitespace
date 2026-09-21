extends Resource
## Speeds: metres/second; acceleration: metres/second squared; oxygen: points.

@export var goal_depth: float = 680.0
@export var sink_speed: float = 5.0
@export var fast_sink_speed: float = 15.0
@export var brake_sink_speed: float = 2.0
@export var vertical_acceleration: float = 12.0
@export var horizontal_speed: float = 7.0
@export var water_acceleration: float = 10.0
@export var platform_acceleration: float = 22.0
@export var oxygen_capacity: float = 100.0
@export var oxygen_consumption: float = 4.0
@export var fast_oxygen_multiplier: float = 2.5
@export var ascent_speed: float = 6.0
@export var air_gravity: float = 9.8
@export var oxygen_radius: float = 3.5
@export var emergency_speed: float = 32.0
@export_range(1.0, 10.0, .1) var rescue_max_seconds: float = 3.5
@export var rescue_clearance: float = 3.0
@export var min_setback: float = 2.0
@export var missed_goal_depth: float = 730.0
@export var ocean_extent: float = 500.0

@export var jelly_push: float = 4.5
@export var jelly_cooldown: float = 3.0

@export var current_strength: float = 1.0
@export var discovery_enabled: bool = true
@export var bubble_lift: float = 8.0
@export var discovery_stream_speed: float = 12.0
@export var cove_stream_speed: float = 24.0
@export var cavern_current_enabled: bool = true
@export var cavern_updraft_speed: float = 9.0
