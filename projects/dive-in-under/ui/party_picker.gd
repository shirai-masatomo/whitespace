extends RefCounted
const Party=preload("res://core/party_ui.gd")
const UISkin=preload("res://ui/ui_skin.gd")
const Art=preload("res://ui/visual_assets.gd")
static func build(parent: Control, game: Control, rect: Rect2) -> void:
	var ids: Array=Party.ids(game.campaign);var width: float=minf(210,(rect.size.x-8*(ids.size()-1))/ids.size())
	for i in ids.size():
		var id: String=ids[i]
		var b:=UISkin.button(parent,"",Rect2(rect.position+Vector2(i*(width+8),0),Vector2(width,rect.size.y)),func():game.call_deferred("select_party_actor",id))
		UISkin.quiet_button(b,game.selected_actor==id);b.set_meta("party_actor",id)
		UISkin.picture(b,Art.actor_texture("hero"),Rect2(4,3,38,rect.size.y-6))
		UISkin.label(b,Party.name_of(game.campaign,id),Rect2(46,2,width-50,23),16)
		UISkin.label(b,"検証用" if game.campaign.get("companions",{}).get(id,{}).get("verification_dummy",false) else "選択中" if game.selected_actor==id else "確認する",Rect2(46,24,width-50,20),12,UISkin.MUTED)
