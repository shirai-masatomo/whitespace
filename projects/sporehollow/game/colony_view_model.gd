extends RefCounted
# Read-only adapters. View categories never become scheduling priorities or job fields.
const CATEGORIES=["すべて","建築","採集","回収","動物","その他","運搬"]
const ARCHITECT={"壁と扉":["wall","wood_wall","stone_wall","door","locked_door"],"床":["soil_tile","wood_tile","stone_tile"],"設置":["kennel","coop","place_wood_crate","place_wood_shelf","cooking_bench","carpentry_bench","sewing_bench","place_kokeshi","place_fossil"],"ゾーン":[]}

static func job_category(w,j: Dictionary) -> String:
	return w.Work.Policy.LABELS[w.Work.category(w,j)]

static func jobs(w,category: String="すべて") -> Array:
	var rows=[]
	for i in range(w.jobs.size()):
		var j=w.jobs[i];var kind=job_category(w,j)
		if category not in ["すべて"] and category!=kind:continue
		rows.append({"id":j.id,"execution_index":i,"category":kind,"state":j.state})
	return rows

static func display_jobs(w,category: String="すべて") -> Array:
	if category!="すべて":return jobs(w,category)
	var rows=[]
	for kind in CATEGORIES:
		if kind not in ["すべて"]:rows.append_array(jobs(w,kind))
	return rows

static func people(w) -> Array:
	var rows=[{"key":"keeper","name":"牧場主","role":"自律作業","state":(w.keeper.get("rest_reason","休息中") if w.keeper.resting else w.Jobs.status(w))+" · 満腹%d / 栄養失調%d%%"%[w.keeper.get("satiety",100),w.keeper.get("malnutrition",0)],"hp":w.keeper.hp,"max_hp":w.keeper.max_hp}]
	for key in w.workers:
		if key=="keeper":continue
		var worker=w.workers[key]
		rows.append({"key":key,"name":worker.get("name",key),"role":"自律作業","state":worker.get("work_status","待機"),"hp":worker.hp,"max_hp":worker.max_hp})
	for a in w.animals:
		if a.get("category","")!="human" or w.workers.has("a%d"%a.id):continue
		rows.append({"key":"a%d"%a.id,"animal_id":a.id,"name":w.animal_name(a),"role":"コーヒー支援" if a.species=="maid" else w.SPECIES[a.species].title,"state":a.state,"hp":a.hp,"max_hp":a.max_hp})
	return rows
