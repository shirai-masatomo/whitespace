extends RefCounted
# Read-only adapters. View categories never become scheduling priorities or job fields.
const CATEGORIES=["すべて","建築","採取","回収","動物","生活","実行順"]
const ARCHITECT={"すべて":[],"壁と扉":["wall","wood_wall","stone_wall","door","locked_door"],"床":["soil_tile","wood_tile","stone_tile"],"飼育":["kennel","coop"],"設置":["place_kokeshi","place_fossil"]}

static func job_category(w,j: Dictionary) -> String:
	if w.BUILD.has(j.kind) or j.kind in ["repair","repair_floor","remove","remove_floor","gate"]:return "建築"
	if j.kind in ["animal_order","milk","equip"]:return "動物"
	if j.kind=="collect":return "採取" if w.natural.has(j.pos) else "回収"
	if j.kind.begins_with("place_"):return "建築"
	return "生活"

static func jobs(w,category: String="すべて") -> Array:
	var rows=[]
	for i in range(w.jobs.size()):
		var j=w.jobs[i];var kind=job_category(w,j)
		if category not in ["すべて","実行順"] and category!=kind:continue
		rows.append({"id":j.id,"execution_index":i,"category":kind,"state":j.state})
	return rows

static func display_jobs(w,category: String="すべて") -> Array:
	if category!="すべて":return jobs(w,category)
	var rows=[]
	for kind in CATEGORIES:
		if kind not in ["すべて","実行順"]:rows.append_array(jobs(w,kind))
	return rows

static func people(w) -> Array:
	var rows=[{"key":"keeper","name":"牧場主","role":"牧場仕事","state":w.Jobs.status(w),"hp":w.keeper.hp,"max_hp":w.keeper.max_hp}]
	for a in w.animals:
		if a.get("category","")!="human":continue
		rows.append({"key":"a%d"%a.id,"animal_id":a.id,"name":w.animal_name(a),"role":"コーヒー支援" if a.species=="maid" else w.SPECIES[a.species].title,"state":a.state,"hp":a.hp,"max_hp":a.max_hp})
	return rows
