extends "res://tests/test_scale_logic.gd"
const Before=preload("res://tests/selection_before_reference.gd")
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if DisplayServer.get_name()!="headless" or out=="":quit(2);return
	var w=fixture(1);w.animals.clear();var g=Main.new();g.world=w;g.group=-1;g.drag_start=Vector2.ZERO
	for i in range(1000):w.trees[Vector2i(i%100,i/100)]={}
	var samples=[];var equivalent=true
	for repeat in range(3):
		var old_encounters=[];var began=Time.get_ticks_usec()
		for motion in range(20):
			var area=Rect2(0,0,240+motion*240,420)
			for c in Before.candidates(g):
				if area.has_point(c.point):
					var key=[c["class"],c.id]
					if key not in old_encounters:old_encounters.append(key)
		var before_ms=(Time.get_ticks_usec()-began)/1000.0
		g.selection_static_key=[];g.drag_ranks={};g.drag_class="";var new_encounters=[];began=Time.get_ticks_usec()
		for motion in range(20):
			var area=Rect2(0,0,240+motion*240,420)
			for c in g.selection_candidates(area,true,true):
				if g.drag_class=="":g.drag_class=c["class"]
				var key=[c["class"],c.id];g.drag_ranks[key]=new_encounters.size();new_encounters.append(key)
		var after_ms=(Time.get_ticks_usec()-began)/1000.0
		equivalent=equivalent and old_encounters==new_encounters
		samples.append({"before_ms":before_ms,"after_ms":after_ms,"motions":20,"candidates":1000,"same_encounter_order":old_encounters==new_encounters})
	g.free()
	FileAccess.open(out+"/drag-scale.json",FileAccess.WRITE).store_string(JSON.stringify({"samples":samples,"passed":equivalent,"reference":"Exact candidate producer from 8e3a1e8; encounter loop copied from update_drag_class; world-coordinate rectangles, no OS or GPU"},"\t"))
	if not equivalent:push_error("Selection order changed")
	print("Drag scale: ",samples);quit(0 if equivalent else 1)
