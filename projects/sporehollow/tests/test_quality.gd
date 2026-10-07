extends "res://tests/test_ranch_content.gd"
const ES=preload("res://game/enemy_skills.gd")
const Forest=preload("res://game/forest_pattern.gd")
func run():
 for id in ES.ROWS:
  var skill=ES.get_skill(id)
  check(["SkillID","Name","Type","UnlockLevel","Cooldown","Condition","Effect","IconID","Rarity","AIHints"].all(func(field):return skill.has(field)),"Shared enemy skill fields: "+id)
 var w=open_world();var dancer=enemy(w,"dancer",Vector2i(12,10));var friend=enemy(w,"destroyer",Vector2i(13,10))
 check(C.enemy_step(w,dancer) and dancer.get("dance_at",0)>w.tick,"Dance starts a bounded action with CT")
 w.tick+=5
 check(not C.enemy_step(w,dancer),"After dance hold, common AI runs even with allies present")
 dancer.pos=w.keeper.pos+Vector2i.RIGHT;dancer.can_see_keeper=true
 check(not C.enemy_step(w,dancer),"Adjacent opponent takes priority over another dance")
 var hp=w.keeper.hp;P.enemy_step(w,dancer);check(w.keeper.hp<hp,"Dancer actually uses fan melee")
 w=open_world();var salary=enemy(w,"salaryman",Vector2i(12,10));salary.debug_phone_chance=1.0
 P.enemy_hurt(w,salary,1)
 check(salary.phone_started and salary.action_id=="phone_take","100 percent fixture triggers phone on damage")
 for i in range(8):w.tick+=1;P.enemy_step(w,salary)
 check(salary.phone_success and not salary.phone_started and w.spawn_schedule.any(func(row):return row.wave==999),"Phone ends and schedules reinforcement")
 step(w,12)
 check(w.enemies.size()==2,"Daytime reinforcement arrives without encounter schedule")
 var reinforcement=w.enemies.back();var origin=reinforcement.path[0]
 check(not w.inside(origin) and w.distance(origin,reinforcement.entry)>10,"Reinforcement starts beyond outer forest")
 for i in range(150):
  w.step()
  if w.inside(reinforcement.pos):break
 check(w.inside(reinforcement.pos) and reinforcement.path.size()>10,"Reinforcement physically enters then runs normal AI")
 w=open_world()
 for i in range(6):
  salary=enemy(w,"salaryman",Vector2i(8+i,10));salary.debug_phone_chance=1.0;P.enemy_hurt(w,salary,1);w.tick+=8;P.enemy_step(w,salary)
 check(w.spawn_schedule.filter(func(row):return row.wave==999).size()==4,"Reinforcement chain cap stays four")
 w=open_world();var maid=enemy(w,"maid",Vector2i(10,10));friend=enemy(w,"salaryman",Vector2i(11,10));friend.hp=10;w.keeper.hp=10
 C.enemy_step(w,maid)
 check(friend.hp==13 and w.keeper.hp==10,"Enemy maid gives coffee only to her faction")
 check(not Farm.Shop.table().maid.Enabled and not Farm.Shop.generate(1,31,[],20).any(func(row):return row.product=="maid"),"Maid removed from normal shop")
 check(P.Encounters.plan(11,31,0).chosen.has("maid") and D.enemy("maid").recruitable,"Maid is recruitable ordinary enemy")
 var cow=add(w,"cow",Vector2i(10,11));maid.debug_recruit_chance=0.0;C.recruit_maid(w,maid);maid.debug_recruit_chance=1.0
 check(not C.recruit_maid(w,maid),"Same cow is not rolled repeatedly")
 var second=add(w,"cow",Vector2i(9,10));var pos=maid.pos
 check(C.recruit_maid(w,maid) and maid.done and w.animals.back().species=="maid" and w.animals.back().pos==pos,"Recruit transfers to roster at same place, without duplicate actor")
 friend.done=true
 var allied=w.animals.back();w.keeper.pos=pos+Vector2i.UP;C.animal_step(w,allied)
 check(w.keeper.hp==13,"Recruited maid reuses player-side coffee")
 w=open_world();maid=enemy(w,"maid",Vector2i(8,10));cow=add(w,"cow",Vector2i(8,11));maid.debug_recruit_chance=0;maid.ultimate_gauge=100;maid.can_see_keeper=true
 C.enemy_step(w,maid)
 check(maid.get("rage_until",0)>w.tick and cow.hp==cow.max_hp,"Enemy rage activates but never attacks cow")
 w=open_world();var attacker=enemy(w,"ninja",w.keeper.pos+Vector2i.RIGHT);attacker.attack_power=99
 w.Life.hurt(w,attacker)
 check(w.keeper.state=="unconscious" and w.Life.targetable(w,true) and not w.Life.targetable(w),"Knockout remains capturable but not a combat target")
 w.enemies.clear()
 for i in range(47):w.tick+=1;w.Life.step(w)
 check(w.keeper.state=="unconscious","Capture grace is not removed early")
 w.tick+=1;w.Life.step(w)
 check(w.keeper.state=="hidden_rest" and not w.Life.targetable(w,true),"Uncaptured keeper enters hidden recovery after grace")
 w.Life.hurt(w,attacker);check(w.keeper.hp==0,"Hidden recovery rejects damage")
 w.paused=true;var tick=w.tick;step(w,30);check(w.tick==tick and w.keeper.hp==0,"Pause freezes hidden recovery")
 w.paused=false
 for i in range(24):w.tick+=1;w.Life.step(w)
 check(w.keeper.hp==1 and w.keeper.state=="hidden_rest","Hidden recovery is one HP per six seconds")
 for i in range(168):w.tick+=1;w.Life.step(w)
 check(w.keeper.hp==8 and w.keeper.state=="free" and w.jobs_held,"Recovery restores low HP and explicit work resume")
 w=open_world();var dog=w.animals[0];dog.mode="attack_target";dog.attack_target_id=0;dog.pos=Vector2i(8,10)
 var distraction=enemy(w,"destroyer",Vector2i(9,10));attacker=enemy(w,"ninja",Vector2i(7,10));attacker.attack_power=1;w.Life.hurt(w,attacker);w.animal_step(dog)
 check(dog.rescuing and w.last_keeper_attacker_id==attacker.id,"Damage activates rescue over player target")
 dog.mode="rest";w.animal_step(dog);check(not dog.rescuing,"Explicit rest still suppresses rescue")
 for kind in ["destroyer","martial_artist","salaryman","ninja","animal_tamer","runner","dancer","thief","maid"]:
  w=open_world();w.keeper.state="hidden_rest";w.keeper.hp=0;dog=w.animals[0];dog.pos=Vector2i(11,10);dog.mode="rest";dog.hp=999;dog.max_hp=999
  var e=enemy(w,kind,Vector2i(13,10));e.ai_accuracy=100;e.debug_recruit_chance=0;e.can_see_keeper=false
  for i in range(100):w.tick+=1;w.RaiderAI.perceive(e,w);w.enemy_step(e)
  check(e.pos!=Vector2i(13,10) or dog.hp<999 or e.get("led_animal",-1)>=0,"AI audit: ordinary action continues without keeper: "+kind)
  check(e.get("chosen_target",{}).get("kind","")!="keeper","Hidden keeper is not selected: "+kind)
 w=open_world();w.debug_enabled=true;w.paused=true
 for kind in D.ENEMY_ROWS.keys()+["doberman"]:
  w.enemies.clear();check(w.debug_spawn_enemy(kind) and not w.inside(w.enemies.back().pos) and w.tick==0,"Paused external debug spawn: "+kind)
 for i in range(9):w.PlayerEvents.add(w,"event%d"%i)
 check(w.player_events.size()==6 and w.player_events.back().text=="event8","Player feed bounded, newest last")
 w.player_events.clear();w.PlayerEvents.damage(w,{},w.keeper,1,"poison");w.tick+=1;w.PlayerEvents.damage(w,{},w.keeper,1,"poison")
 check(w.player_events.size()==1 and w.player_events[0].text.contains("2ダメージ"),"Poison tick messages aggregate")
 var consistent=true;var spaced=true;var count=0
 for y in range(-25,26):
  for x in range(-25,26):
   var p=Vector2i(x,y);var present=Forest.tree(p,31,true);consistent=consistent and present==Forest.tree(p,31,true)
   if present:
    count+=1
    spaced=spaced and not Forest.tree(p+Vector2i.RIGHT,31,true) and not Forest.tree(p+Vector2i.DOWN,31,true)
 check(consistent and spaced and count>100,"Forest deterministic clusters have minimum cardinal spacing")
 w=open_world();w.spawn_schedule=[{"tick":10,"wave":999,"role":"salaryman","entry":w.entries[0],"lv":1}];w.tick=8;w.start_night();step(w,2)
 check(w.enemies.size()==1,"Day to night preserves pending phone arrival delay")
 w=open_world();w.debug_enabled=true;w.trees[w.entries[0]]="blocked"
 check(w.debug_spawn_enemy("maid") and w.enemies.back().entry!=w.entries[0],"Blocked debug entry uses another valid gate")
 for entry in w.entries:w.trees[entry]="blocked"
 check(not w.debug_spawn_enemy("maid") and not w.events.is_empty(),"All blocked gates report failure")
 FileAccess.open("res://artifacts/quality-tests.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":record,"reinforcement":{"origin":str(origin),"entry":str(reinforcement.entry),"path_cells":reinforcement.path.size(),"final":str(reinforcement.pos)},"tuning":ES.TUNING,"capture_grace":w.Life.CAPTURE_GRACE,"hidden_heal_seconds":w.Life.HIDDEN_HEAL_SECONDS,"hidden_recover_hp":w.Life.HIDDEN_RECOVER_HP},"  "))
 print("QUALITY: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)
