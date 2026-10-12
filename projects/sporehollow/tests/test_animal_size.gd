extends SceneTree
const Current=preload("res://game/main.gd")
var checks=0
var failures=0
func check(ok: bool, message: String):
	checks+=1
	if not ok:failures+=1;push_error(message)
func _initialize():call_deferred("run")
func run():
	var old=load(OS.get_environment("ANIMAL_SIZE_PROBE_ROOT")+"/baseline_main.gd").new()
	var now=Current.new()
	old.automated=true;now.automated=true
	old.world=old.Farm.new({},31).begin_day();now.world=old.world
	old.visual_time=2.25;now.visual_time=2.25
	check(now.ACTOR_SCALE==old.ACTOR_SCALE,"Existing hit box/keeper scale unchanged")
	check(is_equal_approx(now.ANIMAL_DRAW_SCALE/old.ACTOR_SCALE,1.25),"Animal map art increases exactly 25 percent")
	var foot=Vector2(123.5,287.25)
	var old_transform=Transform2D(0,Vector2.ONE*old.ACTOR_SCALE,0,foot*(1-old.ACTOR_SCALE))
	var new_transform=Transform2D(0,Vector2.ONE*now.ANIMAL_DRAW_SCALE,0,foot*(1-now.ANIMAL_DRAW_SCALE))
	check((old_transform*foot).is_equal_approx(new_transform*foot),"Foot anchor fixed under map animal transform")
	var frames=0
	for clips in [now.Art.CLIPS,now.Delivered.CLIPS,now.SixMotion.Data.CLIPS]:
		for key in clips:
			var species=key.get_slice("/",0)
			if not now.Farm.SPECIES.has(species) or now.Farm.SPECIES[species].category=="human":continue
			var clip=clips[key]
			for f in clip.frames:
				var anchor=f.anchor if f is Dictionary and f.has("anchor") else clip.anchor
				var old_corner=old_transform*(foot-anchor)
				var new_corner=new_transform*(foot-anchor)
				check((new_corner-foot).is_equal_approx((old_corner-foot)*1.25),"Fixed foot for "+key)
				frames+=1
	var w=now.world
	for species in w.SPECIES:
		var actor={"id":w.campaign.next_animal_id,"species":species,"lv":1,"loyalty":85,"name":"","unavailable_through_day":0}
		w.campaign.next_animal_id+=1;w.add_resident(actor)
		var a=w.animals.back();a.pos=Vector2i(12,13)
		for facing in [-1,1]:
			a.facing=facing
			for action in ["idle","walk","rest"]:
				var id="a%d"%a.id
				old.actor_art[id]={"action":action,"at":2.0,"facing":facing};now.actor_art[id]=old.actor_art[id].duplicate()
				if species in now.SixMotion.ACTORS:
					old.six_art[id]={"action":"idle","at":2.0,"facing":facing};now.six_art[id]=old.six_art[id].duplicate()
				check(old.animal_hit_rect(a)==now.animal_hit_rect(a),"Hit box unchanged: "+species+"/"+action+"/"+str(facing))
	for species in ["doberman","kidnapper"]:
		w.spawn_enemy({"role":species,"entry":w.entries[0],"debug_single":true})
		var e=w.enemies.back()
		for facing in [-1,1]:
			e.facing=facing;old.enemy_art[e.id]={"action":"idle","at":2.0,"facing":facing};now.enemy_art[e.id]=old.enemy_art[e.id].duplicate()
			check(old.enemy_hit_rect(e)==now.enemy_hit_rect(e),"Enemy hit box unchanged: "+species)
	print("ANIMAL_SIZE: %d checks, failures=%d; %d delivered animal frames, both directions; baseline runtime hit-box comparison"%[checks,failures,frames])
	old.free();now.free()
	quit(1 if failures else 0)
