extends SceneTree
var checks=[]
func _initialize():call_deferred("run")
func check(ok,note):
	checks.append({"passed":bool(ok),"check":note})
	if not ok:push_error(note)
func wait_ready(boot):
	var deadline=Time.get_ticks_msec()+30000
	var tick=-1;var guarded=false
	while not boot.finished and boot.failure=="" and Time.get_ticks_msec()<deadline:
		if boot.game!=null and boot.game.loading_initialized:
			guarded=true
			if tick<0:tick=boot.game.world.tick
			check(boot.game.world.tick==tick and not boot.game.can_process(),"Loading leaves world tick frozen and simulation disabled")
			var event=InputEventKey.new();event.keycode=KEY_SPACE;event.pressed=true
			var paused=boot.game.world.paused;boot.game._input(event)
			check(boot.game.world.paused==paused,"Loading rejects world keyboard input")
		await process_frame
	check(guarded and boot.finished and boot.failure=="" and boot.frozen_ok,"Preparation completes only after frozen initial draw")
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="" or "--isolated-review" not in OS.get_cmdline_user_args():quit(2);return
	var boot=load("res://game/loading.tscn").instantiate();boot.review_mode=true;root.add_child(boot)
	await wait_ready(boot)
	if not boot.finished:quit(1);return
	var g=boot.game
	check(g.world.W==100 and g.world.H==68 and g.is_processing() and not g.startup_loading,"New map is complete and controls enabled")
	check(not g.world.merchant_present(),"First-day merchant remains disabled")
	g.world.story.intro_seen=true;g.world.Story.persist(g.world)
	g.world.campaign.gold=987654
	var snapshot="user://colony.snapshot"
	check(g.world.Snapshot.save(g.world,snapshot),"Save fixture in isolated user-data")
	var saved_hash=FileAccess.get_sha256(snapshot)
	boot.queue_free();await process_frame
	boot=load("res://game/loading.tscn").instantiate();root.add_child(boot)
	await wait_ready(boot)
	if not boot.finished:quit(1);return
	g=boot.game;g.set_process(false)
	check(g.world.campaign.gold!=987654 and g.world.W==100 and g.world.H==68,"Normal startup ignores existing snapshot and creates a new map")
	g.menu_page="main";g.ColonyMenu.build(g)
	check(not g.buttons.has("menu_save") and not g.buttons.has("menu_load") and g.buttons.menu_exit.text=="終了","Menu exposes no save/load or save-on-exit")
	g.ColonyMenu.start_new(g)
	check(not DirAccess.dir_exists_absolute("user://history"),"New game creates no save history")
	check(FileAccess.get_sha256(snapshot)==saved_hash,"Loading does not overwrite the existing save")
	g.world.paused=false;var tick=g.world.tick;g.world.step()
	check(g.world.tick==tick+1,"Simulation can advance after preparation")
	var failed=checks.filter(func(c):return not c.passed).size()
	FileAccess.open(out+"/loading.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failed},"\t"))
	print("Loading: ",checks.size()," checks, ",failed," failures");quit(1 if failed else 0)
