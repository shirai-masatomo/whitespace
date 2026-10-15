extends RefCounted
static func primary(g):
	match g.selected.get("kind", ""):
		"tree":g.harvest_selected_trees()
		"rock", "mountain":
			var p=g.selected.pos if g.selected.has("pos") else g.world.mountains.get(g.selected.id,{}).get("pos",Vector2i(-1,-1))
			if not g.world.Tasks.designate(g.world,"mine",p):g.notice(g.world.Tasks.reason(g.world,"mine",p))
			g.refresh()
		"structure":
			var p=g.world.Buildings.anchor(g.world,g.selected.pos);var b=g.world.structures.get(p,{})
			if b.get("status")=="ready" and g.world.Craft.Data.BENCHES.has(b.kind):g.crafting_panel.show(g,p)
		_:
			if not g.selected_resources.is_empty():g.collect_selected()
static func cancel_or_remove(g):
	g.prune_selection()
	var cancel={};var remove={};var w=g.world
	if g.selected.get("kind")=="job":cancel[g.selected.id]=true
	elif g.selected.get("kind")=="building_set":
		for r in g.selected_buildings:
			if r.has("job_id"):cancel[r.job_id]=true
			else:remove[[r.layer,r.pos]]=r
	elif g.selected.get("kind") in ["structure","floor"]:
		for p in g.selected_structures:remove[[g.selection_layer,p]]={"layer":g.selection_layer,"pos":p}
	else:
		var points=g.selected_trees if g.selected.get("kind")=="tree" else g.selected_resources
		if g.selected.get("kind")=="rock":points=[g.selected.pos]
		if g.selected.get("kind")=="mountain":points=[w.mountains.get(g.selected.id,{}).get("pos",Vector2i(-1,-1))]
		for p in points:
			for j in w.Stock.cancel_targets(w,p,p):
				if j.kind in ["clear_tree","mine","collect","haul"]:cancel[j.id]=true
	var cancelled=0;var demolished=0
	for id in cancel:
		if w.Jobs.cancel(w,id):cancelled+=1
	for r in remove.values():
		if w.act("remove_floor" if r.layer=="floor" else "remove",r.pos):demolished+=1
	g.notice("取消%d件・解体予約%d件"%[cancelled,demolished]);g.refresh()
static func resources_forbidden(g)->bool:
	var flags=[]
	for p in g.selected_resources:
		if g.world.natural.has(p):flags.append(g.world.natural_forbidden.get(p,false))
		for row in g.world.items_at(p,true):flags.append(row.get("forbidden",false))
	return not flags.is_empty() and flags.all(func(v):return v)
static func forbid_resources(g,value:bool):
	var count=0;var w=g.world
	for p in g.selected_resources:
		if w.natural.has(p) and w.natural_forbidden.get(p,false)!=value:
			if value:w.natural_forbidden[p]=true
			else:w.natural_forbidden.erase(p)
			count+=1
			for j in w.jobs:
				if j.kind=="collect" and j.pos==p:
					if value:w.Work.block(w,j,"採集対象は禁止中です")
					else:j.retry_at=w.tick
		for r in w.items_at(p,true):
			if r.get("forbidden",false)==value:continue
			r.forbidden=value;r.erase("forbidden_reconciled");count+=1
	w.Stock.reconcile_forbidden(w);w.Stock.sync(w)
	g.notice(("禁止" if value else "許可")+"：%d件変更"%count);g.refresh()
static func context_status(g,title):
	if g.selected.get("kind") not in ["structure","floor"] or g.selected_structures.size()!=1:return
	var b=g.selected_store().get(g.selected_structures[0],{})
	if b.is_empty():return
	title.text=g.world.Buildings.NAMES.get(b.kind,b.kind)+"  HP %d / %d"%[b.hp,b.max_hp]
	if not g.world.Craft.Data.BENCHES.has(b.kind):return
	var jobs=g.world.jobs.filter(func(j):return j.kind=="craft" and j.bench_id==b.id)
	var text="製作待ち"
	if not jobs.is_empty():
		text=g.world.Craft.summary(g.world,jobs[0])
		if jobs.size()>1:text+="\n次："+g.world.Craft.Catalog.title(g.world.Craft.Data.RECIPES[jobs[1].recipe].output)
	var height=116
	for child in g.context_panel.get_children():
		if child is Button:child.position.y+=height
	g.context_panel.size.x=maxf(430,g.context_panel.size.x);g.context_panel.size.y+=height
	g.ColonyPanels.label(g.context_panel,text,Vector2(9,27),13)
	var detail=g.context_panel.get_child(g.context_panel.get_child_count()-1)
	detail.name="FacilityStatus";detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;detail.size=Vector2(g.context_panel.size.x-18,110)
	g.context_panel.set_meta("bench_id",b.id)
static func update_status(g):
	if not is_instance_valid(g.context_panel) or not g.context_panel.has_meta("bench_id"):return
	if g.context_panel.get_meta("status_tick",-1)==g.world.tick:return
	g.context_panel.set_meta("status_tick",g.world.tick)
	var jobs=g.world.jobs.filter(func(j):return j.kind=="craft" and j.bench_id==g.context_panel.get_meta("bench_id"))
	var text="製作待ち" if jobs.is_empty() else g.world.Craft.summary(g.world,jobs[0])
	if jobs.size()>1:text+="\n次："+g.world.Craft.Catalog.title(g.world.Craft.Data.RECIPES[jobs[1].recipe].output)
	g.context_panel.get_node("FacilityStatus").text=text
static func draw_marks(g,rows:Array):
	var w=g.world;var visible=(g.get_canvas_transform().affine_inverse()*g.get_viewport_rect()).grow(80)
	for row in rows:
		if row.forbidden>0 and visible.has_point(g.center(row.pos)):g.SelectionVisual.forbidden(g,g.center(row.pos)+row.offset,row.forbidden<row.amount)
	for p in w.natural:
		if w.natural_forbidden.get(p,false) and visible.has_point(g.center(p)):g.SelectionVisual.forbidden(g,g.center(p))
	for p in w.trees:
		if w.tree_work.get(p,{}).get("forbidden",false) and visible.has_point(g.center(p)):g.SelectionVisual.forbidden(g,g.StoryView.tree_foot(g,p)+Vector2(0,-28))
	for p in w.rocks:
		if w.rocks[p].get("forbidden",false) and visible.has_point(g.center(p)):g.SelectionVisual.forbidden(g,g.center(p))
	for r in w.mountains.values():
		if r.get("forbidden",false) and r.remaining>0 and visible.has_point(g.center(r.pos)):g.SelectionVisual.forbidden(g,g.center(r.pos))
	for a in w.animals:
		if a.placed and a.get("forbidden",false) and visible.has_point(g.center(a.pos)):g.SelectionVisual.forbidden(g,g.actor_pixel("a%d"%a.id,a.pos))
	for r in g.selected_buildings:
		if g.selected.get("kind")=="building_set":g.SelectionVisual.outline(g,g.SelectionVisual.building_rect(g,r.kind,r.pos))
