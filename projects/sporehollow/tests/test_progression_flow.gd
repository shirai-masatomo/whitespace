extends "res://tests/test_progression.gd"
func run():
	var w=fresh();var e=enemy(w,"destroyer",Vector2i(8,8));w.animals[0].pos=Vector2i(2,2)
	var p=Vector2i(9,8)
	w.structures[p]={"id":98,"kind":"wall","hp":8,"max_hp":8,"armor":0,"status":"ready","open":false}
	e.target_weights={"keeper":0,"animal":0,"structure":1,"idol":0}
	check(P.target_candidates(w,e).size()==1,"Solid wall surface is a visible target")
	for i in range(8): w.tick=i;P.enemy_step(w,e)
	check(w.structures[p].status=="destroyed" and w.combat_log.size()==2,"Normal enemy step breaks soil wall with two timed hits")
	w=fresh();e=enemy(w,"animal_tamer",Vector2i(4,5));var hen=add(w,"hen",Vector2i(5,5));P.tame(w,e,hen)
	var path=[];var previous=hen.pos;var overlaps=false;var teleported=false
	for i in range(160):
		w.tick+=1;P.lead_out(w,e);P.tick(w)
		path.append({"tick":w.tick,"enemy":[e.pos.x,e.pos.y],"animal":[hen.pos.x,hen.pos.y]})
		if hen.placed and hen.pos==e.pos:overlaps=true
		if w.distance(previous,hen.pos)>1:teleported=true
		previous=hen.pos
		if e.done:break
	check(e.done and hen.get("lost",false),"Tamer physically crosses exterior boundary with animal")
	check(not overlaps and not teleported,"Abduction keeps distinct cells and one-cell animal steps")
	w=fresh();e=enemy(w,"doberman",Vector2i(8,8));P.enemy_hurt(w,e,999)
	check(e.get("dead",false) and not e.done and e.hp==0 and e.faction=="enemy","Enemy Doberman leaves the bounded enemy corpse and does not join")
	for i in range(32):w.tick+=1;P.tick(w)
	check(e.done and not w.campaign.animals.any(func(a):return a.species=="doberman"),"Unrevived enemy corpse expires without joining")
	w=fresh();e=enemy(w,"runner",Vector2i(7,10));var tired=false
	for i in range(200):
		w.tick+=1;P.walk(w,e,Vector2i(16,10) if e.pos.x<16 and i<75 else Vector2i(5,10))
		if e.get("tired_until",0)>w.tick:tired=true;break
	check(tired,"Actual running accumulates fatigue")
	w=fresh();w.add_item("collar",1);var dog=w.animals[0]
	P.equip_job(w,dog.id,"collar");w.Jobs.cancel(w,w.jobs[0].id)
	check(w.item_count("collar")==1 and dog.equipment.is_empty(),"Cancelling unexecuted equipment preserves inventory")
	P.equip_job(w,dog.id,"collar");w.add_item("collar",-1);w.Jobs.step(w)
	check(w.jobs.is_empty() and dog.equipment.is_empty(),"Missing stock at execution cancels without negative inventory")
	# Genuine multi-day economy and fixed-tick gameplay. No debug money, HP or spawning.
	var morning=Farm.new({},31);var days=[]
	for day in range(1,9):
		while morning.train_animal(1):pass
		for product in ["collar","doberman","bullfrog","hedgehog","berry"]:
			if product=="collar" and morning.animals[0].equipment.get("item_id","")=="collar":continue
			if product in Farm.SPECIES and morning.animals.any(func(a):return a.species==product):continue
			morning.buy(product)
		w=morning.begin_day()
		if w.item_count("collar")>0:P.equip_job(w,1,"collar")
		for a in w.animals:
			if a.species!="shiba" and w.item_count("berry")>0:P.equip_job(w,a.id,"berry")
		var stopped_at=0
		for i in range(1700):
			if w.phase=="day" and w.jobs.is_empty() and not w.keeper.resting:w.act("keeper_rest")
			if w.phase=="defend" and w.tick%12==0:
				var threats=w.enemies.filter(func(n):return not n.done and not n.flee and w.distance(n.pos,w.keeper.pos)<=6)
				if not threats.is_empty() and w.keeper.resting and not w.keeper.forced_rest:w.act("keeper_rest")
				if not threats.is_empty() and w.Life.able(w) and w.distance(threats[0].pos,w.keeper.pos)<=2:
					var cells=w.neighbors(w.keeper.pos).filter(func(c):return w.walkable(c) and not w.actor_occupied(c,w.keeper.pos))
					cells.sort_custom(func(a,b):return w.distance(a,threats[0].pos)>w.distance(b,threats[0].pos))
					if not cells.is_empty():w.act("keeper_move",cells[0])
			w.step();stopped_at=i
			if w.result!="":break
		var row={"day":day,"result":w.result,"defeat_reason":w.story.defeat_reason,"steps":stopped_at,"karma":w.story.hidden.karma,"gold":w.campaign.gold,"encounters":w.enemies.map(func(n):return n.archetype),"animals":w.campaign.animals.map(func(a):return {"id":a.id,"species":a.species,"hp":a.get("hp",0)}),"history":w.campaign.animal_history.duplicate(true)}
		days.append(row)
		check(w.story.hidden.karma==0 and w.enemies.all(func(n):return n.type_tag in ["Human","Animal"]),"Day %d remains low-karma Human/Animal"%day)
		if w.result!="win":break
		morning=Farm.new(w.next_campaign(),31)
	check(days.all(func(row):return row.result in ["win","loss"]),"Every played day terminates instead of stalling")
	if w.result=="loss":
		var retry=Farm.new(w.morning_checkpoint,31)
		check(w.story.defeat_reason!="" and retry.result=="" and retry.campaign.day==w.campaign.day and retry.campaign.gold==w.morning_checkpoint.gold,"Loss has a reason and restores the same morning without a reward")
	var benchmark={"seed":31,"target_day":8,"reached_day":days[-1].day,"last_result":days[-1].result,"passed":days.size()==8 and days[-1].result=="win","classification":"balance observation, separate from technical regression"}
	FileAccess.open("user://progression-flow.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":records,"abduction_path":path,"days":days,"survival_benchmark":benchmark},"  "))
	print("SURVIVAL_BENCHMARK: "+JSON.stringify(benchmark))
	print("PROGRESSION FLOW: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)
