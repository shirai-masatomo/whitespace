extends "res://tests/test_navigation.gd"
## Freeze one living ally at an idol contact to isolate endpoint occupancy, not enemy timers.
func run():
	var cases=[]
	for role in ["destroyer","ninja","idol_breaker","idol_extractor"]:
		for crowded in [false,true]:
			var w=fresh();hidden(w)
			w.story.idol={"position":[12,8],"home":[12,8],"hp":180,"max_hp":180,"state":"installed","carrier":-1,"prepare":0.0}
			var e=enemy(w,Vector2i(10,8),role);var blocker={}
			if crowded:blocker=enemy(w,Vector2i(11,8),"salaryman")
			var trace=[];var first_move=-1;var first_objective=-1;var still=0;var longest_still=0;var switches=0;var previous_target="";var physical=true
			for i in range(240):
				var before=e.pos;enemy_tick(w,e)
				if before==e.pos:still+=1
				else:
					still=0
					if first_move<0:first_move=w.tick
				longest_still=maxi(longest_still,still)
				var target=str(e.get("chosen_target",{}).get("kind",""))+str(e.get("chosen_target",{}).get("id",-1))
				if previous_target!="" and previous_target!=target:switches+=1
				previous_target=target
				if first_objective<0 and (w.story.idol.hp<180 or w.story.idol.state!="installed"):first_objective=w.tick
				physical=physical and (blocker.is_empty() or e.pos!=blocker.pos) and e.pos not in w.Story.idol_cells(w)
				if i%8==0:trace.append({"tick":w.tick,"pos":e.pos,"state":e.state,"target":e.get("chosen_target",{}).duplicate(true),"search_goal":e.search_goal,"choose_at":e.get("choose_at",0),"stamina":e.stamina,"move_credit":e.move_credit,"next_attack":e.next_attack,"move_stopped_until":e.move_stopped_until,"idol_hp":w.story.idol.hp,"idol_state":w.story.idol.state})
				if first_objective>=0:break
			check(physical,"No occupied-cell or idol overlap: "+role+str(crowded))
			check(first_objective>=0,"A free alternate idol contact restores objective progress: "+role+str(crowded))
			cases.append({"role":role,"crowded":crowded,"first_move_seconds":first_move*w.DT if first_move>=0 else -1,"first_objective_seconds":first_objective*w.DT if first_objective>=0 else -1,"longest_stationary_seconds":longest_still*w.DT,"target_switches":switches,"trace":trace})
			print("IDOL_CONTACT ",role," crowded=",crowded," objective=",first_objective*w.DT," still=",longest_still*w.DT," switches=",switches)
	FileAccess.open("user://idol-congestion.json",FileAccess.WRITE).store_string(JSON.stringify({"cases":cases,"checks":records,"scope":"f96467a contact occupancy diagnosis, fixed stationary ally; distinct from the later forest-entry image"},"  "))
	print("IDOL_CONGESTION: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)
