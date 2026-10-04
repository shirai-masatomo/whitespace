extends "res://tests/test_controls.gd"

func run():
	output=OS.get_environment("FARM_REVIEW_OUTPUT")
	root.size=Vector2i(1280,800)
	game=load("res://game/main.tscn").instantiate();game.automated=true
	game.world=Farm.new({},17).begin_day();game.world.paused=true;game.world.natural.clear()
	root.add_child(game);await process_frame;game.reset_view();game.refresh()
	for material in ["wall","wood_wall","stone_wall"]:
		for damaged in [false,true]:
			for page in range(2):
				game.world.structures.clear()
				for index in range(8):
					var mask=page*8+index
					var origin=Vector2i(3+(index%4)*6,4+(index/4)*6)
					site(material,origin)
					for pair in [[Vector2i.UP,1],[Vector2i.RIGHT,2],[Vector2i.DOWN,4],[Vector2i.LEFT,8]]:
						if mask & pair[1]:site(material,origin+pair[0])
					check(game.BuildingArt.wall_mask(game,origin)==mask,"Wall mask %d"%mask)
				if damaged:
					for b in game.world.structures.values():b.hp=b.max_hp/2.0
				await capture("%s_masks_%d_%s"%[material,page,"damaged" if damaged else "normal"])

	game.world.structures.clear()
	for row in range(2):
		for column in range(2):
			var origin=Vector2i(7+column*9,5+row*6)
			var direction=Vector2i.DOWN if row==1 else Vector2i.RIGHT
			site("wood_wall",origin-direction);site("wood_wall",origin+direction)
			site("door" if column==0 else "locked_door",origin)
			for y in range(origin.y-1,origin.y+2):
				for x in range(origin.x-1,origin.x+2):site("wood_tile",Vector2i(x,y))
	for state in ["closed","open","broken_lock","damaged"]:
		for b in game.world.structures.values():
			if b.kind in Farm.Buildings.DOORS:
				b.open=state=="open"
				if state=="broken_lock":b.lock_hp=0
				if state=="damaged":b.hp=b.max_hp/2.0
		await capture("wood_doors_"+state)
	# Compare a same-cell actor against front/rear posts while traversing an open door.
	var cell=Vector2i(7,5)
	game.world.structures[cell].open=true
	game.world.keeper.pos=cell+Vector2i.UP;game.reset_view();game.world.paused=false
	game.choose_walk();await mouse(game.screen_cell(cell+Vector2i.DOWN))
	for i in range(45):
		game.automated=false;game._process(1.0/30.0);game.automated=true
		await process_frame
		if i%5==0:await capture("door_walk_%02d"%i)
	check(game.world.keeper.pos==cell+Vector2i.DOWN,"Keeper traverses open door")
	check(game.world.structures[cell].kind=="door","Door art does not remove structure")
	game.world.paused=true
	site("stone_tile",Vector2i(9,5));site("soil_tile",Vector2i(9,6))
	await capture("wood_floor_boundaries")
	if output!="":
		record.implementation_commit=OS.get_environment("FARM_REVIEW_COMMIT")
		record.asset_commit="ebe446e5329aa7780b6ef5f13268ceb9433c9796"
		FileAccess.open(output+"/observations.json",FileAccess.WRITE).store_string(JSON.stringify(record,"  "))
	print("BUILDING ART: ",checks," checks failures=",failures)
	quit(1 if failures else 0)
