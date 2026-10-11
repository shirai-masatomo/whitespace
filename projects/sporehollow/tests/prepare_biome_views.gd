extends SceneTree
const Farm=preload("res://game/world.gd")
func _initialize():call_deferred("run")
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="" or "--isolated-review" not in OS.get_cmdline_user_args():quit(2);return
	var w=Farm.new({},31).begin_day();var views=[]
	var cases=[["01-overview",Vector2i(25,17),0.43],["02-idol",Vector2i(24,17),1.0],["03-open-grass",Vector2i(29,17),1.0]]
	for row in [["04-woodland",1],["05-rocky",2],["06-lush",0],["07-dry",3]]:
		var best=Vector2i.ZERO;var score=-1.0
		for y in range(w.H):
			for x in range(w.W):
				var p=Vector2i(x,y);var value=w.Biome.field(w,p)[row[1]]
				if value>score:score=value;best=p
		cases.append([row[0],best,0.9])
	cases.append_array([["08-top",Vector2i(25,3),0.7],["09-bottom",Vector2i(25,30),0.7],["10-left",Vector2i(3,17),0.7],["11-right",Vector2i(46,17),0.7],["12-top-left",Vector2i(3,3),0.7],["13-top-right",Vector2i(46,3),0.7],["14-bottom-left",Vector2i(3,30),0.7],["15-bottom-right",Vector2i(46,30),0.7]])
	var stump=w.natural.keys().filter(func(p):return w.natural[p]=="stump")[0]
	cases.append(["16-harvest-target",stump,1.0]);cases.append(["17-mine-target",w.rocks.keys()[0],1.0])
	for row in cases:views.append({"name":row[0],"cell":[row[1].x,row[1].y],"zoom":row[2],"ticks":504})
	for period in [["morning",0],["night",1224]]:
		for row in cases.slice(0,2):views.append({"name":row[0]+"-"+period[0],"cell":[row[1].x,row[1].y],"zoom":row[2],"ticks":period[1]})
	var f=FileAccess.open(out+"/views-seed31.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"seed":31,"views":views},"\t"));f.close()
	if load("res://tests/capture_biome01.gd")==null:quit(1);return
	print("Prepared ",views.size()," capture views; capture script parsed; no rendering performed")
	quit()
