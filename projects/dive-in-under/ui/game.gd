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
var field_equipment:=false
var field_status:=false
var flow_selection: Dictionary={"kind":"actor","side":"hero"}
var event_choice: String=""
var event_choice_key: String=""
var ui_epoch:=0
var ui_block_until:=0
var last_e_down: int=-1000
var e_held:=false
var primary_button: Button
var secondary_button: Button
var modal_owner: Control
var x_held:=false
var last_x_down: int=-1000
var flow_memory: Dictionary={}
var last_left_item: String=""
var gear_drag: Dictionary={}
var status_memory: Dictionary={}
var equipment_candidate: String=""
var reward_selected: String=""
var replace_selected: String=""
var reward_confirmation: String=""
var presenting:=false
var presentation_battle: Dictionary={}
var presentation_journal: Array=[]
var presentation_generation:=0
var intro_active:=false
var intro_seen: Dictionary={}
var dungeon_music: AudioStreamPlayer
var dungeon_music_path: String=""
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
	get_window().title="Dive In Under "+str(ProjectSettings.get_setting("application/config/version"))
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
	play_timer.timeout.connect(func(): if campaign.get("phase")=="battle" and ui_mode=="campaign" and auto_play: perform("round",{},int(campaign.revision)))
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
	ui_epoch+=1; primary_button=null; secondary_button=null; modal_owner=null
	cancel_presentation(); intro_active=false; field_equipment=false
	if is_instance_valid(dungeon_music): dungeon_music.stop(); dungeon_music_path=""
	route_map_open=false
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
		flow_memory={}; cfg=Expedition.load_config(); campaign=Expedition.fresh(cfg,campaign_seed if smoke_dir!="" else int(Time.get_ticks_usec()%2147483647))
		Expedition.Journey.enable(campaign)
		campaign.phase="town"; campaign.trips=0; town_page="hub"; session_departed=false; warehouse_state={}; auto_play=true; notice=""; show_campaign(); return
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
	if presenting or intro_active:
		if action=="round": return
	var old_journal: Array=campaign.get("journal",[]).duplicate()
	var candidate:=Expedition.act(campaign,action,revision,args,data,cfg)
	if candidate==campaign:
		if action in ["organize","organize_bag"]: notice="すでに選択した順序に整理されています。"; show_campaign()
		return
	if legacy_persistence_mode:
		var error: String=save_store.write_game(candidate)
		if error!="":
			auto_play=false; notice="保存できないため操作を取り消しました："+error
			show_campaign(); return
	elif action=="depart":
		session_departed=true
		candidate=Expedition.act(candidate,"descend",int(candidate.revision),{},data,cfg)
	campaign=candidate; loaded={"ok":true,"status":"ok"}; notice=""
	if action in ["equip","equip_reward"]:
		var equipped_uid: String=args.get("uid","item-%d"%(int(campaign.next_item)-1))
		if campaign.items.has(equipped_uid):
			equipment_focus=cfg.items[campaign.items[equipped_uid]].slot
			flow_selection={"kind":"equipment","uid":equipped_uid,"slot":equipment_focus}
	elif action=="unequip" and not campaign.inventory.is_empty(): flow_selection={"kind":"inventory","uid":campaign.inventory[-1],"slot":""}
	elif action=="claim_reward": flow_selection={"kind":"inventory","uid":"item-%d"%(int(campaign.next_item)-1),"slot":""}
	if action in ["town","depart"]:
		town_page="hub"; field_equipment=false; intro_seen={}; intro_active=false; cancel_presentation()
		if action=="depart": auto_play=true
	if action=="round" and Expedition.Journey.active(campaign) and campaign.has("round_presentation"):
		presentation_journal=old_journal
		present_round(campaign.round_presentation)
		return
	if action in ["deposit","withdraw","to_cloth"]:
		warehouse_state.uid=args.get("uid","")
		warehouse_state.source={"deposit":"warehouse","withdraw":"inventory","to_cloth":"cloth"}[action]
		notice={"deposit":"倉庫へ預けました。","withdraw":"バックパックへ引き出しました。","to_cloth":"父親の風呂敷へ移しました。"}[action]
	if action in ["organize","organize_bag"]: notice="選択した順序に整理しました。"
	if action=="open_chest": preload("res://ui/journey_sound.gd").play(self,330)
	if action=="transfer": notice="%sへ移しました。×1 / 個体・耐久を保持"%{"warehouse":"倉庫","inventory":"バックパック","cloth":"父親の風呂敷"}[args.destination]
	if action in ["claim_reward","exchange_reward","abandon_rewards","equip_reward"]: reward_confirmation=""
	if action in ["equip","unequip"]: equipment_candidate=""
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
	remember_flow()
	ui_epoch+=1; primary_button=null; secondary_button=null; modal_owner=null
	if campaign.get("phase") in ["result","town"]:
		route_map_open=false; field_equipment=false; field_status=false
		if not presenting: presentation_battle={}
	if Expedition.Journey.active(campaign) and campaign.get("phase")=="battle" and not presenting: ensure_intro()
	update_dungeon_music()
	preparation_music.set_preparation_active(campaign.get("phase")=="town")
	if not legacy_persistence_mode:
		timer.stop(); play_timer.stop(); title_visible=false; ui_mode="campaign"; play_buttons={}
		background.set_depth(maxi(1,int(campaign.floor)))
		if field_status or (campaign.phase=="town" and town_page in ["status","warehouse"]):
			root_layout()
			var old:=screen.get_child(0); screen.remove_child(old); old.queue_free()
			for side in ["left","right","top","bottom"]: screen.add_theme_constant_override("margin_"+side,0)
			if field_status or town_page=="status":
				status_view=Control.new(); status_view.set_script(preload("res://ui/status_view.gd")); status_view.game=self; status_view.return_page="hub"; screen.add_child(status_view)
			else:
				warehouse_view=Control.new(); warehouse_view.set_script(preload("res://ui/warehouse_view.gd")); warehouse_view.game=self; screen.add_child(warehouse_view)
		else:
			show_play_view("equipment" if field_equipment or (campaign.phase=="town" and town_page=="equipment") else ("exploration" if presenting else ("hub" if campaign.phase=="town" else campaign.phase)))
		if campaign.phase=="battle" and auto_play and not field_equipment and not field_status and not presenting and not intro_active: play_timer.wait_time=0.6/play_speed; play_timer.start()
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
	return preload("res://ui/item_presenter.gd").current(campaign,cfg,uid) if uid!="" else preload("res://ui/item_presenter.gd").text(item.stats)

