extends RefCounted
const E=preload("res://core/expedition.gd")
const UISkin=preload("res://ui/ui_skin.gd")
static func find_nav(node: Node, key: String) -> Button:
	if node is Button and node.get_meta("nav","")==key: return node
	for child in node.get_children():
		var b:=find_nav(child,key)
		if b!=null: return b
	return null
static func check(game: Control, ok: bool, message: String) -> bool:
	return game.smoke_check(ok,message)
static func click(game: Control, key: String) -> void:
	var b:=find_nav(game.screen,key)
	if b==null: game.smoke_check(false,"Missing control: "+key); return
	await game.click_control(b)
	await game.get_tree().create_timer(0.25).timeout
static func shot(game: Control, name: String) -> void:
	await game.get_tree().create_timer(0.12).timeout
	await game.capture(name+".png")
static func write(game: Control, record: Dictionary, name: String) -> void:
	var f:=FileAccess.open(game.smoke_dir.path_join(name),FileAccess.WRITE); f.store_string(JSON.stringify(record,"\t")); f.close()
static func fixture(game: Control, enemy: String, floor_number: int) -> void:
	game.campaign.phase="battle"; game.campaign.floor=floor_number; game.campaign.highest_floor=maxi(floor_number,game.campaign.highest_floor)
	game.campaign.battle={"enemy_id":enemy,"enemy_level":1 if floor_number<10 else 10,"seed":123,"hero":E.hero(game.campaign,game.cfg),"rounds":0,"rules_version":3,"encounter_version":2}
	var level: int=game.campaign.battle.enemy_level
	game.campaign.journal=["町でHP/SPを回復し、地下へ向かった。","地下%dF：%s Lv.%d が現れた。"%[floor_number,game.data.enemies[enemy].name,level]]
	game.show_campaign()
static func compare(game: Control, root: String, target: String, screenshot: String, output: String, note: String) -> void:
	var im:=Image.load_from_file(root.path_join(target))
	if im==null or im.is_empty(): game.smoke_check(false,"Missing comparison reference: "+target); return
	var actual:=Image.load_from_file(game.smoke_dir.path_join(screenshot+".png"))
	var viewport:=SubViewport.new(); viewport.size=Vector2i(2560,1050); viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS; game.add_child(viewport)
	var c:=Control.new(); c.size=Vector2(2560,1050); c.theme=game.theme; viewport.add_child(c)
	var bg:=ColorRect.new(); bg.color=Color("09151d"); bg.size=c.size; c.add_child(bg)
	UISkin.label(c,"改善前（保存済み実画面）" if output.begins_with("before-after") else "参考UI",Rect2(25,15,1225,55),36)
	UISkin.label(c,"実ゲーム EXE 0.6.0",Rect2(1305,15,1230,55),36)
	UISkin.picture(c,ImageTexture.create_from_image(im),Rect2(16,85,1248,705))
	UISkin.picture(c,ImageTexture.create_from_image(actual),Rect2(1296,85,1248,705))
	UISkin.label(c,note,Rect2(30,820,2500,195),29,UISkin.INK,true)
	await game.get_tree().process_frame
	await game.get_tree().process_frame
	await RenderingServer.frame_post_draw
	if not check(game,viewport.get_texture().get_image().save_png(game.smoke_dir.path_join(output+".png"))==OK,"Comparison exported"): return
	viewport.queue_free()
