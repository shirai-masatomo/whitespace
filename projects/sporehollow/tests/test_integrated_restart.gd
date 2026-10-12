extends SceneTree
const Snapshot=preload("res://game/research_snapshot.gd")
func _initialize():call_deferred("run")
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="" or "--isolated-review" not in OS.get_cmdline_user_args():quit(2);return
	var w=Snapshot.restore(out+"/restart.snapshot");var expected=FileAccess.open(out+"/restart-expected.bin",FileAccess.READ).get_var(false)
	var had_cargo=not w.Stock.cargo(w,"keeper").is_empty() and w.build_deliveries.has("keeper")
	for i in range(400):
		w.step()
		if w.metrics.built>=2:break
	var actual={"tick":w.tick,"built":w.metrics.built,"totals":w.Stock.totals(w),"used":w.stock_used,"pos":w.keeper.pos}
	var passed=had_cargo and actual==expected
	FileAccess.open(out+"/integrated-restart.json",FileAccess.WRITE).store_string(JSON.stringify({"method":"Separate Godot process restores transport snapshot and finishes normal World.step","cargo_and_assignments_restored":had_cargo,"same_completion":actual==expected,"actual":actual,"expected":expected,"passed":passed},"\t"))
	if not passed:push_error("Separate-process delivery completion differs")
	print("IntegratedRestart: ",passed);quit(0 if passed else 1)
