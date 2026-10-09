extends RefCounted
const Assets=preload("res://game/ui_assets.gd")
const UI=preload("res://game/ui_style.gd")

# Page ink uses local coordinates; palette controls add the book origin once.
const BOOK_ORIGIN=Vector2(128,100)
const LEFT_PAGE=Rect2(136,64,336,442)
const RIGHT_PAGE=Rect2(548,64,344,442)
const TITLE=Rect2(144,119,320,35)
const DESCRIPTION=Rect2(144,348,320,76)
const MUTED=Color("72745e")
const CONTROLS={
	"book_animals":Rect2(140,66,156,36),"book_enemies":Rect2(308,66,92,36),
	"book_list":Rect2(556,66,100,36),"close_market":Rect2(762,66,122,36),
	"book_prev":Rect2(144,466,76,36),"book_next":Rect2(808,466,76,36),
	"train":Rect2(556,384,176,36),"rename":Rect2(744,384,140,36),
	"name_edit":Rect2(556,424,166,36),"save_name":Rect2(728,424,156,36)}

static func screen_rect(local: Rect2) -> Rect2:
	return Rect2(local.position+BOOK_ORIGIN,local.size)

static func compact_control(control: Control,local: Rect2):
	control.add_theme_font_size_override("font_size",17)
	for state in ["normal","hover","pressed","disabled","focus","read_only"]:
		if control.has_theme_stylebox(state):
			var style=control.get_theme_stylebox(state).duplicate()
			style.content_margin_top=4;style.content_margin_bottom=4
			style.content_margin_left=8;style.content_margin_right=8
			control.add_theme_stylebox_override(state,style)
	control.position=local.position+BOOK_ORIGIN
	control.size=local.size

static func layout_controls(g):
	for id in CONTROLS:
		var key="train_%d"%g.training_id if id=="train" else id
		if id=="name_edit":
			if g.rename_open and is_instance_valid(g.name_edit):compact_control(g.name_edit,CONTROLS[id])
		elif g.buttons.has(key):compact_control(g.buttons[key],CONTROLS[id])

static func list_rect(index: int) -> Rect2:
	return Rect2([144,312,556,724][index%4],132+(index/4)*166,148,146)

static func skill_rect(index: int) -> Rect2:
	return Rect2(556+(index%3)*108,188+(index/3)*92,88,88)

static func text_layout(g,value: String,area: Rect2,size: int,minimum: int=14) -> TextParagraph:
	var paragraph=TextParagraph.new()
	for font_size in range(size,minimum-1,-1):
		paragraph.clear()
		paragraph.add_string(value,g.FONT,font_size)
		paragraph.width=area.size.x
		paragraph.break_flags=TextServer.BREAK_MANDATORY|TextServer.BREAK_WORD_BOUND|TextServer.BREAK_ADAPTIVE
		if paragraph.get_size().y<=area.size.y:break
	return paragraph

static func text(g,c,area: Rect2,value: String,size: int=18,color: Color=UI.INK,minimum: int=14):
	text_layout(g,value,area,size,minimum).draw(c.get_canvas_item(),area.position,color)

static func animal_skills(g,a: Dictionary) -> Array:
	var result=[]
	var ids=g.Farm.AnimalData.stats(a.species,a.lv).skills+a.get("bonus_skills",[])
	for id in ids:
		var skill=g.Farm.AnimalData.skill(id)
		if skill.is_empty():continue
		var locked=a.lv<skill.unlock_level
		var detail=skill.name+"\n"+("Active" if skill.type=="active" else "Passive")+" / Lv%d"%skill.unlock_level+(" / CT %s秒"%str(skill.cooldown) if skill.type=="active" and skill.cooldown>0 else "")+"\n条件："+skill.condition+"\n"+skill.effect
		if locked:detail+="\n未解放：Lv%dで使えるようになります。"%skill.unlock_level
		result.append({"id":id,"tooltip":detail,"locked":locked,"ultimate":false})
	if a.species=="maid":result.append({"id":"rage","tooltip":g.Farm.ProgressData.EnemySkills.tooltip(g.Farm.ProgressData.EnemySkills.get_skill("rage")),"locked":false,"ultimate":true})
	return result

