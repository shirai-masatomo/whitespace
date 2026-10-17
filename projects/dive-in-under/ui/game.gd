extends "res://ui/main.gd"
const Expedition = preload("res://core/expedition.gd")
const SaveStore = preload("res://core/save_store.gd")
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
var new_button: Button
var confirm_button: Button
var continue_button: Button
var resume_probe := false
var campaign_replay_path := ""
var campaign_resume := false
var campaign_final_probe := false
var campaign_seed := 123
const CampaignReplay = preload("res://ui/campaign_replay.gd")

func initialize_game() -> void:
	cfg=Expedition.load_config()
	if cfg.is_empty(): get_tree().quit(1); return
	var save_path := "user://campaign-v1.json"
	if smoke_dir!="": save_path=smoke_dir.path_join("campaign-smoke.json")
	for arg in OS.get_cmdline_user_args():
		if arg=="--resume-probe": resume_probe=true
		if smoke_dir!="" and arg.begins_with("--campaign-replay="): campaign_replay_path=arg.trim_prefix("--campaign-replay=")
		if arg=="--campaign-resume": campaign_resume=true
		if arg=="--campaign-final-probe": campaign_final_probe=true
		if smoke_dir!="" and arg.begins_with("--campaign-seed="): campaign_seed=int(arg.trim_prefix("--campaign-seed="))
	save_store=SaveStore.new(save_path,data,cfg)
	loaded=save_store.load_game()
	cfg=save_store.cfg
	if loaded.ok: campaign=loaded.state
	play_timer=Timer.new()
	play_timer.wait_time=0.6
	play_timer.timeout.connect(func(): if campaign.get("phase")=="battle" and ui_mode=="campaign": perform("round",{},int(campaign.revision)))
	add_child(play_timer)
	get_tree().auto_accept_quit=false

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST:
		# Every accepted action is already committed. Closing never advances the world.
		get_tree().quit()

func show_title() -> void:
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
	left.add_child(text_label("ひとりで潜り、町へ持ち帰る",26))
	continue_button=button("続きから",continue_campaign)
	continue_button.disabled=not loaded.get("ok",false)
	left.add_child(continue_button)
	new_button=button("新しく始める",request_new)
	left.add_child(new_button)
	if loaded.get("status","")=="recoverable": left.add_child(button("前回の保存から復旧する",recover_campaign))
	left.add_child(button("終了",func(): get_tree().quit()))
	var right:=column(row,400)
	right.add_child(text_label("探索・帰還・再挑戦",24))
	var explanation:=text_label("初めての探索では帰還できません。\nその後は、町で回復して何度でも挑めます。\n\n変更は操作ごとに自動保存されます。",18)
	explanation.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; right.add_child(explanation)
	right.add_child(HSeparator.new())
	launch_button=button("開発用：単発戦闘の確認",show_battle)
	right.add_child(launch_button)
	right.add_child(text_label("本編の保存・成長へは影響しません。",16))
	if loaded.get("status","") not in ["ok","missing"]: notice=loaded.get("error","")
	var status:=text_label(notice,16); status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; root.add_child(status)
	var spacer:=Control.new(); spacer.size_flags_vertical=Control.SIZE_EXPAND_FILL; root.add_child(spacer)
	root.add_child(text_label("0.4.0 visual candidate A  ·  工程1試作  ·  初回イベント・成長・死亡ペナルティは仮設定",16))
	new_button.grab_focus()

func show_battle() -> void:
	play_timer.stop(); ui_mode="tool"; timer.wait_time=0.5
	super.show_battle()

func request_new() -> void:
	if FileAccess.file_exists(save_store.path):
		var root:=root_layout()
		root.add_child(text_label("新しい探索を始めますか",32))
		root.add_child(text_label("現在の保存を同じ保存先に退避して、新しく始めます。",20))
		confirm_button=button("保存を退避して新しく始める",start_new)
		root.add_child(confirm_button)
		root.add_child(button("戻る",show_title))
	else: start_new()

