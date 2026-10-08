extends "res://tests/test_ranch_content.gd"
const T=P.Targets
func hidden(w):
	w.keeper.hp=0;w.keeper.state="hidden_rest";w.keeper.carrier=-1
func run():
	var w=open_world();var e=enemy(w,"salaryman",Vector2i(11,8))
	check(T.weights(w,e)==e.target_weights,"Healthy keeper preserves ordinary role weights")
	for role in T.PRESSURE_ROLES:
		w=open_world();hidden(w);e=enemy(w,role,Vector2i(11,8))
		var dog=w.animals[0];dog.pos=Vector2i(10,8);dog.mode="rest"
		var hp=w.story.idol.hp;P.enemy_step(w,e)
		check(e.chosen_target.get("kind")=="idol" and w.story.idol.hp<hp,"Visible idol takes pressure while keeper is hidden: "+role)
		check(e.object_attack_power>0,"Pressure role can damage objects: "+role)
		e.debug_phone_chance=0.0 # Phone interruption has its own quality scenario.
		P.enemy_hurt(w,e,1,dog.id);e.next_attack=0;var dog_hp=dog.hp
		P.enemy_step(w,e)
		check(e.chosen_target.get("kind")=="animal" and dog.hp<dog_hp,"Adjacent attacking defender still draws retaliation: "+role)
		e.threat_until=0;e.next_attack=0;P.enemy_step(w,e)
		check(e.chosen_target.get("kind")=="idol","Returns to idol after nearby threat expires: "+role)
	# Unconscious can still be abducted. Hiding, rather than HP zero alone, ends that priority.
	w=open_world();w.keeper.hp=0;w.keeper.state="unconscious";w.keeper.pos=Vector2i(10,8)
	e=enemy(w,"kidnapper",Vector2i(11,8));w.RaiderAI.perceive(e,w)
	check(not P.enemy_step(w,e),"Capturable downed keeper stays on the kidnapper path")
	e.carry="keeper";w.keeper.carrier=e.id;w.keeper.state="captured"
	check(not P.enemy_step(w,e),"Carrier keeps extraction priority")
	e.carry="";hidden(w);P.enemy_step(w,e)
	check(e.chosen_target.get("kind")=="idol","Kidnapper changes to an observed idol after hiding")
	# Seeing the idol, not the keeper state, creates location memory.
	w=open_world();hidden(w);e=enemy(w,"salaryman",Vector2i(2,2));e.sight_range=2
	P.enemy_step(w,e)
	check(not e.has("last_known_idol_position") and e.chosen_target.get("kind","") not in ["idol","idol_memory"],"Down transition does not reveal a distant idol")
	e.pos=Vector2i(11,8);e.sight_range=5;T.observe(w,e)
	check(e.get("last_known_idol_position")==Vector2i(12,8),"Actual line of sight records the idol position")
	e.pos=Vector2i(4,8);P.enemy_step(w,e)
	check(e.chosen_target.get("kind")=="idol_memory" and e.chosen_target.pos==Vector2i(12,8),"Lost sight pursues only the remembered place")
	w.story.idol.position=[18,8];e.pos=Vector2i(11,8);P.enemy_step(w,e)
	check(not e.has("last_known_idol_position") and e.chosen_target.get("kind","") not in ["idol","idol_memory"],"Inspecting an empty remembered place does not reveal the moved idol")
	w=open_world();hidden(w);e=enemy(w,"ninja",Vector2i(10,8));w.trees[Vector2i(11,8)]="occluder"
	check(T.observe(w,e).is_empty(),"Occlusion prevents idol discovery")
	w=open_world();hidden(w);e=enemy(w,"salaryman",Vector2i(11,8));T.observe(w,e)
	w.story.idol.hp=0;P.enemy_step(w,e)
	check(not e.has("last_known_idol_position") and e.chosen_target.get("kind","") not in ["idol","idol_memory"],"Inspecting the destroyed idol clears stale pursuit")
	# Non-object roles keep their identity, including nonlethal martial artists.
	for role in ["martial_artist","animal_tamer","dancer","thief"]:
		w=open_world();hidden(w);e=enemy(w,role,Vector2i(11,8))
		check(T.weights(w,e).get("idol",0)==0 and P.target_candidates(w,e).all(func(t):return t.kind not in ["idol","structure"]),"No impossible object target: "+role)
	w=open_world();hidden(w);e=enemy(w,"martial_artist",Vector2i(11,8));var dog=w.animals[0];dog.pos=Vector2i(10,8);dog.hp=2
	P.strike(w,e,{"kind":"animal","id":dog.id,"pos":dog.pos})
	check(dog.hp==1,"Martial artist remains nonlethal")
	w=open_world();hidden(w);e=enemy(w,"animal_tamer",Vector2i(11,8));var hen=add(w,"hen",Vector2i(10,8))
	P.enemy_step(w,e)
	check(e.chosen_target.get("kind")=="animal" and hen.get("loyalty_loss",0)>0,"Tamer still targets livestock")
	w=open_world();hidden(w);e=enemy(w,"thief",Vector2i(11,8));e.stolen={"kind":"milk","pos":Vector2i(11,8)}
	C.enemy_step(w,e)
	check(e.state=="盗品を持って退却","Thief retains stolen-item escape")
	# Supports accompany visible allies; they are not assigned zero-damage idol attacks.
	w=open_world();hidden(w);e=enemy(w,"dancer",Vector2i(8,8));var ally=enemy(w,"destroyer",Vector2i(11,8));e.dance_at=9999
	check(C.enemy_step(w,e) and e.state=="仲間に続く","Dancer follows a visible advancing ally between dances")
	w=open_world();hidden(w);e=enemy(w,"maid",Vector2i(10,8));ally=enemy(w,"destroyer",Vector2i(11,8));ally.hp=10
	var idol_hp=w.story.idol.hp;C.enemy_step(w,e)
	check(ally.hp==13 and w.story.idol.hp==idol_hp,"Maid supports the advancing faction without normal attacks")
	w.keeper.state="free";w.keeper.hp=8
	check(T.weights(w,ally)==ally.target_weights,"Recovery restores ordinary role weights")
	FileAccess.open("user://target-policy-tests.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":records,"down_weights":T.DOWN_WEIGHTS,"scope":"role and perception contracts; no difficulty calibration"},"  "))
	print("TARGET_POLICY: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)
