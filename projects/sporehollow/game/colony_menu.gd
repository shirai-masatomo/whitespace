extends RefCounted

static func page(g,id: String):
	g.menu_page=id;build(g)
static func label(parent,text: String,at: Vector2,size: int=20,width: float=620):
	var node=Label.new();node.text=text;node.position=at;node.size=Vector2(width,70)
	node.add_theme_font_size_override("font_size",size);node.add_theme_color_override("font_color",Color("f3ead1"))
	node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;parent.add_child(node);return node
static func button(g,id: String,text: String,rect: Rect2,callback):
	g.add_button(g.menu,id,text,rect,callback)
static func build(g):
	for child in g.menu.get_children():g.menu.remove_child(child);child.queue_free()
	for id in g.buttons.keys():
		if id.begins_with("menu_"):g.buttons.erase(id)
	var shade=ColorRect.new();shade.size=Vector2(1280,800);shade.color=Color(0.03,0.08,0.06,0.88);g.menu.add_child(shade)
	var titles={"main":"メニュー","help":"操作ガイド","version":"バージョン","new":"新しく始める"}
	label(g.menu,titles[g.menu_page],Vector2(400,160),28,480)
	if g.menu_page=="main":
		button(g,"menu_resume","牧場へ戻る",Rect2(400,240,480,46),g.toggle_menu)
		button(g,"menu_save","保存する",Rect2(400,310,230,44),g.ColonyPanels.research_save.bind(g))
		button(g,"menu_load","保存を読み込む",Rect2(650,310,230,44),g.ColonyPanels.research_load.bind(g))
		g.buttons.menu_save.disabled=g.save_load_blocked
		g.buttons.menu_load.disabled=not FileAccess.file_exists(g.development_save_path) and not FileAccess.file_exists("user://autonomy.snapshot")
		button(g,"menu_help","操作ガイド",Rect2(400,376,230,44),page.bind(g,"help"))
		button(g,"menu_version","バージョン",Rect2(650,376,230,44),page.bind(g,"version"))
		button(g,"menu_new","新しく始める",Rect2(400,444,480,44),page.bind(g,"new"))
		button(g,"menu_exit","保存せず終了" if g.save_load_blocked else "保存して終了",Rect2(400,512,480,44),g.notification.bind(g.NOTIFICATION_WM_CLOSE_REQUEST))
		var boundary=label(g.menu,"終了時に自動保存します。\n仕事・物資・敵・時計を保って再開します。",Vector2(400,582),17,480);boundary.name="SaveBoundaryNote"
		var status=label(g.menu,g.save_status,Vector2(400,660),17,480);status.name="MenuSaveStatus"
	elif g.menu_page=="help":
		var guide=label(g.menu,"左クリック：選択・指定\n右クリック：選択解除。取消は命令のキャンセル\n空白を左ドラッグ：地図移動\n未選択のホイール / Ctrl＋ホイール：ズーム\nTab：モード　Shift：指示する動物\n命令のホイール：6種類を巡回（Ctrlはズーム）\n建築・命令・ゾーン：クリックまたは範囲指定\n徴兵：地面で移動、敵で指定攻撃。通常仕事は保留\nSpace：停止／再開\n1 / 2 / 3：0.5 / 1 / 2倍　4：休息中のみ4倍\n＋ / ＝ / テンキー＋：速く　− / テンキー−：遅く",Vector2(330,230),19,640);guide.name="ControlGuide";guide.size.y=380
	elif g.menu_page=="version":
		var m=JSON.parse_string(FileAccess.get_file_as_string("res://game/build_stamp.json")) if FileAccess.file_exists("res://game/build_stamp.json") else {}
		label(g.menu,"ホイッスル牧場・開発版\n\n本体 "+str(m.get("commit","未記録")).left(8)+"\n素材 "+str(m.get("asset_delivery_commit","未記録")).left(8)+"\n\n調整中の仕様と未確認範囲は試遊の報告書へ記録しています。",Vector2(330,240),20,640)
	elif g.menu_page=="new":
		label(g.menu,"この牧場を終え、1日目の05:00から新しく始めます。\n\n今の状態は復元履歴に残し、続き用の保存を新しい牧場へ置き換えます。",Vector2(330,240),21,640)
		button(g,"menu_confirm_new","新しい牧場を始める",Rect2(400,460,480,46),start_new.bind(g))
	if g.menu_page=="new":label(g.menu,g.save_status,Vector2(330,550),17,640)
	if g.menu_page!="main":button(g,"menu_back","メニューへ戻る",Rect2(400,660,480,44),page.bind(g,"main"))
	g.menu.move_to_front()
static func start_new(g):
	var previous=g.world.paused;g.world.paused=g.menu_was_paused
	var directory="user://history";var err=DirAccess.make_dir_recursive_absolute(directory)
	var stem=directory+"/colony_%d_%d"%[int(Time.get_unix_time_from_system()),Time.get_ticks_usec()]
	var path=stem+".snapshot";var suffix=0
	while FileAccess.file_exists(path):suffix+=1;path=stem+"_%d.snapshot"%suffix
	var backed_up=err==OK and g.world.Snapshot.save(g.world,path)
	g.world.paused=previous
	if not backed_up:g.save_status="復元履歴を保存できないため、開始を止めました";build(g);return
	var fresh=g.Farm.new({},g.world.seed_value+1).begin_day()
	if fresh==null or not g.save_morning(fresh):g.save_status="新しい牧場を保存できませんでした";build(g);return
	g.world=fresh;g.reset_view();g.menu_page="main";g.speed=1;g.accumulated=0;g.refresh();g.StoryView.open(g,"intro")
