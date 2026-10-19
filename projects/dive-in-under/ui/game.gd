extends "res://ui/main.gd"
const Expedition = preload("res://core/expedition.gd")
const SaveStore = preload("res://core/save_store.gd")
var last_defense_flash := ""
var legacy_persistence_mode:=false
var session_departed:=false
var preparation_music: Node
var route_map_open:=false
var play_view: Control
var equipment_focus: String="head"
var cfg: Dictionary
var campaign: Dictionary = {}
var save_store: RefCounted
var loaded: Dictionary = {}
var play_timer: Timer
var auto_play := true
var play_speed := 1
var ui_mode := "title"
var notice := ""
var play_buttons: Dictionary = {}
var town_page := "hub"
var warehouse_state: Dictionary = {}
var warehouse_view: Control
var status_view: Control
var status_return_page := "hub"
var new_button: Button
var confirm_button: Button
var continue_button: Button
var resume_probe := false
var campaign_replay_path := ""
var campaign_resume := false
var campaign_final_probe := false
var migration_probe := false
var migration_resume := false
const MigrationProbe = preload("res://ui/migration_probe.gd")
var campaign_seed := 123
const CampaignReplay = preload("res://ui/campaign_replay.gd")

func initialize_game() -> void:
	get_window().title="Dive In Under 0.6.2"
	Engine.max_fps=60
	legacy_persistence_mode=smoke_dir!="" and "--legacy-persistence-check" in OS.get_cmdline_user_args()
	cfg=Expedition.load_config()
	if cfg.is_empty(): get_tree().quit(1); return
	var save_path := "user://campaign-v1.json"
	if smoke_dir!="": save_path=smoke_dir.path_join("campaign-smoke.json")
	for arg in OS.get_cmdline_user_args():
		if arg=="--resume-probe": resume_probe=true
		if smoke_dir!="" and arg=="--migration-probe": migration_probe=true
		if smoke_dir!="" and arg=="--migration-resume": migration_resume=true
		if smoke_dir!="" and arg.begins_with("--campaign-replay="): campaign_replay_path=arg.trim_prefix("--campaign-replay=")
		if arg=="--campaign-resume": campaign_resume=true
		if arg=="--campaign-final-probe": campaign_final_probe=true
		if smoke_dir!="" and arg.begins_with("--campaign-seed="): campaign_seed=int(arg.trim_prefix("--campaign-seed="))
	if legacy_persistence_mode:
		save_store=SaveStore.new(save_path,data,cfg)
		loaded=save_store.load_game(); cfg=save_store.cfg
		if loaded.ok: campaign=loaded.state
	else:
		loaded={"ok":false,"status":"missing"}
	play_timer=Timer.new()
	play_timer.wait_time=0.6
	play_timer.timeout.connect(func(): if campaign.get("phase")=="battle" and ui_mode=="campaign": perform("round",{},int(campaign.revision)))
	add_child(play_timer)
	preparation_music=Node.new()
	preparation_music.set_script(preload("res://ui/preparation_music.gd"))
	add_child(preparation_music)
	get_tree().auto_accept_quit=false

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST:
		# Every accepted action is already committed. Closing never advances the world.
		get_tree().quit()

func show_title() -> void:
	preparation_music.set_preparation_active(false)
	if not legacy_persistence_mode:
		timer.stop(); play_timer.stop(); ui_mode="title"; title_visible=true; show_play_view("title"); return
	background.set_depth(1)
	timer.stop()
	if is_instance_valid(play_timer): play_timer.stop()
	ui_mode="title"; title_visible=true
	var root:=root_layout()
	root.add_child(text_label("D I V E   I N   U N D E R",46))
	root.add_child(text_label("深く、まだ見ぬ地下へ。",22))
	var gap:=Control.new(); gap.custom_minimum_size.y=35; root.add_child(gap)
	var row:=HBoxContainer.new(); row.add_theme_constant_override("separation",32); root.add_child(row)
	var left:=column(row,500)
	section_heading(left,"ひとりで潜り、町へ持ち帰る")
	continue_button=button("続きから",continue_campaign)
	continue_button.disabled=not loaded.get("ok",false)
	left.add_child(continue_button)
	new_button=button("新しく始める",request_new)
	left.add_child(new_button)
	if loaded.get("status","")=="recoverable": left.add_child(button("前回の保存から復旧する",recover_campaign))
	left.add_child(button("終了",func(): get_tree().quit()))
	var right:=column(row,400)
	section_heading(right,"探索・帰還・再挑戦")
	var explanation:=text_label("最初から1Fを探索し、解決後は町へ帰還できます。\nHPが0になると通常の死亡です。町で回復し何度でも挑めます。\n\n変更は操作ごとに自動保存されます。",18)
	explanation.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; right.add_child(explanation)
	if smoke_dir!="" or "--developer-tools" in OS.get_cmdline_user_args():
		right.add_child(HSeparator.new())
		launch_button=button("開発用：単発戦闘の確認",show_battle)
		right.add_child(launch_button)
		right.add_child(text_label("本編の保存・成長へは影響しません。",16))
	if loaded.get("status","") not in ["ok","missing"]: notice=loaded.get("error","")
	var status:=text_label(notice,16); status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; root.add_child(status)
	var spacer:=Control.new(); spacer.size_flags_vertical=Control.SIZE_EXPAND_FILL; root.add_child(spacer)
	root.add_child(text_label("0.5.4",16))
	new_button.grab_focus()

