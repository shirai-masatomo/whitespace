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
	if g.book_section=="enemies":
		var id=g.ProgressView.ENEMY_ORDER[g.training_id]
		if g.world.campaign.enemy_knowledge.get(id,0)>=2:
			for i in range(g.Farm.ProgressData.EnemySkills.BY_ACTOR.get(id,[]).size()):
				var skill=g.Farm.ProgressData.EnemySkills.get_skill(g.Farm.ProgressData.EnemySkills.BY_ACTOR[id][i])
				hover(g,"enemy_skill_"+skill.SkillID,Rect2(712,274+i*72,318,54),g.Farm.ProgressData.EnemySkills.tooltip(skill))
		return
	if g.world.phase=="shop":g.build_training()
	var rows=g.book_records().filter(func(a):return a.id==g.training_id)
	if rows.is_empty():return
	var a=rows[0]
	var ids=g.Farm.AnimalData.stats(a.species,a.lv).skills+a.get("bonus_skills",[])
	for i in range(ids.size()):
		var skill=g.Farm.AnimalData.skill(ids[i])
		var text=skill.name+"\n"+("Active" if skill.type=="active" else "Passive")+" / Lv%d"%skill.unlock_level+(" / CT %s秒"%str(skill.cooldown) if skill.type=="active" and skill.cooldown>0 else "")+"\n条件："+skill.condition+"\n"+skill.effect
		hover(g,"skill_"+ids[i],Rect2(704,270+i*64,330,52),text)
	if a.species=="maid":hover(g,"skill_rage",Rect2(704,436,330,49),g.Farm.ProgressData.EnemySkills.tooltip(g.Farm.ProgressData.EnemySkills.get_skill("rage")))

static func hover(g,id: String,rect: Rect2,text: String):
	g.add_button(g.palette,id,"",rect,func():pass)
	g.buttons[id].tooltip_text=text
	for state in ["normal","hover","pressed","focus"]:g.buttons[id].add_theme_stylebox_override(state,StyleBoxEmpty.new())

static func draw(g,c,id: int):
	if id<0: grid(g,c,-id-1);return
	if g.book_section=="enemies":g.ProgressView.enemy_page(g,c,id);return
	var rows=g.book_records().filter(func(a):return a.id==id)
	if rows.is_empty():return
	var a=rows[0];var species=g.Farm.SPECIES[a.species]
	var named=a.get("name","")!=""
	g.label_on(c,Vector2(152,136),a.name if named else species.title,27,UI.INK)
	g.label_on(c,Vector2(152,163),species.title if named else "名前なし",15,UI.INK)
	Assets.badge(g,c,Vector2(306,147),g.Farm.ProgressData.rarity(a.get("rarity",0)))
	Assets.portrait_frame(g,c,Rect2(172,183,258,152),g.Farm.ProgressData.rarity(a.get("rarity",0)))
	Assets.portrait(c,a.species,Rect2(176,189,250,140),"portrait")
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
		c.draw_texture_rect(Assets.skill_texture(skills[i]),Rect2(576,y,28,28),false)
		g.label_on(c,Vector2(618,y+21),skill.name+("（未解放）" if a.lv<skill.unlock_level else ""),19,UI.INK)
		g.label_on(c,Vector2(618,y+42),"発動" if skill.type=="active" else "パッシブ",13,Color("75816c"))
	if a.species=="maid":c.draw_texture_rect(Assets.skill_texture("rage"),Rect2(576,335,28,28),false)
	g.label_on(c,Vector2(576,370),"必殺技：激ギレ" if a.species=="maid" else "必殺技：未習得",17,UI.INK)
	g.label_on(c,Vector2(576,397),"技ゲージ %d / %d"%[a.get("ultimate_gauge",0),a.get("ultimate_gauge_max",100)],14,UI.INK)
	g.label_on(c,Vector2(576,442),"忠誠 %d  ·  共通EXP %d"%[a.get("loyalty",0),g.world.campaign.exp_pool],16,UI.INK)

static func grid(g,c,page: int):
	var records=g.book_records()
	for slot in range(8):
		var index=page*8+slot;var rect=list_rect(slot);var p=rect.position
		var row=records[index] if index<records.size() else {}
		var enemy=g.book_section=="enemies"
		var key=(g.ProgressView.ENEMY_ORDER[row.id] if enemy else row.species) if not row.is_empty() else ""
		var known=not row.is_empty() and (not enemy or g.world.campaign.enemy_knowledge.get(key,0)>0)
		var tier=g.Farm.ProgressData.rarity(g.Farm.ProgressData.enemy(key).rarity if enemy and known else row.get("rarity",0))
		c.draw_style_box(g.MarketView.panel(Color("eee1ba") if known else Color("767865"),Color(g.Farm.ProgressData.RARITY_COLORS[tier]) if known else Color("626553"),2),rect)
		if known:
			var title=(g.Farm.ProgressData.enemy(key).name if key!="doberman" else "ドーベルマン") if enemy else g.Farm.animal_name(row)
			Assets.portrait(c,key,Rect2(p+Vector2(25,8),Vector2(114,77)),"enemy" if enemy else "animal")
			g.MarketView.text(g,c,Rect2(p+Vector2(10,87),Vector2(145,32)),title,16)
			Assets.emblem(g,c,p+Vector2(126,112),tier,27)
		else:g.label_on(c,p+Vector2(68,81),"?",40,Color("b8b9a2"))
	g.label_on(c,Vector2(464,520),"%d / %d"%[page+1,maxi(1,ceili(records.size()/8.0))],14,UI.INK)