static func enemy_skills(g,id: String,known: int) -> Array:
	var result=[]
	if known<2:return result
	for skill_id in g.Farm.ProgressData.EnemySkills.BY_ACTOR.get(id,[]):
		var skill=g.Farm.ProgressData.EnemySkills.get_skill(skill_id)
		result.append({"id":skill_id,"tooltip":g.Farm.ProgressData.EnemySkills.tooltip(skill),"locked":false,"ultimate":skill.Type=="Ultimate"})
	return result

static func build(g):
	if g.training_id<0:
		var records=g.book_records();var page=-g.training_id-1
		for i in range(page*8,mini(records.size(),page*8+8)):
			var row=records[i];var rect=list_rect(i%8)
			hover(g,"book_entry_%d"%row.id,screen_rect(rect),"",g.book_detail.bind(row.id))
		return
	g.add_button(g.palette,"book_list","一覧",screen_rect(CONTROLS.book_list),g.book_detail.bind(-1))
	if g.book_section=="enemies":
		var id=g.ProgressView.ENEMY_ORDER[g.training_id]
		var enemy_entries=enemy_skills(g,id,g.world.campaign.enemy_knowledge.get(id,0))
		for i in range(enemy_entries.size()):hover(g,"enemy_skill_"+enemy_entries[i].id,screen_rect(skill_rect(i)),enemy_entries[i].tooltip)
		return
	if g.world.phase in ["shop","day"]:g.build_training()
	var rows=g.book_records().filter(func(a):return a.id==g.training_id)
	if rows.is_empty():return
	var skills=animal_skills(g,rows[0])
	for i in range(skills.size()):hover(g,"skill_"+skills[i].id,screen_rect(skill_rect(i)),skills[i].tooltip)

static func hover(g,id: String,rect: Rect2,detail: String,callback: Callable=Callable()):
	var action=callback
	if not action.is_valid():action=func():pass
	g.add_button(g.palette,id,"",rect,action)
	var button=g.buttons[id]
	button.tooltip_text=detail
	for state in ["normal","pressed","focus"]:button.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	var highlight=StyleBoxFlat.new()
	highlight.bg_color=Color(1,1,1,0.10);highlight.border_color=UI.GOLD
	highlight.set_border_width_all(2);highlight.set_corner_radius_all(4)
	button.add_theme_stylebox_override("hover",highlight)

static func header(g,c,title: String,subtitle: String,tier: int):
	text(g,c,TITLE,title,26,UI.INK,18)
	text(g,c,Rect2(144,157,180,28),subtitle,15,MUTED)
	Assets.badge(g,c,Vector2(332,158),tier)

static func draw_skills(g,c,skills: Array):
	text(g,c,Rect2(556,122,328,32),"スキル",22)
	text(g,c,Rect2(556,157,328,24),"アイコンにカーソルを合わせると詳細",14,MUTED)
	for i in range(skills.size()):
		var skill=skills[i];var rect=skill_rect(i)
		var edge=Color("ab843e") if skill.ultimate else Color("b8ac8a")
		c.draw_style_box(g.MarketView.panel(Color("e8dfc2") if skill.locked else Color("f4e9c9"),edge,2 if skill.ultimate else 1),rect)
		c.draw_texture_rect(Assets.skill_texture(skill.id),rect.grow(-7),false,Color(1,1,1,0.38) if skill.locked else Color.WHITE)
		if skill.locked:
			# The lock distinguishes an unavailable skill without a persistent label.
			var p=rect.position+Vector2(66,67)
			c.draw_rect(Rect2(p+Vector2(0,5),Vector2(13,10)),MUTED)
			c.draw_arc(p+Vector2(6.5,5),4,PI,TAU,10,MUTED,2)

static func page_number(g,c,page: int,total: int):
	text(g,c,Rect2(382,476,82,24),"%d / %d"%[page,total],14,MUTED)

# Only an owned individual's explicit name belongs on a thumbnail.
# animal_name() falls back to a species title, and enemy records use catalog names.
static func grid_name(row: Dictionary,enemy: bool) -> String:
	return "" if enemy else str(row.get("name","")).strip_edges()

static func nameplate_rect(card: Rect2) -> Rect2:
	return Rect2(card.position+Vector2(10,94),Vector2(128,48))

static func portrait_rect(card: Rect2) -> Rect2:
	# Reserve the same lower name area even when it is blank.
	return Rect2(card.position+Vector2(20,12),Vector2(108,76))

