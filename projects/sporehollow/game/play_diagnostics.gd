extends Node
## Opt-in wall-clock frame samples. CPU scopes are nested, NOT additive GPU timings.
const Metrics=preload("res://game/terrain_metrics.gd")
const LIMIT=30000
const SECONDS=120.0
const CASES=["baseline","simple_ground","no_decor","no_scene","no_world","no_hud","no_audio","grain","noise","gravel","all_chunks","no_occupancy","legacy_color","manual_chunks"]
static var experiment="baseline"
static var requested=false
static var scripted=false
static var duration=120.0
static var gpu_timing=false
var active=false
var samples=[]
var stages={}
var boot
var started=0
var last=0
var ready_at=0
var previous_camera=Vector2.INF
var seen={}
var label:Label
var last_label=0
var result_path=""
var output="user://diagnostics"
var segment="loading"
var saved=false
static var input_events=0

static func configure():
	var args=OS.get_cmdline_user_args()
	requested="--diagnostics" in args
	gpu_timing="--diag-gpu" in args
	duration=120.0
	scripted=requested and "--diag-route" in args
	experiment="baseline"
	for arg in args:
		if requested and arg.begins_with("--diag-case="):
			var value=arg.trim_prefix("--diag-case=")
			if value in CASES:experiment=value
		if requested and arg.begins_with("--diag-seconds="):duration=clampf(float(arg.trim_prefix("--diag-seconds=")),30,120)

func _ready():
	process_mode=Node.PROCESS_MODE_ALWAYS
	var layer=CanvasLayer.new();layer.layer=120;add_child(layer)
	label=Label.new();label.position=Vector2(12,72);label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font",load("res://assets/fonts/ui_font.tres"));label.add_theme_font_size_override("font_size",14)
	label.add_theme_color_override("font_shadow_color",Color.BLACK);label.add_theme_constant_override("shadow_offset_x",1);label.add_theme_constant_override("shadow_offset_y",1)
	layer.add_child(label);label.hide();set_process(false)
	RenderingServer.frame_post_draw.connect(sample)
	if requested:
		if OS.get_environment("FARM_DIAG_OUTPUT")!="":output=OS.get_environment("FARM_DIAG_OUTPUT")
		begin()

func begin():
	active=true;saved=false;input_events=0;
	if gpu_timing:RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(),true)
	samples.clear();seen.clear();Metrics.frame.clear();Metrics.enabled=true
	started=Time.get_ticks_usec();last=started;previous_camera=Vector2.INF
	label.show();set_process(true)

static func observe_input(event):
	# Only count game-window presses, never record typed text or unrelated apps.
	if Metrics.enabled and ((event is InputEventKey and event.pressed and not event.echo) or (event is InputEventMouseButton and event.pressed)):input_events+=1

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F9:
		if active:stop()
		else:begin()
		get_viewport().set_input_as_handled()

func mark_ready(data):
	stages=data.duplicate();ready_at=Time.get_ticks_usec()
	stages.map_seed=boot.game.world.seed_value;stages.map_size=[boot.game.world.W,boot.game.world.H]
	stages.terrain_hash=hash(boot.game.world.terrain);stages.initial_tick=boot.game.world.tick
	stages.initial_camera=[boot.game.camera.position.x,boot.game.camera.position.y];stages.initial_zoom=boot.game.camera.zoom.x
	stages.resumed=FileAccess.file_exists(boot.game.development_save_path)
	stages.engine_to_loader_ms=boot.started/1000.0
	if active:
		stages.engine_to_loader_ms=boot.started/1000.0
		if scripted:
			boot.game.story_modal="";boot.game.world.story.intro_seen=true;boot.game.refresh()

func _process(_delta):
	if DisplayServer.get_name()=="headless":sample()
	if not active:return
	if scripted and ready_at>0:
		var g=boot.game;var t=(Time.get_ticks_usec()-ready_at)/1000000.0
		g.keys_down.clear()
		# Repeatable camera route. This is scripted movement, not an OS-input claim.
		if t<30:segment="idle_0_30"
		elif t<40:segment="scroll_new";g.keys_down[KEY_D]=true
		elif t<50:segment="scroll_return";g.keys_down[KEY_A]=true
		elif t<60:segment="scroll_diagonal";g.keys_down[KEY_D]=true;g.keys_down[KEY_W]=true
		elif t<70:segment="wide";g.camera.zoom=Vector2.ONE*0.35
		elif t<80:segment="wide_scroll";g.keys_down[KEY_S]=true
		else:segment="idle_80_120"
	var origin=maxi(ready_at,started) if requested and ready_at>0 else started
	if (ready_at>0 or not requested) and (Time.get_ticks_usec()-origin)/1000000.0>=duration:stop()

