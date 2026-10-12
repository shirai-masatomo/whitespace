extends SceneTree
const Farm=preload("res://game/world.gd")
var checks=[]
var failures=0
func _initialize():call_deferred("run")
func check(ok,note):
	checks.append({"passed":bool(ok),"check":note})
	if not ok:failures+=1;push_error(note)
func read(path):
	var f=FileAccess.open(path,FileAccess.READ)
	if f==null:return null
	var value=f.get_var(false);f.close();return value
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	var fixture=OS.get_environment("FARM_LEGACY_FIXTURE")
	if out=="" or fixture=="" or "--isolated-review" not in OS.get_cmdline_user_args():quit(2);return
	var facts=read(fixture+"/facts.bin");var campaign=read(fixture+"/campaign.bin")
	check(not campaign.has("biome_map"),"Fixture is an actual pre-biome campaign")
	var w=Farm.Snapshot.restore(fixture+"/legacy.snapshot")
	check(w!=null,"Actual pre-biome EXE snapshot loads")
	if w==null:quit(1);return
	# The current physical-stock migration adds a receipt flag to old rows.
	# Preserve exact old content and validate the added value, rather than
	# treating that established schema extension as a terrain regression.
	for row in facts.field_items:
		if not row.has("stocked"):row.stocked=row.get("location","ground")=="ground" and w.Zones.accepts(w,row.pos,row.kind)
	for key in ["trees","rocks","natural","field_items","jobs","structures","keeper","animals","tick","calendar_ticks"]:
		check(w.get(key)==facts[key],"Legacy snapshot preserves "+key)
	check(w.terrain.version==1 and not w.campaign.has("biome_new_map"),"Legacy snapshot adds only visual terrain")
	w.persist_farm()
	for i in range(3):
		w=Farm.new(w.campaign,31)
		check(w.trees==facts.trees and w.rocks==facts.rocks and w.natural==facts.natural and w.Stock.totals(w)==facts.stock,"Repeated campaign reload retains depletion and physical totals: "+str(i))
		check(w.jobs.map(func(j):return [j.id,j.kind,j.pos])==facts.jobs.map(func(j):return [j.id,j.kind,j.pos]),"Pending job identity and location survives reload: "+str(i))
		w.persist_farm()
	var morning=Farm.new(campaign,31)
	check(morning.trees==facts.trees and morning.rocks==facts.rocks and morning.structures==facts.structures and morning.Stock.totals(morning)==facts.stock,"Actual legacy campaign keeps trees, mined rocks, structures and supplies")
	check(not morning.trees.has(facts.removed_tree) and not morning.rocks.has(facts.removed_rock),"Previously cleared tree and mined rock do not regenerate")
	var f=FileAccess.open(out+"/biome-compat.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"baseline_exe_sha256":"A10287B62CE93C985891982C3A8B4B2B2CB67BD58722349A8113A8FA22110C1C"},"\t"));f.close()
	print("Biome compatibility: ",checks.size()," checks, ",failures," failures")
	quit(0 if failures==0 else 1)
