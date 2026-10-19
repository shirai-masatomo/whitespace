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
	return stage.display_foot(stage.hero_position_hint() if side=="hero" else stage.enemy_position_hint())
static func status_text(unit: Dictionary) -> String:
	var parts: Array[String]=[]
	for id in unit.get("statuses",{}): parts.append("%s %d機会"%[LABELS[id],unit.statuses[id].remaining])
	return " / ".join(parts)
func _draw() -> void:
	if battle.is_empty(): return
	var font:=get_theme_default_font()
	for side in ["hero","enemy"]:
		var unit: Dictionary=battle[side]
		var badges: Dictionary=unit.get("statuses",{}).duplicate(true)
		if unit.get("defense_until",-1)>=0: badges.defense={"remaining":maxi(1,unit.defense_until-unit.action_count)}
		var i:=0
		for id in badges:
			var pos:=point(side)+Vector2(-95+i*66,-190)
			pos.x=clampf(pos.x,4,size.x-70); pos.y=maxf(106,pos.y)
			draw_rect(Rect2(pos,Vector2(64,32)),Color(0.025,0.055,0.07,.93))
			draw_rect(Rect2(pos,Vector2(64,32)),COLORS[id],false,2)
			draw_string(font,pos+Vector2(4,23),"%s%d"%[LABELS[id],badges[id].remaining],HORIZONTAL_ALIGNMENT_LEFT,-1,16,COLORS[id]); i+=1
	if intensity<=0: return
	for e in effects:
		var id: String=e.get("status","defense")
		if not COLORS.has(id): continue
		var side: String=e.get("target",e.get("actor","hero"))
		var p:=point(side)+Vector2(0,-95)
		var color: Color=COLORS[id]; color.a=intensity*.8
		if id=="poison":
			for n in range(6): draw_rect(Rect2(p+Vector2((n%3-1)*22,(n/3)*24-35-intensity*10),Vector2(7,7)),color)
		elif id=="paralysis":
			draw_polyline(PackedVector2Array([p+Vector2(-12,-52),p+Vector2(12,-18),p+Vector2(-10,-18),p+Vector2(12,18)]),color,4)
		elif id=="blind": draw_rect(Rect2(p+Vector2(-48,-56),Vector2(96,48)),Color(.14,.04,.22,intensity*.75))
		else: draw_arc(p,38,-PI,0,16,color,4)
		var label: String=LABELS[id]
		if e.type=="status_damage": label+=" -%d"%e.damage
		if e.type=="action_skipped": label+=" / 行動不能"
		draw_string(font,Vector2(clampf(p.x+40,8,size.x-170),p.y-62),label,HORIZONTAL_ALIGNMENT_LEFT,-1,18,color)
func visual_audit() -> Dictionary:
	return {"effect":"phase1-statuses","static_character":true,"duration_seconds":0.4,"combat_rng_used":false,"events":effects,"hero_statuses":battle.get("hero",{}).get("statuses",{}),"enemy_statuses":battle.get("enemy",{}).get("statuses",{})}
