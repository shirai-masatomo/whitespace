extends RefCounted
const UISkin=preload("res://ui/ui_skin.gd")
const Items=preload("res://ui/equipment_art.gd")
const Cell=preload("res://ui/item_cell.gd")
const Silhouette=preload("res://ui/slot_silhouette.gd")
static func cell(parent: Control, game: Control, host: Control, rect: Rect2, source: String, uid: String, slot: String="", selected: bool=false) -> Button:
	var b:=Button.new(); b.set_script(Cell); b.game=game; b.host=host; b.source=source; b.uid=uid; b.slot=slot; b.position=rect.position; b.size=rect.size
	UISkin.quiet_button(b,selected); b.set_meta("item_source",source); b.set_meta("item_uid",uid); b.set_meta("equip_slot",slot)
	b.actor_id=host.get_actor() if host.has_method("get_actor") else "hero"
	parent.add_child(b); b.pressed.connect(func():if not Input.is_key_pressed(KEY_SHIFT):host.call_deferred("select_item",source,uid,slot))
	var template: String=""
	if source=="pending":
		var i: int=preload("res://core/journey.gd").reward_index(game.campaign,uid)
		if i>=0: template=game.campaign.pending_rewards[i].id
	elif uid!="": template=game.campaign.items.get(uid,"")
	if template!="":
		var item: Dictionary=game.cfg.items[template]
		b.tooltip_text=game.cfg.slots.get(slot,game.cfg.slots.get(item.slot,"素材"))+" / "+item.name
		UISkin.picture(b,Items.texture(template,item.slot),Rect2(5,4,rect.size.x-10,rect.size.y-9))
		if template=="C01":
			var quantity: int=game.campaign.pending_rewards[preload("res://core/journey.gd").reward_index(game.campaign,uid)].get("quantity",1) if source=="pending" else int(game.campaign.quantities.get(uid,1))
			var amount:=UISkin.label(b,"×%d"%quantity,Rect2(2,rect.size.y-18,rect.size.x-4,16),12); amount.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
			b.tooltip_text+=" / %dG"%quantity
		if source!="pending" and item.slot!="" and game.campaign.item_condition.has(uid):
			var condition: Dictionary=game.campaign.item_condition[uid]
			var back:=ColorRect.new(); back.color=Color(.015,.04,.055,.94); back.position=Vector2(2,rect.size.y-17); back.size=Vector2(rect.size.x-4,15); back.mouse_filter=Control.MOUSE_FILTER_IGNORE; b.add_child(back)
			var value:=UISkin.label(b,"耐%d"%int(condition.current),Rect2(3,rect.size.y-18,rect.size.x-6,16),11); value.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
			b.tooltip_text+=" / 耐久 %d/%d"%[condition.current,condition.maximum]
	elif slot!="":
		var silhouette:=Control.new(); silhouette.set_script(Silhouette); silhouette.mouse_filter=Control.MOUSE_FILTER_IGNORE; silhouette.slot=slot; silhouette.position=Vector2.ONE*10; silhouette.size=rect.size-Vector2.ONE*20; b.add_child(silhouette); b.tooltip_text=game.cfg.slots[slot]+" / 未装備"
	else: b.tooltip_text="空きマス"
	return b
static func bag(parent: Control, game: Control, host: Control, origin: Vector2, columns: int=4, edge: int=44) -> void:
	for i in 15:
		var uid: String=game.campaign.inventory[i] if i<game.campaign.inventory.size() else ""
		cell(parent,game,host,Rect2(origin+Vector2(i%columns,int(i/columns))*(edge+4),Vector2.ONE*edge),"inventory",uid,"",game.flow_selection.get("uid","")==uid and uid!="")