static func run(game: Control) -> void:
	var restart: bool="--ui-integration-restart" in OS.get_cmdline_user_args()
	var root: String=""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--reference-root="): root=arg.trim_prefix("--reference-root=")
	if not check(game,DisplayServer.get_name()!="headless" and not game.legacy_persistence_mode and game.save_store==null and game.campaign.is_empty(),"Normal session starts fresh without SaveStore"): return
	if not check(game,find_nav(game.screen,"start")!=null and not "続きから" in preload("res://ui/status_review.gd").text_in(game.screen),"Title has start, no continue"): return
	await shot(game,"title-restarted" if restart else "title")
	await click(game,"start")
	game.auto_play=false
	if not check(game,game.campaign.phase=="town" and game.campaign.floor==0 and game.campaign.trips==1,"Start opens preparation before first expedition"): return
	if restart:
		if not check(game,game.campaign.inventory.is_empty() and game.campaign.warehouse.is_empty() and game.campaign.exp==0 and game.campaign.gold==0,"Separate process discards previous in-memory growth/items"): return
		write(game,{"complete":true,"run_id":game.smoke_run_id,"rendered":true,"fresh_process":true,"no_save_store":true},"integration-restart.json")
		game.get_tree().quit(); return
	await shot(game,"preparation")
	var starter: String=game.campaign.equipment.head
	if not check(game,starter!="" and game.campaign.items[starter]=="A02" and E.SLOTS.size()==11,"Blue starter cloak remains head equipment with eleven slots"): return
	var before: String=game.CampaignReplay.hash_state(game.campaign)
	await click(game,"status")
	var view: Control=game.status_view
	if not check(game,view.active_tab=="equipment" and view.item_buttons.size()==11,"Status opens eleven equipment slots"): return
	await game.click_control(view.item_buttons.head); await shot(game,"status-equipment")
	for tab in ["abilities","conditions","profile"]:
		await game.click_control(view.tab_buttons[tab]); await shot(game,"status-"+tab)
	if not check(game,before==game.CampaignReplay.hash_state(game.campaign),"Tab and slot selection are read-only"): return
	await game.click_control(view.back_button); await game.get_tree().create_timer(0.25).timeout
	if not check(game,game.town_page=="hub","Status returns to preparation"): return
	await click(game,"warehouse"); await shot(game,"warehouse-empty")
	if not check(game,game.warehouse_view.visual_audit().backpack_capacity==15 and game.warehouse_view.visual_audit().cloth_capacity==3,"Warehouse stays separate, bag 15 and protected cloth 3"): return
	# Fixture contains only existing item data. It is never installed into a normal new session.
	var uid: String=E.add_item(game.campaign,"I01")
	game.campaign.item_condition[uid].current=63
	for id in ["I02","I03","I04","I05","I06","I07","I08","I09","I11"]: E.add_item(game.campaign,id)
	game.show_campaign()
	await game.click_control(game.warehouse_view.rows[uid])
	await game.click_control(game.play_buttons.deposit)
	if not check(game,uid in game.campaign.warehouse and game.campaign.item_condition[uid].current==63,"Deposit keeps individual UID/durability"): return
	await game.click_control(game.play_buttons.withdraw)
	if not check(game,uid in game.campaign.inventory and game.campaign.item_condition[uid].current==63,"Withdraw keeps individual UID/durability"): return
	await game.click_control(game.play_buttons.to_cloth)
	if not check(game,uid in game.campaign.cloth,"Protected transfer works"): return
	for item_uid in game.campaign.inventory.duplicate():
		game.perform("deposit",{"uid":item_uid},int(game.campaign.revision))
	game.warehouse_state.source="warehouse"; game.warehouse_state.uid=game.campaign.warehouse[0]; game.show_campaign()
	E.add_item(game.campaign,"I04"); E.add_item(game.campaign,"I10")
	game.show_campaign()
	await shot(game,"warehouse")
	await game.click_control(game.find_button(game.screen,"戻る"))
	await click(game,"equipment")
	await click(game,"slot-head"); await shot(game,"equipment")
	await game.click_control(game.play_buttons.unequip)
	if not check(game,starter in game.campaign.inventory and game.campaign.equipment.head=="","Explicit unequip action works"): return
	await game.click_control(game.play_buttons.equip)
	if not check(game,game.campaign.equipment.head==starter,"Explicit equip restores same starter UID"): return
	await click(game,"back")
	var warehouse: Array=game.campaign.warehouse.duplicate()
	E.gain_exp(game.campaign,40,game.cfg); game.campaign.gold=37
	game.show_campaign(); await shot(game,"preparation-grown")
	await game.click_control(game.play_buttons.depart)
	if not check(game,game.campaign.floor==1 and game.campaign.trips==1,"Depart enters real 1F and keeps first trip count"): return
	var after_depart: Dictionary=game.campaign.duplicate(true)
	# Render fixed normal/boss/event/result states; each is identified as a fixture.
	fixture(game,"E04",1)
	if not check(game,game.campaign.phase=="battle","Battle screenshot is captured before automatic outcome"): return
	await shot(game,"battle")
	game.auto_play=true; game.show_campaign()
	await game.get_tree().create_timer(0.73).timeout
	game.auto_play=false; game.play_timer.stop()
	if not check(game,int(game.campaign.battle.get("rounds",0))>0 or game.campaign.phase!="battle","Normal battle advances automatically"): return
	fixture(game,"B10",10); await shot(game,"boss")
	game.campaign=after_depart
	game.campaign.journal=["地下1F：探索を続けている。"]
	game.campaign.phase="explore"; game.campaign.battle={}; game.campaign.floor=1
	game.show_campaign(); await shot(game,"exploration")
	if not check(game,game.play_view.route.nodes().size()==3 and not game.play_view.route.nodes()[2].type_revealed,"Minimap only previous/current/next; concealed future kind"): return
	await click(game,"minimap"); await shot(game,"map")
	await click(game,"close-map")
	game.campaign.phase="event"; game.campaign.event=game.cfg.events.keys()[0]; game.show_campaign()
	await shot(game,"event")
	await game.click_control(game.play_buttons.event)
	# Return through the real campaign actions, retain same-process contents and growth.
	game.campaign.phase="explore"; game.show_campaign()
	await game.click_control(game.play_buttons["return"]); await shot(game,"return")
	await game.click_control(game.play_buttons.town)
	if not check(game,game.campaign.phase=="town" and game.campaign.warehouse==warehouse and game.campaign.exp>0 and game.campaign.gold==37,"Return to preparation retains growth and inventory in process"): return
	var keep: Dictionary=game.campaign.duplicate(true)
	game.campaign.phase="explore"; game.campaign.floor=1
	E.finish(game.campaign,"death","死亡結果の表示検証（既存コアの固定状態）",game.cfg); game.show_campaign()
	await shot(game,"death")
	await game.click_control(game.play_buttons.town)
	if not check(game,game.campaign.phase=="town" and uid in game.campaign.cloth,"Death returns to preparation and cloth survives"): return
	game.campaign=keep; game.campaign.floor=10; game.campaign.highest_floor=11
	E.finish(game.campaign,"clear","10F突破結果の表示検証（固定状態）",game.cfg); game.show_campaign(); await shot(game,"clear")
	if root!="":
		var cases: Array=[
			["assets/ui-reference/supplemental/title-latest.png","title","タイトル：独立した背景＋実ボタン。ロゴ専用透過素材・設定機能は未採用。"],
			["assets/ui-reference/supplemental/preparation-latest.png","preparation","準備：４導線と実データを採用。画像内の名前・Lv・装備数値は流用しない。"],
			["assets/ui-reference/supplemental/warehouse-latest.png","warehouse","倉庫：左15＋3／中央6列／右詳細。左は既存の縦一覧を維持。個別耐久、容量無制限は実装仕様。既存アイテムの固定検証状態。"],
			["assets/ui-mocks/03_status_pixel.webp","status-equipment","ステータス：4タブと11枠を維持。表示のみで装備を外さず、準備の装備画面へ分離。"],
			["assets/ui-mocks/01_exploration_pixel.webp","exploration","探索：洞窟・人物・ログ・実ゲージ・地図。未定の分岐構造を捏造せず現行の主経路を表示。"],
			["assets/ui-mocks/02_battle_pixel.webp","battle","戦闘：フルオート。手動攻撃コマンドと複数人パーティは採用しない。固定敵・実コア進行の描画検証。"]]
		for row in cases: await compare(game,root,row[0],row[1],"comparison-"+row[1],row[2])
		var before_cases: Array=[
			["review/current/77-normal-first-title.png","title"],
			["review/current/80-first-town.png","preparation"],
			["review/equipment-and-interface/equipment-assets-isolated/equipment-warehouse.png","warehouse"],
			["review/equipment-and-interface/status-isolated/status-equipment.png","status-equipment"],
			["review/current/88-normal-exploration.png","exploration"],
			["review/current/82-normal-battle.png","battle"]]
		for row in before_cases: await compare(game,root,row[0],row[1],"before-after-"+row[1],"左：変更前の保存済み実画面。右：今回の配布EXE。版・出典・ハッシュは索引で区別。固定検証状態を含み、同一セーブの攻略比較ではありません。")
	write(game,{"complete":true,"run_id":game.smoke_run_id,"rendered":true,"no_save_store":true,"session_only":true,"restart_required":true,"tabs":4,"slots":11,"bag_capacity":15,"cloth_capacity":3,"warehouse_transfers":true,"same_process_retention":true,"depart_1f":true,"auto_battle":true,"map_hidden_kinds":true,"comparisons":6,"fixture_screens":["warehouse","preparation-grown","battle","boss","exploration","map","event","death","clear"],"normal_screens":["title","preparation","status-equipment","status-abilities","status-conditions","status-profile","warehouse-empty","equipment","return"]},"integration-review.json")
	game.get_tree().quit()
