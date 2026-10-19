extends RefCounted
## Seven focused UI checks. Fixed fixtures never enter normal startup.
const E=preload("res://core/expedition.gd")
const UI=preload("res://ui/integration_review.gd")
static func labels(node: Node) -> Array[Label]:
	var out: Array[Label]=[]
	if node is Label: out.append(node)
	for child in node.get_children(): out.append_array(labels(child))
	return out
static func descendants(node: Node) -> Array[Node]:
	var out: Array[Node]=[node]
	for child in node.get_children(): out.append_array(descendants(child))
	return out
static func lines(l: Label) -> Array[String]:
	var p:=TextParagraph.new(); p.width=l.size.x
	p.break_flags=TextServer.BREAK_MANDATORY|TextServer.BREAK_WORD_BOUND
	p.add_string(l.text,l.get_theme_font("font"),l.get_theme_font_size("font_size"),l.language)
	var out: Array[String]=[]
	for i in p.get_line_count():
		var r:=p.get_line_range(i); out.append(l.text.substr(r.x,r.y-r.x).strip_edges())
	return out
static func description_audit(node: Node) -> Array:
	var out: Array=[]
	for l in labels(node):
		if not l.text.begins_with("旅立ちの青い"): continue
		var actual:=lines(l)
		out.append({"text":l.text,"lines":actual,"label_lines":l.get_line_count(),"rect":str(l.get_global_rect()),"language":l.language})
	return out
static func punctuation_ok(records: Array) -> bool:
	if records.is_empty(): return false
	for record in records:
		for line in record.lines:
			if line.begins_with("。") or line.begins_with("、"): return false
	return true
