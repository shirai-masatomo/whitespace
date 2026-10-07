extends "res://tests/test_controls.gd"
func click(id: String):
 check(game.buttons.has(id),"UI exists: "+id)
 if game.buttons.has(id):await mouse(game.buttons[id].get_global_rect().get_center())
func run():
 output=OS.get_environment("FARM_REVIEW_OUTPUT")
 if DisplayServer.get_name()!="headless" and (output=="" or not "--isolated-review" in OS.get_cmdline_user_args()):quit(2);return
 root.size=Vector2i(1280,800)
 game=load("res://game/main.tscn").instantiate();game.automated=true;game.world=Farm.new({},31).begin_day();root.add_child(game);game.set_process(false);await process_frame
 var w=game.world;game.story_modal="";w.paused=true;w.day_seconds=9999
 game.reset_view();game.refresh();game._process(0)
 game.choose_walk();var mode=game.group
 for pair in [[KEY_1,0.5],[KEY_2,1.0],[KEY_3,2.0],[KEY_KP_1,0.5],[KEY_KP_2,1.0],[KEY_KP_3,2.0]]:
  await key(pair[0]);check(game.speed==pair[1] and game.group==mode,"Digit sets speed only: "+str(pair[0]))
 await key(KEY_4);check(game.speed==2.0,"Unavailable 4x leaves speed unchanged")
 w.Life.set_rest(w,true);await key(KEY_KP_4);check(game.speed==4.0,"Rest permits keypad 4x")
 w.danger_serial+=1;game.sync_danger();check(game.speed==1.0,"Danger overrides high speed")
 w.Life.set_rest(w,false);game.refresh()
 w.add_item("whistle",1);w.add_item("collar",1);w.add_item("berry",2)
 var jobs=w.jobs.size();var tick=w.tick
 await click("inventory");game._process(0)
 check(game.story_modal=="inventory" and w.jobs.size()==jobs and w.tick==tick,"Inventory is paused read-only and not a job")
 await key(KEY_3);check(game.speed==1.0,"Inventory blocks world shortcuts")
 await capture("05_inventory")
 await key(KEY_ESCAPE);game._process(0);check(game.story_modal=="","Inventory closes through modal boundary")
 await click("keeper_book");game._process(0)
 check(game.field_book and w.phase=="day" and w.jobs.size()==jobs,"Field book reuses existing UI without phase/job mutation")
 game._process(0.6);game._process(0)
 await capture("02_book_eight_slots")
 await click("book_enemies")
 for id in Farm.ProgressData.ENEMY_ROWS:w.campaign.enemy_knowledge[id]=3
 game.book_detail(game.ProgressView.ENEMY_ORDER.find("dancer"));game.refresh();game._process(0.5);game._process(0)
 check(game.buttons.has("enemy_skill_resurrection") and "Ultimate" in game.buttons.enemy_skill_resurrection.tooltip_text,"Enemy skill hover comes from shared definition")
 var motion=InputEventMouseMotion.new();motion.position=game.buttons.enemy_skill_resurrection.get_global_rect().get_center();Input.parse_input_event(motion);await create_timer(0.8).timeout
 await capture("03_enemy_skill_hover")
 await key(KEY_1);check(game.speed==1.0 and w.tick==tick,"Book blocks world speed and time")
 await mouse(Vector2(700,500),MOUSE_BUTTON_RIGHT);game._process(0.6);game._process(0)
 check(not game.field_book and w.phase=="day" and w.paused,"Closing field book preserves prior pause and phase")
 # Explicit rendering fixture: five Human types, no changes to combat tuning.
 w.keeper.pos=Vector2i(9,10)
 for p in w.trees.keys():
  if p.x>=8 and p.x<=18 and p.y>=8 and p.y<=12:w.trees.erase(p)
 for i in range(4):
  w.spawn_enemy({"role":["salaryman","destroyer","dancer","maid"][i],"entry":w.entries[0],"debug_single":true});w.enemies.back().pos=Vector2i(11+i*2,10)
 game.neutral();game.reset_view();game.camera.zoom=Vector2(0.5,0.5);game.camera.position=game.center(Vector2i(12,9));game.refresh();game._process(0)
 await capture("01_forest_humans")
 w.keeper.state="hidden_rest";w.keeper.hp=2
 for text in ["サラリーマン：応援要請","柴犬 → 盗賊　10ダメージ","舞姫：復活の舞","武闘家が復活","牧場主：隠れて療養中"]:w.PlayerEvents.add(w,text)
 game.camera.zoom=Vector2(1.35,1.35);game.camera.position=game.center(Vector2i(12,10));game.choose_walk();game._process(0)
 await capture("04_hidden_rest_event_log")
 if output!="":
  record.implementation_commit=OS.get_environment("FARM_REVIEW_COMMIT");record.asset_delivery_commit="a34390e584037cef78c9f49dcec4b18bd44f6f3d";record.method="Isolated real input; controlled actor positions and knowledge, paused render fixture. Simulation covered by test_quality."
  FileAccess.open(output+"/observations.json",FileAccess.WRITE).store_string(JSON.stringify(record,"  "))
 print("QUALITY_UI: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)