func show_battle() -> void:
	preparation_music.set_preparation_active(false)
	play_timer.stop(); ui_mode="tool"; timer.wait_time=0.5
	super.show_battle()

func request_new() -> void:
	if not legacy_persistence_mode:
		if campaign.is_empty(): start_new()
		else: show_campaign()
		return
	if FileAccess.file_exists(save_store.path):
		var root:=root_layout()
		root.add_child(text_label("新しい探索を始めますか",32))
		root.add_child(text_label("現在の保存を同じ保存先に退避して、新しく始めます。",20))
		confirm_button=button("保存を退避して新しく始める",start_new)
		root.add_child(confirm_button)
		root.add_child(button("戻る",show_title))
	else: start_new()

func start_new() -> void:
	if not legacy_persistence_mode:
		cfg=Expedition.load_config(); campaign=Expedition.fresh(cfg,campaign_seed if smoke_dir!="" else int(Time.get_ticks_usec()%2147483647))
		campaign.phase="town"; town_page="hub"; session_departed=false; warehouse_state={}; auto_play=true; notice=""; show_campaign(); return
	var error: String=save_store.preserve_current()
	if error!="": notice=error; show_title(); return
	cfg=Expedition.load_config(); save_store.cfg=cfg
	var candidate:=Expedition.fresh(cfg,campaign_seed if smoke_dir!="" else int(Time.get_ticks_usec()%2147483647))
	candidate=Expedition.act(candidate,"descend",int(candidate.revision),{},data,cfg)
	error=save_store.write_game(candidate)
	if error!="": notice=error; show_title(); return
	campaign=candidate; loaded={"ok":true,"status":"ok"}; notice=""; auto_play=true
	show_campaign()

func recover_campaign() -> void:
	var error: String=save_store.preserve_current()
	if error=="": error=save_store.write_game(loaded.state)
	if error!="": notice=error; show_title(); return
	continue_campaign()

func continue_campaign() -> void:
	loaded=save_store.load_game()
	if not loaded.ok: notice=loaded.error; show_title(); return
	cfg=save_store.cfg
	campaign=loaded.state; auto_play=false; notice=""; show_campaign()

func perform(action: String, args: Dictionary, revision: int) -> void:
	var candidate:=Expedition.act(campaign,action,revision,args,data,cfg)
	if candidate==campaign:
		if action=="organize": notice="すでに選択した順序に整理されています。"; show_campaign()
		return
	if legacy_persistence_mode:
		var error: String=save_store.write_game(candidate)
		if error!="":
			auto_play=false; notice="保存できないため操作を取り消しました："+error
			show_campaign(); return
	elif action=="depart":
		if not session_departed: candidate.trips-=1
		session_departed=true
		candidate=Expedition.act(candidate,"descend",int(candidate.revision),{},data,cfg)
	campaign=candidate; loaded={"ok":true,"status":"ok"}; notice=""
	if action=="town": town_page="hub"
	if action in ["deposit","withdraw","to_cloth"]:
		warehouse_state.uid=args.get("uid","")
		warehouse_state.source={"deposit":"warehouse","withdraw":"inventory","to_cloth":"cloth"}[action]
		notice={"deposit":"倉庫へ預けました。","withdraw":"バックパックへ引き出しました。","to_cloth":"父親の風呂敷へ移しました。"}[action]
	if action=="organize": notice="選択した順序に整理しました。"
	show_campaign()

func command(label: String, action: String, args: Dictionary = {}) -> Button:
	var revision:=int(campaign.revision)
	var b:=button(label,func(): perform(action,args,revision))
	play_buttons[action]=b
	b.set_meta("campaign_action",action); b.set_meta("campaign_args",args)
	return b

func paragraph(parent: Node, value: String, font_size: int = 18) -> Label:
	var l:=text_label(value,font_size); l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; parent.add_child(l); return l

func portrait(parent: Node, height: float) -> void:
	var texture := VisualAssets.actor_texture("hero")
	if texture == null: return
	var image := TextureRect.new()
	image.texture = texture
	image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.custom_minimum_size = Vector2(height*1.1,height)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(image)

func show_play_view(mode: String) -> void:
	root_layout()
	var old:=screen.get_child(0); screen.remove_child(old); old.queue_free()
	for side in ["left","right","top","bottom"]: screen.add_theme_constant_override("margin_"+side,0)
	play_view=Control.new(); play_view.set_script(preload("res://ui/play_view.gd")); play_view.game=self; play_view.mode=mode; screen.add_child(play_view)
