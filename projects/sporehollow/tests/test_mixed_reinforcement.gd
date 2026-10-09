extends "res://tests/test_ranch_content.gd"
const Fixture=preload("res://tests/review_mixed_fixture.gd")

func run():
	var w=Fixture.create_salary();var caller=w.enemies[0];var dancer=w.enemies[1]
	check(caller.phone_started and not caller.get("phone_success",false),"Fixture begins during the two-second call")
	check(w.player_events.any(func(e):return e.text.contains("電話中")),"Call start is labelled separately from success")
	P.enemy_hurt(w,caller,999)
	check(not caller.phone_started and w.spawn_schedule.is_empty(),"Death before success cancels the call without a reservation")
	check(w.player_events.any(func(e):return e.text.contains("電話を中断")),"Interrupted call reports its cancellation")
	C.enemy_step(w,dancer)
	check(caller.revived and not caller.phone_started and not caller.get("phone_success",false),"Revival does not resume the interrupted phone")
	w.tick+=12;P.enemy_step(w,caller)
	check(w.spawn_schedule.is_empty(),"The old call deadline cannot produce a delayed reinforcement")
	caller.debug_phone_chance=1.0;P.enemy_hurt(w,caller,1)
	check(caller.phone_started,"A revived unsuccessful caller may roll again on a new surviving hit")
	w.tick=caller.phone_until;P.enemy_step(w,caller)
	check(caller.phone_success and w.spawn_schedule.size()==1,"The new completed call schedules exactly one reinforcement")
	check(w.player_events.any(func(e):return e.text.contains("応援要請が成立")),"Reservation is announced only after success")
	var due=w.spawn_schedule[0].tick
	P.enemy_hurt(w,caller,999)
	check(caller.phone_success and w.spawn_schedule.size()==1 and w.spawn_schedule[0].tick==due,"Death after success preserves the already requested arrival")

	w=Fixture.create_salary("reserved");caller=w.enemies[0];dancer=w.enemies[1]
	w.tick=caller.phone_until;P.enemy_step(w,caller);P.enemy_hurt(w,caller,999);C.enemy_step(w,dancer)
	check(caller.revived and caller.phone_success and not caller.phone_started,"Success remains consumed across resurrection")
	caller.debug_phone_chance=1.0;P.enemy_hurt(w,caller,1)
	check(not caller.phone_started and w.spawn_schedule.size()==1,"Successful revived caller cannot duplicate its reservation")
	P.enemy_hurt(w,caller,999);P.enemy_hurt(w,dancer,999)
	var count=w.enemies.size()
	for i in range(11):w.step()
	check(w.enemies.size()==count and not w.early_clear,"Pending reinforcement prevents early clear after both original enemies fall")
	w.step()
	check(w.enemies.size()==count+1 and not w.inside(w.enemies.back().pos),"Scheduled reinforcement appears outside the forest even after its caller dies")
	check(not w.early_clear,"Approaching live reinforcement continues the night before its time limit")
	var arriving=w.enemies.back();arriving.debug_phone_chance=0.0
	check(w.player_events.any(func(e):return e.text.contains("増援が森から接近")) and not w.player_events.any(func(e):return e.text.contains("牧場に到着")),"Outer forest spawn says approaching, never already arrived")
	for i in range(160):
		w.step()
		if w.inside(arriving.pos):break
	check(w.inside(arriving.pos) and arriving.get("reinforcement_arrived",false) and w.player_events.any(func(e):return e.text.contains("牧場に到着")),"Physical crossing into the farm reports arrival")
	for i in range(4):w.step()
	check(w.player_events.filter(func(e):return e.text.contains("牧場に到着")).size()==1,"Arrival notification does not repeat each tick")

	w=Fixture.create_salary("dawn");caller=w.enemies[0]
	for i in range(4):w.step()
	check(w.remaining_night()==0 and w.phase=="defend" and caller.phone_started,"Night time limit waits for an active call")
	var ui=load("res://game/main.tscn").instantiate();ui.automated=true;ui.world=w;root.add_child(ui);ui.set_process(false);await process_frame
	check(ui.clock_label_text()=="夜明け待ち：電話中","The zero clock explains an active phone hold")
	for i in range(4):w.step()
	check(caller.phone_success and w.phase=="defend" and w.spawn_schedule.size()==1,"Successful pending call continues to hold dawn")
	check(ui.clock_label_text()=="夜明け待ち：増援の準備中","The zero clock explains a pending reservation")
	for i in range(11):w.step()
	check(w.phase=="defend" and w.enemies.size()==2,"Dawn stays held until the three-second arrival deadline")
	w.step()
	check(w.phase=="dawn" and w.enemies.size()==3 and not w.inside(w.enemies.back().pos),"Current survival rule settles at the due spawn, before the forest approach ends")
	var morning=Farm.new(w.next_campaign(),32)
	check(morning.campaign.day==10 and morning.enemies.is_empty() and morning.spawn_schedule.all(func(e):return e.get("wave",0)!=999),"No old caller or reservation leaks into the next morning")
	ui.queue_free();await process_frame
	print("MIXED_REINFORCEMENT: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)
