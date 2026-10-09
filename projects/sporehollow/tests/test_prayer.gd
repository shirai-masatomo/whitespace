extends "res://tests/test_story.gd"
## Transaction fixtures, not a balance or human-play assessment.
const CATEGORIES={"animal":"pray_animal","gold":"pray_gold","item":"pray_item"}
func ready(seed_number: int=17):
	var c=Farm.new_campaign();c.day=2
	var w=Farm.new(c,seed_number).begin_day()
	w.day_seconds=10000;w.nature_config.spawn_chance_per_second=0
	w.story.investigated=true
	w.start_night();w.spawn_schedule.clear()
	w.animals[0].mode="rest";w.animals[0].order_until=999999
	return w

func run():
	night_contract()
	var w=quiet(1)
	for kind in CATEGORIES.values():check(not local(w,kind),"First-night gate: "+kind)
	w=ready();w.story.investigated=false
	check(not local(w,"pray_gold"),"Investigation remains required")
	w.story.investigated=true
	check(not local(w,"pray_wealth"),"Obsolete fixed-gold action stays disabled in production")
	w.paused=true;check(local(w,"pray_item"),"Paused category prayer can be queued")
	var tick=w.tick
	for i in range(20):w.step()
	check(w.tick==tick and w.story.prayers.is_empty() and w.story.hidden.karma==0,"Paused plan commits no time, reward or karma")
	check(not local(w,"pray_animal"),"A second category cannot reserve the same idol")
	w.Jobs.cancel(w,w.jobs[0].id)
	check(w.story.prayers.is_empty() and w.story.prayed_day==0,"Cancel keeps the daily allowance")
	local(w,"pray_gold");w.paused=false;w.step();w.Life.hurt(w,{"id":99,"attack_power":1})
	check(w.jobs.is_empty() and w.story.prayers.is_empty() and w.story.hidden.karma==0,"Hit interrupts a new category before commitment")
	var samples=[]
	for seed_number in [17,31,73]:
		for category in CATEGORIES:
			w=ready(seed_number)
			var gold=w.campaign.gold;var count=w.campaign.animals.size();var items=w.campaign.items.duplicate(true)
			check(local(w,CATEGORIES[category]),"Accepted onsite prayer %s/%d"%[category,seed_number]);drain(w)
			check(w.story.prayers.size()==1 and w.campaign.gold==gold and w.campaign.animals.size()==count and w.campaign.items==items,"No immediate gift: "+category)
			var prayer=w.story.prayers[0]
			check(prayer.category==category and prayer.seed==seed_number and prayer.reward_record.is_empty() and w.story.hidden.karma==3 and prayer.karma_at_prayer==3,"Committed record retains category, seed and three karma")
			check(not local(w,"pray_item"),"Daily limit applies across categories")
			w.Story.morning(w,2)
			check(not prayer.rewarded,"No reward before next dawn")
			w.Story.morning(w,3)
			check(prayer.rewarded and not prayer.reward_record.is_empty(),"Dawn settles selected category: "+category)
			var reward=prayer.reward_record
			if category=="gold":
				check(w.campaign.gold==gold+reward.gold_amount and reward.gold_amount in [40,60,90] and w.campaign.animals.size()==count and w.campaign.items==items,"Gold gift does not add animals/items")
			elif category=="item":
				check(w.item_count(reward.item_id)==items.get(reward.item_id,0)+1 and w.campaign.gold==gold and w.campaign.animals.size()==count,"Item gift is one implemented item only")
			else:
				var a=w.Orders.animal(w,prayer.animal_id)
				check(w.campaign.animals.size()==count+1 and a.species!="shiba" and a.source=="idol" and a.bonus_skills==reward.bonus_skills and a.rarity==reward.rarity,"Animal gift keeps individual data and excludes Shiba")
				check(a.placed and a.pos!=w.keeper.pos and w.animals.filter(func(other):return other.placed and other.pos==a.pos).size()==1,"Animal uses an unoccupied admission cell")
				check(w.campaign.gold==gold and w.campaign.items==items,"Animal gift does not add cash/items")
			var settled=w.campaign.duplicate(true);var history=w.story.duplicate(true)
			w.Story.morning(w,3)
			check(w.campaign==settled and w.story==history,"Repeated dawn does not duplicate gift or news")
			var again=ready(seed_number);local(again,CATEGORIES[category]);drain(again);again.Story.morning(again,3)
			check(again.story.prayers[0].reward_record==reward,"Same seed, day and category reproduce reward")
			samples.append({"seed":seed_number,"category":category,"reward":reward.duplicate(true)})
	# Block the ordinary logistics entry; gift ownership must survive while admission waits.
	w=ready();site(w,"wall",w.logistics_entry);local(w,"pray_animal");drain(w);w.Story.morning(w,3)
	var animal_id=w.story.prayers[0].animal_id;var waiting=w.Orders.animal(w,animal_id)
	check(not waiting.placed and waiting.deployment=="admission_pending" and w.story.prayers[0].rewarded,"Blocked gift waits without rerolling or occupying another actor")
	w.persist_farm();var stored=w.campaign.duplicate(true);stored.day=3;stored.night_ready=false
	var restored=Farm.new(stored,17)
	check(restored.campaign.animals.size()==2 and not restored.Orders.animal(restored,animal_id).placed,"Reconstruction preserves one waiting gift")
	restored.structures.erase(restored.logistics_entry);restored.admit(restored.Orders.animal(restored,animal_id),restored.logistics_entry)
	check(restored.Orders.animal(restored,animal_id).placed,"Clearing admission allows the same individual to enter")
	# Real day transition and the same morning retry, with battle resolution as a fixture.
	w=ready(31);local(w,"pray_gold");drain(w);w.start_night();w.spawn_schedule.clear();w.finish(true)
	var morning=Farm.new(w.next_campaign(),31)
	var baseline=morning.campaign.duplicate(true);var gift=morning.story.prayers[0].reward_record
	check(morning.campaign.day==3 and morning.story.prayers[0].rewarded and morning.campaign.gold==40+w.score.gold+gift.gold_amount,"Normal dawn includes defense reward and one prayer reward")
	w=morning.begin_day();w.start_night();w.spawn_schedule.clear();local(w,"pray_animal");drain(w)
	var retry=Farm.new(w.morning_checkpoint,31)
	check(retry.campaign.gold==baseline.gold and retry.campaign.animals==baseline.animals and retry.story==baseline.world_story,"Morning retry restores money, animals, PrayerIDs and reactions together")
	var pending=w.campaign.duplicate(true);w.persist_farm();pending=w.campaign.duplicate(true)
	var resumed=Farm.new(pending,31);resumed.Story.morning(resumed,4)
	w.Story.morning(w,4)
	check(resumed.story.prayers[-1].reward_record==w.story.prayers[-1].reward_record,"Pending prayer survives campaign reconstruction without reroll")
	# Old saves retain the already-promised fixed payment, even without legacy action enabled.
	w=ready();w.story.prayers.append({"id":"old-1","day":1,"wish":"wealth","reward_day":2,"rewarded":false})
	var before=w.campaign.gold;w.Story.morning(w,2);w.Story.morning(w,2)
	check(w.campaign.gold==before+60 and w.story.prayers[0].rewarded,"Legacy reward is honored exactly once")
	w=ready();local(w,"pray_item");drain(w);w.Story.morning(w,5);w.campaign.day=11;w.phase="day";w.start_night()
	check(w.spawn_schedule.any(func(e):return e.role=="thief") and w.story.hidden.security<=2,"Non-milestone night selects bounded item reaction after introduction")
	check(w.story.news.all(func(n):return not "金鉱" in n.title),"Item prayer does not publish an unrelated gold discovery")
	var no_prayer=ready();no_prayer.Story.morning(no_prayer,5);no_prayer.make_schedule()
	check(no_prayer.story.hidden.karma==0 and no_prayer.spawn_schedule.all(func(e):return e.role not in ["idol_breaker","idol_extractor"]),"No-prayer route remains independent")
	FileAccess.open("user://prayer-tests.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":records,"samples":samples,"scope":"deterministic transactions, not balance or human play"},"  "))
	print("PRAYER: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)

func night_contract():
	var w=quiet(1)
	w.story.investigated=true;w.start_night();w.spawn_schedule.clear()
	check(not w.Story.idol_glowing(w) and not local(w,"pray_gold"),"First night neither lights nor accepts a prayer")
	w=quiet(2);w.story.investigated=true
	check(not w.Story.idol_glowing(w),"Second daytime is unlit")
	for kind in CATEGORIES.values():
		check(not local(w,kind) and w.Story.reason(w,kind,w.Story.at(w))=="祈れるのは夜だけです","Day rejects category before reserving resources: "+kind)
	w.start_night();w.spawn_schedule.clear();w.story.investigated=false
	check(w.Story.idol_glowing(w) and not local(w,"pray_gold"),"Second night gives a light cue but still requires investigation")
	local(w,"inspect_idol");drain(w)
	check(w.story.investigated and w.Story.idol_glowing(w),"Onsite inspection unlocks prayer without consuming the light")
	w.paused=true;local(w,"pray_gold")
	check(w.Story.idol_glowing(w) and w.story.prayed_day==0 and w.story.hidden.karma==0,"Queued prayer keeps the light and consumes nothing")
	w.Jobs.cancel(w,w.jobs[0].id);w.paused=false
	local(w,"pray_gold");drain(w)
	check(not w.Story.idol_glowing(w) and w.story.hidden.karma==3 and w.story.prayed_day==2,"Completion adds exactly three karma and turns off the light")
	w.finish(true)
	check(w.phase=="dawn" and not w.Story.idol_glowing(w),"Completed night has no glow")
	var next=Farm.new(w.next_campaign(),17)
	check(next.phase=="shop" and not next.Story.idol_glowing(next) and next.story.prayed_day==2,"Morning preserves last prayer day without lighting")
	w=next.begin_day()
	check(not w.Story.idol_glowing(w) and not local(w,"pray_item"),"Next day is still unavailable")
	w.start_night();w.spawn_schedule.clear()
	check(w.Story.idol_glowing(w) and local(w,"pray_item"),"Next night restores the single shared opportunity")
	drain(w)
	check(w.story.hidden.karma==6 and w.story.prayers.size()==2 and not w.Story.idol_glowing(w),"Two completed nights accumulate six karma only")
	# Partial prayers do not survive dawn and block the next day's unrelated work.
	w=ready();local(w,"pray_item");w.step()
	check(w.jobs.size()==1 and w.jobs[0].elapsed>0 and w.story.prayers.is_empty(),"Partial work has no committed reward")
	check(w.act("wall",Vector2i(8,8)),"Independent construction queues behind the prayer")
	w.finish(true)
	check(w.jobs.size()==1 and w.jobs[0].kind=="wall" and w.story.prayed_day==0 and w.story.hidden.karma==0,"Dawn cancels only unfinished prayer with no cost")
	next=Farm.new(w.next_campaign(),17)
	check(next.jobs.size()==1 and next.jobs[0].kind=="wall" and next.story.prayers.is_empty(),"Morning reconstruction retains construction and no expired wish")
	w=ready();local(w,"pray_gold");w.persist_farm()
	var legacy_pending=w.campaign.duplicate(true);legacy_pending.night_ready=false
	next=Farm.new(legacy_pending,17)
	check(next.jobs.is_empty() and next.story.prayed_day==0 and next.story.hidden.karma==0,"Old morning prayer plan expires without consuming the next opportunity")
	# A pre-revision category contract preserves its recorded karma and reward seed.
	w=ready();local(w,"pray_animal");drain(w)
	w.story.hidden.karma=1;w.story.prayers[0].karma_at_prayer=1
	var expected=w.ProgressData.idol_reward("animal",1,w.seed_value,2)
	w.persist_farm();var stored=w.campaign.duplicate(true);stored.day=3;stored.night_ready=false
	next=Farm.new(stored,17)
	check(next.story.hidden.karma==1 and next.story.prayers[0].karma_at_prayer==1 and next.story.prayers[0].reward_record==expected,"Old plus-one category contract is not upgraded or rerolled")
	var save=load("res://game/morning_save.gd")
	var snapshot=save.capture(next)
	check(save.write(snapshot,"user://prayer-compat/morning.sav").status=="ok","Existing WRM1 format accepts the unchanged story schema")
	var restored=save.restore(save.read("user://prayer-compat/morning.sav").record)
	check(restored!=null and restored.story==next.story and restored.campaign.animals.size()==next.campaign.animals.size(),"WRM1 round trip preserves old karma, one gift and prayer history")