func start_new() -> void:
	var error: String=save_store.preserve_current()
	if error!="": notice=error; show_title(); return
	cfg=Expedition.load_config(); save_store.cfg=cfg
	var candidate:=Expedition.fresh(cfg,campaign_seed if smoke_dir!="" else int(Time.get_ticks_usec()%2147483647))
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
	if candidate==campaign: return
	var error: String=save_store.write_game(candidate)
	if error!="":
		auto_play=false; notice="保存できないため操作を取り消しました："+error
		show_campaign(); return
	campaign=candidate; loaded={"ok":true,"status":"ok"}; notice=""
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

func show_campaign() -> void:
	timer.stop(); play_timer.stop(); title_visible=false; ui_mode="campaign"; play_buttons={}
	background.set_depth(campaign.floor if campaign.phase not in ["town","result"] else 1)
	var root:=root_layout()
	var header:=HBoxContainer.new(); header.custom_minimum_size.y=52; root.add_child(header)
	var names: Dictionary={"explore":"地下への道","battle":"自動戦闘","event":"地下の出来事","result":"探索結果","town":"町 / 倉庫と装備"}
	var heading:=text_label(names[campaign.phase],30); heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL; header.add_child(heading)
	var title:=button("保存済み / タイトルへ",func(): loaded=save_store.load_game(); show_title())
	header.add_child(title); play_buttons["title"]=title
	if campaign.phase=="town": show_town(root)
	elif campaign.phase=="result": show_result(root)
	else: show_exploration(root)
	var footer:=text_label(notice if notice!="" else "自動保存済み  ·  主人公ひとり  ·  静止ドットは候補素材 / 数値・ペナルティは試作設定",15)
	footer.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; root.add_child(footer)
	if campaign.phase=="battle" and auto_play:
		play_timer.wait_time=0.6/play_speed; play_timer.start()