func show_campaign() -> void:
	preparation_music.set_preparation_active(campaign.get("phase")=="town")
	if not legacy_persistence_mode:
		timer.stop(); play_timer.stop(); title_visible=false; ui_mode="campaign"; play_buttons={}
		background.set_depth(maxi(1,int(campaign.floor)))
		if campaign.phase=="town" and town_page in ["status","warehouse"]:
			root_layout()
			var old:=screen.get_child(0); screen.remove_child(old); old.queue_free()
			for side in ["left","right","top","bottom"]: screen.add_theme_constant_override("margin_"+side,0)
			if town_page=="status":
				status_view=Control.new(); status_view.set_script(preload("res://ui/status_view.gd")); status_view.game=self; status_view.return_page="hub"; screen.add_child(status_view)
			else:
				warehouse_view=Control.new(); warehouse_view.set_script(preload("res://ui/warehouse_view.gd")); warehouse_view.game=self; screen.add_child(warehouse_view)
		else:
			show_play_view("equipment" if campaign.phase=="town" and town_page=="equipment" else ("hub" if campaign.phase=="town" else ("result" if campaign.phase=="result" else "exploration")))
		if campaign.phase=="battle" and auto_play: play_timer.wait_time=0.6/play_speed; play_timer.start()
		return
	timer.stop(); play_timer.stop(); title_visible=false; ui_mode="campaign"; play_buttons={}
	background.set_depth(campaign.floor if campaign.phase not in ["town","result"] else 1)
	if campaign.phase in ["explore","battle","event"]:
		show_wide_exploration()
		if campaign.phase=="battle" and auto_play:
			play_timer.wait_time=0.6/play_speed; play_timer.start()
		return
	if campaign.phase=="town" and town_page in ["warehouse","status"]:
		root_layout()
		var old_root:=screen.get_child(0); screen.remove_child(old_root); old_root.queue_free()
		for side in ["left","right","top","bottom"]: screen.add_theme_constant_override("margin_"+side,0)
		if town_page=="warehouse":
			warehouse_view=Control.new(); warehouse_view.set_script(preload("res://ui/warehouse_view.gd")); warehouse_view.game=self; screen.add_child(warehouse_view)
		else:
			status_view=Control.new(); status_view.set_script(preload("res://ui/status_view.gd")); status_view.game=self; status_view.return_page=status_return_page; screen.add_child(status_view)
		return
	var root:=root_layout()
	var header:=HBoxContainer.new(); header.custom_minimum_size.y=52; root.add_child(header)
	var names: Dictionary={"explore":"地下への道","battle":"自動戦闘","event":"地下の出来事","result":"探索結果","town":"町 / 装備" if town_page=="equipment" else "地下の町"}
	var heading:=text_label(names[campaign.phase],30); heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL; header.add_child(heading)
	var title:=button("保存済み / タイトルへ",func(): loaded=save_store.load_game(); show_title())
	header.add_child(title); play_buttons["title"]=title
	if campaign.phase=="town":
		if town_page=="equipment": show_equipment(root)
		else: show_town_hub(root)
	elif campaign.phase=="result": show_result(root)
	else: show_wide_exploration()
	var footer:=text_label(notice if notice!="" else "0.5.4  ·  自動保存済み",15)
	footer.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; root.add_child(footer)
	if campaign.phase=="battle" and auto_play:
		play_timer.wait_time=0.6/play_speed; play_timer.start()

func compact_control(control: Button) -> Button:
	control.custom_minimum_size.y=42
	for mode in ["normal","hover","pressed","disabled","focus"]:
		var style:=theme.get_stylebox(mode,"Button").duplicate() as StyleBoxFlat
		style.set_content_margin_all(7)
		control.add_theme_stylebox_override(mode,style)
	return control

