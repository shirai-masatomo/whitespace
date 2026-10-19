extends Button
## Payloads are references, never ownership. Only the shared controller commits a move.
var game: Control
var host: Control
var source: String
var uid: String
var slot: String
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed and event.double_click:
		accept_event(); host.call_deferred("activate_item",source,uid,slot)
func _get_drag_data(_at: Vector2) -> Variant:
	if uid=="": return null
	var payload: Dictionary={"kind":"equipment-item","source":source,"uid":uid,"slot":slot,"revision":int(game.campaign.revision)}
	var preview:=Label.new(); preview.text=tooltip_text; preview.add_theme_font_size_override("font_size",16)
	set_drag_preview(preview); game.gear_drag=payload; return payload
func _can_drop_data(_at: Vector2, value: Variant) -> bool:
	var allowed: bool=host.accepts_gear(value,source,slot)
	if host.has_method("show_drag_reason"):
		host.show_drag_reason("ここへ移動できます。" if allowed else preload("res://ui/gear_actions.gd").reason(game,value,source,slot))
	return allowed
func _drop_data(_at: Vector2, value: Variant) -> void:
	host.call_deferred("drop_gear",value,source,slot)
func _notification(what: int) -> void:
	if what in [NOTIFICATION_DRAG_BEGIN,NOTIFICATION_DRAG_END]: queue_redraw()
func _draw() -> void:
	if is_instance_valid(host) and get_viewport().gui_is_dragging() and host.accepts_gear(game.gear_drag,source,slot):
		draw_rect(Rect2(Vector2.ONE,size-Vector2.ONE*2),Color("6ed1bf"),false,3)
