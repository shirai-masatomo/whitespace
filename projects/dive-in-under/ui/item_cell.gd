extends Button
## The whole framed Button owns hit tests. Children are decorative only.
var game: Control
var host: Control
var source: String
var uid: String
var slot: String
var cell_index: int=-1
var actor_id: String="hero"
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		if event.shift_pressed and host.has_method("quick_item"):
			accept_event();host.call_deferred("quick_item",source,uid,slot);return
		if event.double_click:
			accept_event();host.call_deferred("activate_item",source,uid,slot)
func _get_drag_data(_at: Vector2) -> Variant:
	if uid=="" or is_instance_valid(game.modal_owner):return null
	var payload: Dictionary={"kind":"equipment-item","source":source,"uid":uid,"slot":slot,"actor":actor_id,"revision":int(game.campaign.revision)}
	if Input.is_key_pressed(KEY_SHIFT) and source in ["inventory","warehouse","cloth"] and game.campaign.items.get(uid)=="C01":payload.quantity=maxi(1,int(game.campaign.quantities[uid])/2)
	var preview:=Label.new();preview.text=tooltip_text+(" / 移動 %d枚"%payload.quantity if payload.has("quantity") else "");preview.add_theme_font_size_override("font_size",16)
	set_drag_preview(preview);game.gear_drag=payload;return payload
func _can_drop_data(_at: Vector2, value: Variant) -> bool:
	if disabled:return false
	return host.accepts_cell(value,source,slot,cell_index) if host.has_method("accepts_cell") else host.accepts_gear(value,source,slot)
func _drop_data(_at: Vector2, value: Variant) -> void:
	if host.has_method("drop_cell"):host.call_deferred("drop_cell",value,source,slot,cell_index)
	else:host.call_deferred("drop_gear",value,source,slot)
func _notification(what: int) -> void:
	if what in [NOTIFICATION_DRAG_BEGIN,NOTIFICATION_DRAG_END]:queue_redraw()
func _draw() -> void:
	if is_instance_valid(host) and get_viewport().gui_is_dragging() and _can_drop_data(Vector2.ZERO,game.gear_drag):draw_rect(Rect2(Vector2.ONE,size-Vector2.ONE*2),Color("6ed1bf"),false,3)
