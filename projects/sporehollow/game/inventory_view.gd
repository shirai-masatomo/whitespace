extends RefCounted
## Read-only inspection uses the existing modal boundary, never creates a job.
static func open(g):
	g.story_modal="inventory"
	var panel=Panel.new();g.story_panel=panel
	panel.size=Vector2(1280,800);panel.mouse_filter=Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel",g.MarketView.panel(Color(0.13,0.20,0.16,0.94)))
	g.controls.get_parent().add_child(panel);panel.theme=g.controls.theme
	var title=Label.new();title.text="持ち物";title.position=Vector2(240,125);title.add_theme_font_size_override("font_size",30);panel.add_child(title)
	var scroll=ScrollContainer.new();scroll.position=Vector2(240,185);scroll.size=Vector2(800,430);panel.add_child(scroll)
	var list=VBoxContainer.new();list.custom_minimum_size.x=775;list.add_theme_constant_override("separation",12);scroll.add_child(list)
	var counts=g.world.campaign.items.duplicate()
	counts.merge(g.world.resource_snapshot(),true)
	var ids=counts.keys();ids.sort()
	for id in ids:
		if counts[id]<=0:continue
		var product=g.world.Shop.table().get(id,{"Name":id,"Rarity":0})
		var row=HBoxContainer.new();row.custom_minimum_size.y=62;row.add_theme_constant_override("separation",18);list.add_child(row)
		var pic=TextureRect.new();pic.texture=g.MarketView.texture_for(id);pic.custom_minimum_size=Vector2(54,54);pic.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;pic.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;row.add_child(pic)
		var body=Label.new();body.custom_minimum_size.x=560
		var name={"soil":"土","wood":"木材","stone":"石"}.get(id,product.Name)
		var purpose=g.MarketView.description(id)
		if id in ["soil","wood","stone"]:purpose="建設・改築に使う素材"
		body.text=name+" ×%d"%counts[id]+"\n"+purpose.replace("\n"," ")
		body.add_theme_font_size_override("font_size",17);body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		row.add_child(body)
		var tier=g.world.ProgressData.rarity(product.Rarity)
		var emblem=TextureRect.new();emblem.texture=g.Direction.ASSETS["ui.rarity_"+g.world.ProgressData.RARITY_NAMES[tier].to_lower()].texture;emblem.custom_minimum_size=Vector2(40,40);emblem.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;emblem.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;emblem.tooltip_text=g.world.ProgressData.RARITY_NAMES[tier];row.add_child(emblem)
		var equipment=g.world.ProgressData.ITEMS.get(id,{})
		row.tooltip_text=purpose+("\n装備対象："+str(equipment.get("equip_targets",[])) if not equipment.is_empty() else ("\n建設モードで設置" if id in ["kokeshi","fossil"] else ""))
	g.add_button(panel,"inventory_close","閉じる",Rect2(870,640,160,44),g.StoryView.close.bind(g))