func open_town_page(page: String) -> void:
	town_page=page; show_campaign()

func open_status() -> void:
	if is_instance_valid(modal_owner): return
	if campaign.phase=="town":
		if town_page=="status": return
		status_return_page=town_page if town_page in ["hub","equipment","warehouse"] else "hub"
		open_town_page("status")
	else:
		if field_status: return
		field_status=true; play_timer.stop(); cancel_presentation(); show_campaign()
func close_status() -> void:
	if field_status: field_status=false; show_campaign()
	else: open_town_page(status_return_page if status_return_page in ["hub","equipment","warehouse"] else "hub")
func remember_flow() -> void:
	if not is_instance_valid(play_view) or not play_view.is_inside_tree(): return
	for child in play_view.get_children():
		if child.has_method("save_ui_state"): child.save_ui_state()
func toggle_auto_battle() -> void:
	if campaign.get("phase")!="battle" and not presenting: return
	auto_play=not auto_play; play_timer.stop(); cancel_presentation(); show_campaign()

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
	if "--review-fixes" in OS.get_cmdline_user_args():
		await preload("res://ui/review_fixes.gd").run(self); return
	if "--flow-review" in OS.get_cmdline_user_args():
		await preload("res://ui/flow_review.gd").run(self); return
	if "--journey-review" in OS.get_cmdline_user_args():
		await preload("res://ui/journey_review.gd").run(self); return
	if "--refinement-review" in OS.get_cmdline_user_args():
		await preload("res://ui/refinement_review.gd").run(self); return
	if "--title-review" in OS.get_cmdline_user_args():
		await preload("res://ui/title_review.gd").run(self); return
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

func item_at(node: Node, point: Vector2) -> String:
	if node is Button and node.is_visible_in_tree() and node.has_meta("item_source") and node.get_global_rect().has_point(point):
		return "%s/%s/%s"%[node.get_meta("item_source"),node.get_meta("item_uid",""),node.get_meta("equip_slot","")]
	for child in node.get_children():
		var found: String=item_at(child,point)
		if found!="": return found
	return ""
