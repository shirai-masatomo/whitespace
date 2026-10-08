extends RefCounted
const Data=preload("res://game/progression_data.gd")
const UI=preload("res://game/ui_style.gd")
const ENEMY_ORDER=["kidnapper","salaryman","destroyer","martial_artist","ninja","animal_tamer","runner","doberman","dancer","thief","maid"]
const NOTES={
 "dancer":"優雅な舞で仲間を励ます。\n倒れた仲間にも、もう一度立つ力を与える。",
 "thief":"毒瓶で相手を遠ざけ、目ぼしい物を持ち去る。\n逃げ切られる前なら、盗品を取り戻せる。",
 "maid":"忙しく仲間を気遣うコーヒー配り。\n怒らせると怖いが、乳牛には心を許す。",
 "kidnapper":"牧場主を探して忍び寄る。\n倒れたところを担ぎ、森の外へ連れ去る。",
 "destroyer":"頑丈な体で、目につく建物へ向かう。\n振り回す鉄球は、壁にも脅威となる。",
 "martial_artist":"勝負は好むが、命までは奪わない。\n戦いの前後には礼を欠かさない。",
 "salaryman":"頼りなさそうでも、仲間とのつながりは強い。\n追い詰められると電話を取り出す。",
 "ninja":"遠くから手裏剣で牽制し、近づけば短刀を抜く。\n見通しの良い場所には注意。",
 "animal_tamer":"動物に優しく呼びかけ、心を揺さぶる。\n手懐けた相手を連れて帰ろうとする。",
 "runner":"驚くほど足が速い。\nただし、走り続けるとすぐ息が上がる。",
 "doberman":"主人とともに現れる、用心深い番犬。\n屋外を駆け回り、敵へ立ち向かう。"}

static func placeholder(game,c,id: String,p: Vector2,size_value: float=1.0):
	# Intentionally schematic tokens, not a generated final character design.
	var animal=id in ["bullfrog","hedgehog","doberman"]
	var color=Color("8c9a6c") if animal else Color("9b7970")
	c.draw_rect(Rect2(p-Vector2(15,26)*size_value,Vector2(30,36)*size_value),color)
	c.draw_rect(Rect2(p-Vector2(15,26)*size_value,Vector2(30,36)*size_value),UI.WOOD,false,2)
	var title=game.Farm.SPECIES[id].title if animal else Data.enemy(id).name
	game.label_on(c,p+Vector2(-22,-32)*size_value,title,12,UI.INK)
	game.label_on(c,p+Vector2(-12,4)*size_value,"仮",12,UI.PAPER)

static func enemy_page(game,c,index: int):
	var id=ENEMY_ORDER[clampi(index,0,ENEMY_ORDER.size()-1)]
	var known=game.world.campaign.enemy_knowledge.get(id,0)
	var row=Data.enemy(id)
	if id=="doberman": row.name="ドーベルマン"; row.type_tag="Animal"; row.role_text="敵側の迎撃犬"
	game.label_on(c,Vector2(152,137),row.name if known>0 else "？？？",24,UI.INK)
	if known==0:
		c.draw_rect(Rect2(264,236,64,78),Color("8a8778"))
		game.label_on(c,Vector2(286,284),"?",32,UI.PAPER)
		game.label_on(c,Vector2(156,365),"？？？",24,UI.INK)
		game.label_on(c,Vector2(584,215),"まだ出会っていません",20,UI.INK)
	else:
		if id=="kidnapper":
			c.draw_set_transform(Vector2(296,315),0,Vector2(2.5,2.5))
			game.Delivered.draw_clip(c,"enemy/idle_right",Vector2.ZERO,0)
			c.draw_set_transform(Vector2.ZERO)
		else: game.Assets.portrait(c,id,Rect2(186,191,240,148),"enemy_portrait")
		game.Assets.badge(game,c,Vector2(330,120),row.rarity)
		game.Assets.portrait_frame(game,c,Rect2(182,186,248,159),row.rarity)
		game.label_on(c,Vector2(156,385),"人間" if row.type_tag=="Human" else "動物",15,UI.INK)
		game.MarketView.text(game,c,Rect2(152,403,292,84),NOTES[id],16)
		game.label_on(c,Vector2(584,137),"スキル",22,UI.INK)
		if known>=2:
			for i in range(Data.EnemySkills.BY_ACTOR.get(id,[]).size()):
				var skill=Data.EnemySkills.get_skill(Data.EnemySkills.BY_ACTOR[id][i]);var y=174+i*72
				c.draw_texture_rect(game.Assets.skill_texture(skill.SkillID),Rect2(584,y,32,32),false)
				game.label_on(c,Vector2(630,y+21),skill.Name,19,UI.INK)
				game.label_on(c,Vector2(630,y+42),skill.Type,13,Color("75816c"))
		else:game.label_on(c,Vector2(584,215),"行動を観察すると、詳しく分かります。",16,UI.INK)
		if known>=3:game.label_on(c,Vector2(584,450),"倒した",16,UI.INK)

	game.label_on(c,Vector2(470,510),"%d / %d"%[index+1,ENEMY_ORDER.size()],14,UI.INK)

static func equipment_buttons(game):
	var selected=game.world.animals.filter(func(a):return a.id in game.selected_animals and game.world.available(a))
	if selected.size()!=1: return
	var a=selected[0]; var choices=[]
	for id in Data.ITEMS:
		if game.world.item_count(id)>0 and game.Farm.Progression.can_equip(a,id): choices.append(id)
	if not a.equipment.is_empty(): choices.append("unequip")
	for i in range(choices.size()):
		var id=choices[i]
		game.add_button(game.palette,"equip_"+id,"外す" if id=="unequip" else Data.ITEMS[id].name+" ×%d"%game.world.item_count(id),Rect2(375+i*170,650,162,40),game.reserve_equipment.bind(a.id,id))
	if choices.is_empty(): game.notice("装備できる持ち物がありません")
