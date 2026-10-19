extends ScrollContainer
var view: Control
var destination: String
func _can_drop_data(_at: Vector2, value: Variant) -> bool:
	return view.accepts(value,destination)
func _drop_data(_at: Vector2, value: Variant) -> void:
	view.call_deferred("move_item",value.uid,value.source,destination,int(value.revision))
func _notification(what: int) -> void:
	if what in [NOTIFICATION_DRAG_BEGIN,NOTIFICATION_DRAG_END]: queue_redraw()
func _draw() -> void:
	if is_instance_valid(view) and not view.drag_payload.is_empty() and get_viewport().gui_is_dragging() and view.accepts(view.drag_payload,destination):
		draw_rect(Rect2(Vector2.ONE,size-Vector2.ONE*2),Color("6ed1bf"),false,3)