static func nameplate_layout(g,value: String,plate: Rect2) -> TextParagraph:
	var paragraph=text_layout(g,value,plate.grow(-4),15,13)
	paragraph.alignment=HORIZONTAL_ALIGNMENT_CENTER
	return paragraph

static func draw_nameplate(g,c,card: Rect2,value: String):
	var plate=nameplate_rect(card)
	c.draw_style_box(g.MarketView.panel(Color("e8dbb8"),Color("c3ac78"),1),plate)
	var paragraph=nameplate_layout(g,value,plate)
	paragraph.draw(c.get_canvas_item(),plate.position+Vector2(4,(plate.size.y-paragraph.get_size().y)*0.5),UI.INK)

static func draw(g,c,id: int):
	if id<0:grid(g,c,-id-1);return
	if g.book_section=="enemies":g.ProgressView.enemy_page(g,c,id);return
	var records=g.book_records()
	var rows=records.filter(func(a):return a.id==id)
	if rows.is_empty():return
	var a=rows[0];var species=g.Farm.SPECIES[a.species]
	var named=a.get("name","")!=""
	var tier=g.Farm.ProgressData.rarity(a.get("rarity",0))
	header(g,c,a.name if named else species.title,species.title+"  ·  Lv%d"%a.lv,tier)
	Assets.portrait_frame(g,c,Rect2(184,199,244,138),tier)
	Assets.portrait(c,a.species,Rect2(188,203,236,130),"portrait")
	text(g,c,DESCRIPTION,g.Farm.AnimalData.character_text(a.species),16)
	var maximum=g.animal_hp(a);var hp=a.get("hp",maximum)
	var state="療養・%d日朝に復帰"%(a.unavailable_through_day+1) if a.get("unavailable_through_day",0)>=g.world.campaign.day else "活動中"
	text(g,c,Rect2(144,430,320,26),"HP %d / %d   ·   %s"%[hp,maximum,state],16)
	c.draw_rect(Rect2(144,457,320,5),Color("c8bd9b"))
	c.draw_rect(Rect2(144,457,320.0*clampf(float(hp)/maxi(1,maximum),0,1),5),Color("789965"))
	draw_skills(g,c,animal_skills(g,a))
	c.draw_line(Vector2(556,296),Vector2(884,296),Color("c8bd9b"),1)
	text(g,c,Rect2(556,304,328,26),"忠誠 %d  ·  共通EXP %d"%[a.get("loyalty",0),g.world.campaign.exp_pool],17)
	text(g,c,Rect2(556,334,328,26),"装備："+g.Farm.ProgressData.ITEMS.get(a.get("equipment",{}).get("item_id",""),{}).get("name","なし"),17)
	if a.species=="maid":text(g,c,Rect2(556,362,328,20),"技ゲージ %d / %d"%[a.get("ultimate_gauge",0),a.get("ultimate_gauge_max",100)],14,MUTED)
	page_number(g,c,records.find(a)+1,records.size())

static func grid(g,c,page: int):
	var records=g.book_records()
	for slot in range(8):
		var index=page*8+slot;var rect=list_rect(slot);var p=rect.position
		var row=records[index] if index<records.size() else {}
		var enemy=g.book_section=="enemies"
		var key=(g.ProgressView.ENEMY_ORDER[row.id] if enemy else row.species) if not row.is_empty() else ""
		var known=not row.is_empty() and (not enemy or g.world.campaign.enemy_knowledge.get(key,0)>0)
		var tier=g.Farm.ProgressData.rarity(g.Farm.ProgressData.enemy(key).rarity if enemy and known else row.get("rarity",0))
		c.draw_style_box(g.MarketView.panel(Color("eee1ba") if known else Color("d3c8a8"),Color(g.Farm.ProgressData.RARITY_COLORS[tier]) if known else Color("b7ac8e"),1),rect)
		if known:
			var name=grid_name(row,enemy)
			Assets.portrait(c,key,portrait_rect(rect),"enemy" if enemy else "animal")
			if name!="":draw_nameplate(g,c,rect,name)
			Assets.emblem(g,c,p+Vector2(118,8),tier,22)
		else:g.label_on(c,p+Vector2(59,83),"?",38,Color("8b876e"))
	page_number(g,c,page+1,maxi(1,ceili(records.size()/8.0)))
