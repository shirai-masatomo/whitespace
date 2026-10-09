extends SceneTree
const Audio=preload("res://game/farm_audio.gd")
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok: bool,why: String):
	checks+=1
	if not ok:failures+=1;push_error(why)
func run():
	check(DisplayServer.get_name()=="headless","Music checks do not open a window")
	var audio=Audio.new();root.add_child(audio);audio.set_process(false)
	check(audio.music.stream is AudioStreamMP3 and absf(audio.music.stream.get_length()-177.5543)<0.1,"Original MP3 decodes with the expected 177.55-second duration")
	check(audio.music.stream.loop and audio.music.stream.loop_offset==0 and audio.music.max_polyphony==1,"One looping music voice")
	var master_db=AudioServer.get_bus_volume_db(0);var master_mute=AudioServer.is_bus_mute(0)
	audio.set_context("shop");await create_timer(0.1).timeout
	check(audio.music_enabled and audio.music.playing,"Morning starts daytime music")
	check(audio.music_level==0 and audio.music.volume_db==-80,"Starting music begins at silence")
	audio._process(0.25);var quarter=audio.music_level
	check(quarter>0 and quarter<db_to_linear(-16.0)*0.25,"Smooth two-second fade starts gently")
	audio._process(0.25);check(audio.music_level>quarter and audio.music_level<db_to_linear(-16.0),"Intermediate gain rises without jumping to its target")
	var player=audio.music;var prior=player.get_playback_position()
	for i in range(10):audio.set_context("day");audio._process(0.1)
	await create_timer(0.1).timeout
	check(audio.music==player and player.get_playback_position()>prior and audio.get_children().filter(func(n):return n.name=="DayMusic").size()==1,"Repeated frames and shop-to-day transition neither restart nor duplicate music")
	check(audio.music_level<=db_to_linear(-16.0)+0.001,"Conservative music gain leaves headroom for effects")
	audio.set_context("day",true);audio._process(1)
	check(is_equal_approx(audio.music_level,db_to_linear(-23.0)) and player.playing,"Menu/book/pause soften music without resetting playback")
	for phase in ["day","defend","dawn","result","shop"]:
		var gain=audio.music_level;audio.set_context(phase);audio._process(0)
		check(is_equal_approx(audio.music_level,gain),"Rapid context retarget starts at current gain: "+phase)
		audio._process(0.1)
	audio.set_context("day");audio._process(1)
	var before_out=audio.music_level;audio.set_context("defend");audio._process(0.4)
	check(player.playing and audio.music_level>0 and audio.music_level<before_out,"Night fades halfway before stopping")
	audio.set_context("defend");audio._process(2)
	check(audio.night and not audio.music_enabled and not player.playing and audio.music_resume>0,"Night fades the music out and remembers its position")
	var resume=audio.music_resume;audio.set_context("dawn");await create_timer(0.05).timeout
	check(player.playing and player.get_playback_position()>=resume-0.03 and not audio.night,"Dawn resumes the same track")
	audio.set_context("result");audio._process(2)
	check(not player.playing,"Defeat does not leave daytime music underneath the result")
	check(AudioServer.get_bus_volume_db(0)==master_db and AudioServer.is_bus_mute(0)==master_mute,"Context fades preserve master gain and mute settings")
	var playback=audio.music.stream.instantiate_playback();playback.start(audio.music.stream.get_length()-0.03)
	var samples=playback.mix_audio(1.0,8820)
	check(not samples.is_empty() and playback.get_loop_count()>0,"Decoder crosses the actual end and loops to the beginning")
	check(Audio.seam_gain(0,177)==0 and Audio.seam_gain(177,177)==0 and Audio.seam_gain(1,177)==1,"Loop envelope has quiet seam endpoints and preserves the body")
	audio.queue_free();await process_frame
	print("DAY_MUSIC: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)
