extends RefCounted
## Filter retains physical cell numbers; bounded pages never render unbounded empty space.
const Storage=preload("res://core/storage.gd")
const Grid=preload("res://ui/item_grid.gd")
const Skin=preload("res://ui/ui_skin.gd")
static func build(parent: Control, game: Control, host: Control, rect: Rect2, state: Dictionary, columns: int=5, rows: int=4) -> void:
	Storage.ensure_positions(game.campaign)
	var category:=OptionButton.new();category.position=rect.position;category.size=Vector2(rect.size.x*0.45,32);parent.add_child(category)
	var keys: Array=["all","weapon","armor","accessory","other"]
	for name in ["すべて","武器","防具（盾・マント含む）","装飾品","その他"]:category.add_item(name)
	category.select(maxi(0,keys.find(state.get("filter","all"))))
	category.item_selected.connect(func(i):state.filter=keys[i];host.call_deferred("refresh_storage"))
	var slots:=OptionButton.new();slots.position=rect.position+Vector2(rect.size.x*.47,0);slots.size=Vector2(rect.size.x*.53,32);parent.add_child(slots)
	slots.add_item("全ての部位");slots.set_item_metadata(0,"")
	for slot in game.cfg.slots:
		var probe: Dictionary={"slot":slot}
		if not Storage.matches(probe,state.get("filter","all")):continue
		slots.add_item(game.cfg.slots[slot]);slots.set_item_metadata(slots.item_count-1,slot)
		if slot==state.get("slot",""):slots.select(slots.item_count-1)
	slots.item_selected.connect(func(i):state.slot=slots.get_item_metadata(i);host.call_deferred("refresh_storage"))
	var count: int=columns*rows;var page: int=maxi(0,int(state.get("page",0)));var edge: float=minf((rect.size.x-(columns-1)*6)/columns,(rect.size.y-84-(rows-1)*6)/rows)
	for i in count:
		var actual: int=page*count+i;var uid: String=Storage.uid_at(game.campaign,actual)
		var hidden: bool=uid!="" and not Storage.matches(game.cfg.items[game.campaign.items[uid]],state.get("filter","all"),state.get("slot",""))
		var b:=Grid.cell(parent,game,host,Rect2(rect.position+Vector2((i%columns)*(edge+6),42+int(i/columns)*(edge+6)),Vector2.ONE*edge),"warehouse",uid if not hidden else "","",uid!="" and game.flow_selection.get("uid","")==uid)
		b.cell_index=actual;b.set_meta("storage_cell",actual)
		if hidden:b.disabled=true;b.tooltip_text="マス %d：絞り込み対象外の品（配置は維持）"%(actual+1);Skin.label(b,"対象外",Rect2(3,edge/2-10,edge-6,22),12,Skin.MUTED)
		var num:=Skin.label(b,str(actual+1),Rect2(3,2,28,15),10,Skin.MUTED);num.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var y: float=rect.end.y-32
	Skin.button(parent,"‹",Rect2(rect.position.x,y,44,30),func():state.page=maxi(0,page-1);host.call_deferred("refresh_storage")).disabled=page==0
	Skin.label(parent,"倉庫マス %d–%d"%[page*count+1,(page+1)*count],Rect2(rect.position.x+51,y,rect.size.x-102,30),14)
	Skin.button(parent,"›",Rect2(rect.end.x-44,y,44,30),func():state.page=page+1;host.call_deferred("refresh_storage"))
