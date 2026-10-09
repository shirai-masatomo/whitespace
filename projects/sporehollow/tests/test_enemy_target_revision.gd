extends "res://tests/test_ranch_content.gd"
## Seed31: solid idol surfaces, keeper capability and bounded lost-sight memory.
const T=P.Targets
var evidence=[]
func hidden(w):
	w.keeper.hp=0;w.keeper.state="hidden_rest"
func run():
	# Same 2x2 idol, three screenshot-side contact cells. No animation is required to hit.
	for cell in [Vector2i(14,8),Vector2i(14,9),Vector2i(13,10)]:
		var w=open_world();hidden(w);var e=enemy(w,"salaryman",cell)
		var before=w.story.idol.hp
		for i in range(16):
			w.tick+=1;w.Combat.recover(e,w.DT);w.RaiderAI.perceive(e,w);P.enemy_step(w,e)
		evidence.append({"scenario":"idol_contact","start":str(cell),"end":str(e.pos),"damage":before-w.story.idol.hp,"state":e.state})
		check(w.story.idol.hp<before,"Each right/bottom idol contact attacks instead of waiting: "+str(cell))
		check(e.pos not in w.Story.idol_cells(w),"Enemy never enters the solid idol: "+str(cell))
	var w=open_world();w.keeper.pos=Vector2i(11,8)
	for role in D.ENEMY_ROWS.keys()+["doberman"]:
		var e=enemy(w,role,Vector2i(11,7));w.RaiderAI.perceive(e,w)
		var candidates=P.target_candidates(w,e)
		check(candidates.any(func(t):return t.kind=="keeper"),"Every archetype can select the visible active keeper: "+role)
		check(not candidates.any(func(t):return t.kind=="idol"),"Active keeper excludes ordinary idol targeting: "+role)
		var hp=w.story.idol.hp;P.strike(w,e,{"kind":"idol","id":-1,"pos":Vector2i(12,8)})
		check(w.story.idol.hp==hp,"Stale ordinary idol strike is rejected after recovery: "+role)
		w.enemies.clear()
	# Exact close range is eight adjacent cells; there is no chase or damage-history gate.
	for delta in [Vector2i.RIGHT,Vector2i(1,1)]:
		w=open_world();var e=enemy(w,"maid",w.keeper.pos+delta);var pos=w.keeper.pos;var hp=e.hp
		w.Life.step(w)
		check(e.hp==hp-w.Life.ATTACK and w.keeper.pos==pos,"Keeper initiates against nearby nonattacking maid without moving: "+str(delta))
	w=open_world();var e=enemy(w,"maid",w.keeper.pos+Vector2i(2,0));var pos=w.keeper.pos;var hp=e.hp
	for i in range(40):w.tick+=1;w.Life.step(w)
	check(e.hp==hp and w.keeper.pos==pos,"Keeper does not chase or strike an enemy two cells away")
	w=open_world();e=enemy(w,"maid",w.keeper.pos+Vector2i(1,1));w.trees[w.keeper.pos+Vector2i.RIGHT]="tree";hp=e.hp
	w.Life.step(w);check(e.hp==hp,"Diagonal close attack cannot pass an occluding corner")
	# An unseen current position cannot replace the remembered cell.
	w=open_world();e=enemy(w,"salaryman",Vector2i(5,8));w.keeper.pos=Vector2i(8,8);w.RaiderAI.perceive(e,w)
	w.keeper.pos=Vector2i(22,13);w.RaiderAI.perceive(e,w)
	check(w.RaiderAI.target(e,w)==Vector2i(8,8),"Lost sight follows the last observed cell, not the keeper's current position")
	w.trees[Vector2i(8,8)]="tree";var goal=w.RaiderAI.target(e,w)
	check(e.last_known_keeper_position==null and goal!=Vector2i(8,8),"Unreachable remembered cell is discarded for reachable exploration")
	w=open_world();e=enemy(w,"salaryman",Vector2i(5,8));e.can_see_keeper=false;e.last_known_keeper_position=Vector2i(8,8)
	goal=w.RaiderAI.target(e,w)
	for i in range(40):w.tick+=1;goal=w.RaiderAI.target(e,w)
	check(e.last_known_keeper_position==null,"No physical progress for eight seconds ends stale memory pursuit")
	w=open_world();e=enemy(w,"salaryman",Vector2i(5,8));e.can_see_keeper=false;e.last_known_keeper_position=e.pos
	goal=w.RaiderAI.target(e,w)
	check(e.last_known_keeper_position==null and goal!=e.pos,"Arriving at an empty remembered cell starts surrounding exploration")
	w=open_world();hidden(w);e=enemy(w,"salaryman",Vector2i(4,4));e.sight_range=0
	for p in [Vector2i(3,4),Vector2i(5,4),Vector2i(4,3),Vector2i(4,5)]:w.trees[p]="tree"
	check(w.RaiderAI.target(e,w)==e.pos,"No reachable exploration cell waits without teleporting")
	w.trees.erase(Vector2i(5,4));check(w.RaiderAI.target(e,w)!=e.pos,"Opening a route resumes exploration on the next decision")
	# Explicit statue roles keep their exceptional purpose with a healthy keeper.
	for role in ["idol_breaker","idol_extractor"]:
		w=open_world();e=enemy(w,role,Vector2i(11,8));var before=w.story.idol.hp
		w.Story.idol_enemy(w,e)
		check(w.story.idol.hp<before if role=="idol_breaker" else w.story.idol.carrier==e.id,"Explicit statue role retains its purpose: "+role)
	w=open_world();w.keeper.pos=Vector2i(22,13)
	var maid=enemy(w,"maid",Vector2i(7,8));var dancer=enemy(w,"dancer",Vector2i(10,8));var nearer=enemy(w,"salaryman",Vector2i(8,8))
	w.Content.maid_step(w,maid,true)
	check(maid.coffee_target==dancer.id,"Maid prefers nearby support-skill holder before nearer ordinary ally")
	maid.coffee_served=[dancer.id];w.Content.maid_step(w,maid,true)
	check(maid.coffee_target==nearer.id,"Maid proceeds to other recipient after supporting dancer")
	FileAccess.open("user://enemy-target-revision.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":records,"seed":31,"evidence":evidence},"  "))
	print("ENEMY_TARGET_REVISION: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)
