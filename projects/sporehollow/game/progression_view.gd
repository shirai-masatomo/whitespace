extends RefCounted
const Data=preload("res://game/progression_data.gd")
const UI=preload("res://game/ui_style.gd")
const ENEMY_ORDER=["kidnapper","salaryman","destroyer","martial_artist","ninja","animal_tamer","runner","doberman"]
const NOTES={
	"kidnapper":"牧場主を見つけると追跡。\n気絶させて森の外へ運びます。",
	"destroyer":"建物を優先して壊します。\n鉄球は隣接した相手だけに当たります。",
	"martial_artist":"戦闘の前後に礼をします。\n相手のHPを1より下へ減らしません。",
	"salaryman":"被弾すると応援を呼ぶことがあります。\n増援は森の外から入ってきます。",
	"ninja":"手裏剣は見通せる5マス以内。\n壁や閉じたドアで防げます。",
	"animal_tamer":"一時的に動物の忠誠を下げます。\n連れ去りは境界の手前なら救出可能。",
	"runner":"8秒走ると4秒間バテます。\n犬を連れていることがあります。",
	"doberman":"敵側の犬。屋内には入りません。\n主人が去っても自動では仲間になりません。"}

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
		else: game.Assets.portrait(c,id,Rect2(186,191,240,148),"enemy")
		game.Assets.badge(game,c,Vector2(156,346),row.rarity)
		game.label_on(c,Vector2(156,398),row.type_tag+" / "+Data.RARITY_NAMES[row.rarity],16,UI.INK)
		game.label_on(c,Vector2(584,170),row.role_text,20,UI.INK)
		game.label_on(c,Vector2(584,230),NOTES[id] if known>=2 else "行動を観察すると、詳しく分かります。",16,UI.INK)
		if known>=3: game.label_on(c,Vector2(584,342),{"salaryman":"撃退時：少量のお金","ninja":"撃退時：巻物1個"}.get(id,"撃退を確認しました"),16,UI.INK)
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
