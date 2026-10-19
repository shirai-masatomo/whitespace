extends RefCounted
const UISkin=preload("res://ui/ui_skin.gd")
const Items=preload("res://ui/equipment_art.gd")
const Cell=preload("res://ui/item_cell.gd")
const Silhouette=preload("res://ui/slot_silhouette.gd")
static func cell(parent: Control, game: Control, host: Control, rect: Rect2, source: String, uid: String, slot: String="", selected: bool=false) -> Button:
	var b:=Button.new(); b.set_script(Cell); b.game=game; b.host=host; b.source=source; b.uid=uid; b.slot=slot; b.position=rect.position; b.size=rect.size
	UISkin.quiet_button(b,selected); b.set_meta("item_source",source); b.set_meta("item_uid",uid); b.set_meta("equip_slot",slot)
	parent.add_child(b); b.pressed.connect(func():host.select_item(source,uid,slot))
	var template: String=""
	if source=="pending":
		var i: int=preload("res://core/journey.gd").reward_index(game.campaign,uid)
		if i>=0: template=game.campaign.pending_rewards[i].id
	elif uid!="": template=game.campaign.items.get(uid,"")
	if template!="":
		var item: Dictionary=game.cfg.items[template]
		b.tooltip_text=game.cfg.slots.get(slot,game.cfg.slots.get(item.slot,"素材"))+" / "+item.name+" ×1"
		UISkin.picture(b,Items.texture(template,item.slot),Rect2(5,4,rect.size.x-10,rect.size.y-9))
		var count:=UISkin.label(b,"1",Rect2(rect.size.x-18,rect.size.y-22,15,20),12); count.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	elif slot!="":
		var silhouette:=Control.new(); silhouette.set_script(Silhouette); silhouette.slot=slot; silhouette.position=Vector2.ONE*10; silhouette.size=rect.size-Vector2.ONE*20; b.add_child(silhouette); b.tooltip_text=game.cfg.slots[slot]+" / 未装備"
	else: b.tooltip_text="バックパック / 空き枠"
	return b
static func bag(parent: Control, game: Control, host: Control, origin: Vector2, columns: int=4, edge: int=44) -> void:
	for i in 15:
		var uid: String=game.campaign.inventory[i] if i<game.campaign.inventory.size() else ""
		cell(parent,game,host,Rect2(origin+Vector2(i%columns,int(i/columns))*(edge+4),Vector2.ONE*edge),"inventory",uid,"",game.flow_selection.get("uid","")==uid and uid!="")
