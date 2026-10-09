extends RefCounted
const Farm=preload("res://game/world.gd")

static func create(carrying: bool=false,intercept: bool=false):
	# Day-nine mid-battle fixture, not a new-game route or an assertion of normal encounter odds.
	var campaign=Farm.new({},31).campaign.duplicate(true)
	campaign.day=9;campaign.world_story.intro_seen=true;campaign.animals[0].lv=3
	var row={"id":campaign.next_animal_id,"species":"hen","category":"bird","lv":1,"loyalty":0,"name":"","unavailable_through_day":0}
	campaign.next_animal_id+=1;campaign.animals.append(row)
	var w=Farm.new(campaign,31).begin_day()
	w.trees.clear();w.natural.clear();w.field_items.clear()
	w.keeper.pos=Vector2i(6,10)
	var dog=w.animals[0];dog.pos=Vector2i(7,10);dog.home=dog.pos;dog.order=dog.pos;dog.mode="stay";dog.order_until=99999
	var hen=w.animals[1];hen.pos=Vector2i(10,10);hen.home=hen.pos;hen.order=hen.pos
	w.start_night();w.spawn_schedule.clear()
	w.spawn_enemy({"role":"animal_tamer","entry":Vector2i(23,10),"lv":1,"debug_single":true})
	w.enemies.back().pos=Vector2i(11,10)
	w.spawn_enemy({"role":"dancer","entry":Vector2i(23,10),"lv":1,"debug_single":true})
	w.enemies.back().pos=Vector2i(12,11);w.enemies.back().ultimate_gauge=100
	if carrying:
		# A legal mid-abduction start, produced by the same rule used by the enemy AI.
		w.keeper.pos=Vector2i(7,10);dog.pos=Vector2i(8,10);dog.home=dog.pos;dog.order=dog.pos
		w.Progression.tame(w,w.enemies[0],hen)
		if intercept:
			# Same combat stats; the defender starts on the captor's route, not three cells behind.
			w.keeper.pos=Vector2i(9,9);dog.pos=Vector2i(11,9);dog.home=dog.pos;dog.order=dog.pos
			w.campaign.items.whistle=1
	return w

static func create_salary(variant: String="interrupt"):
	# Controlled day-nine phone boundary. Only its first trigger is forced; subsequent
	# random calls are disabled so interruption and reservation can be compared alone.
	var campaign=Farm.new({},31).campaign.duplicate(true)
	campaign.day=9;campaign.world_story.intro_seen=true;campaign.animals[0].lv=3
	var w=Farm.new(campaign,31).begin_day()
	w.trees.clear();w.natural.clear();w.field_items.clear();w.keeper.pos=Vector2i(7,8)
	var dog=w.animals[0]
	dog.pos=Vector2i(10,10) if variant=="interrupt" else Vector2i(9,10)
	if variant=="dawn":dog.pos=Vector2i(6,12);w.config.time_limit_seconds=1.0
	dog.home=dog.pos;dog.order=dog.pos;dog.mode="stay";dog.order_until=99999
	w.start_night();w.spawn_schedule.clear()
	w.spawn_enemy({"role":"salaryman","entry":Vector2i(23,10),"lv":1,"debug_single":true})
	var salary=w.enemies.back();salary.pos=Vector2i(11,10)
	w.spawn_enemy({"role":"dancer","entry":Vector2i(23,10),"lv":1,"debug_single":true})
	w.enemies.back().pos=Vector2i(12,11);w.enemies.back().ultimate_gauge=100
	salary.debug_phone_chance=1.0;w.Progression.enemy_hurt(w,salary,1);salary.debug_phone_chance=0.0
	return w
