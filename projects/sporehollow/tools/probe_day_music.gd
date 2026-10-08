extends SceneTree
func _initialize():call_deferred("run")
func run():
	var stream=AudioStreamMP3.new()
	stream.data=FileAccess.get_file_as_bytes("res://assets/audio/Porch_Swing_Serenade.mp3")
	var playback=stream.instantiate_playback()
	var rate=AudioServer.get_mix_rate();var total=ceili(stream.get_length()*rate)
	var sum=0.0;var peak=0.0;var first_sum=0.0;var last_sum=0.0;var count=0;var first_count=0;var last_count=0
	playback.start()
	while count<total:
		var samples=playback.mix_audio(1.0,mini(4096,total-count))
		if samples.is_empty():break
		for sample in samples:
			var power=(sample.x*sample.x+sample.y*sample.y)*0.5
			sum+=power;peak=maxf(peak,maxf(absf(sample.x),absf(sample.y)))
			if count<rate*0.25:first_sum+=power;first_count+=1
			if count>=total-rate*0.25:last_sum+=power;last_count+=1
			count+=1
	var info={"length_seconds":stream.get_length(),"decoded_frames":count,"mix_rate":rate,"peak":peak,"rms":sqrt(sum/maxi(1,count)),"first_250ms_rms":sqrt(first_sum/maxi(1,first_count)),"last_250ms_rms":sqrt(last_sum/maxi(1,last_count))}
	FileAccess.open("res://artifacts/audio-probe/analysis.json",FileAccess.WRITE).store_string(JSON.stringify(info,"  "))
	print(JSON.stringify(info))
	quit()
