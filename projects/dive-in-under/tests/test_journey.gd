extends SceneTree
const E=preload("res://core/expedition.gd")
var data: Dictionary
var cfg: Dictionary
var count:=0
var failures:=0
func check(ok: bool, message: String) -> void:
	count+=1
	if not ok: failures+=1; printerr("FAIL "+message)
func act(s: Dictionary, action: String, args: Dictionary={}) -> Dictionary:
	var result: Dictionary=E.act(s,action,int(s.revision),args,data,cfg)
	check(E.validate(result,data,cfg)=="","valid state after "+action+": "+E.validate(result,data,cfg))
	return result
func initial() -> Dictionary:
	var s:=E.fresh(cfg,123); E.Journey.enable(s); s.phase="town"; s.trips=0
	return s
func _initialize() -> void:
	data=E.Catalog.load_data(); cfg=E.load_config()
	if cfg.is_empty(): quit(1); return
	check(not cfg.is_empty() and E.Journey.validate_definition(cfg.journey,data,cfg)=="","route references")
	var s:=initial(); var uid:=E.add_item(s,"I01"); s.item_condition[uid].current=37
	var before: int=s.items.size()
	s=act(s,"transfer",{"uid":uid,"source":"inventory","destination":"warehouse"})
	check(s.items.size()==before and uid in s.warehouse and s.item_condition[uid].current==37,"transfer identity")
	var stale: int=s.revision-1
	check(E.act(s,"transfer",stale,{"uid":uid,"source":"warehouse","destination":"inventory"},data,cfg)==s,"stale transfer rejects")
	s=act(s,"transfer",{"uid":uid,"source":"warehouse","destination":"cloth"})
	for i in 2: var other:=E.add_item(s,"I10"); s=act(s,"to_cloth",{"uid":other})
	var no_room:=E.add_item(s,"I10")
	check(act(s,"to_cloth",{"uid":no_room})==s,"cloth fourth rejected")
	cfg.items.I10.supply=true
	check(E.Storage.reason(s,no_room,"inventory","warehouse",cfg)=="支給品は倉庫へ預けられません","supply restriction")
	cfg.items.I10.erase("supply")
	s=act(s,"depart"); s=act(s,"descend")
	check(s.phase=="battle" and s.floor==1,"first normal node")
	var blocked:=E.add_item(s,"I04")
	check(act(s,"equip",{"uid":blocked})==s,"battle equip forbidden")
	# Stand-alone nonbattle equipment tests preserve existing HP/SP rather than granting recovery.
	var field:=initial(); field.phase="explore"; field.trips=1; field.floor=2; field.highest_floor=2
	var ring:=E.add_item(field,"I07"); field.hp=11
	field=act(field,"equip",{"uid":ring}); check(field.hp==11 and E.hero(field,cfg).max_hp==29,"max HP equip no heal")
	field=act(field,"unequip",{"slot":"neck"}); check(field.hp==11,"unequip no heal")
	var new_head:=E.add_item(field,"I01"); var old_head: String=field.equipment.head
	while field.inventory.size()<15: E.add_item(field,"I10")
	field=act(field,"equip",{"uid":new_head}); check(field.inventory.size()==15 and old_head in field.inventory and field.equipment.head==new_head,"full bag one-for-one swap")
	check(act(field,"unequip",{"slot":"head"})==field,"full bag removal blocked")
	# Pending rewards remain outside carried capacity, never as orphaned owned instances.
	field.phase="treasure"; E.Journey.add_reward(field,"I05")
	field=act(field,"open_chest"); var token: String=field.pending_rewards[0].token
	check(act(field,"claim_reward",{"token":token})==field,"full bag receipt blocked")
	check(act(field,"return")==field and act(field,"continue_rewards")==field,"cannot silently leave pending rewards")
	var exchanged: String=field.inventory[0]
	field=act(field,"exchange_reward",{"token":token,"replace_uid":exchanged,"confirmed":true})
	check(field.inventory.size()==15 and not field.items.has(exchanged) and field.pending_rewards.is_empty(),"explicit full bag exchange")
	check(act(field,"claim_reward",{"token":token})==field,"same token cannot be claimed twice")
	field=act(field,"continue_rewards"); check(field.phase=="explore","receipt returns to same floor")
	field.phase="event"; field.event="EV01"; field.hp=9
	field=act(field,"journey_event",{"choice":"drink"}); check(field.phase=="event_result" and field.hp==15 and field.event_result.hp_delta==6,"event result staged")
	check(act(field,"round")==field,"event cannot advance battle")
	field=act(field,"continue_event"); check(field.phase=="explore","event returns")
	# Small later-area fixture uses the same node lookup, receipt and event logic; never shipped as public content.
	var later: Dictionary=cfg.journey.duplicate(true); later.public_max_floor=12
	for n in [11,12]:
		var node: Dictionary=cfg.journey.nodes[1 if n==11 else 2].duplicate(true); node.id="test-%d"%n; node.floor=n; later.nodes.append(node)
	later.nodes[10].rewards={"I11":100}; later.nodes[11].events=["EV05"]
	check(E.Journey.validate_definition(later,data,cfg)=="","later content references")
	var old: Dictionary=cfg.journey; cfg.journey=later
	var future:=initial(); future.phase="explore"; future.trips=1; future.floor=10; future.highest_floor=10
	future=act(future,"descend"); check(future.phase=="treasure" and future.pending_rewards[0].id=="I11","later treasure uses common flow")
	future=act(future,"open_chest"); future=act(future,"claim_reward",{"token":future.pending_rewards[0].token}); future=act(future,"continue_rewards"); future=act(future,"descend")
	future=act(future,"journey_event",{"choice":"take"}); check(future.phase=="event_result" and future.pending_rewards[0].id=="I10","later event uses common flow")
	future=act(future,"continue_event"); cfg.journey=old
	# One fresh, deterministic route with normal actions and no prepared growth/gear.
	var normal:=initial(); normal.seed=10000
	var plan: Array=[]; var cleared_trip:=0
	for step in 700:
		if normal.trips>18: break
		var choice: Dictionary=preload("res://tools/journey_policy.gd").choose(normal,cfg)
		if choice.is_empty(): break
		var next: Dictionary=E.act(normal,choice.action,int(normal.revision),choice.args,data,cfg)
		if choice.action=="depart": next=E.act(next,"descend",int(next.revision),{},data,cfg)
		if not check_transition(next,normal,choice.action): break
		normal=next
		plan.append({"action":choice.action,"args":choice.args,"sha256":JSON.stringify(JSON.parse_string(JSON.stringify(normal))).sha256_text(),"phase":normal.phase,"floor":normal.floor,"revision":normal.revision})
		if normal.phase=="result" and normal.result.kind=="clear": cleared_trip=int(normal.trips)
		if cleared_trip>0 and normal.trips>cleared_trip: break
	check(cleared_trip>0 and normal.trips>cleared_trip,"fresh normal 10F clear, return, organize and redepart")
	var output:=FileAccess.open("res://artifacts/journey-plan.json",FileAccess.WRITE)
	output.store_string(JSON.stringify({"seed":10000,"actions":plan,"cleared_trip":cleared_trip,"final_level":E.hero(normal,cfg).level,"complete":cleared_trip>0 and normal.trips>cleared_trip},"\t")); output.close()
	print("JOURNEY_PLAN actions=%d trips=%d clear_trip=%d level=%d phase=%s"%[plan.size(),normal.trips,cleared_trip,E.hero(normal,cfg).level,normal.phase])
	print("JOURNEY_TESTS: %d checks, %d failures"%[count,failures]); quit(0 if failures==0 else 1)

func check_transition(next: Dictionary, previous: Dictionary, action: String) -> bool:
	var reason: String=E.validate(next,data,cfg)
	if next==previous or reason!="": check(false,"normal route "+action+" / "+reason); return false
	return true