func show_exploration(root: VBoxContainer) -> void:
	var row:=HBoxContainer.new(); row.size_flags_vertical=Control.SIZE_EXPAND_FILL; row.add_theme_constant_override("separation",16); root.add_child(row)
	var controls:=column(row,210)
	controls.add_child(text_label("地下 %d F" % campaign.floor,30))
	paragraph(controls,VisualAssets.depth_name(campaign.floor),17)
	paragraph(controls,"初めての探索" if not campaign.first_done else "第 %d 回の探索" % campaign.trips)
	paragraph(controls,"帰り道は、まだ見つからない。" if not campaign.first_done else "進むか、持ち帰るか。",16)
	var down:=command("さらに潜る" if campaign.floor>0 else "地下1Fへ潜る","descend")
	down.disabled=campaign.phase!="explore" or campaign.floor>=10; controls.add_child(down)
	var retreat:=command("町へ帰還する","return")
	retreat.disabled=not campaign.first_done or campaign.phase!="explore"; controls.add_child(retreat)
	if campaign.phase=="battle":
		var pause:=button("一時停止" if auto_play else "自動戦闘を再開",func(): auto_play=not auto_play; show_campaign())
		controls.add_child(pause); play_buttons["pause"]=pause
		controls.add_child(button("速度：%d倍" % play_speed,func(): play_speed=2 if play_speed==1 else 1; show_campaign()))
	var center:=column(row,640,false,true)
	var h:=Expedition.hero(campaign,cfg)
	if campaign.phase=="battle":
		var b:=Expedition.battle_state(campaign,data)
		paragraph(center,"%s Lv.%d   HP %d / %d" % [b.enemy.name,b.enemy.level,b.enemy.hp,b.enemy.max_hp])
		var bar:=health_bar(Color("b4523b")); bar.max_value=b.enemy.max_hp; bar.value=b.enemy.hp; center.add_child(bar)
		paragraph(center,"ROUND %02d / 完全自動" % b.round,17)
	elif campaign.phase=="explore" and campaign.get("last_outcome","")=="victory":
		var banner:=paragraph(center,"勝利  /  次の一歩を選ぶ",28)
		banner.add_theme_color_override("font_color",Color("f0bd72"))
	else: paragraph(center,"静かな通路" if campaign.phase=="explore" else cfg.events[campaign.event].name,22)
	var picture:=Control.new(); picture.set_script(BattleStage); picture.floor_number=campaign.floor; picture.enemy_id=campaign.battle.get("enemy_id",""); picture.clip_contents=true; center.add_child(picture)
	if campaign.phase=="event":
		var choices:=HBoxContainer.new(); center.add_child(choices)
		choices.add_child(command(cfg.events[campaign.event].choice,"event",{"choice":"accept"}))
		choices.add_child(command("見送る","event",{"choice":"skip"}))
	center.add_child(text_label(VisualAssets.preview_note(picture.enemy_id),14))
	var log:=RichTextLabel.new(); log.custom_minimum_size.y=100; log.size_flags_vertical=Control.SIZE_EXPAND_FILL; log.scroll_following=true
	log.add_theme_stylebox_override("normal",box(Color("081215"),Color("987b49")))
	log.text="\n".join(campaign.journal); center.add_child(log)
	var status:=column(row,250,true)
	status.add_child(text_label("主人公 / Lv.%d" % h.level,23))
	portrait(status,84)
	status.add_child(text_label("HP  %d / %d" % [h.hp,h.max_hp],20))
	var hpbar:=health_bar(Color("a84936")); hpbar.max_value=h.max_hp; hpbar.value=h.hp; status.add_child(hpbar)
	status.add_child(text_label("SP  %d / %d" % [h.sp,h.max_sp],20))
	var spbar:=health_bar(Color("327e9b")); spbar.max_value=maxi(1,h.max_sp); spbar.value=h.sp; status.add_child(spbar)
	paragraph(status,"ATK %d   DEF %d\nSPD %d\n\nGold %d\n携行品 %d個\n最深到達 %dF" % [h.atk,h.def,h.spd,campaign.gold,campaign.inventory.size(),campaign.highest_floor],19)
	var growth:=Expedition.level_info(campaign,cfg)
	paragraph(status,"次のLvまで EXP %d / %d" % [growth.progress,growth.next],16)

func show_result(root: VBoxContainer) -> void:
	var row:=HBoxContainer.new(); row.size_flags_vertical=Control.SIZE_EXPAND_FILL; row.add_theme_constant_override("separation",32); root.add_child(row)
	var info:=column(row,700)
	var labels: Dictionary={"death":"主人公死亡","story_death":"主人公死亡 / 初回イベント","return":"帰還成功","draw":"戦闘打切り / 探索中断","clear":"10F突破"}
	var banner:=paragraph(info,labels[campaign.result.kind],36)
	banner.add_theme_color_override("font_color",Color("f0bd72"))
	paragraph(info,campaign.result.reason,24)
	paragraph(info,"到達 %dF   /   Lv.%d   /   Gold %d" % [campaign.result.floor,Expedition.hero(campaign,cfg).level,campaign.gold],22)
	var loss: Dictionary=campaign.result.loss
	paragraph(info,"今回の損失：Gold %d / EXP %d / 携行品 %d\n町ではHP/SPを全回復します。再挑戦に費用はかかりません。" % [loss.gold,loss.exp,loss.items],18)
	if campaign.result.kind=="story_death": paragraph(info,"この初回イベントは記録済みです。次の探索では再発しません。",18)
	info.add_child(command("町へ戻り、再挑戦の準備","town"))
	var log:=column(row,350,true)
	paragraph(log,"最後の記録",24)
	paragraph(log,"\n".join(campaign.journal.slice(-7)),17)