func show_wide_exploration() -> void:
	var root:=root_layout()
	for side in ["left","right","top","bottom"]: screen.add_theme_constant_override("margin_"+side,16)
	root.add_theme_constant_override("separation",0)
	var row:=HBoxContainer.new(); row.add_theme_constant_override("separation",16); row.size_flags_vertical=Control.SIZE_EXPAND_FILL; root.add_child(row)
	var field:=VBoxContainer.new(); field.custom_minimum_size.x=896; field.size_flags_horizontal=Control.SIZE_EXPAND_FILL; field.add_theme_constant_override("separation",12); row.add_child(field)
	var picture:=Control.new(); picture.set_script(BattleStage); picture.wide_layout=true; picture.floor_number=campaign.floor; picture.enemy_id=campaign.battle.get("enemy_id",""); field.add_child(picture)
	# Small live HUD over the distant scenery; the floor remains unobstructed.
	var hud:=PanelContainer.new(); hud.position=Vector2(12,12); hud.size=Vector2(490,0)
	hud.add_theme_stylebox_override("panel",box(Color(0.025,0.07,0.085,0.92),Color("b18a4d"),2)); picture.add_child(hud)
	var hud_rows:=VBoxContainer.new(); hud_rows.add_theme_constant_override("separation",3); hud.add_child(hud_rows)
	if campaign.phase=="battle":
		var b:=Expedition.battle_state(campaign,data)
		var overlay:=Control.new(); overlay.set_script(StatusOverlay); overlay.battle=b
		var key: String="%s/%s/%s"%[campaign.battle.seed,b.round,campaign.revision]
		if key!=last_defense_flash:
			overlay.effects=b.log.filter(func(entry):return entry.round==b.round and (entry.type in ["status_applied","status_damage","action_skipped"] or (entry.type=="skill" and entry.skill=="S105")))
			last_defense_flash=key
		picture.add_child(overlay)
		hud_rows.add_child(text_label("%s Lv.%d  HP %d / %d  ROUND %02d" % [b.enemy.name,b.enemy.level,b.enemy.hp,b.enemy.max_hp,b.round],18))
		if VisualAssets.actor_texture(b.enemy.id)==null: hud_rows.add_child(text_label("静止画像待ち / 敵IDを仮表示",15))
		var enemy_status: String=StatusOverlay.status_text(b.enemy)
		if enemy_status!="": hud_rows.add_child(text_label(enemy_status,15))
		var bar:=health_bar(Color("b4523b")); bar.max_value=b.enemy.max_hp; bar.value=b.enemy.hp; hud_rows.add_child(bar)
	else:
		hud_rows.add_child(text_label("地下 %d F  /  %s" % [campaign.floor,VisualAssets.depth_name(campaign.floor)],22))
		var message: String=cfg.events[campaign.event].name if campaign.phase=="event" else ("勝利 / 次の一歩を選ぶ" if campaign.get("last_outcome","")=="victory" else "静かな通路")
		hud_rows.add_child(text_label(message,18))
	var journal:=VBoxContainer.new(); journal.add_theme_constant_override("separation",4); journal.size_flags_vertical=Control.SIZE_EXPAND_FILL; field.add_child(journal)
	var log_heading:=PanelContainer.new(); var heading_style:=box(Color("081215"),Color("987b49")); heading_style.set_content_margin_all(4); log_heading.add_theme_stylebox_override("panel",heading_style); journal.add_child(log_heading)
	log_heading.add_child(text_label("メッセージ / 戦闘は完全自動",16))
	var log:=RichTextLabel.new(); log.custom_minimum_size.y=128; log.size_flags_vertical=Control.SIZE_EXPAND_FILL; log.scroll_following=true
	log.add_theme_stylebox_override("normal",box(Color("081215"),Color("987b49")))
	log.text="\n".join(campaign.journal); journal.add_child(log)
	var status:=column(row,336,true); status.get_parent().z_index=1000; status.get_parent().clip_contents=true; status.get_parent().size_flags_horizontal=Control.SIZE_FILL; status.add_theme_constant_override("separation",6)
	var h:=Expedition.hero(campaign,cfg)
	section_heading(status,"主人公 / Lv.%d" % h.level)
	status.add_child(text_label("HP  %d / %d" % [h.hp,h.max_hp],20))
	var hpbar:=health_bar(Color("a84936")); hpbar.max_value=h.max_hp; hpbar.value=h.hp; status.add_child(hpbar)
	status.add_child(text_label("SP  %d / %d" % [h.sp,h.max_sp],20))
	var spbar:=health_bar(Color("327e9b")); spbar.max_value=maxi(1,h.max_sp); spbar.value=h.sp; status.add_child(spbar)
	paragraph(status,"ATK %d   DEF %d   SPD %d\nGold %d  / 携行品 %d個" % [h.atk,h.def,h.spd,campaign.gold,campaign.inventory.size()],18)
	var defense_text: String="防御 / 自動・SP%d"%int(data.rules.skills.S105.sp_cost)
	if campaign.phase=="battle":
		var defense_state:=Expedition.battle_state(campaign,data)
		var status_text: String=StatusOverlay.status_text(defense_state.hero)
		if status_text!="": paragraph(status,status_text,16)
		if defense_state.hero.defense_until>=0:
			defense_text+="\n防御中 DEF %.1f / 次の自身行動終了まで"%Expedition.Combat.effective_def(defense_state.hero,data.rules)
		elif not "S105" in defense_state.hero.skills:
			defense_text+="\n旧戦闘の継続中 / 次の戦闘から使用"
		elif defense_state.hero.cooldown_until>defense_state.hero.action_count:
			defense_text+="\n再使用まで残り%d行動機会"%int(defense_state.hero.cooldown_until-defense_state.hero.action_count)
		elif h.sp<int(data.rules.skills.S105.sp_cost): defense_text+="\nSP不足 / 町で回復"
		else: defense_text+="\nHP60%以下で自動使用"
	else: defense_text+="\nHP60%以下で自動使用"
	var defense_label:=paragraph(status,defense_text,15)
	defense_label.add_theme_color_override("font_color",Color("124459"))
	var growth:=Expedition.level_info(campaign,cfg)
	paragraph(status,"次のLvまで EXP %d / %d" % [growth.progress,growth.next],16)
	section_heading(status,"地下 %d F / 最深 %d F" % [campaign.floor,campaign.highest_floor])
	paragraph(status,VisualAssets.depth_name(campaign.floor),17)
	paragraph(status,"第 %d 回の通常探索" % Expedition.normal_trips(campaign),16)
	var down:=compact_control(command("さらに潜る" if campaign.floor>0 else "地下1Fへ潜る","descend")); down.disabled=campaign.phase!="explore" or campaign.floor>=10; status.add_child(down)
	var retreat:=compact_control(command("町へ帰還する","return")); retreat.disabled=campaign.phase!="explore"; status.add_child(retreat)
	if campaign.phase=="battle":
		var playback:=HBoxContainer.new(); playback.add_theme_constant_override("separation",8); status.add_child(playback)
		var pause:=compact_control(button("一時停止" if auto_play else "戦闘を再開",func(): auto_play=not auto_play; show_campaign())); pause.size_flags_horizontal=Control.SIZE_EXPAND_FILL; playback.add_child(pause); play_buttons["pause"]=pause
		var speed:=compact_control(button("速度 %d倍" % play_speed,func(): play_speed=2 if play_speed==1 else 1; show_campaign())); playback.add_child(speed)
	if campaign.phase=="event":
		status.add_child(compact_control(command(cfg.events[campaign.event].choice,"event",{"choice":"accept"})))
		status.add_child(compact_control(command("見送る","event",{"choice":"skip"})))
	var spacer:=Control.new(); spacer.size_flags_vertical=Control.SIZE_EXPAND_FILL; status.add_child(spacer)
	paragraph(status,notice if notice!="" else "0.5.0 / 自動保存済み",14)
	var title:=compact_control(button("保存済み / タイトルへ",func(): loaded=save_store.load_game(); show_title())); status.add_child(title); play_buttons["title"]=title