func sample():
	if not active:return
	var sample_started=Time.get_ticks_usec()
	var now=Time.get_ticks_usec();var ms=(now-last)/1000.0;last=now
	var row={"t_ms":(now-started)/1000.0,"frame_ms":ms,"cpu":Metrics.take(),"engine_process_ms":Performance.get_monitor(Performance.TIME_PROCESS)*1000.0,"memory_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"objects":Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),"ready_ms":(now-ready_at)/1000.0 if ready_at>0 else -1.0,"segment":segment,"focused":DisplayServer.window_is_focused()}
	if gpu_timing:
		var rid=get_viewport().get_viewport_rid()
		row.gpu_render_ms=RenderingServer.viewport_get_measured_render_time_gpu(rid)
		row.render_cpu_ms=RenderingServer.viewport_get_measured_render_time_cpu(rid)
		row.frame_setup_cpu_ms=RenderingServer.get_frame_setup_time_cpu()
	if ready_at>0 and boot.game!=null:
		var g=boot.game;var pos=g.camera.position;var view=g.get_canvas_transform().affine_inverse()*g.get_viewport_rect()
		var new_chunks=0
		for y in range(floori(view.position.y/336),ceili(view.end.y/336)):
			for x in range(floori(view.position.x/384),ceili(view.end.x/384)):
				var key=Vector2i(x,y)
				if not seen.has(key):seen[key]=true;new_chunks+=1
		row.merge({"camera":[pos.x,pos.y],"zoom":g.camera.zoom.x,"tick":g.world.tick,"paused":g.world.paused,"speed":g.speed,"menu_open":g.menu_open,"modal":g.story_modal!="" or g.field_book or g.field_shop,"input_events":input_events,"moving":pos!=previous_camera,"first_view_chunks":new_chunks});previous_camera=pos
	samples.append(row)
	if now-last_label>250000:
		label.text="診断 F9で保存 | %.0f FPS / %.1f ms | %.0f秒\n%s"%[1000.0/maxf(ms,0.01),ms,(now-started)/1000000.0,experiment];last_label=now
	Metrics.finish("diagnostic_sample",sample_started)
	if samples.size()>=LIMIT:call_deferred("stop")

static func summary(rows:Array)->Dictionary:
	if rows.is_empty():return {"frames":0}
	var values=[];var total=0.0;var over=[0,0,0]
	for row in rows:
		var ms=float(row.frame_ms);values.append(ms);total+=ms
		for i in range(3):
			if ms>[33,50,100][i]:over[i]+=1
	values.sort()
	return {"frames":rows.size(),"mean_ms":total/rows.size(),"fps":1000.0*rows.size()/maxf(total,0.01),"p95_ms":values[mini(values.size()-1,ceili(values.size()*0.95)-1)],"p99_ms":values[mini(values.size()-1,ceili(values.size()*0.99)-1)],"max_ms":values[-1],"over_33_50_100":over}

func stop():
	if not active:return
	active=false;
	if gpu_timing:RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(),false)
	Metrics.enabled=false;Metrics.frame.clear();set_process(false)
	var groups={"all":summary(samples)}
	for key in ["loading","first_30","30_120","moving","stationary","first_view","revisit","scroll_new","scroll_return","scroll_diagonal","wide","wide_scroll"]:
		var rows=samples.filter(func(r):
			match key:
				"loading":return r.ready_ms<0
				"first_30":return r.ready_ms>=0 and r.ready_ms<30000
				"30_120":return r.ready_ms>=30000
				"moving":return r.get("moving",false)
				"stationary":return r.ready_ms>=0 and not r.get("moving",false)
				"first_view":return r.get("first_view_chunks",0)>0
				"revisit":return r.get("moving",false) and r.get("first_view_chunks",0)==0
			return r.segment==key)
		groups[key]=summary(rows)
	DirAccess.make_dir_recursive_absolute(output)
	var files=Array(DirAccess.get_files_at(output)).filter(func(f):return f.begins_with("play-") and f.ends_with(".json"));files.sort()
	while files.size()>=5:DirAccess.remove_absolute(output+"/"+files.pop_front())
	result_path=output+"/play-%d.json"%int(Time.get_unix_time_from_system()*1000)
	var data={"schema":1,"case":experiment,"scripted_route":scripted,"input_events":input_events,"engine":Engine.get_version_info(),"renderer":RenderingServer.get_current_rendering_method(),"gpu":RenderingServer.get_video_adapter_name(),"audio_driver":AudioServer.get_driver_name(),"gpu_timing_enabled":gpu_timing,"vsync":DisplayServer.window_get_vsync_mode(),"fps_cap":Engine.max_fps,"window_mode":DisplayServer.window_get_mode(),"shader_cache":ProjectSettings.get_setting("rendering/shader_compiler/shader_cache/enabled"),"startup":stages,"summary":groups,"memory_note":"at most 30000 frame rows; at most 32 MiB JSON; five output files retained","frames":samples,"unavailable":["Present wait","OS compositor frame interval","driver shader compilation"],"timing_note":"GPU/render CPU timestamp queries are delayed by several frames, never subtract from same row wall time. A zero GPU query is unavailable, not zero workload. memory_bytes is Godot tracked static memory, not Windows working set. frame_ms = frame_post_draw callback interval, includes scheduling/vsync; cpu scopes nested and non-additive; engine_process_ms engine monitor may describe previous frame"}
	if FileAccess.file_exists("res://game/build_stamp.json"):data.build=JSON.parse_string(FileAccess.get_file_as_string("res://game/build_stamp.json"))
	var file=FileAccess.open(result_path,FileAccess.WRITE)
	if file==null:label.text="診断保存に失敗: "+error_string(FileAccess.get_open_error());return
	var encoded=JSON.stringify(data)
	if encoded.length()>32*1024*1024:
		data.frames=samples.map(func(r):
			var light=r.duplicate();light.cpu={} if r.frame_ms<=33 else r.cpu;return light)
		data.cpu_details_trimmed=true;encoded=JSON.stringify(data)
	file.store_string(encoded);file.close();saved=true
	label.text="診断を保存しました（F9で再計測）\n"+ProjectSettings.globalize_path(result_path)
	print("DIAGNOSTICS_SAVED ",ProjectSettings.globalize_path(result_path))
	if "--diag-shot" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless":
		get_viewport().get_texture().get_image().save_png(output+"/diagnostic.png")
	if scripted:
		boot.game.keys_down.clear();get_tree().quit()

func _notification(what):
	if what==NOTIFICATION_WM_CLOSE_REQUEST and active:stop()
