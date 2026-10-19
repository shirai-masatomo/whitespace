extends SceneTree
const Catalog = preload("res://core/catalog.gd")
const E = preload("res://core/expedition.gd")
const Sim = preload("res://tools/campaign_simulation.gd")

func stop(message: String) -> void:
	printerr(message); quit(2)

func write(path: String, value: String) -> bool:
	var f:=FileAccess.open(path,FileAccess.WRITE)
	if f==null: return false
	f.store_string(value); f.close(); return true

func _initialize() -> void:
	var o: Dictionary={"trials":"3","seed":"10000","out":"","config":"res://data/v1/expedition.json","policy":"res://data/scenarios/campaign.json","commit":"unrecorded","baseline":"","strict":"false","trace":"false"}
	for arg in OS.get_cmdline_user_args():
		var pair:=arg.trim_prefix("--").split("=",true,1)
		if pair.size()!=2 or not o.has(pair[0]): stop("Unknown argument: "+arg); return
		o[pair[0]]=pair[1]
	if o.out=="" or not o.seed.is_valid_int() or not o.trials.is_valid_int() or int(o.seed)<0 or int(o.seed)>2147383647 or int(o.trials)<1 or int(o.trials)>10000: stop("Invalid output/seed/trials"); return
	if not o.strict in ["true","false"] or not o.trace in ["true","false"] or (o.strict=="true" and o.baseline==""): stop("Invalid strict/trace flag"); return
	var data:=Catalog.load_data()
	var cfg=JSON.parse_string(FileAccess.get_file_as_string(o.config))
	if cfg is Dictionary: cfg.condition_rules=JSON.parse_string(FileAccess.get_file_as_string("res://data/v1/equipment-condition.json"))
	var policy=JSON.parse_string(FileAccess.get_file_as_string(o.policy))
	if not cfg is Dictionary or E.validate_config(cfg,data)!="": stop("Invalid config"); return
	if not policy is Dictionary or Sim.Policy.validate(policy)!="": stop("Invalid policy"); return
	if o.trace=="true" and int(o.trials)!=1: stop("Trace requires one seed"); return
	var report:=Sim.run(data,cfg,policy,range(int(o.seed),int(o.seed)+int(o.trials)))
	report.metadata={"engine":Engine.get_version_info().string,"runner_contract":"campaign-v1","game_commit":o.commit,"config_version":cfg.config_version,"data_version":data.data_version,"config_sha256":FileAccess.get_sha256(o.config),"data_sha256":FileAccess.get_sha256(Catalog.PATH),"policy_sha256":FileAccess.get_sha256(o.policy),"combat_sha256":FileAccess.get_sha256("res://core/combat.gd"),"expedition_sha256":FileAccess.get_sha256("res://core/expedition.gd"),"policy_code_sha256":FileAccess.get_sha256("res://tools/campaign_policy.gd")}
	report.metadata.enemy_pack_sha256=FileAccess.get_sha256(data.enemy_pack) if data.has("enemy_pack") else ""
	report.metadata.equipment_condition_sha256=FileAccess.get_sha256("res://core/equipment_condition.gd")
	report.metadata.condition_rules_sha256=FileAccess.get_sha256("res://data/v1/equipment-condition.json")
	var summary:=Sim.summary(report)
	if o.baseline!="":
		var baseline=JSON.parse_string(FileAccess.get_file_as_string(o.baseline))
		if not baseline is Dictionary: stop("Invalid baseline"); return
		report.comparison=Sim.compare(baseline,report,o.strict=="true")
		if report.comparison.has("error"): stop(report.comparison.error); return
		summary+="同条件差分: "+JSON.stringify(report.comparison.delta)+"\n"
	if o.trace=="true":
		if int(o.trials)!=1: stop("Trace requires one seed"); return
		report.replay=Sim.play(data,cfg,policy,int(o.seed),true)
	if not write(o.out,JSON.stringify(report,"\t")) or not write(o.out+".txt",summary): stop("Cannot write output"); return
	print(summary)
	if o.strict=="true" and not report.comparison.strict_equal: printerr("STRICT_CAMPAIGN_MISMATCH"); quit(1); return
	quit(0 if report.metrics.invalid_results==0 else 1)
