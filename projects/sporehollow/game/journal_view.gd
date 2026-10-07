extends RefCounted
const Assets=preload("res://game/ui_assets.gd")
const UI=preload("res://game/ui_style.gd")

static func list_rect(index: int) -> Rect2:
	return Rect2([132,314,570,752][index%4],172+(index/4)*160,164,144)

static func build(g):
	if g.training_id<0:
		var records=g.book_records();var page=-g.training_id-1
		for i in range(page*8,mini(records.size(),page*8+8)):
			var row=records[i];var rect=list_rect(i%8)
			g.add_button(g.palette,"book_entry_%d"%row.id,"",Rect2(rect.position+Vector2(128,100),rect.size),g.book_detail.bind(row.id))
			for state in ["normal","hover","pressed","focus"]:g.buttons["book_entry_%d"%row.id].add_theme_stylebox_override(state,StyleBoxEmpty.new())
		return
	g.add_button(g.palette,"book_list","一覧",Rect2(880,116,130,44),g.book_detail.bind(-1))
	if g.book_section!="animals":return
	g.build_training()
	var rows=g.world.campaign.animals.filter(func(a):return a.id==g.training_id)
	if rows.is_empty():return
	var a=rows[0]
	for i in range((g.Farm.AnimalData.stats(a.species,a.lv).skills+a.get("bonus_skills",[])).size()):
		var id=(g.Farm.AnimalData.stats(a.species,a.lv).skills+a.get("bonus_skills",[]))[i]
		var skill=g.Farm.AnimalData.skill(id)
		g.add_button(g.palette,"skill_"+id,"",Rect2(704,270+i*64,330,52),func():pass)
		var b=g.buttons["skill_"+id]
		b.tooltip_text=skill.name+"\n"+("発動" if skill.type=="active" else "パッシブ")+" / Lv%d"%skill.unlock_level+(" / CT %s秒"%str(skill.cooldown) if skill.type=="active" and skill.cooldown>0 else "")+"\n"+skill.condition+"\n"+skill.effect
		for state in ["normal","hover","pressed","focus"]:b.add_theme_stylebox_override(state,StyleBoxEmpty.new())

static func draw(g,c,id: int):
	if id<0: grid(g,c,-id-1);return
	if g.book_section=="enemies":g.ProgressView.enemy_page(g,c,id);return
	var rows=g.world.campaign.animals.filter(func(a):return a.id==id)
	if rows.is_empty():return
	var a=rows[0];var species=g.Farm.SPECIES[a.species]
	var named=a.get("name","")!=""
	g.label_on(c,Vector2(152,136),a.name if named else species.title,27,UI.INK)
	g.label_on(c,Vector2(152,163),species.title if named else "名前なし",15,UI.INK)
	Assets.badge(g,c,Vector2(306,147),g.Farm.ProgressData.rarity(a.get("rarity",0)))
	Assets.portrait(c,a.species,Rect2(176,189,250,140))
	g.MarketView.text(g,c,Rect2(152,351,294,64),g.Farm.AnimalData.character_text(a.species),16)
	var maximum=g.animal_hp(a);var hp=a.get("hp",maximum)
	c.draw_rect(Rect2(152,432,280,7),Color("bab395"))
	c.draw_rect(Rect2(152,432,280.0*hp/maximum,7),Color("789965"))
	g.label_on(c,Vector2(152,459),"HP %d / %d · Lv%d"%[hp,maximum,a.lv],16,UI.INK)
	g.label_on(c,Vector2(152,484),"療養中" if a.get("unavailable_through_day",0)>=g.world.campaign.day else "活動中",15,UI.INK)
	g.label_on(c,Vector2(152,509),"装備："+g.Farm.ProgressData.ITEMS.get(a.get("equipment",{}).get("item_id",""),{}).get("name","なし"),15,UI.INK)
	g.label_on(c,Vector2(576,136),"スキル",22,UI.INK)
	var skills=g.Farm.AnimalData.stats(a.species,a.lv).skills+a.get("bonus_skills",[])
	for i in range(skills.size()):
		var skill=g.Farm.AnimalData.skill(skills[i]);var y=174+i*64
		c.draw_texture_rect(UI.icon(Assets.SKILL_ICONS.get(skills[i],"spark")),Rect2(576,y,28,28),false)
		g.label_on(c,Vector2(618,y+21),skill.name+("（未解放）" if a.lv<skill.unlock_level else ""),19,UI.INK)
		g.label_on(c,Vector2(618,y+42),"発動" if skill.type=="active" else "パッシブ",13,Color("75816c"))
	g.label_on(c,Vector2(576,370),"必殺技：未習得",17,UI.INK)
	g.label_on(c,Vector2(576,397),"技ゲージ %d / %d"%[a.get("ultimate_gauge",0),a.get("ultimate_gauge_max",100)],14,UI.INK)
	g.label_on(c,Vector2(576,442),"忠誠 %d  ·  共通EXP %d"%[a.get("loyalty",0),g.world.campaign.exp_pool],16,UI.INK)

static func grid(g,c,page: int):
	var records=g.book_records()
	g.label_on(c,Vector2(152,136),"牧場の仲間" if g.book_section=="animals" else "敵",24,UI.INK)
	if records.is_empty():g.label_on(c,Vector2(152,224),"まだ仲間がいません",18,UI.INK)
	for index in range(page*8,mini(records.size(),page*8+8)):
		var row=records[index];var rect=list_rect(index%8);var p=rect.position
		var enemy=g.book_section=="enemies";var key=g.ProgressView.ENEMY_ORDER[row.id] if enemy else row.species
		var known=not enemy or g.world.campaign.enemy_knowledge.get(key,0)>0
		var title=(g.Farm.ProgressData.enemy(key).name if key!="doberman" else "ドーベルマン") if enemy else g.Farm.animal_name(row)
		c.draw_style_box(g.MarketView.panel(Color("eee1ba"),Color("cbbd94")),rect)
		if known:Assets.portrait(c,key,Rect2(p+Vector2(32,8),Vector2(100,68)),"enemy" if enemy else "animal")
		else:g.label_on(c,p+Vector2(71,55),"?",30,Color("8b8774"))
		g.MarketView.text(g,c,Rect2(p+Vector2(10,80),Vector2(148,26)),title if known else "？？？",16)
		if known:Assets.badge(g,c,p+Vector2(10,113),g.Farm.ProgressData.rarity(row.get("rarity",0)),true)
	g.label_on(c,Vector2(464,520),"%d / %d"%[page+1,maxi(1,ceili(records.size()/8.0))],14,UI.INK)
