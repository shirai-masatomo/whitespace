extends Control
const UISkin=preload("res://ui/ui_skin.gd")
var host: Control
var stage: Control
var side: String
var pick: Button
var name_label: Label
var bar: Control
var hp: Label
var body_pick: Button
func _ready() -> void:
	mouse_filter=MOUSE_FILTER_IGNORE; z_index=960; size=Vector2(156,43)
	pick=Button.new(); pick.flat=true; pick.size=size; add_child(pick); pick.pressed.connect(func():host.select_actor(side)); pick.set_meta("actor_select",side)
	name_label=UISkin.label(self,"",Rect2(4,0,148,18),13)
	bar=UISkin.gauge(self,1,1,Rect2(4,21,148,7),Color("b83e32") if side=="hero" else Color("b0783a"))
	hp=UISkin.label(self,"",Rect2(4,29,148,16),12); hp.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	body_pick=Button.new(); body_pick.flat=true; body_pick.mouse_default_cursor_shape=CURSOR_POINTING_HAND; body_pick.set_meta("actor_body",side); body_pick.pressed.connect(func():host.select_actor(side)); stage.add_child(body_pick); body_pick.z_index=900
	for state in ["normal","hover","pressed","focus"]:
		body_pick.add_theme_stylebox_override(state,StyleBoxEmpty.new()); pick.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	refresh()
func _process(_delta: float) -> void:
	var actor: Sprite2D=stage.hero_art if side=="hero" else stage.enemy_art
	position=Vector2(clampf(actor.position.x-78,4,stage.size.x-160),minf(actor.position.y+6,stage.size.y-46))
	if actor.texture:
		body_pick.position=actor.position+actor.offset*actor.scale; body_pick.size=actor.texture.get_size()*actor.scale
func refresh() -> void:
	var unit: Dictionary=host.battle[side]
	visible=unit.hp>0; body_pick.visible=visible
	name_label.text=unit.name+" Lv.%d"%int(unit.level); hp.text="%d / %d"%[unit.hp,unit.max_hp]; bar.value=unit.hp; bar.max_value=unit.max_hp
func visual_audit() -> Dictionary:
	return {"side":side,"visible":visible,"rect":str(get_global_rect()),"body_rect":str(body_pick.get_global_rect()),"hp":hp.text}

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color(.015,.04,.055,.88))
	var selected: bool=host.game.flow_selection.get("kind")=="actor" and host.game.flow_selection.get("side")==side
	draw_rect(Rect2(Vector2.ZERO,size),Color("e7c47d") if selected else Color("455b60"),false,1)