func show_result(root: VBoxContainer) -> void:
	var row:=HBoxContainer.new(); row.size_flags_vertical=Control.SIZE_EXPAND_FILL; row.add_theme_constant_override("separation",32); root.add_child(row)
	var info:=column(row,700)
	var labels: Dictionary={"death":"主人公死亡","story_death":"旧版の導入イベント記録","return":"帰還成功","draw":"戦闘打切り / 探索中断","clear":"10F突破"}
	var banner:=paragraph(info,labels[campaign.result.kind],36)
	banner.add_theme_color_override("font_color",Color("f0bd72"))
	paragraph(info,campaign.result.reason,24)
	paragraph(info,"到達 %dF   /   Lv.%d   /   Gold %d" % [campaign.result.floor,Expedition.hero(campaign,cfg).level,campaign.gold],22)
	var loss: Dictionary=campaign.result.loss
	paragraph(info,"今回の損失：Gold %d / EXP %d / 携行品 %d\n町ではHP/SPを全回復します。再挑戦に費用はかかりません。" % [loss.gold,loss.exp,loss.items],18)
	if campaign.result.kind=="story_death": paragraph(info,"旧版の履歴です。通常死亡数には加えません。町へ戻って探索を続けられます。",18)
	info.add_child(command("町へ戻り、再挑戦の準備","town"))
	var log:=column(row,350,true)
	section_heading(log,"最後の記録")
	paragraph(log,"\n".join(campaign.journal.slice(-7)),17)

func compact_button(label: String, callback: Callable) -> Button:
	var b:=button(label,callback); b.custom_minimum_size.y=28; b.add_theme_font_size_override("font_size",16)
	for state_name in ["normal","hover","pressed","disabled"]:
		var style: StyleBoxFlat=theme.get_stylebox("normal" if state_name=="disabled" else state_name,"Button").duplicate()
		style.content_margin_top=3; style.content_margin_bottom=3
		if state_name=="disabled":
			style.bg_color=Color("c0ad83"); style.border_color=Color("a28c61"); style.shadow_size=0
		b.add_theme_stylebox_override(state_name,style)
	b.add_theme_color_override("font_disabled_color",Color("70634a"))
	return b

func item_picture(uid: String, pixels: int=32) -> TextureRect:
	var t:=TextureRect.new(); t.texture=preload("res://ui/equipment_art.gd").texture(campaign.items[uid],cfg.items[campaign.items[uid]].slot)
	t.custom_minimum_size=Vector2(pixels,pixels); t.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; t.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST; t.mouse_filter=Control.MOUSE_FILTER_IGNORE; return t

