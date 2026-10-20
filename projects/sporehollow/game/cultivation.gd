extends RefCounted
## Only crop timing/output. Existing Craft owns seed transport and worker claims.
static func seed(w,j) -> bool:
	if j.recipe!="grow_mushroom":return false
	var rec=w.Craft.Data.RECIPES[j.recipe]
	w.structures[j.pos].culture={"seeded_tick":w.tick,"ready_tick":w.tick+ceili(rec.grow_seconds/w.DT),"harvest_progress":0.0}
	j.craft_progress=0.0;j.started=false;j.phase="grow";j.state="pending";j.block_reason="生育中・48時間後に収穫"
	w.craft_revision+=1;w.Stock.sync(w);w.Work.release(w,j)
	w.PlayerEvents.add(w,"キノコ栽培床へ植菌しました","seed:%d"%j.id)
	return true
static func harvest(w,j,a) -> bool:
	if j.recipe!="grow_mushroom":return false
	var b=w.structures[j.pos];var crop=b.get("culture",{})
	if crop.is_empty():return false
	if w.tick<int(crop.ready_tick):w.Work.release(w,j);j.state="pending";j.phase="grow";return true
	if not w.Jobs.walk(w,j,w.Buildings.job_goals(w,j),a):return true
	j.phase="work";j.state="working";j.started=true;j.block_reason=""
	crop.harvest_progress+=w.DT*w.Jobs.factor(a)
	if crop.harvest_progress<w.Craft.Data.RECIPES[j.recipe].harvest_seconds:return true
	var rec=w.Craft.Data.RECIPES[j.recipe]
	var drop=w.Craft.output_cell(w,j,a,rec.count)
	if drop==null:j.state="blocked";j.block_reason="収穫物の置き場が満杯です。周囲の物資を回収してください";return true
	w.Stock.add(w,rec.output,rec.count,drop).stocked=false
	b.erase("culture");j.made+=rec.count;j.craft_progress=0.0;j.started=false;j.batch_active=false;j.phase="move";j.block_reason="";w.craft_revision+=1
	w.PlayerEvents.add(w,"キノコ3個を収穫しました。現地から回収できます","harvest:%d:%d"%[j.id,j.made])
	if j.bill_mode=="count" and j.made>=j.bill_amount:w.Craft.cancel(w,j);w.Jobs.complete(w,j,true)
	else:w.Work.release(w,j);j.state="pending"
	return true
static func summary(w,j) -> String:
	var crop=w.structures[j.pos].culture;var left=maxi(0,int(crop.ready_tick)-w.tick)*w.DT
	return "キノコ · 植菌1 → 収穫3 · 完成%d\n%s\n%s"%[j.made,"生育中：あと %.1f時間"%(left/18.0) if left>0 else ("収穫中" if j.get("assigned_to","")!="" and j.state=="working" else "収穫可能 · 担当者待ち"),"収穫進捗 %d%%"%mini(100,int(crop.harvest_progress/4.0*100)) if left<=0 else "種菌は消費済み。生育中は作業者不要"]
