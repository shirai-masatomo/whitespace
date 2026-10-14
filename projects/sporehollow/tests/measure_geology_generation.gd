extends SceneTree
const Farm=preload("res://game/world.gd")
const Metrics=preload("res://game/terrain_metrics.gd")
func _initialize():call_deferred("run")
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if DisplayServer.get_name()!="headless" or out=="":quit(2);return
	var rows=[]
	for seed in [31,97,2026]:
		for version in [5,6]:
			Metrics.enabled=true;Metrics.take();var started=Time.get_ticks_usec();var c=Farm.new_campaign()
			c.biome_map=Farm.Biome.generate(seed,100,68,version);var terrain_ms=(Time.get_ticks_usec()-started)/1000.0
			var w=Farm.new(c,seed).begin_day();var total_ms=(Time.get_ticks_usec()-started)/1000.0
			var detail=Metrics.take();Metrics.enabled=false
			rows.append({"seed":seed,"version":version,"terrain_ms":terrain_ms,"total_new_world_ms":total_ms,"stages":detail,"rock_cells":w.rocks.size(),"mountains":w.mountains.size(),"repairs":w.terrain.placement.repair_removed_cells.size()})
	FileAccess.open(out+"/generation-timing.json",FileAccess.WRITE).store_string(JSON.stringify({"method":"Headless low-priority sequential logic only, same seed and map size; no GPU or FPS measurement","rows":rows},"\t"));print("GENERATION_TIMING_COMPLETE");quit()
