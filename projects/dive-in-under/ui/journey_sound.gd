extends RefCounted
static func play(parent: Node, frequency: int) -> void:
	var samples:=PackedByteArray(); samples.resize(2205*2)
	for i in 2205:
		var value: int=int(sin(TAU*frequency*i/22050.0)*sin(PI*i/2205.0)*5000)
		samples.encode_s16(i*2,value)
	var wav:=AudioStreamWAV.new(); wav.format=AudioStreamWAV.FORMAT_16_BITS; wav.mix_rate=22050; wav.data=samples
	var player:=AudioStreamPlayer.new(); player.stream=wav; player.volume_db=-14; parent.add_child(player)
	player.finished.connect(player.queue_free); player.play()
