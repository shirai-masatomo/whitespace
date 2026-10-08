extends "res://tests/test_progression.gd"
const E=P.Encounters
func prepare(day: int,seed_value: int=31):
	var c=Farm.new_campaign();c.day=day
	return Farm.new(c,seed_value).begin_day()
func win(w):
	w.start_night();w.spawn_schedule.clear();w.finish(true)
func run():
	var definition=E.route_definition();var target=definition.completion_night
	check(definition.last_intro==11 and target==15,"Arrival is derived from the final introduction and next existing milestone")
	check(not E.NIGHTS.has(target) and target%E.MILESTONE.interval==0,"The endpoint uses a real milestone, not an overridden introduction night")
	check(E.route_phase(11)=="introduction" and E.route_phase(12)=="mixed" and E.route_phase(target)=="milestone" and E.route_phase(target+1)=="continuation","Every section has an explicit transition")
	var scenarios=[]
	for seed_value in [17,31,73]:
		var w=prepare(target-1,seed_value);win(w)
		check(not E.reached(w.campaign),"Night before the milestone is not completion: "+str(seed_value))
		w=prepare(target,seed_value);w.start_night();w.finish(false)
		check(not E.reached(w.campaign),"Losing the milestone cannot award completion: "+str(seed_value))
		w=prepare(target,seed_value);var plan=w.spawn_schedule.duplicate(true);var morning=w.morning_checkpoint.duplicate(true)
		for i in range(20):E.route_text(w.campaign)
		check(w.spawn_schedule==plan,"Progress presentation leaves seeded encounter scheduling unchanged: "+str(seed_value))
		win(w);var settled=w.campaign.duplicate(true);var miracles=w.story.miracles.duplicate(true)
		check(E.reached(settled) and settled.route_progress.completed_through_day==target and settled.route_progress.milestones.size()==1,"Successful milestone records one completion: "+str(seed_value))
		w.finish(true)
		check(w.campaign==settled and w.story.miracles==miracles,"Repeated finish cannot duplicate money, growth or completion: "+str(seed_value))
		var next=Farm.new(w.next_campaign(),seed_value+1);var again=Farm.new(next.morning_checkpoint,seed_value+1)
		check(next.campaign.day==target+1 and next.phase=="shop" and E.reached(next.campaign) and again.campaign.route_progress==next.campaign.route_progress,"The next morning and its retry retain completion: "+str(seed_value))
		var rewind=Farm.new(morning,seed_value)
		check(not E.reached(rewind.campaign),"Rewinding before the victory restores the earlier incomplete state: "+str(seed_value))
		# State-flow fixture, not a survival/balance test. Mirrors main.advance seed+1 each morning.
		var cycle=Farm.new({},seed_value);var chosen=[]
		for day in range(1,target+1):
			chosen.append(E.plan(day,cycle.seed_value,0).chosen)
			w=cycle.begin_day();win(w);cycle=Farm.new(w.next_campaign(),w.seed_value+1)
		check(cycle.campaign.day==target+1 and cycle.seed_value==seed_value+target and E.reached(cycle.campaign),"Actual morning seed increment crosses the full existing route: "+str(seed_value))
		scenarios.append({"initial_seed":seed_value,"next_morning_seed":cycle.seed_value,"encounters":chosen,"completion":cycle.campaign.route_progress})
	var w=prepare(target);w.story.investigated=true;w.Story.pray(w,"gold");win(w)
	var gold=w.campaign.gold;var progress=w.campaign.route_progress.duplicate(true)
	w.Story.morning(w,target+1);w.finish(true)
	check(w.campaign.gold==gold and w.story.miracles.size()==1 and w.campaign.route_progress==progress,"Prayer settlement and endpoint overlap exactly once")
	var legacy=Farm.new_campaign();legacy.day=target+1;legacy.erase("route_progress")
	var migrated=Farm.new(legacy,31)
	check(not E.reached(migrated.campaign) and migrated.campaign.route_progress.completed_through_day==0,"Reading an old late campaign does not invent unobserved achievements")
	check(E.plan(target+1,31,0).chosen.size()==E.TABLE_NIGHT.count,"The game continues beyond the provisional endpoint")
	FileAccess.open("user://campaign-route-tests.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":records,"definition":definition,"scenarios":scenarios,"scope":"state and reward contracts; victories forced in transition fixtures, not human survival"},"  "))
	print("CAMPAIGN_ROUTE: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)
