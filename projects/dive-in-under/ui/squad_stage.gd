extends Control
## The same live squad state drives portraits, HP, selection, effects and targets.
const UISkin=preload("res://ui/ui_skin.gd")
const Art=preload("res://ui/visual_assets.gd")
const S=preload("res://core/squad_combat.gd")
var host: Control
var battle: Dictionary={}
var floor_number: int=1
var background_override: String=""
var integrated_layout: bool=true
var wide_layout: bool=true
var enemy_id: String=""
var hero_art: Sprite2D
var enemy_art: Sprite2D
var cards: Dictionary={}
func _ready() -> void:
	clip_contents=true
	UISkin.picture(self,Art.background_texture(background_override if background_override!="" else "cavern"),Rect2(Vector2.ZERO,size),true)
	for team in ["allies","enemies"]:
		var indexes: Dictionary={"front":0,"back":0}
		for id in battle[team]:
			var unit: Dictionary=battle.units[id];var rank_name: String=S.rank(battle,id);var row: int=indexes[rank_name];indexes[rank_name]+=1
			var x: int=(158 if rank_name=="front" else 15) if team=="allies" else (418 if rank_name=="front" else 562)
			var box:=Control.new();box.position=Vector2(x,26+row*120);box.size=Vector2(138,112);add_child(box)
			var key: String="hero" if team=="allies" else unit.id
			var image: TextureRect=UISkin.picture(box,Art.actor_texture(key),Rect2(19,0,100,78));image.mouse_filter=Control.MOUSE_FILTER_IGNORE
			var pick:=Button.new();pick.flat=true;pick.size=box.size;box.add_child(pick);pick.set_meta("actor_select",id);pick.pressed.connect(func():host.select_actor(id))
			var label: Label=UISkin.label(box,unit.name,Rect2(2,77,134,18),14,UISkin.INK,true)
			var hp: Control=UISkin.gauge(box,unit.hp,unit.max_hp,Rect2(4,98,130,7),Color("ba4a39"))
			var status: Label=UISkin.label(box,"",Rect2(88,8,47,58),13,UISkin.GOLD,true)
			cards[id]={"box":box,"image":image,"name":label,"hp":hp,"status":status,"origin":box.position}
	refresh_squad(battle)
func refresh_squad(value: Dictionary) -> void:
	battle=value
	for id in cards:
		var c: Dictionary=cards[id];var u: Dictionary=battle.units[id];c.hp.value=u.hp;c.box.modulate=Color.WHITE if u.hp>0 else Color(.35,.35,.35,.5)
		c.name.text=u.name+"  %d/%d"%[u.hp,u.max_hp]
		var names: Array=[]
		for effect in u.statuses:names.append({"poison":"毒","blind":"暗闇","paralysis":"麻痺"}.get(effect,effect))
		if u.defense_until>=0:names.append("防御")
		c.status.text="\n".join(names)
func present_event(event: Dictionary, game: Control) -> void:
	var actor: String=event.get("actor","");var target: String=event.get("target",actor)
	if not cards.has(actor) or not cards.has(target):game.impact(event);return
	var c: Dictionary=cards[actor];var other: Dictionary=cards[target];var tween:=create_tween()
	if event.type=="attack":tween.tween_property(c.box,"position",c.origin+Vector2(10 if actor in battle.allies else -10,0),.08)
	else:tween.tween_interval(.08)
	tween.tween_callback(func():
		game.impact(event)
		var popup:=Label.new();popup.text=("-%d"%event.damage if event.hit else "MISS") if event.type=="attack" else ("毒 -%d"%event.damage if event.type=="status_damage" else ("HP +%d"%event.healing if event.has("healing") else "状態／技能"));popup.position=other.box.position+Vector2(5,22);popup.add_theme_font_size_override("font_size",21);popup.add_theme_color_override("font_color",UISkin.GOLD);popup.add_theme_constant_override("outline_size",5);add_child(popup)
		var f:=popup.create_tween();f.tween_property(popup,"position:y",popup.position.y-18,.13);f.tween_callback(popup.queue_free)
	)
	tween.tween_property(c.box,"position",c.origin,.08)