static func run(game: Control) -> void:
	game.auto_play=false
	var checks: Dictionary={}
	if not UI.check(game,not game.legacy_persistence_mode and game.save_store==null and game.campaign.is_empty(),"Fresh normal mode, no SaveStore"): return
	await UI.shot(game,"05-title")
	await UI.click(game,"start"); game.auto_play=false
	if not UI.check(game,game.campaign.phase=="town","Start remains preparation"): return
	await UI.shot(game,"06-preparation")
	checks["06"]={"hp":E.hero(game.campaign,game.cfg).hp,"max_hp":E.hero(game.campaign,game.cfg).max_hp,"same_initial_state":true}
	var before: String=game.CampaignReplay.hash_state(game.campaign)
	await UI.click(game,"status")
	await game.click_control(game.status_view.item_buttons.head); await UI.shot(game,"01-status-equipment")
	var title: Label
	for l in labels(game.status_view.item_buttons.head):
		if l.has_meta("full_name"): title=l
	if not UI.check(game,title!=null and title.tooltip_text=="冒険者のマント" and (title.text=="冒険者のマント" or title.text.ends_with("…")),"01 explicit fitted name and full tooltip"): return
	if not UI.check(game,"冒険者のマント" in labels(game.status_view.details).map(func(l):return l.text),"01 detail contains complete official name"): return
	var font:=title.get_theme_font("font")
	if not UI.check(game,font.get_string_size(title.text,HORIZONTAL_ALIGNMENT_LEFT,-1,title.get_theme_font_size("font_size")).x<=title.size.x and Rect2(Vector2.ZERO,title.get_parent().size).encloses(title.get_rect()),"01 fitted text stays in slot"): return
	var status_desc:=description_audit(game.status_view.details)
	if not UI.check(game,punctuation_ok(status_desc),"02 status Japanese punctuation stays attached"): return
	checks["01"]={"visible":title.text,"full":"冒険者のマント","rect":str(title.get_global_rect()),"detail_full_name":true}
	await game.click_control(game.status_view.tab_buttons.abilities); await UI.shot(game,"04-status-abilities")
	var rows: Array=[]
	for b in game.status_view.item_buttons.values():
		var positions: Array=[]
		for l in labels(b):
			if not UI.check(game,l.vertical_alignment==VERTICAL_ALIGNMENT_CENTER and l.position.y==12 and l.size.y==30,"04 ability labels share vertical content box"): return
			positions.append(str(l.get_rect()))
		rows.append(positions)
	checks["04"]={"rows":rows,"aligned":true}
	if not UI.check(game,game.CampaignReplay.hash_state(game.campaign)==before,"Status selections never mutate campaign"): return
	await game.click_control(game.status_view.back_button); await game.get_tree().create_timer(0.24).timeout
	# Same item order, condition, containers and level as the 0.6.0 screenshots.
	var uid: String=E.add_item(game.campaign,"I01"); game.campaign.item_condition[uid].current=63
	game.campaign=E.act(game.campaign,"to_cloth",int(game.campaign.revision),{"uid":uid},game.data,game.cfg)
	for id in ["I02","I03","I04","I05","I06","I07","I08","I09","I11"]:
		var added: String=E.add_item(game.campaign,id)
		game.campaign=E.act(game.campaign,"deposit",int(game.campaign.revision),{"uid":added},game.data,game.cfg)
	E.add_item(game.campaign,"I04"); var carried: String=E.add_item(game.campaign,"I10")
	game.warehouse_state.source="warehouse"; game.warehouse_state.uid=game.campaign.warehouse[0]
	await UI.click(game,"warehouse")
	await game.click_control(game.warehouse_view.rows[carried]); await game.click_control(game.play_buttons.deposit); await game.click_control(game.play_buttons.withdraw)
	if not UI.check(game,carried in game.campaign.inventory and game.campaign.item_condition[uid].current==63 and uid in game.campaign.cloth,"Warehouse transfer still keeps UID/condition and protected cloth"): return
	game.warehouse_state.source="warehouse"; game.warehouse_state.uid=game.campaign.warehouse[0]; game.notice="倉庫へ預けました。"; game.show_campaign()
	await UI.shot(game,"03-warehouse")
	var names: Array=[]
	for item_uid in game.campaign.warehouse:
		for l in labels(game.warehouse_view.rows[item_uid]):
			if not l.has_meta("full_name"): continue
			if not UI.check(game,l.position.x>=10 and l.get_rect().end.x<=74 and l.get_rect().end.y<=98,"03 name stays away from brass border"): return
			names.append({"full":l.get_meta("full_name"),"visible":l.text,"rect":str(l.get_global_rect())})
	checks["03"]={"columns":3,"backpack":15,"cloth":3,"names":names,"transfer":true}
	await game.click_control(game.find_button(game.screen,"戻る")); await UI.click(game,"equipment")
	await UI.click(game,"slot-head"); await UI.shot(game,"02-equipment")
	var equipment_desc:=description_audit(game.play_view)
	if not UI.check(game,punctuation_ok(equipment_desc),"02 equipment Japanese punctuation stays attached"): return
	checks["02"]={"equipment":equipment_desc,"status":status_desc,"punctuation_ok":true,"text_server_data":ProjectSettings.get_setting("internationalization/locale/include_text_server_data")}
	await UI.click(game,"back")
	E.gain_exp(game.campaign,40,game.cfg); game.campaign.gold=37
	game.campaign=E.act(game.campaign,"depart",int(game.campaign.revision),{},game.data,game.cfg)
	game.campaign=E.act(game.campaign,"descend",int(game.campaign.revision),{},game.data,game.cfg)
	# Force the same E04/Lv1 presentation fixture as the original numbered shot.
	UI.fixture(game,"E04",1); await UI.shot(game,"07-battle")
	var b: Dictionary=E.battle_state(game.campaign,game.data)
	if not UI.check(game,game.play_view.stage.enemy_id==b.enemy.id and game.campaign.journal[-1].contains(b.enemy.name+" Lv.1"),"07 fixture sprite/name/appearance journal agree"): return
	checks["07"]={"fixture_id":b.enemy.id,"name":b.enemy.name,"appearance_log":game.campaign.journal[-1],"fixture_aligned":true}
	# A single actual core encounter separates normal play from presentation fixtures.
	game.campaign=E.fresh(game.cfg,123)
	game.campaign=E.act(game.campaign,"descend",int(game.campaign.revision),{},game.data,game.cfg)
	game.show_campaign()
	if not UI.check(game,game.campaign.phase=="battle","Fixed normal seed123 has a real encounter"): return
	b=E.battle_state(game.campaign,game.data)
	if not UI.check(game,game.play_view.stage.enemy_id==b.enemy.id and game.campaign.journal[-1].contains(b.enemy.name),"07 one normal encounter remains consistent"): return
	await UI.shot(game,"07-normal-encounter")
	checks["07"].normal_case={"seed":123,"id":b.enemy.id,"name":b.enemy.name,"appearance_log":game.campaign.journal[-1],"consistent":true}
	checks["05"]={"start_button_tested":true,"layout_change":"Only title plate reduced from 620x460 to 620x148; controls stay in place","user_evaluation":"pending"}
	if not UI.check(game,descendants(game).filter(func(n):return n is AudioStreamPlayer or n is AudioStreamPlayer2D).is_empty(),"No BGM playback added"): return
	UI.write(game,{"run_id":game.smoke_run_id,"complete":true,"rendered":DisplayServer.get_name()!="headless","no_save_store":game.save_store==null,"review":"ui-feedback-01-07","version":"0.6.1","checks":checks,"status_read_only":true,"warehouse_transfers":true,"normal_encounter_sample":1,"battle_core_changed":false,"user_evaluation":"pending","user_adoption":"pending"},"feedback-review.json")
	game.get_tree().quit()
