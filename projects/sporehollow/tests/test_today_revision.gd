extends "res://tests/test_story.gd"
const Enc=Farm.Progression.Encounters
func pairs(w):
	return w.spawn_schedule.map(func(e):return [e.tick*Farm.DT,e.role,e.lv])
func run():
	var expected_low=[[10.0,"salaryman",1],[10.0,"salaryman",1],[10.0,"salaryman",1],[10.0,"salaryman",1],[10.0,"salaryman",1],[20.0,"kidnapper",1]]
	var expected_high=[[10.0,"martial_artist",1],[10.0,"maid",1],[15.0,"kidnapper",1],[15.0,"destroyer",1],[20.0,"salaryman",1],[25.0,"salaryman",1],[30.0,"salaryman",1],[35.0,"salaryman",1],[40.0,"salaryman",1]]
	for day in [5,10]:
		for karma in [9,10]:
			var w=quiet(day);w.story.hidden.karma=karma;w.start_night()
			check(pairs(w)==(expected_high if karma==10 else expected_low),"Exact simultaneous groups and five-second salarymen: day%d karma%d"%[day,karma])
			var frozen=w.spawn_schedule.duplicate(true);w.story.hidden.karma+=3;w.paused=true
			for i in range(40):w.step()
			check(w.tick==0 and w.schedule_index==0 and w.spawn_schedule==frozen,"Pause and prayer cannot change frozen night's plan")
			w.paused=false
			for i in range(161):
				w.step()
				for e in w.enemies:e.done=true # Resolve actors only; scheduler follows normal ticks.
			check(w.schedule_index==frozen.size() and w.enemies.size()==frozen.size(),"Every scheduled actor spawns exactly once")
	var seen={}
	for seed_number in range(1,65):
		var plan=Enc.plan(2,seed_number,0);seen[plan.selection]=plan
	check(seen.size()==4,"Seeded equal A-D selection covers all four patterns")
	check(seen.A.first_attack_seconds==15 and seen.A.chosen==["salaryman","salaryman","salaryman"],"A provisional fifteen seconds")
	check(seen.B.first_attack_seconds==15 and seen.B.waves[1].start_seconds==0,"B applies fifteen seconds to both enemies")
	check(seen.C.waves[1].start_seconds==10 and seen.D.waves[1].start_seconds==0 and seen.D.waves[2].start_seconds==5,"C and D grouped times")
	for day in range(6,10):check(Enc.plan(day,31,0).chosen[0]=={6:"ninja",7:"animal_tamer",8:"runner",9:"dancer"}[day],"Existing introduction preserved day%d"%day)
	for material in ["soil","wood","stone"]:
		var w=quiet(2);w.story.idol.hp=10;w.materials=3;w.set("wood",3);w.set("stone",3)
		var before=w.resource_amount(material);var amount={"soil":1,"wood":2,"stone":3}[material]
		check(local(w,"repair_idol_"+material),"Material repair accepted: "+material);drain(w)
		check(w.story.idol.hp==10+amount and w.resource_amount(material)==before-1,"One selected resource consumed for exact HP: "+material)
		w.story.idol.hp=w.story.idol.max_hp-1;local(w,"repair_idol_"+material);drain(w)
		check(w.story.idol.hp==w.story.idol.max_hp,"Repair clamps at maximum: "+material)
		before=w.resource_amount(material);check(not local(w,"repair_idol_"+material) and w.resource_amount(material)==before,"Full statue consumes nothing")
		w.story.idol.hp=10;w.add_resource(material,-w.resource_amount(material));check(not local(w,"repair_idol_"+material),"Missing material rejected")
	var construction=quiet(2);var cell=Vector2i(9,10)
	construction.trees.clear();construction.natural.clear();construction.field_items.clear();construction.enemies.clear();construction.keeper.pos=cell+Vector2i.LEFT
	construction.field_items.append({"kind":"egg","pos":cell})
	check(not construction.act("wall",cell),"Loose item blocks new construction without disappearing")
	construction.field_items.clear();construction.act("wall",cell)
	var job=construction.jobs[0];var paid=construction.materials
	construction.field_items.append({"kind":"egg","pos":cell})
	construction.step()
	check(job.state=="blocked" and not job.started and construction.field_items.size()==1 and construction.materials==paid,"Drop after reservation blocks start, preserving item and paid materials")
	construction.field_items.clear()
	for i in range(12):
		construction.step()
		if job.started:break
	check(job.started,"Removing obstruction allows construction to start")
	construction.field_items.append({"kind":"egg","pos":cell});var remaining=job.remaining
	construction.step()
	check(job.state=="blocked" and job.remaining==remaining and construction.field_items.size()==1,"Drop during construction preserves progress and item")
	construction.field_items.clear();drain(construction)
	check(construction.structures[cell].status=="ready" and construction.materials==paid,"Clearing obstruction completes original paid job once")
	# Consecutive campaign days: normal clocks/dawn, controlled combat resolution. Not human survival proof.
	var campaign=Farm.new_campaign();var nights=[]
	for day in range(1,11):
		var w=Farm.new(campaign,31).begin_day();w.day_seconds=2;w.nature_config.spawn_chance_per_second=0
		var used=0
		for i in range(1000):
			w.step()
			for e in w.enemies:e.done=true
			used+=1
			if w.result!="":break
		check(w.result=="win" and w.schedule_index==w.spawn_schedule.size(),"Day/night/dawn and all waves complete: "+str(day))
		nights.append({"day":day,"ticks":used,"schedule":pairs(w),"result":w.result})
		campaign=w.next_campaign()
	check(campaign.day==11 and Enc.reached(campaign),"Night10 milestone retained on morning11")
	FileAccess.open("user://today-revision.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":records,"nights":nights,"combat_fixture":"mark spawned enemies done each tick"},"  "))
	print("TODAY_REVISION: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)
