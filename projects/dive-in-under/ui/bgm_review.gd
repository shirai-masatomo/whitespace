extends RefCounted
## Explicit isolated review only. Captures game-generated PCM, never microphone/device input.
const UI=preload("res://ui/integration_review.gd")
const Review=preload("res://ui/feedback_review.gd")
static func wait(game: Control, seconds: float) -> void:
	await game.get_tree().create_timer(seconds).timeout
static func snapshot(player: AudioStreamPlayer, label: String) -> Dictionary:
	return {"screen":label,"player_id":player.get_instance_id(),"playback_id":player.get_stream_playback().get_instance_id() if player.playing else 0,"position":player.get_playback_position(),"playing":player.playing,"gain_linear":player.volume_linear}
static func samples_info(frames: PackedVector2Array) -> Dictionary:
	var peak:=0.0; var power:=0.0; var delta:=0.0; var silence:=0; var longest:=0
	var last:=Vector2.ZERO
	for sample in frames:
		peak=maxf(peak,maxf(absf(sample.x),absf(sample.y)))
		power+=sample.length_squared()*0.5
		delta=maxf(delta,maxf(absf(sample.x-last.x),absf(sample.y-last.y)))
		silence=silence+1 if maxf(absf(sample.x),absf(sample.y))<0.00001 else 0
		longest=maxi(longest,silence); last=sample
	return {"frames":frames.size(),"peak":peak,"rms":sqrt(power/maxi(1,frames.size())),"max_sample_delta":delta,"longest_near_silence_seconds":float(longest)/AudioServer.get_mix_rate()}
static func save_wav(game: Control, frames: PackedVector2Array, filename: String) -> void:
	var bytes:=PackedByteArray(); bytes.resize(frames.size()*4)
	for i in frames.size():
		bytes.encode_s16(i*4,int(clampf(frames[i].x,-1.0,1.0)*32767.0))
		bytes.encode_s16(i*4+2,int(clampf(frames[i].y,-1.0,1.0)*32767.0))
	var wav:=AudioStreamWAV.new(); wav.format=AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate=int(AudioServer.get_mix_rate()); wav.stereo=true; wav.data=bytes
	game.smoke_check(wav.save_to_wav(game.smoke_dir.path_join(filename))==OK,"Captured BGM WAV saved")