func compact_button(label: String, callback: Callable) -> Button:
	var b:=button(label,callback); b.custom_minimum_size.y=28; b.add_theme_font_size_override("font_size",16)
	for state_name in ["normal","hover","pressed"]:
		var style: StyleBox=theme.get_stylebox(state_name,"Button").duplicate()
		style.content_margin_top=3; style.content_margin_bottom=3
		b.add_theme_stylebox_override(state_name,style)
	return b

func item_list(parent: VBoxContainer, source: String) -> void:
	var scroll:=ScrollContainer.new(); scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL; scroll.custom_minimum_size.y=200; parent.add_child(scroll)
	var list:=VBoxContainer.new(); list.size_flags_horizontal=Control.SIZE_EXPAND_FILL; scroll.add_child(list)
	for uid in campaign[source]:
		var item: Dictionary=cfg.items[campaign.items[uid]]
		paragraph(list,item.name,17)
		var effects: Array=[]
		for key in item.stats:
			effects.append({"max_hp":"HP","max_sp":"SP","atk":"ATK","def":"DEF","spd":"SPD"}[key]+" +"+str(item.stats[key]))
		if not effects.is_empty(): paragraph(list," / ".join(effects),15)
		var row:=HBoxContainer.new(); list.add_child(row)
		var revision:=int(campaign.revision)
		if source=="inventory":
			var equip:=compact_button("装備",func(): perform("equip",{"uid":uid},revision)); equip.disabled=item.slot==""; equip.set_meta("campaign_action","equip"); equip.set_meta("campaign_args",{"uid":uid}); row.add_child(equip)
			var deposit:=compact_button("預ける",func(): perform("deposit",{"uid":uid},revision))
			deposit.set_meta("campaign_action","deposit"); deposit.set_meta("campaign_args",{"uid":uid}); row.add_child(deposit)
		else:
			var withdraw:=compact_button("取り出す",func(): perform("withdraw",{"uid":uid},revision))
			withdraw.set_meta("campaign_action","withdraw"); withdraw.set_meta("campaign_args",{"uid":uid}); row.add_child(withdraw)
		list.add_child(HSeparator.new())
	if campaign[source].is_empty(): paragraph(list,"まだ何もありません。",17)

func show_town(root: VBoxContainer) -> void:
	var h:=Expedition.hero(campaign,cfg)
	root.add_child(text_label("HP %d / %d   SP %d / %d   Lv.%d   ATK %d  DEF %d  SPD %d   /   Gold %d" % [h.hp,h.max_hp,h.sp,h.max_sp,h.level,h.atk,h.def,h.spd,campaign.gold],21))
	var row:=HBoxContainer.new(); row.size_flags_vertical=Control.SIZE_EXPAND_FILL; row.add_theme_constant_override("separation",16); root.add_child(row)
	var bag:=column(row,300); bag.add_child(text_label("所持品 / 携行",24)); item_list(bag,"inventory")
	var equipment:=column(row,430,true)
	var equipment_heading:=HBoxContainer.new(); equipment.add_child(equipment_heading)
	var equipment_title:=text_label("装備 / 11部位",24); equipment_title.size_flags_horizontal=Control.SIZE_EXPAND_FILL; equipment_heading.add_child(equipment_title)
	portrait(equipment_heading,62)
	equipment.add_theme_constant_override("separation",2)
	for slot in Expedition.SLOTS:
		var line:=HBoxContainer.new(); equipment.add_child(line)
		var uid: String=campaign.equipment[slot]
		var label:=text_label(cfg.slots[slot]+"："+("—" if uid=="" else cfg.items[campaign.items[uid]].name),16)
		label.size_flags_horizontal=Control.SIZE_EXPAND_FILL; line.add_child(label)
		var revision:=int(campaign.revision)
		var remove:=compact_button("外す",func(): perform("unequip",{"slot":slot},revision)); remove.disabled=uid==""; line.add_child(remove)
	var storage:=column(row,300); storage.add_child(text_label("倉庫",24)); item_list(storage,"warehouse")
	var depart:=command("HP/SP回復済み  →  もう一度地下へ","depart"); root.add_child(depart)