func item_list(parent: VBoxContainer, source: String) -> void:
	var scroll:=ScrollContainer.new(); scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL; scroll.custom_minimum_size.y=200; parent.add_child(scroll)
	var list:=VBoxContainer.new(); list.size_flags_horizontal=Control.SIZE_EXPAND_FILL; scroll.add_child(list)
	for uid in campaign[source]:
		var item: Dictionary=cfg.items[campaign.items[uid]]
		var heading:=HBoxContainer.new(); list.add_child(heading); heading.add_child(item_picture(uid)); heading.add_child(text_label(item.name,17))
		if item.slot!="": paragraph(list,condition_text(uid),15)
		var effects := item_effects(item,uid)
		if effects != "": paragraph(list,effects,15)
		var row:=HBoxContainer.new(); list.add_child(row)
		var revision:=int(campaign.revision)
		if source=="inventory":
			var equip:=compact_button("装備",func(): perform("equip",{"uid":uid},revision)); equip.disabled=item.slot==""; equip.set_meta("campaign_action","equip"); equip.set_meta("campaign_args",{"uid":uid}); row.add_child(equip)
		if item.slot!="": row.add_child(repair_button(uid))
		list.add_child(HSeparator.new())
	if campaign[source].is_empty(): paragraph(list,"まだ何もありません。",17)

func condition_text(uid: String) -> String:
	var value: Dictionary=campaign.item_condition[uid]
	return "%s耐久 %d/%d"%["破損 / " if value.current==0 else "",value.current,value.maximum]

func repair_button(uid: String) -> Button:
	var price:=Expedition.Condition.cost(campaign,uid,cfg)
	var revision:=int(campaign.revision)
	var b:=compact_button("修理 %dG"%maxi(0,price),func(): perform("repair",{"uid":uid},revision))
	b.disabled=price<=0 or campaign.gold<price
	b.set_meta("campaign_action","repair"); b.set_meta("campaign_args",{"uid":uid})
	return b

func item_effects(item: Dictionary, uid: String="") -> String:
	var effects: Array[String] = []
	for key in item.stats:
		effects.append("%s %+d" % [{"max_hp":"HP","max_sp":"SP","atk":"ATK","def":"DEF","spd":"SPD"}[key],Expedition.Condition.bonus(campaign,uid,int(item.stats[key])) if uid!="" else int(item.stats[key])])
	return " / ".join(effects)

func open_town_page(page: String) -> void:
	town_page=page; show_campaign()

func open_status() -> void:
	if campaign.phase!="town": return
	status_return_page=town_page
	open_town_page("status")

