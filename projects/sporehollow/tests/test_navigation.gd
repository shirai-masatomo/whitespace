extends SceneTree
## Seed31 reproductions: goal churn, actor detour, feline escape and idol contact.
## Frozen actors in the collision/flee fixtures isolate a valid occupancy context.
const Farm=preload("res://tests/open_ranch_fixture.gd")
var checks=0
var failures=0
var records=[]
func _initialize():call_deferred("run")
func check(ok:bool,why:String):
 checks+=1;records.append({"check":why,"passed":ok})
 if not ok:failures+=1;push_error(why)
func fresh():
 var w=Farm.new({},31).begin_day()
 w.day_seconds=9999;w.nature_config.spawn_chance_per_second=0
 w.trees.clear();w.natural.clear();w.structures.clear();w.field_items.clear();w.floors.clear();w.animals.clear();w.spawn_schedule.clear()
 w.keeper.pos=Vector2i(22,13)
 return w
func enemy(w,p,role="kidnapper"):
 w.spawn_enemy({"role":role,"entry":w.entries[0],"lv":1,"debug_single":true})
 var e=w.enemies.back();e.pos=p;e.ai_accuracy=100
 return e
func cat(w,p):
 var a={"id":2,"species":"cat","category":"cat","lv":1,"loyalty":0,"name":"","unavailable_through_day":0}
 w.campaign.animals.append(a);w.add_resident(a)
 var c=w.animals.back();c.pos=p;c.home=p;c.order=p
 return c
func hidden(w):w.keeper.hp=0;w.keeper.state="hidden_rest"
func enemy_tick(w,e):w.tick+=1;w.Combat.recover(e,w.DT);w.enemy_step(e)
func run():
 var w=fresh();hidden(w);var e=enemy(w,Vector2i(10,8));e.sight_range=0
 var visited={e.pos:true};var changed_in_flight=false
 for i in range(120):
  var old_goal=e.search_goal;var old_pos=e.pos;var deadline=e.search_goal_until
  enemy_tick(w,e);visited[e.pos]=true
  if old_goal!=null and old_pos!=old_goal and w.tick<deadline and e.search_goal!=old_goal:changed_in_flight=true
 check(not changed_in_flight,"Hidden keeper preserves an unfinished reachable exploration goal")
 check(visited.size()>8,"Unopposed exploration reaches new ground instead of a three-cell cycle")
 w=fresh();w.trees[Vector2i(4,8)]="tree";e=enemy(w,Vector2i(3,8));e.sight_range=0
 var goal=w.RaiderAI.target(e,w)
 check(not w.Story.terrain_block(w,goal) and not w.find_path(e.pos,goal,true).is_empty(),"Exploration does not select a terrain-blocked waypoint")
 w=fresh();hidden(w);e=enemy(w,Vector2i(3,8));e.sight_range=0
 goal=w.RaiderAI.target(e,w);w.tick=1000
 check(w.RaiderAI.target(e,w)==goal and e.search_visits.is_empty(),"Unfinished reachable goal survives the old deadline and is not counted as visited")
 var stamina=e.stamina;var path_size=e.path.size();w.move_enemy(e,e.pos,goal)
 check(e.stamina==stamina and e.path.size()==path_size,"No movement cannot consume stamina or masquerade as path progress")
 w=fresh();w.keeper.pos=Vector2i(12,8);e=enemy(w,Vector2i(8,8));var blocker=enemy(w,Vector2i(9,8));var overlap=false
 for i in range(60):
  enemy_tick(w,e);overlap=overlap or e.pos==blocker.pos
  if w.distance(e.pos,w.keeper.pos)<=1:break
 check(w.distance(e.pos,w.keeper.pos)<=1,"Pursuit routes around a stationary living ally")
 check(not overlap,"Routing around an ally never overlaps actors")
 w=fresh();var c=cat(w,Vector2i(10,8));e=enemy(w,Vector2i(8,8))
 for p in [Vector2i(10,7),Vector2i(10,9),Vector2i(11,8)]:w.trees[p]="tree"
 var escaped=false;var physical=true
 for i in range(120):
  var before=c.pos;w.tick+=1;w.animal_step(c)
  physical=physical and w.distance(before,c.pos)<=1 and w.walkable(c.pos) and c.pos!=e.pos
  if w.distance(c.pos,e.pos)>c.detection_range:escaped=true;break
 check(escaped,"Frightened cat follows a route out of a local distance maximum")
 check(physical,"Cat escape consists of legal single-cell steps")
 c.pos=Vector2i(16,8);c.fear=28;c.move_credit=1;var relocated=c.pos
 w.animal_step(c)
 check(w.distance(relocated,c.pos)<=1,"Changed position invalidates stale escape steps rather than teleporting")
 w=fresh();c=cat(w,Vector2i(10,8));e=enemy(w,Vector2i(8,8))
 for p in [Vector2i(9,7),Vector2i(9,9),Vector2i(10,7),Vector2i(10,9),Vector2i(11,8)]:w.trees[p]="tree"
 var stayed=true
 for i in range(60):w.tick+=1;w.animal_step(c);stayed=stayed and c.pos==Vector2i(10,8)
 check(stayed,"Without an escape route the cat holds the safest reachable cell instead of oscillating")
 for role in ["kidnapper","salaryman","ninja","runner","doberman","destroyer"]:
  w=fresh();hidden(w);w.story.idol={"position":[12,8],"home":[12,8],"hp":180,"max_hp":180,"state":"installed","carrier":-1,"prepare":0.0}
  e=enemy(w,Vector2i(9,8),role);physical=true
  for i in range(64):
   enemy_tick(w,e);physical=physical and e.pos not in w.Story.idol_cells(w)
   if w.story.idol.hp<180:break
  check(w.story.idol.hp<180,"Distant observed idol can be approached and attacked: "+role)
  check(physical,"Idol approach never enters its footprint: "+role)
 FileAccess.open("user://navigation-tests.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":records,"seed":31},"  "))
 print("NAVIGATION: %d checks, failures=%d"%[checks,failures])
 quit(1 if failures else 0)
