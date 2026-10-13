extends Node
## Lightweight entry: no preload dependency on game, map or audio resources.
const Probe=preload("res://game/play_diagnostics.gd")
var probe
const SCENE="res://game/main.tscn"
var review_mode=false
var game
var finished=false
var failure=""
var frozen_ok=true
var timings={}
var overlay:CanvasLayer
var status:Label
var bar:ProgressBar
var started=0

func _ready():
	get_tree().auto_accept_quit=false
	started=Time.get_ticks_usec()
	Probe.configure();probe=Probe.new();probe.boot=self;add_child(probe)
	overlay=CanvasLayer.new();overlay.layer=100;add_child(overlay)
	var background=ColorRect.new();background.color=Color("344c3b");background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);overlay.add_child(background)
	var center=CenterContainer.new();center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);background.add_child(center)
	var box=VBoxContainer.new();box.custom_minimum_size=Vector2(480,180);box.add_theme_constant_override("separation",20);center.add_child(box)
	var font=load("res://assets/fonts/ui_font.tres")
	var title=Label.new();title.text="ホイッスル牧場";title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;title.add_theme_font_override("font",font);title.add_theme_font_size_override("font_size",30);title.modulate=Color("eee3c5");box.add_child(title)
	status=Label.new();status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;status.add_theme_font_override("font",font);status.add_theme_font_size_override("font_size",18);status.modulate=Color("ddd6b7");box.add_child(status)
	bar=ProgressBar.new();bar.custom_minimum_size=Vector2(480,12);bar.show_percentage=false;box.add_child(bar)
	var fill=StyleBoxFlat.new();fill.bg_color=Color("c7aa64");bar.add_theme_stylebox_override("fill",fill)
	var back=StyleBoxFlat.new();back.bg_color=Color("263d31");bar.add_theme_stylebox_override("background",back)
	call_deferred("prepare")

func stage(message: String,value: float):
	status.text=message;bar.value=value
	await get_tree().process_frame
	if DisplayServer.get_name()!="headless":await RenderingServer.frame_post_draw

func fail(message: String):
	failure=message;status.text=message+"\n閉じて、もう一度起動してください。";push_error(message)

func prepare():
	await stage("素材を読み込んでいます…",5)
	timings.first_loading_frame_ms=(Time.get_ticks_usec()-started)/1000.0
	var began=Time.get_ticks_usec()
	if ResourceLoader.load_threaded_request(SCENE)!=OK:fail("素材の読み込みを開始できませんでした");return
	var progress=[]
	while true:
		var state=ResourceLoader.load_threaded_get_status(SCENE,progress)
		if state==ResourceLoader.THREAD_LOAD_LOADED:break
		if state in [ResourceLoader.THREAD_LOAD_FAILED,ResourceLoader.THREAD_LOAD_INVALID_RESOURCE]:fail("素材を読み込めませんでした");return
		if not progress.is_empty():bar.value=5+float(progress[0])*45
		await get_tree().process_frame
	var scene=ResourceLoader.load_threaded_get(SCENE)
	# This existing isolated runner owns scene construction and never starts a player world.
	if "--review-onsite" in OS.get_cmdline_user_args() and "--isolated-review" in OS.get_cmdline_user_args() and OS.get_environment("FARM_REVIEW_OUTPUT")!="":
		get_tree().change_scene_to_packed(scene);return
	timings.resource_load_ms=(Time.get_ticks_usec()-began)/1000.0
	await stage("牧場と住人を準備しています…",55)
	if review_mode and DisplayServer.get_name()!="headless":get_viewport().get_texture().get_image().save_png(OS.get_environment("FARM_REVIEW_OUTPUT")+"/loading.png")
	began=Time.get_ticks_usec()
	game=scene.instantiate();game.startup_loading=true;game.automated=review_mode
	game.process_mode=Node.PROCESS_MODE_DISABLED
	add_child(game)
	while not game.loading_initialized:await get_tree().process_frame
	timings.world_and_scene_ms=(Time.get_ticks_usec()-began)/1000.0
	var frozen_tick=game.world.tick
	await stage("地面と描画を準備しています…",85)
	began=Time.get_ticks_usec()
	# Submit the actual initial view while the opaque loading layer still owns input.
	# Simulation remains disabled; GPU upload and initial _draw caches finish here.
	for frame in range(4):
		game.queue_redraw();game.hud.queue_redraw()
		await get_tree().process_frame
		if DisplayServer.get_name()!="headless":await RenderingServer.frame_post_draw
	frozen_ok=game.world.tick==frozen_tick
	if not frozen_ok:fail("牧場の準備状態を確認できませんでした");return
	timings.initial_draw_ms=(Time.get_ticks_usec()-began)/1000.0
	await stage("準備ができました",100)
	game.accumulated=0;game.keys_down.clear()
	game.startup_loading=false;game.process_mode=Node.PROCESS_MODE_INHERIT
	game.set_process(true);game.set_process_input(true);game.set_process_unhandled_input(true)
	overlay.queue_free();finished=true
	timings.until_control_ms=(Time.get_ticks_usec()-started)/1000.0
	probe.mark_ready(timings)
	game.start_entry_reviews()
	set_process(false)

func _input(_event):
	if not finished:get_viewport().set_input_as_handled()

func _notification(what):
	# Closing a partial startup must not save an incomplete/new world over an existing one.
	if what==NOTIFICATION_WM_CLOSE_REQUEST and not finished:get_tree().quit()