func show_town_hub(root: VBoxContainer) -> void:
	var welcome:=column(root,700)
	section_heading(welcome,"次の旅の支度")
	paragraph(welcome,"ランタンの灯りが迎える、地下の町。
持ち帰った品を預け、装備を整えよう。",22)
	welcome.add_child(button("ステータス",open_status))
	welcome.add_child(button("倉庫を開く",func(): open_town_page("warehouse")))
	welcome.add_child(button("装備・修理",func(): open_town_page("equipment")))
	welcome.add_child(command("地下へ潜る","depart"))

func show_equipment(root: VBoxContainer) -> void:
	var h:=Expedition.hero(campaign,cfg)
	var summary:=PanelContainer.new()
	summary.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var summary_style:=box(Color("0b1d25"),Color("b18a4d"),2)
	summary_style.shadow_size=0
	summary_style.content_margin_left=12; summary_style.content_margin_right=12
	summary_style.content_margin_top=4; summary_style.content_margin_bottom=4
	summary.add_theme_stylebox_override("panel",summary_style)
	root.add_child(summary)
	var summary_text:=text_label("HP %d / %d   SP %d / %d   Lv.%d   ATK %d  DEF %d  SPD %d   /   Gold %d" % [h.hp,h.max_hp,h.sp,h.max_sp,h.level,h.atk,h.def,h.spd,campaign.gold],21)
	summary_text.add_theme_color_override("font_color",Color("f1ead9"))
	summary.add_child(summary_text)
	var row:=HBoxContainer.new(); row.size_flags_vertical=Control.SIZE_EXPAND_FILL; row.add_theme_constant_override("separation",16); root.add_child(row)
	var bag:=column(row,300); section_heading(bag,"所持品 / 携行"); item_list(bag,"inventory")
	var equipment:=column(row,430,true)
	var equipment_heading:=section_heading(equipment,"装備 / 11部位")
	portrait(equipment_heading,34)
	equipment.add_theme_constant_override("separation",1)
	var gear_scroll:=ScrollContainer.new(); gear_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL; equipment.add_child(gear_scroll)
	var gear_rows:=VBoxContainer.new(); gear_rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL; gear_scroll.add_child(gear_rows)
	var slot_index := 0
	for slot in Expedition.SLOTS:
		var uid: String=campaign.equipment[slot]
		var item: Dictionary = {} if uid=="" else cfg.items[campaign.items[uid]]
		var strip := PanelContainer.new()
		var strip_style := box(Color("cfb786") if slot_index%2==0 else Color("dac597"),Color("ad9060"),1)
		strip_style.shadow_size=0
		strip_style.content_margin_left=6; strip_style.content_margin_right=4
		strip_style.content_margin_top=0; strip_style.content_margin_bottom=0
		strip.add_theme_stylebox_override("panel",strip_style)
		gear_rows.add_child(strip)
		var strip_rows:=VBoxContainer.new(); strip_rows.add_theme_constant_override("separation",1); strip.add_child(strip_rows)
		var line:=HBoxContainer.new(); line.add_theme_constant_override("separation",5); strip_rows.add_child(line)
		if uid!="": line.add_child(item_picture(uid,24))
		var slot_label:=text_label(cfg.slots[slot],16); slot_label.custom_minimum_size.x=54; line.add_child(slot_label)
		var label:=text_label("—" if uid=="" else item.name,16)
		label.size_flags_horizontal=Control.SIZE_EXPAND_FILL; line.add_child(label)
		var effect:=text_label("" if uid=="" else item_effects(item,uid),14)
		effect.add_theme_color_override("font_color",Color("41452a")); line.add_child(effect)
		var revision:=int(campaign.revision)
		var remove:=compact_button("外す",func(): perform("unequip",{"slot":slot},revision)); remove.disabled=uid==""; remove.set_meta("campaign_action","unequip"); remove.set_meta("campaign_args",{"slot":slot}); line.add_child(remove)
		if uid!="":
			var condition_row:=HBoxContainer.new(); strip_rows.add_child(condition_row)
			var value:=text_label(condition_text(uid),14); value.size_flags_horizontal=Control.SIZE_EXPAND_FILL; condition_row.add_child(value)
			condition_row.add_child(repair_button(uid))
		slot_index += 1
	root.add_child(button("町へ戻る",func(): open_town_page("hub")))
	var depart:=command("HP/SP回復済み  →  もう一度地下へ","depart"); root.add_child(depart)

func smoke(quit_on_finish: bool = true) -> void:
	if "--bgm-review" in OS.get_cmdline_user_args():
		await preload("res://ui/bgm_review.gd").run(self); return
	if "--ui-feedback-review" in OS.get_cmdline_user_args():
		await preload("res://ui/feedback_review.gd").run(self); return
	if "--ui-integration-review" in OS.get_cmdline_user_args():
		await preload("res://ui/integration_review.gd").run(self); return
	if not legacy_persistence_mode:
		get_tree().quit(2); return # Explicit verification flag is required; never enter legacy tests from normal play.
	if "--equipment-assets-review" in OS.get_cmdline_user_args():
		await preload("res://ui/equipment_assets_review.gd").run(self); return
	if "--status-review" in OS.get_cmdline_user_args():
		await preload("res://ui/status_review.gd").run(self); return
	if "--warehouse-review" in OS.get_cmdline_user_args():
		await preload("res://ui/warehouse_review.gd").run(self); return
	if "--equipment-review" in OS.get_cmdline_user_args():
		await preload("res://ui/equipment_review.gd").run(self); return
	if "--enemy-art-review" in OS.get_cmdline_user_args():
		await preload("res://ui/enemy_art_review.gd").run(self); return
	if migration_probe:
		await MigrationProbe.run(self,migration_resume); return
	if campaign_replay_path!="":
		await CampaignReplay.run(self); return
	if resume_probe:
		var original = JSON.parse_string(FileAccess.get_file_as_string(smoke_dir.path_join("ui-smoke.json")))
		if not smoke_check(loaded.ok and campaign.schema_version==5 and campaign.revision==original.saved_revision and save_store.digest()==original.saved_sha256,"Separate EXE restart checkpoint"): return
		var f:=FileAccess.open(smoke_dir.path_join("resume-smoke.json"),FileAccess.WRITE)
		f.store_string(JSON.stringify({"run_id":smoke_run_id,"restart_loaded":true,"revision":campaign.revision,"phase":campaign.phase,"save_sha256":save_store.digest()},"\t")); f.close()
		get_tree().quit(); return
	await super.smoke(false)
	if smoke_report.is_empty(): return
	var rendered:=DisplayServer.get_name()!="headless"
	await click_control(new_button)
	if is_instance_valid(confirm_button) and confirm_button.is_inside_tree(): await click_control(confirm_button)
	auto_play=false; play_timer.stop()
	if not smoke_check(campaign.floor==1 and campaign.story_deaths==0,"New game enters normal 1F"): return
	if rendered: await capture("04-first-exploration.png")
	await click_control(play_buttons.title); await click_control(continue_button)
	if not smoke_check(campaign.floor==1 and campaign.story_deaths==0,"Continue initial normal exploration"): return
	while campaign.phase=="battle": perform("round",{},int(campaign.revision))
	if campaign.phase=="event": perform("event",{"choice":"skip"},int(campaign.revision))
	if not smoke_check(campaign.phase=="explore" and not play_buttons["return"].disabled,"First return enabled after encounter"): return
	await click_control(play_buttons["return"])
	if not smoke_check(campaign.result.kind=="return" and campaign.deaths==0,"Initial living return saved"): return
	if rendered: await capture("05-first-return.png")
	await click_control(play_buttons.title); await click_control(continue_button)
	if not smoke_check(campaign.result.kind=="return","Continue initial return result"): return
	await click_control(play_buttons.town)
	if rendered: await capture("06-town.png")
	var uid: String=campaign.equipment.head
	if not await CampaignReplay.click(self,"unequip",{"slot":"head"}): return
	await CampaignReplay.click(self,"deposit",{"uid":uid})
	await CampaignReplay.click(self,"withdraw",{"uid":uid})
	if not smoke_check(uid in campaign.inventory and campaign.warehouse.is_empty(),"Initial return enables warehouse roundtrip"): return
	# Find actual town buttons; core inventory stress tests separately cover every move.
	await CampaignReplay.click(self,"equip",{"uid":uid})
	if not smoke_check(campaign.equipment.head==uid,"Town equip input"): return
	await CampaignReplay.click(self,"depart",{})
	if not smoke_check(campaign.phase=="explore","Town departure input"): return
	auto_play=false
	await click_control(play_buttons.descend)
	if campaign.phase=="battle":
		play_timer.stop()
		if rendered: await capture("07-normal-battle.png")
		while campaign.phase=="battle": perform("round",{},int(campaign.revision))
	elif campaign.phase=="event": perform("event",{"choice":"skip"},int(campaign.revision))
	if not smoke_check(campaign.phase=="explore" and campaign.story_deaths==0,"Normal first floor survived"): return
	if rendered: await capture("10-normal-victory.png")
	await click_control(play_buttons["return"])
	if rendered: await capture("08-return-result.png")
	await click_control(play_buttons.town)
	await CampaignReplay.click(self,"depart",{})
	if not smoke_check(campaign.story_deaths==0 and campaign.hp>0,"Retry does not repeat forced death"): return
	# Proceed normally until a real death or 10F clear; no altered stats or forced outcomes.
	var budget:=0
	while campaign.phase!="result" and budget<600:
		if campaign.phase=="explore": await click_control(play_buttons.descend)
		elif campaign.phase=="battle": perform("round",{},int(campaign.revision))
		elif campaign.phase=="event": perform("event",{"choice":"accept"},int(campaign.revision))
		budget+=1
	if not smoke_check(campaign.phase=="result" and campaign.result.kind=="death" and campaign.story_deaths==0,"Normal combat death independent of tutorial"): return
	if rendered: await capture("09-normal-death.png")
	await click_control(play_buttons.town)
	await CampaignReplay.click(self,"depart",{})
	# A separate new profile verifies real HP0 on the very first ordinary expedition.
	await click_control(play_buttons.title)
	await click_control(new_button)
	if is_instance_valid(confirm_button) and confirm_button.is_inside_tree(): await click_control(confirm_button)
	auto_play=false; play_timer.stop(); budget=0
	while campaign.phase!="result" and budget<600:
		if campaign.phase=="explore": await click_control(play_buttons.descend)
		elif campaign.phase=="battle": perform("round",{},int(campaign.revision))
		elif campaign.phase=="event": perform("event",{"choice":"skip"},int(campaign.revision))
		budget+=1
	if not smoke_check(campaign.result.kind=="death" and campaign.hp==0 and campaign.trips==1 and campaign.deaths==1 and campaign.story_deaths==0,"First expedition dies only by normal HP0 combat"): return
	if rendered: await capture("25-first-normal-death.png")
	await click_control(play_buttons.title); await click_control(continue_button)
	if not smoke_check(campaign.result.kind=="death" and campaign.deaths==1,"First normal death result survives restart to title"): return
	await click_control(play_buttons.town); await CampaignReplay.click(self,"depart",{})
	# Leave a real, in-progress battle checkpoint for a separate EXE restart.
	budget=0
	while campaign.phase!="battle" and budget<10:
		if campaign.phase=="explore": await click_control(play_buttons.descend)
		elif campaign.phase=="event": perform("event",{"choice":"skip"},int(campaign.revision))
		budget+=1
	if not smoke_check(campaign.phase=="battle","Prepare midbattle restart"): return
	perform("round",{},int(campaign.revision))
	if not smoke_check(campaign.phase=="battle","Midbattle checkpoint remains active"): return
	smoke_report.loop_input=true; smoke_report.saved_revision=campaign.revision; smoke_report.saved_sha256=save_store.digest()
	smoke_report.normal_death_retry=true
	smoke_report.save_path=save_store.path; smoke_report.checkpoint_phase=campaign.phase
	await click_control(play_buttons.title)
	if not smoke_check(title_visible,"Final title after campaign"): return
	write_smoke_result()
	if quit_on_finish: get_tree().quit()

func find_button(node: Node, label: String) -> Button:
	if node is Button and node.text==label: return node
	for child in node.get_children():
		var found:=find_button(child,label)
		if found!=null: return found
	return null