func _input(event: InputEvent) -> void:
	if legacy_persistence_mode: return
	var viewport:=get_viewport()
	var now: int=Time.get_ticks_msec()
	var code: int=0
	if event is InputEventKey: code=event.physical_keycode if event.physical_keycode else event.keycode
	# Drag cancellation wins over ALL scene-level right-click/X actions.
	if viewport.gui_is_dragging() and ((event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_RIGHT) or (event is InputEventKey and event.pressed and code in [KEY_ESCAPE,KEY_X])):
		viewport.set_input_as_handled(); viewport.gui_cancel_drag(); gear_drag={}; ui_block_until=now+360
		if code==KEY_X: x_held=true; last_x_down=now
		return
	if event is InputEventKey and not event.pressed:
		if code==KEY_E: e_held=false
		if code==KEY_X: x_held=false
	if is_instance_valid(modal_owner) and modal_owner.is_inside_tree():
		if event is InputEventKey:
			viewport.set_input_as_handled()
			if event.pressed and not event.echo:
				if code==KEY_X:
					if x_held: return
					x_held=true; last_x_down=now
				if code==KEY_E: e_held=true; last_e_down=now
				modal_owner.modal_key(code,event.shift_pressed)
			return
		if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_RIGHT:
			viewport.set_input_as_handled()
			if event.pressed and not event.double_click: modal_owner.call_deferred("cancel_modal")
			return
	if event is InputEventMouseButton and event.pressed:
		var target: String=item_at(screen,event.position) if event.button_index==MOUSE_BUTTON_LEFT else ""
		if event.button_index in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_RIGHT] and (now<ui_block_until or event.double_click):
			# Only a genuine second click on the same item may equip; scene transitions never inherit it.
			if event.button_index==MOUSE_BUTTON_LEFT and event.double_click and now>=ui_block_until and target!="" and target==last_left_item: return
			viewport.set_input_as_handled(); return
		if event.button_index==MOUSE_BUTTON_LEFT: last_left_item=target
		if event.button_index==MOUSE_BUTTON_RIGHT:
			viewport.set_input_as_handled()
			if route_map_open:
				for child in play_view.get_children():
					if child.has_method("close_routes"): child.call_deferred("close_routes")
			elif now-last_x_down>=500 and is_instance_valid(secondary_button):
				last_x_down=now; secondary_button.emit_signal("pressed")
			return
	if event is InputEventKey:
		if code in [KEY_E,KEY_X]:
			viewport.set_input_as_handled()
			if not event.pressed: return
			if event.echo or (e_held if code==KEY_E else x_held): return
			var previous: int=last_e_down if code==KEY_E else last_x_down
			if code==KEY_E: e_held=true; last_e_down=now
			else: x_held=true; last_x_down=now
			var b: Button=primary_button if code==KEY_E else secondary_button
			if now-previous>=500 and now>=ui_block_until and is_instance_valid(b) and not b.disabled and b.is_visible_in_tree(): b.emit_signal("pressed")
			return
		if event.pressed and not event.echo and not route_map_open and not field_equipment and not field_status and ui_mode=="campaign":
			for child in play_view.get_children():
				if child.has_method("handle_choice_key") and child.handle_choice_key(code): viewport.set_input_as_handled(); return
		if event.pressed and not event.echo and code in [KEY_I,KEY_C] and ui_mode=="campaign":
			viewport.set_input_as_handled()
			if now<ui_block_until or route_map_open or field_equipment or field_status or (code==KEY_C and campaign.get("phase")=="town" and town_page=="status"): return
			ui_block_until=now+360
			if code==KEY_C: call_deferred("open_status")
			elif campaign.get("phase")=="town": call_deferred("open_town_page","equipment")
			else: call_deferred("open_field_equipment")
			return
		if code==KEY_SPACE and (campaign.get("phase")=="battle" or presenting):
			viewport.set_input_as_handled()
			if event.pressed and not event.echo: call_deferred("toggle_auto_battle")
func ui_action(callback: Callable, epoch: int) -> void:
	if epoch!=ui_epoch or Time.get_ticks_msec()<ui_block_until: return
	ui_block_until=Time.get_ticks_msec()+360; callback.call_deferred()
func set_primary(b: Button) -> void:
	primary_button=b; b.set_meta("primary_affirmative",true)
func set_secondary(b: Button) -> void:
	secondary_button=b; b.set_meta("secondary_affirmative",true)
func resume_auto_battle() -> void:
	if campaign.get("phase")=="battle" and not auto_play:
		auto_play=true; show_campaign()

