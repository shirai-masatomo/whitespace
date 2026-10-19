extends Button
## Drag carries a reference only. Ownership changes once, at an accepted destination.
var view: Control
var source: String
var uid: String
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed and event.shift_pressed:
		accept_event()
		view.call_deferred("move_item",uid,source,"inventory" if source=="warehouse" else "warehouse",int(view.game.campaign.revision))
func _get_drag_data(_at: Vector2) -> Variant:
	var payload: Dictionary={"kind":"dive-item","uid":uid,"source":source,"revision":int(view.game.campaign.revision)}
	var preview:=Label.new(); preview.text=view.game.cfg.items[view.game.campaign.items[uid]].name+" ×1"
	preview.add_theme_color_override("font_color",Color("f5d28a")); set_drag_preview(preview)
	view.drag_payload=payload
	return payload
func _can_drop_data(_at: Vector2, value: Variant) -> bool:
	return view.accepts(value,source,true)
func _drop_data(_at: Vector2, value: Variant) -> void:
	view.call_deferred("move_item",value.uid,value.source,source,int(value.revision))
