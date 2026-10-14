extends RefCounted
# Read-only presentation of the production clock, work and shared stock.
static func rest_target(w) -> String:
	return "dawn" if w.Cycle.period(w)=="night" else "night"
static func threats(w) -> Array:
	return w.enemies.filter(func(e):return not e.done and not e.get("dead",false) and e.hp>0 and (not e.flee or e.get("carry","")!="" or not e.get("stolen",{}).is_empty()))
static func work_name(w,j: Dictionary) -> String:
	if j.get("purpose","")=="merchant":return "交渉"
	if w.BUILD.has(j.kind):return w.Buildings.NAMES.get(j.kind,"建設")
	return {"mine":"採掘","clear_tree":"伐採","train":"調教","direct_attack":"指定攻撃","keeper_equipment":"装備","slaughter":"と殺","milk":"搾乳","place_kokeshi":"こけし設置","place_fossil":"化石設置","move":"移動","collect":"採集","haul":"運搬","repair":"修理","remove":"解体","remove_floor":"床の解体","repair_floor":"床の修理","gate":"ドア開閉","equip":"動物の装備","animal_order":"動物への指示"}.get(j.kind,"作業")
static func work_state(j: Dictionary) -> String:
	if j.get("cancel_requested",false):return "取消待ち"
	if j.get("delivery_owner","")!="":return "材料搬入中"
	if j.get("block_reason","")==preload("res://game/construction_delivery.gd").GROUP_WAIT:return "グループ搬入待ち"
	if j.get("material_wait",false):return "材料待ち"
	if j.state=="blocked":
		var why=j.get("block_reason","")
		return "材料不足" if "資材" in why else "通路待ち" if "通路" in why or "通行" in why else "待機"
	if j.state=="suspended":return "中断中"
	if j.get("assigned_to","")!="":
		if j.get("phase","")=="fetch":return "受取へ"
		if j.get("phase","")=="deliver":return "運搬中"
		return "作業中" if j.state=="working" else "移動中"
	return "待機"
static func work_summary(w) -> String:
	if w.keeper.get("drafted",false):return "徴兵中：通常の仕事は保留"
	var j=w.Work.active(w)
	if not j.is_empty():return work_name(w,j)+" · "+work_state(j)
	if w.keeper.resting:return "休息中：通常の仕事は保留"
	if w.jobs.is_empty():return ""
	if w.jobs_held:return w.Jobs.status(w)
	for pending in w.jobs:
		if pending.get("block_reason","")!="":return work_name(w,pending)+"："+pending.block_reason
	var enabled=w.jobs.any(func(job):return w.workers.values().any(func(a):return int(a.get("work_priorities",{}).get(w.Work.category(w,job),0))>0))
	return "担当者が休息・食事・別の作業中です" if enabled else "役割でこの仕事の担当を設定してください"
static func category_hint(w,kind: String) -> String:
	var category=w.Work.category(w,{"kind":kind,"pos":Vector2i.ZERO})
	var label=w.Work.Policy.LABELS[category]
	var enabled=w.workers.values().any(func(a):return int(a.get("work_priorities",{}).get(category,0))>0)
	return label+"の仕事：役割の優先度で実行" if enabled else label+"の仕事：担当する人の「"+label+"」が停止中"