func transfer_item(uid: String, source: String, destination: String, revision: int) -> void:
	var reason: String=Expedition.Storage.reason(campaign,uid,source,destination,cfg)
	if revision!=int(campaign.revision): reason="表示が更新されました。もう一度選んでください。"
	if reason!="": notice=reason; call_deferred("show_campaign"); return
	warehouse_state.uid=uid; warehouse_state.source=destination
	perform("transfer",{"uid":uid,"source":source,"destination":destination},revision)

func open_field_equipment() -> void:
	if is_instance_valid(modal_owner): return
	if campaign.get("phase") not in ["explore","reward","treasure","event","event_result"] or presenting: return
	field_equipment=true; play_timer.stop(); show_campaign()
func close_equipment() -> void:
	field_equipment=false; show_campaign()
func display_battle() -> Dictionary:
	return presentation_battle if presenting else Expedition.battle_state(campaign,data)
func cancel_presentation() -> void:
	presentation_generation+=1; presenting=false; presentation_battle={}
func ensure_intro() -> void:
	var key: String="%d/%d/%d"%[campaign.trips,campaign.floor,campaign.battle.seed]
	if intro_seen.has(key): return
	intro_seen[key]=true; intro_active=true; play_timer.stop()
	var duration: float=float(cfg.journey.boss_intro_seconds if Expedition.Journey.node(cfg,int(campaign.floor)).kind=="boss" else cfg.journey.intro_seconds)
	preload("res://ui/journey_sound.gd").play(self,90 if campaign.floor==10 else 220)
	finish_intro(key,duration)
func finish_intro(key: String, duration: float) -> void:
	await get_tree().create_timer(duration).timeout
	if campaign.get("phase")=="battle" and key=="%d/%d/%d"%[campaign.trips,campaign.floor,campaign.battle.seed]:
		intro_active=false; show_campaign()
	else: intro_active=false
func present_round(record: Dictionary) -> void:
	cancel_presentation(); var generation: int=presentation_generation
	presenting=true; presentation_battle=record.before.duplicate(true); play_timer.stop(); show_campaign()
	for event in record.events:
		if generation!=presentation_generation: return
		if event.type in ["status_applied","status_removed"]:
			impact(event); continue
		if not event.type in ["attack","status_damage","action_skipped","skill"]: continue
		if is_instance_valid(play_view.stage): play_view.stage.present_event(event,self)
		await get_tree().create_timer(0.30/float(play_speed)).timeout
		if generation!=presentation_generation: return
	if generation!=presentation_generation: return
	presenting=false; presentation_battle={}; show_campaign()
func impact(event: Dictionary) -> void:
	if not presenting: return
	var side: String=event.get("target",event.get("actor","hero"))
	if event.has("target_hp"): presentation_battle[side].hp=event.target_hp
	if event.type=="skill" and event.has("sp"):
		presentation_battle[event.actor].sp=event.sp
		if event.skill=="S105":
			presentation_battle[event.actor].defense_until=event.expires_after_action
			presentation_battle[event.actor].action_count=int(event.expires_after_action)-int(data.rules.skills.S105.duration_own_actions)
	if event.type=="status_applied": presentation_battle[side].statuses[event.status]={"remaining":event.remaining,"potency":event.potency,"skill":event.skill,"source":event.actor}
	if event.type=="status_removed":
		if event.status=="defense": presentation_battle[side].defense_until=-1
		else: presentation_battle[side].statuses.erase(event.status)
	if presentation_battle[side].hp<=0: presentation_battle[side].statuses={}; presentation_battle[side].defense_until=-1
	if is_instance_valid(play_view): play_view.refresh_vitals()
func update_dungeon_music() -> void:
	var path: String=""
	if not campaign.is_empty() and Expedition.Journey.active(campaign) and not title_visible and campaign.phase not in ["town","result"]:
		path=Expedition.Journey.node(cfg,int(campaign.floor)).get("bgm","")
	if path==dungeon_music_path: return
	dungeon_music_path=path
	if not is_instance_valid(dungeon_music): dungeon_music=AudioStreamPlayer.new(); dungeon_music.bus=&"BGM"; add_child(dungeon_music)
	dungeon_music.stop()
	if path!="":
		var track=load(path).duplicate()
		if track is AudioStreamOggVorbis: track.loop=true
		dungeon_music.stream=track; dungeon_music.volume_db=-4; dungeon_music.play()
