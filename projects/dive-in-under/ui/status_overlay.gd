extends Control
## Read-only presentation of committed combat events. No battle RNG or actor motion.
const COLORS={"poison":Color("8fd76c"),"blind":Color("bc92d2"),"paralysis":Color("ffe182"),"defense":Color("8edcff")}
const LABELS={"poison":"毒","blind":"暗闇","paralysis":"麻痺","defense":"防御"}
var battle: Dictionary={}
var effects: Array=[]
var intensity:=1.0
func _ready() -> void:
	mouse_filter=MOUSE_FILTER_IGNORE; z_index=950
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	create_tween().tween_method(func(v: float): intensity=v; queue_redraw(),1.0,0.0,0.4)
func point(side: String) -> Vector2:
	var stage:=get_parent()
	return stage.hero_art.position if side=="hero" else stage.enemy_art.position
static func status_text(unit: Dictionary) -> String:
	var parts: Array[String]=[]
	for id in unit.get("statuses",{}): parts.append("%s %d機会"%[LABELS[id],unit.statuses[id].remaining])
	return " / ".join(parts)
func _process(_delta: float) -> void:
	if not battle.is_empty(): queue_redraw()
func _draw() -> void:
	if battle.is_empty(): return
	var font:=get_theme_default_font()
	for side in ["hero","enemy"]:
		var unit: Dictionary=battle[side]
		if unit.hp<=0: continue
		var badges: Dictionary=unit.get("statuses",{}).duplicate(true)
		if unit.get("defense_until",-1)>=0: badges.defense={"remaining":maxi(1,unit.defense_until-unit.action_count)}
		var i:=0
		for id in badges:
			if not COLORS.has(id): continue
			var p:=point(side)+Vector2(-66,-46-i*25)
			var color: Color=COLORS[id]
			draw_rect(Rect2(p+Vector2(-9,-9),Vector2(18,18)),Color(.02,.06,.08,.88))
			draw_string(font,p+Vector2(-7,6),LABELS[id].left(1),HORIZONTAL_ALIGNMENT_LEFT,-1,15,color)
			var around:=point(side)+Vector2(0,-62)
			var phase: float=float(Time.get_ticks_msec()%1600)/1600.0
			color.a=.48
			if id=="poison":
				for n in 5: draw_circle(around+Vector2(-42+n*21,-24-fmod(phase*40+n*7,40)),2.5,color)
			elif id=="blind":
				draw_arc(around+Vector2(0,-38),45,PI*.1,PI*.9,10,color,2)
			elif id=="paralysis":
				draw_polyline(PackedVector2Array([around+Vector2(43,-35),around+Vector2(36,-16),around+Vector2(45,-16),around+Vector2(39,0)]),color,2)
			else: draw_arc(around,49,0,PI,12,color,2)
			i+=1
func visual_audit() -> Dictionary:
	return {"effect":"phase1-statuses","follows_actual_sprite":true,"duration":"while active; removed on expiry/death/end","combat_rng_used":false,"events":effects,"hero_statuses":battle.get("hero",{}).get("statuses",{}),"enemy_statuses":battle.get("enemy",{}).get("statuses",{})}
