extends "res://tests/test_controls.gd"
func fixture():
 var c=Farm.new_campaign();c.day=2
 var w=Farm.new(c,31).begin_day();w.phase="defend";w.spawn_schedule.clear();return w
func carrier(w,pos,role="kidnapper"):
 w.spawn_enemy({"role":role,"entry":Vector2i(1,5),"lv":1});var e=w.enemies.back();e.pos=pos;e.arrival_complete=true;return e
func run():
 output=OS.get_environment("FARM_REVIEW_OUTPUT")
 if output=="" or not "--isolated-review" in OS.get_cmdline_user_args():quit(2);return
 root.size=Vector2i(1280,800)
 game=load("res://game/main.tscn").instantiate();game.automated=true;game.world=fixture();game.world.story.intro_seen=true
 root.add_child(game);await process_frame;await process_frame;game.set_process(false);game.audio.set_process(false)
 game.visual_time=2.2;game.reset_view();game.refresh();game.queue_redraw();await capture("01_idol_steam")
 var w=game.world;var glowing=w.Story.idol_glowing(w);w.Story.pray(w,"gold");game.queue_redraw();await capture("02_after_prayer")
 check(glowing and not w.Story.idol_glowing(w),"1 Idol steam active on night two and extinguished by prayer")
 var inside_ok=true;var outside_ok=true
 for entry in [Vector2i(1,5),Vector2i(23,5),Vector2i(12,1),Vector2i(12,15)]:
  w=fixture();var e=carrier(w,w.exit_for(entry));e.entry=entry;e.carry="keeper";w.keeper.carrier=e.id;w.keeper.pos=e.pos;w.keeper.hp=0
  for i in range(12):w.tick+=1;w.enemy_step(e)
  inside_ok=inside_ok and not e.done and w.Forest.contains(e.pos,w.W,w.H) and w.keeper.state!="abducted"
  for i in range(150):
   if e.done:break
   w.tick+=1;w.Combat.recover(e,w.DT,false);w.enemy_step(e)
  outside_ok=outside_ok and e.done and w.keeper.state=="abducted" and not w.Forest.contains(e.pos,w.W,w.H)
 check(inside_ok and outside_ok,"2 Keeper remains in forest, exits beyond forest on all four sides")
 w=fixture();var e=carrier(w,Vector2i(-2,5));e.carry="keeper";w.keeper.carrier=e.id;w.keeper.pos=e.pos;w.release_keeper(e)
 var rescued=w.keeper.carrier<0 and w.keeper.state!="abducted" and not w.find_path(w.keeper.pos,Vector2i(1,5)).is_empty()
 w=fixture();e=carrier(w,Vector2i(0,5),"animal_tamer");var a=w.animals[0];a.pos=Vector2i(1,5);a.abductor=e.id;e.led_animal=a.id
 for i in range(12):w.tick+=1;w.enemy_step(e)
 var animal_inside=not a.get("lost",false) and not e.done
 w.Progression.release_animal(w,e);var animal_rescued=a.get("abductor",-1)<0 and not w.animal_path(a,a.pos,Vector2i(1,5)).is_empty()
 a.abductor=e.id;e.led_animal=a.id
 for i in range(200):
  if e.done:break
  w.tick+=1;w.Combat.recover(e,w.DT,false);w.enemy_step(e)
 check(rescued and animal_inside and animal_rescued and a.get("lost",false) and not w.Forest.contains(a.pos,w.W,w.H),"3 Animal follows beyond forest; both rescue paths remain usable")
 var au=game.audio;au.set_context("day");au._process(0);au._process(2);var two=au.music_level;au._process(5)
 var full=is_equal_approx(au.music_level,db_to_linear(au.DAY_VOLUME_DB)) and two<au.music_level and au.music_fade_duration==7
 au.set_context("defend");au._process(2);var tail=au.music_level>0 and not au.night_ambient_started
 au._process(2);var silent=au.music_level<=0.0001 and not au.night_ambient_started
 au._process(0.35);var begin=au.night_ambient_started;au._process(1.5)
 check(full and tail and silent and begin and is_equal_approx(au.ambient.volume_db,au.ambient_target_db),"4 BGM fade in 7s, night tail 4s, gap 0.35s, ambience rise 1.5s")
 FileAccess.open(output+"/three-changes.json",FileAccess.WRITE).store_string(JSON.stringify(record,"  "))
 print("THREE_CHANGES: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)
