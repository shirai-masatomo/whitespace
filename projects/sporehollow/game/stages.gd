extends RefCounted
## Seconds, not ticks: designer-editable invasion rhythms. Entrances use interior grid cells.
const STAGES = {
	1: {"first_attack_seconds": 10.0, "repeat_waves": false, "repeat_interval_seconds": 60.0,
		"time_limit_seconds": 180.0,
		"waves": [
			{"start_seconds": 0.0, "interval_seconds": 6.0, "jitter_seconds": 1.0, "count": 1, "role": "kidnapper", "entries": [[1, 5]], "lv": 1}]},
	2: {"first_attack_seconds": 14.0, "repeat_waves": false, "repeat_interval_seconds": 65.0,
		"time_limit_seconds": 200.0,
		"waves": [
			{"start_seconds": 0.0, "interval_seconds": 8.0, "jitter_seconds": 1.5, "count": 2, "role": "kidnapper", "entries": [[1, 5], [1, 12]], "lv": 1},
			{"start_seconds": 23.0, "interval_seconds": 5.0, "jitter_seconds": 1.5, "count": 3, "role": "kidnapper", "entries": [[1, 12], [1, 5]], "lv": 1}]}
}
