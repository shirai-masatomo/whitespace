extends SceneTree
const Sim = preload("res://tools/campaign_simulation.gd")
func _initialize() -> void:
	var o: Dictionary={"before":"","after":"","out":"","strict":"false"}
	for arg in OS.get_cmdline_user_args():
		var p:=arg.trim_prefix("--").split("=",true,1)
		if p.size()!=2 or not o.has(p[0]): quit(2); return
		o[p[0]]=p[1]
	var before=JSON.parse_string(FileAccess.get_file_as_string(o.before))
	var after=JSON.parse_string(FileAccess.get_file_as_string(o.after))
	if not before is Dictionary or not after is Dictionary or o.out=="" or not o.strict in ["true","false"]: quit(2); return
	var result:=Sim.compare(before,after,o.strict=="true")
	if result.has("error"): printerr(result.error); quit(2); return
	var f:=FileAccess.open(o.out,FileAccess.WRITE)
	if f==null: quit(2); return
	f.store_string(JSON.stringify(result,"\t")); f.close()
	print(JSON.stringify(result.delta))
	quit(1 if o.strict=="true" and not result.strict_equal else 0)
