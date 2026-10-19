extends Node
## One session-owned player; screen rebuilds never own or restart the music.
const TRACK=preload("res://assets/bgm/adventure_preparation_loop.ogg")
const BUS: StringName=&"BGM"
const DEFAULT_GAIN_DB: float=-16.0
const FADE_IN: float=0.35
const FADE_OUT: float=0.7
var player: AudioStreamPlayer
var active:=false
var fade: Tween

func _ready() -> void:
	if AudioServer.get_bus_index(BUS)<0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count-1,BUS)
		AudioServer.set_bus_send(AudioServer.get_bus_index(BUS),&"Master")
	set_gain_db(DEFAULT_GAIN_DB)
	player=AudioStreamPlayer.new()
	player.name="PreparationBGM"
	var track: AudioStreamOggVorbis=TRACK.duplicate()
	track.loop=true
	track.loop_offset=0.0
	player.stream=track
	player.bus=BUS
	player.volume_linear=0.0
	add_child(player)

func set_gain_db(value: float) -> void:
	# Only this bus changes: UI sounds and effects retain their own level.
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS),clampf(value,-60.0,0.0))

func set_preparation_active(value: bool) -> void:
	if active==value: return
	active=value
	if fade!=null and fade.is_valid(): fade.kill()
	if active and not player.playing:
		player.volume_linear=0.0
		player.play()
	if not player.playing: return
	fade=create_tween()
	# Linear amplitude reaches true silence before stop, without a cut or timer restart.
	fade.tween_property(player,"volume_linear",1.0 if active else 0.0,FADE_IN if active else FADE_OUT)
	if not active: fade.tween_callback(func(): if not active: player.stop())
