extends SceneTree
const Farm=preload("res://game/world.gd")
func _initialize():call_deferred("run")
func run():
	var output=OS.get_environment("FARM_REVIEW_OUTPUT")
	if output=="" or not "--isolated-review" in OS.get_cmdline_user_args():quit(2);return
	root.size=Vector2i(1280,800)
	var g=load("res://game/main.tscn").instantiate();g.automated=true;g.world=Farm.new({},31).begin_day();g.world.paused=true;g.world.story.intro_seen=true
	root.add_child(g);await process_frame;await process_frame;g.set_process(false);g.audio.set_process(false);g.reset_view();g.neutral()
	var w=g.world;w.field_items=[{"kind":"egg","pos":Vector2i(7,6),"born_day":1}]
	var accepted=w.Jobs.enqueue(w,"wall",Vector2i(4,6),-1) and w.Jobs.enqueue(w,"collect",Vector2i(7,6),-1)
	for p in [Vector2i(5,6),Vector2i(6,6)]:accepted=w.Jobs.enqueue(w,"wall",p,-1) and accepted
	g.refresh_jobs()
	accepted=w.Jobs.enqueue(w,"wall",Vector2i(8,6),-1) and accepted
	var snapshot=w.jobs.duplicate(true);g.refresh_jobs()
	var headers=g.queue_controls.get_children().filter(func(c):return c.has_meta("job_category")).map(func(c):return c.text)
	var displayed=g.queue_controls.get_children().filter(func(c):return c.has_meta("job_id")).map(func(c):return c.get_meta("job_id"))
	var expected=[snapshot[0].id,snapshot[2].id,snapshot[3].id,snapshot[4].id,snapshot[1].id]
	var passed=accepted and headers==["建築 · 4件","回収 · 1件"] and displayed==expected and w.jobs==snapshot
	var record={"passed":passed,"check":"Default all-jobs view groups four wall jobs and one collection under headings; appended wall appears exactly once; original job records and execution order remain unchanged","headers":headers,"displayed_ids":displayed,"execution_ids":w.jobs.map(func(j):return j.id),"method":"Real enqueue calls on a paused fixture, isolated GPU; no human play"}
	g.queue_redraw();g.hud.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+"/queue-groups.png")
	FileAccess.open(output+"/queue-groups.json",FileAccess.WRITE).store_string(JSON.stringify(record,"\t"))
	if not passed:push_error("Category heading / appended wall invariant failed")
	print("Queue group invariant: ",passed)
	quit(0 if passed else 1)
