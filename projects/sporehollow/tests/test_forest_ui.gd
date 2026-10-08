extends "res://tests/test_controls.gd"
const Forest=preload("res://game/forest_pattern.gd")
func spawn(kind: String,p: Vector2i):
	var w=game.world;w.spawn_enemy({"role":kind,"entry":w.entries[0],"debug_single":true})
	var e=w.enemies.back();e.pos=p;e.approach=[];e.state="見張る";e.facing=-1
	return e
func run():
	output=OS.get_environment("FARM_REVIEW_OUTPUT")
	check(DisplayServer.get_name()=="headless" or ("--isolated-review" in OS.get_cmdline_user_args() and output!=""),"Only headless or isolated rendering")
	root.size=Vector2i(1280,800);game=load("res://game/main.tscn").instantiate();game.automated=true
	game.world=Farm.new({},31).begin_day();root.add_child(game);game.set_process(false);await process_frame
	var w=game.world;game.story_modal="";w.paused=true;w.day_seconds=9999;w.keeper.pos=Vector2i(8,10)
	for i in range(5):spawn(["kidnapper","salaryman","destroyer","dancer","maid"][i],Vector2i(10+i*2,10))
	game.neutral();game.reset_view();game.camera.zoom=Vector2(1.3,1.3);game.camera.position=game.center(Vector2i(13,10));game.refresh();game._process(0)
	var kid=w.enemies[0];var body=game.enemy_hit_rect(kid)
	var native=game.Delivered.CLIPS["enemy/idle_right"].frames[0].get_image().get_used_rect()
	check(is_equal_approx((body.size.x-6)/native.size.x,1.3),"Human size is absolute 1.3, not 1.15 multiplied again")
	var foot=game.actor_pixel("e%d"%kid.id,kid.pos)+Vector2(0,14)
	check((game.HumanVisual.transform(foot)*foot).is_equal_approx(foot),"Enlargement preserves the delivered foot anchor")
	await mouse(game.get_canvas_transform()*(body.position+Vector2(body.size.x/2,8)))
	check(game.selected.get("kind")=="enemy" and game.selected.id==kid.id,"Enlarged head remains selectable")
	game.neutral();game._process(0)
	await capture("01_human_lineup")
	game.camera.zoom=Vector2(0.68,0.68);game.camera.position=game.center(Vector2i(12,5));game._process(0)
	await capture("02_forest_overview")
	var tree=Vector2i(7,0)
	for x in range(2,23):
		if x not in [5,12,19] and Forest.tree(Vector2i(x,0),31,true):tree=Vector2i(x,0);break
	w.enemies.clear();var behind=spawn("destroyer",tree+Vector2i.UP);var front=spawn("salaryman",tree+Vector2i.DOWN)
	game.reset_view();game.camera.zoom=Vector2(1.8,1.8);game.camera.position=game.center(tree+Vector2i.DOWN);game._process(0)
	if game.has_method("scene_actors"):
		var ordered=game.scene_actors();var indexes={}
		for i in range(ordered.size()):
			var row=ordered[i]
			if row.kind=="tree" and row.data==tree:indexes.tree=i
			if row.kind=="enemy":indexes["behind" if row.data.id==behind.id else "front"]=i
		check(indexes.has("tree") and indexes.behind<indexes.tree and indexes.tree<indexes.front,"External tree is between actors by actual foot depth")
		check(ordered.filter(func(row):return row.kind=="tree" and row.data==tree).size()==1,"Border tree is drawn once after ground")
	record.depth_fixture={"tree":str(tree),"behind":str(behind.pos),"front":str(front.pos)}
	await capture("03_tree_depth")
	check(w.tick==0 and w.paused,"Render fixture never advances gameplay")
	if output!="":FileAccess.open(output+"/observations.json",FileAccess.WRITE).store_string(JSON.stringify(record,"  "))
	print("FOREST_UI: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)
