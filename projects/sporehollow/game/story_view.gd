extends RefCounted
const LABELS={"clear_tree":"開拓","inspect_idol":"像を調べる","pray_wealth":"富を願う","repair_idol":"像を修理","recover_idol":"像を固定"}

static func tree(g,p: Vector2i,deep: bool=false):
	var c=g.center(p)
	g.draw_rect(Rect2(c+Vector2(-15,7),Vector2(32,10)),Color(0.12,0.22,0.14,0.3))
	g.draw_rect(Rect2(c+Vector2(-5,-24),Vector2(10,34)),Color("674d37"))
	g.draw_rect(Rect2(c+Vector2(-2,-23),Vector2(3,32)),Color("9a7651"))
	for row in [[-19,-50,40,20],[-27,-40,53,19],[-22,-26,44,12]]:
		g.draw_rect(Rect2(c+Vector2(row[0],row[1]),Vector2(row[2],row[3])),Color("304d3d") if deep else Color("456544"))
	g.draw_rect(Rect2(c+Vector2(-13,-50),Vector2(25,8)),Color("4a6846") if deep else Color("739056"))
	g.draw_rect(Rect2(c+Vector2(-23,-35),Vector2(15,7)),Color("5d7b4b"))

static func idol(g):
	var w=g.world
	if w.story.idol.is_empty(): return
	var p=g.actor_pixel("idol",w.Story.at(w))+g.TILE*0.5
	# Explicit code-art placeholder: abstract weathered object, no invented deity/civilization.
	g.draw_rect(Rect2(p+Vector2(-42,18),Vector2(86,22)),Color("655b42"))
	g.draw_rect(Rect2(p+Vector2(-39,10),Vector2(78,24)),Color("a39871"))
	g.draw_rect(Rect2(p+Vector2(-30,-51),Vector2(60,65)),Color("85672f"))
	g.draw_rect(Rect2(p+Vector2(-26,-55),Vector2(48,64)),Color("c29a4b"))
	g.draw_rect(Rect2(p+Vector2(-18,-61),Vector2(36,18)),Color("e1bd68"))
	g.draw_rect(Rect2(p+Vector2(-20,-48),Vector2(8,45)),Color("ead08a"))
	if w.story.idol.hp<w.story.idol.max_hp/2:
		g.draw_polyline(PackedVector2Array([p+Vector2(7,-48),p+Vector2(0,-28),p+Vector2(12,-11)]),Color("574933"),3)
	if w.story.idol.state in ["preparing","transporting"]:
		var enemies=w.enemies.filter(func(e):return e.id==w.story.idol.carrier and not e.done)
		if not enemies.is_empty(): g.draw_line(p+Vector2(0,18),g.actor_pixel("e%d"%enemies[0].id,enemies[0].pos),Color("cdb580"),3)
		for x in [-31,31]:g.draw_rect(Rect2(p+Vector2(x,29),Vector2(12,8)),Color("504539"))
		g.label_on(g,p+Vector2(-40,-73),"固定を外されている" if w.story.idol.state=="preparing" else "搬出中",15,Color("ffe0a2"))
	if g.selected.get("kind")=="idol" or w.story.idol.hp<w.story.idol.max_hp:
		g.label_on(g,p+Vector2(-38,59),"黄金像 %d/%d"%[w.story.idol.hp,w.story.idol.max_hp],14)

static func open(g,kind: String):
	g.story_modal=kind; g.story_page=0; rebuild(g)

static func close(g):
	if g.story_modal=="intro":
		g.world.story.intro_seen=true; g.world.Story.persist(g.world)
		g.world.morning_checkpoint.world_story=g.world.story.duplicate(true)
	g.story_modal=""
	if is_instance_valid(g.story_panel): g.story_panel.queue_free(); g.story_panel=null
	g.arrival_started=g.clock-3
	g.refresh()

static func next(g):
	g.story_page+=1
	if g.story_page>=g.world.Story.INTRO.size(): close(g)
	else: rebuild(g)

static func rebuild(g):
	if is_instance_valid(g.story_panel):g.story_panel.queue_free()
	var panel=Panel.new(); g.story_panel=panel
	panel.size=Vector2(1280,800); panel.mouse_filter=Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel",g.MarketView.panel(Color(0.13,0.20,0.16,0.9)))
	g.controls.get_parent().add_child(panel);panel.theme=g.controls.theme
	var title=Label.new();title.position=Vector2(230,154);title.add_theme_font_size_override("font_size",30)
	title.text={"intro":"父の残した牧場","diary":"父の記録","radio":"古いラジオ"}.get(g.story_modal,"")
	panel.add_child(title)
	var scroll=ScrollContainer.new();scroll.position=Vector2(230,222);scroll.size=Vector2(820,350);panel.add_child(scroll)
	var body=Label.new();body.custom_minimum_size=Vector2(780,0);body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;body.add_theme_font_size_override("font_size",23)
	if g.story_modal=="intro":body.text=g.world.Story.INTRO[g.story_page]
	elif g.story_modal=="diary":body.text="『像を壊してはいけない。』\n\n父の消息も、この像の由来も、まだ分からない。"
	else:
		body.text=""
		for news in g.world.story.news:body.text+="%d日目　%s\n%s\n\n"%[news.day,news.title,news.text]
		if body.text=="":body.text="今は、遠い雑音だけが聞こえる。"
	scroll.add_child(body)
	g.add_button(panel,"story_close","読み終える" if g.story_modal!="intro" else "スキップ",Rect2(230,612,180,46),close.bind(g))
	if g.story_modal=="intro":g.add_button(panel,"story_next","次へ" if g.story_page<3 else "牧場へ",Rect2(840,612,180,46),next.bind(g))

static func morning_buttons(g):
	g.add_button(g.palette,"diary","父の記録",Rect2(350,635,140,36),open.bind(g,"diary"))
	g.add_button(g.palette,"intro_again","回想",Rect2(498,635,100,36),open.bind(g,"intro"))
	if g.world.story.radio:
		g.add_button(g.palette,"radio","ラジオ",Rect2(810,635,140,36),open.bind(g,"radio"))
		if not g.world.story.news.is_empty():
			var headline=Label.new();headline.position=Vector2(350,683);headline.size=Vector2(600,28)
			headline.text="放送："+g.world.story.news[-1].title;headline.add_theme_font_size_override("font_size",17)
			headline.mouse_filter=Control.MOUSE_FILTER_IGNORE;g.palette.add_child(headline)

static func debug(g):
	var w=g.world
	for entry in w.entries:g.draw_rect(Rect2(Vector2(entry)*g.TILE,g.TILE),Color(0.9,0.4,0.3,0.4))
	for p in w.trees:g.label_on(g,g.center(p),w.trees[p],10)
