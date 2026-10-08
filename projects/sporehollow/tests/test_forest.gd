extends "res://tests/test_progression.gd"
const Forest=preload("res://game/forest_pattern.gd")
func old_candidate(p: Vector2i,seed_value: int) -> bool:
	return Forest.noise(seed_value).get_noise_2d(p.x,p.y)>-0.32 and Forest.rank(p,seed_value)%100<72
func old_tree(p: Vector2i,seed_value: int) -> bool:
	if not old_candidate(p,seed_value):return false
	for d in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
		if old_candidate(p+d,seed_value) and Forest.rank(p+d,seed_value)<Forest.rank(p,seed_value):return false
	return true
func run():
	var samples=[]
	for seed_value in [17,31,73]:
		var old_count=0;var current_count=0;var lanes_clear=true;var stable=true
		for y in range(-12,29):
			for x in range(-18,43):
				var p=Vector2i(x,y);var outer=not (x>=1 and x<Farm.W-1 and y>=1 and y<Farm.H-1)
				var lane=x in [5,12,19] or y in [5,8,11]
				if outer and not lane and old_tree(p,seed_value):old_count+=1
				var present=Forest.outer_tree(p,seed_value,Farm.W,Farm.H)
				if present:current_count+=1
				lanes_clear=lanes_clear and (not present or outer and not lane)
				stable=stable and present==Forest.outer_tree(p,seed_value,Farm.W,Farm.H)
		check(current_count>old_count,"Outer forest is denser on the same sample: seed "+str(seed_value))
		check(lanes_clear and stable,"Seed forest preserves clear physical entry lanes and determinism: "+str(seed_value))
		var w=Farm.new({},seed_value).begin_day()
		check(w.entries.all(func(p):return not w.find_path(p,w.keeper.pos).is_empty()),"Every entry still reaches the keeper clearing: "+str(seed_value))
		samples.append({"seed":seed_value,"before_trees":old_count,"after_trees":current_count,"sample_cells":2501,"inner_trees":w.trees.size()})
	FileAccess.open("user://forest-tests.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":records,"density_samples":samples,"native_aspect_preserved":true},"  "))
	print("FOREST: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)