static func run(game: Control) -> void:
	if not UI.check(game,DisplayServer.get_name()!="headless" and not game.legacy_persistence_mode and game.save_store==null and game.campaign.is_empty(),"Fresh isolated rendered normal-mode game"): return
	var music: Node=game.preparation_music
	var player: AudioStreamPlayer=music.player
	var master: int=AudioServer.get_bus_index(&"Master")
	var master_db: float=AudioServer.get_bus_volume_db(master)
	var bus: int=AudioServer.get_bus_index(&"BGM")
	var capture:=AudioEffectCapture.new(); capture.buffer_length=5.0
	if not UI.check(game,not player.playing,"Title remains silent"): return
	await UI.click(game,"start"); game.auto_play=false
	await wait(game,0.5)
	if not UI.check(game,game.campaign.phase=="town" and player.playing and is_equal_approx(player.volume_linear,1.0),"Preparation starts BGM with fade-in"): return
	var stream: AudioStreamOggVorbis=player.stream
	if not UI.check(game,stream.loop and stream.loop_offset==0.0 and stream.get_length()>75.0 and stream.get_length()<77.0,"Export contains native looping OGG"): return
	var identity: int=player.get_stream_playback().get_instance_id()
	var screens: Array=[snapshot(player,"preparation")]
	var state: String=game.CampaignReplay.hash_state(game.campaign)
	await UI.click(game,"status")
	for tab in ["abilities","conditions","profile","equipment"]:
		await game.click_control(game.status_view.tab_buttons[tab]); await wait(game,0.12)
		screens.append(snapshot(player,"status-"+tab))
	await game.click_control(game.status_view.back_button); await wait(game,0.3)
	await UI.click(game,"warehouse"); screens.append(snapshot(player,"warehouse"))
	await game.click_control(game.find_button(game.warehouse_view,"戻る")); await wait(game,0.2)
	await UI.click(game,"equipment"); await UI.click(game,"slot-head")
	screens.append(snapshot(player,"equipment")); await UI.click(game,"back")
	var last_position: float=-1.0
	for screen in screens:
		if not UI.check(game,screen.playing and screen.playback_id==identity and screen.player_id==player.get_instance_id() and screen.position>=last_position,"Same uninterrupted playback: "+screen.screen): return
		last_position=screen.position
	if not UI.check(game,game.CampaignReplay.hash_state(game.campaign)==state and Review.descendants(game).filter(func(n):return n is AudioStreamPlayer).size()==1,"Screen changes preserve data and one player"): return
	if not UI.check(game,AudioServer.get_bus_volume_db(bus)==-16.0 and AudioServer.get_bus_volume_db(master)==master_db and player.bus==&"BGM","Quiet dedicated BGM bus leaves Master/SFX unchanged"): return
	await UI.shot(game,"preparation-bgm")
	# Accelerate only the explicit review by seeking near the end, not waiting/restarting 76 s.
	AudioServer.add_bus_effect(master,capture)
	player.seek(stream.get_length()-1.5)
	await wait(game,0.2)
	capture.clear_buffer()
	var near_end: float=player.get_playback_position()
	await wait(game,2.8)
	var after_wrap: float=player.get_playback_position()
	var pcm: PackedVector2Array=capture.get_buffer(capture.get_frames_available())
	var info:=samples_info(pcm)
	save_wav(game,pcm,"native-loop-boundary.wav")
	if not UI.check(game,near_end>70.0 and after_wrap>0.1 and after_wrap<3.0 and player.playing and player.get_stream_playback().get_instance_id()==identity,"Native OGG wraps without restarting player"): return
	if not UI.check(game,info.frames>int(AudioServer.get_mix_rate()*2.5) and info.rms>0.001 and info.peak<1.0 and capture.get_discarded_frames()==0,"Exported game mixes audible unclipped PCM across loop"): return
	# A conservative technical check; perceived musical naturalness remains a listening judgment.
	if not UI.check(game,info.longest_near_silence_seconds<0.2 and info.max_sample_delta<0.12,"No measured long dropout or abrupt full-scale click in captured loop"): return
	# Exercise the actual departure Button, result/return path and cancellation of an in-flight fade.
	capture.clear_buffer()
	await game.click_control(game.play_buttons.depart)
	var immediate: float=player.volume_linear
	await wait(game,0.28); var middle: float=player.volume_linear
	await wait(game,0.5); var stopped: bool=not player.playing
	var fade_pcm: PackedVector2Array=capture.get_buffer(capture.get_frames_available())
	save_wav(game,fade_pcm,"departure-fade.wav")
	if not UI.check(game,game.campaign.floor==1 and immediate>middle and middle>0.0 and stopped,"Departure fades to silence then stops"): return
	# Fixture only to reach result without fighting: production core remains unchanged.
	game.campaign.phase="explore"; game.campaign.battle={}; game.campaign.event=""; game.show_campaign()
	game.perform("return",{},int(game.campaign.revision))
	if not UI.check(game,game.campaign.phase=="result" and not player.playing,"Result remains silent"): return
	game.perform("town",{},int(game.campaign.revision)); await wait(game,0.45)
	if not UI.check(game,player.playing and music.active,"Return to preparation restarts the theme"): return
	var returning_id: int=player.get_stream_playback().get_instance_id()
	game.show_title(); await wait(game,0.1); game.show_campaign(); await wait(game,0.8)
	if not UI.check(game,player.playing and player.volume_linear==1.0 and player.get_stream_playback().get_instance_id()==returning_id,"Fast return cancels stale stop without duplicate/restart"): return
	game.show_title(); await wait(game,0.8)
	if not UI.check(game,not player.playing,"Leaving preparation for title also fades to silence"): return
	UI.write(game,{"complete":true,"rendered":true,"no_save_store":game.save_store==null,"run_id":game.smoke_run_id,"native_loop":stream.loop,"loop_offset":stream.loop_offset,"length_seconds":stream.get_length(),"loop_wrap":true,"near_end":near_end,"after_wrap":after_wrap,"pcm_audible":true,"pcm":info,"capture_discarded_frames":capture.get_discarded_frames(),"mix_rate":AudioServer.get_mix_rate(),"audio_driver":AudioServer.get_driver_name(),"continuity":true,"screens":screens,"quiet_bus":true,"bgm_gain_db":AudioServer.get_bus_volume_db(bus),"fade_out":true,"fade_seconds":music.FADE_OUT,"fade_immediate":immediate,"fade_middle":middle,"rapid_return":true,"title_silent":true,"listening_status":"technical PCM check only; user listening and actual device balance pending"},"bgm-review.json")
	game.get_tree().quit()
