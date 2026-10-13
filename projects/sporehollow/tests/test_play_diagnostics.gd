extends SceneTree
const Probe=preload("res://game/play_diagnostics.gd")
const Metrics=preload("res://game/terrain_metrics.gd")
func _initialize():call_deferred("run")
func run():
	assert(not Probe.requested and Probe.experiment=="baseline" and not Metrics.enabled)
	var values=[]
	for x in range(1,101):values.append({"frame_ms":float(x)})
	var s=Probe.summary(values)
	assert(s.frames==100 and s.mean_ms==50.5 and s.p95_ms==95 and s.p99_ms==99 and s.max_ms==100)
	assert(s.over_33_50_100==[67,50,0])
	assert(Probe.summary([]).frames==0)
	var probe=Probe.new();root.add_child(probe)
	probe.output=OS.get_environment("FARM_REVIEW_OUTPUT")+"/diagnostic-test"
	probe.begin();assert(probe.active and Metrics.enabled)
	await process_frame
	probe.stop();assert(not probe.active and not Metrics.enabled and probe.saved)
	var data=JSON.parse_string(FileAccess.get_file_as_string(probe.result_path))
	assert(data.case=="baseline" and data.has("frames") and data.has("unavailable"))
	for i in range(6):probe.begin();await process_frame;probe.stop();await create_timer(0.01).timeout
	assert(DirAccess.get_files_at(probe.output).size()<=5)
	probe.queue_free();print("Play diagnostics: default off, percentiles, thresholds, start/stop, output, retention passed");quit()
