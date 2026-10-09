extends "res://tests/test_ranch_content.gd"
func run():
 var w=open_world();var maid=enemy(w,"maid",Vector2i(8,10));var friend=enemy(w,"salaryman",Vector2i(9,10))
 maid.arrival_cleared=true;maid.ultimate_gauge=0;friend.hp=10
 C.enemy_step(w,maid)
 check(friend.hp==13 and maid.escort_target==friend.id,"Coffee recipient becomes escort target")
 friend.pos=Vector2i(14,10);maid.coffee_rest_until=9999
 var start=maid.pos;var overlap=false
 for i in range(32):
  w.tick+=1;w.Combat.recover(maid,w.DT);C.enemy_step(w,maid);overlap=overlap or maid.pos==friend.pos
 check(maid.pos!=start and w.distance(maid.pos,friend.pos)<=2,"Coffee cooldown permits following a moving ally")
 check(not overlap,"Escort never overlaps supported ally")
 var held=maid.pos
 for i in range(8):w.tick+=1;C.enemy_step(w,maid)
 check(maid.pos==held,"Maid holds nearby instead of circling")
 friend.hp=0;friend.dead=true
 var next=enemy(w,"destroyer",Vector2i(15,12));C.enemy_step(w,maid)
 check(maid.escort_target==next.id,"Dead support recipient is replaced")
 next.flee=true;C.enemy_step(w,maid)
 check(not maid.has("escort_target"),"Fleeing ally is not escorted")
 var hp=w.keeper.hp;maid.pos=w.keeper.pos+Vector2i.RIGHT
 C.enemy_step(w,maid)
 check(w.keeper.hp==hp,"Normal escort state does not attack keeper")
 print("MAID_ESCORT: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)
