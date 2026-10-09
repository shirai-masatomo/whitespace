extends RefCounted
const Farm=preload("res://game/world.gd")

static func create():
	var campaign=Farm.new({},31).campaign.duplicate(true)
	campaign.world_story.intro_seen=true;campaign.animals[0].loyalty=100
	campaign.animals.append({"id":campaign.next_animal_id,"species":"hen","category":"bird","lv":1,"loyalty":0,"name":"","unavailable_through_day":0})
	campaign.next_animal_id+=1
	var w=Farm.new(campaign,31).begin_day()
	w.trees.clear();w.story.trees=[];w.natural.clear();w.field_items.clear();w.spawn_schedule.clear();w.day_seconds=600
	w.keeper.pos=Vector2i(6,10)
	for i in range(2):
		var a=w.animals[i];a.pos=Vector2i(7,10) if i==0 else Vector2i(14,11);a.home=a.pos;a.order=a.pos
	var cell=Vector2i(12,11);var d=Farm.BUILD.wall
	w.structures[cell]={"id":w.next_structure_id,"kind":"wall","status":"ready","hp":d.hp,"max_hp":d.hp,"cost":d.cost,"resource":d.get("resource","soil"),"open":false}
	w.next_structure_id+=1
	return w