func smoke(quit_on_finish: bool = true) -> void:
	if campaign_replay_path!="":
		await CampaignReplay.run(self); return
	if resume_probe:
		var original = JSON.parse_string(FileAccess.get_file_as_string(smoke_dir.path_join("ui-smoke.json")))
		if not smoke_check(loaded.ok and campaign.first_done and campaign.revision==original.saved_revision and save_store.digest()==original.saved_sha256,"Separate EXE restart checkpoint"): return
		var f:=FileAccess.open(smoke_dir.path_join("resume-smoke.json"),FileAccess.WRITE)
		f.store_string(JSON.stringify({"run_id":smoke_run_id,"restart_loaded":true,"revision":campaign.revision,"phase":campaign.phase,"save_sha256":save_store.digest()},"\t")); f.close()
		get_tree().quit(); return
	await super.smoke(false)
	if smoke_report.is_empty(): return
	var rendered:=DisplayServer.get_name()!="headless"
	await click_control(new_button)
	if is_instance_valid(confirm_button) and confirm_button.is_inside_tree(): await click_control(confirm_button)
	if not smoke_check(campaign.phase=="explore" and not campaign.first_done,"New game enters first exploration"): return
	if not smoke_check(play_buttons["return"].disabled,"First return disabled"): return
	await click_control(play_buttons.descend)
	if rendered: await capture("04-first-exploration.png")
	await click_control(play_buttons.title)
	await click_control(continue_button)
	if not smoke_check(campaign.floor==1 and not campaign.first_done,"Continue initial exploration"): return
	await click_control(play_buttons.descend)
	if not smoke_check(campaign.phase=="result" and campaign.first_done,"First death saved"): return
	if rendered: await capture("05-death-result.png")
	await click_control(play_buttons.title); await click_control(continue_button)
	if not smoke_check(campaign.phase=="result" and campaign.story_deaths==1,"Continue death result"): return
	await click_control(play_buttons.town)
	if rendered: await capture("06-town.png")
	var uid: String=campaign.inventory[0]
	# Find actual town buttons; core inventory stress tests separately cover every move.
	var equip_button:=find_button(screen,"装備")
	await click_control(equip_button)
	if not smoke_check(campaign.equipment.head==uid,"Town equip input"): return
	await click_control(play_buttons.depart)
	if not smoke_check(campaign.phase=="explore","Town departure input"): return
	auto_play=false
	await click_control(play_buttons.descend)
	if campaign.phase=="battle":
		play_timer.stop()
		if rendered: await capture("07-normal-battle.png")
		while campaign.phase=="battle": perform("round",{},int(campaign.revision))
	elif campaign.phase=="event": perform("event",{"choice":"skip"},int(campaign.revision))
	if not smoke_check(campaign.phase=="explore" and campaign.first_done,"Normal first floor survived"): return
	if rendered: await capture("10-normal-victory.png")
	await click_control(play_buttons["return"])
	if rendered: await capture("08-return-result.png")
	await click_control(play_buttons.town)
	await click_control(play_buttons.depart)
	if not smoke_check(campaign.story_deaths==1 and campaign.hp>0,"Retry does not repeat forced death"): return
	# Proceed normally until a real death or 10F clear; no altered stats or forced outcomes.
	var budget:=0
	while campaign.phase!="result" and budget<600:
		if campaign.phase=="explore": await click_control(play_buttons.descend)
		elif campaign.phase=="battle": perform("round",{},int(campaign.revision))
		elif campaign.phase=="event": perform("event",{"choice":"accept"},int(campaign.revision))
		budget+=1
	if not smoke_check(campaign.phase=="result" and campaign.result.kind=="death" and campaign.story_deaths==1,"Normal combat death independent of tutorial"): return
	if rendered: await capture("09-normal-death.png")
	await click_control(play_buttons.town)
	await click_control(play_buttons.depart)
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
