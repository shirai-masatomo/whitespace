extends RefCounted
## Rendering fixtures, not a normal new-game balance claim. Mutations occur only at setup.
const Farm=preload("res://game/world.gd")

static func create(kind: String="keeper_active"):
	var campaign=Farm.new_campaign();campaign.day=6
	var w=Farm.new(campaign,31).begin_day()
	w.story.intro_seen=true;w.day_seconds=600
	w.trees.clear();w.story.trees=[];w.natural.clear();w.structures.clear();w.floors.clear();w.field_items.clear();w.spawn_schedule.clear();w.refresh_indoor()
	for a in w.animals:a.placed=false
	w.keeper.pos=Vector2i(11,8);w.keeper.sleepiness=0
	if kind=="close_maid":
		spawn(w,"maid",w.keeper.pos+Vector2i(1,1))
	elif kind=="memory_blocked":
		w.keeper.pos=Vector2i(8,8)
		var e=spawn(w,"salaryman",Vector2i(5,8))
		w.RaiderAI.perceive(e,w)
		w.keeper.pos=Vector2i(22,13);w.trees[Vector2i(8,8)]="tree_a"
		w.RaiderAI.perceive(e,w)
	else:
		if kind=="keeper_hidden":w.keeper.hp=0;w.keeper.state="hidden_rest"
		for p in [Vector2i(14,8),Vector2i(14,9),Vector2i(13,10)]:spawn(w,"salaryman",p)
	return w

static func spawn(w,role: String,pos: Vector2i) -> Dictionary:
	w.spawn_enemy({"role":role,"entry":w.entries[0],"lv":1,"debug_single":true})
	var e=w.enemies.back();e.pos=pos;e.path=[pos];e.arrival_complete=true;e.arrival_cleared=true
	return e
