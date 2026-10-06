extends "res://game/world.gd"
## Pre-story, open-ground fixture for isolated construction contract tests.
## World-story integration and normal gameplay use world.gd directly.
func _init(data: Dictionary={}, seed_number: int=17, stage_override: Dictionary={}):
	var source=new_campaign() if data.is_empty() else data.duplicate(true)
	if not source.has("world_story"):
		source.world_story={"version":1,"intro_seen":true,"investigated":false,"radio":false,"prayed_day":0,"next_prayer_id":1,"prayers":[],"events":[],"news":[],"miracles":[],"cleared":[],"trees":[],"hidden":{"security":0,"economy":0,"disease":0,"anomaly":0,"recognition":0,"karma":0},"idol":{},"defeat_reason":""}
	super(source,seed_number,stage_override)
