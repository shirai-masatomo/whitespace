extends "res://tests/test_navigation.gd"
## Image-shaped fixture: a resting maid at the border and two arrivals behind her.
func run():
	var cases=[]
	for role in ["salaryman","maid"]:
		var w=fresh();hidden(w)
		var entry=Vector2i(12,15);var edge=w.exit_for(entry);var outward=edge-entry
		for i in range(3):
			w.spawn_enemy({"role":role,"entry":entry,"lv":1,"debug_single":true})
			var e=w.enemies.back();e.pos=edge+outward*i;e.entry=entry;e.ai_accuracy=100
		var entered={};var trace=[];var first_move={};var longest={};var still={};var physical=true
		for i in range(240):
			w.tick+=1
			for e in w.enemies:
				var before=e.pos;w.Combat.recover(e,w.DT);w.enemy_step(e)
				if e.pos==before:still[e.id]=still.get(e.id,0)+1
				else:
					still[e.id]=0
					if not first_move.has(e.id):first_move[e.id]=w.tick*w.DT
				longest[e.id]=maxi(longest.get(e.id,0),still[e.id])
				if w.inside(e.pos) and not entered.has(e.id):entered[e.id]=w.tick*w.DT
				physical=physical and w.enemies.filter(func(other):return other.pos==e.pos).size()==1
			if i%8==0:trace.append({"seconds":w.tick*w.DT,"actors":w.enemies.map(func(e):return {"id":e.id,"pos":e.pos,"state":e.state,"stamina":e.stamina,"coffee_rest_until":e.get("coffee_rest_until",0),"coffee_served":e.get("coffee_served",[])})})
			if entered.size()==3:break
		check(entered.size()==3,"All three arrivals enter the field with an open entrance: "+role)
		check(physical,"Arrival queue never overlaps: "+role)
		cases.append({"role":role,"entered_seconds":entered,"first_move_seconds":first_move,"longest_still_seconds":longest.values().max()*w.DT,"trace":trace})
		print("FOREST_ENTRY ",role," entered=",entered," longest_still=",longest.values().max()*w.DT)
	for entry in [Vector2i(1,5),Vector2i(23,8),Vector2i(12,1),Vector2i(19,15)]:
		var w=fresh();hidden(w);var e=enemy(w,w.exit_for(entry),"maid");e.entry=entry
		var blocker=enemy(w,entry,"salaryman")
		for i in range(24):enemy_tick(w,e)
		check(e.pos!=blocker.pos,"Alternate routing never crosses the occupied entry actor: "+str(entry))
		blocker.done=true
		for i in range(16):enemy_tick(w,e)
		check(w.inside(e.pos) and e.pos!=entry and e.get("arrival_cleared",false),"Vacated entry resumes and is cleared: "+str(entry))
		check(e.get("coffee_rest_until",0)>w.tick,"Normal finite support rest still starts after entry")
		var departure=enemy(w,w.exit_for(entry),"maid");departure.entry=entry;departure.flee=true
		for i in range(8):enemy_tick(w,departure)
		check(departure.done,"Departing maid is not pulled back into arrival: "+str(entry))
	FileAccess.open("user://forest-entry.json",FileAccess.WRITE).store_string(JSON.stringify({"cases":cases,"checks":records,"scope":"Seed31; image-shaped border fixture, not the user's saved runtime state"},"  "))
	print("FOREST_ENTRY: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)
