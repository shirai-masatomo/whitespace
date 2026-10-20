extends SceneTree
const E=preload("res://core/expedition.gd")
const Catalog=preload("res://core/catalog.gd")
const P=preload("res://ui/item_presenter.gd")
const Choices=preload("res://ui/event_choices.gd")
var checks:=0
func check(value: bool, message: String) -> void:
	assert(value,message)
	if not value: push_error(message); quit(1)
	checks+=1
func _initialize() -> void:
	var cfg:=E.load_config(); var data:=Catalog.load_data(); var state:=E.fresh(cfg,10000); E.Journey.enable(state); state.phase="town"; state.trips=0
	var uid: String=E.add_item(state,"I02"); state.inventory.erase(uid); state.equipment.body=uid
	for condition in [0,37,100]:
		state.item_condition[uid].current=condition
		var value: int=E.Condition.bonus(state,uid,2)
		check(E.Condition.stats(state,uid,cfg).def==value,"shared item current equals existing bonus")
		check(E.hero(state,cfg).def==int(cfg.initial.def)+E.Condition.stats(state,state.equipment.head,cfg).get("def",0)+value,"hero uses same per-instance current")
		check(P.current(state,cfg,uid)==P.text(E.Condition.stats(state,uid,cfg)),"all presentation adapters share current stats")
		check(state.item_condition[uid].current==condition,"presentation is read only")
	state.item_condition[uid].current=37
	check("現在値" in P.performance(state,cfg,uid) and "基礎値" in P.performance(state,cfg,uid),"base and effective values labelled")
	check("所持金不足"==P.repair_reason(state,cfg,uid),"repair insufficient funds")
	state.gold=1000
	var repaired:=E.act(state,"repair",int(state.revision),{"uid":uid},data,cfg)
	check(E.Condition.stats(repaired,uid,cfg)==E.Condition.stats(state,uid,cfg,true),"repair preview equals actual restored current")
	check(P.repair_reason(repaired,cfg,uid)=="修理不要","repair unnecessary")
	state.phase="reward";state.trips=1;state.floor=2;state.highest_floor=2
	check(P.repair_reason(state,cfg,uid)=="町で修理できます","repair town-only reason")
	var closed:=E.fresh(cfg,10000);E.Journey.enable(closed);closed.phase="explore";closed.floor=1;closed.highest_floor=1
	closed=E.act(closed,"advance_ready",int(closed.revision),{},data,cfg)
	var skipped:=E.act(closed,"skip_chest",int(closed.revision),{},data,cfg)
	check(skipped.floor==3 and skipped.phase=="event" and skipped.pending_rewards.is_empty() and skipped.items==closed.items,"closed skip changes one node without receiving")
	check(E.act(skipped,"skip_chest",int(closed.revision),{},data,cfg)==skipped,"stale skip cannot repeat")
	var opened:=E.act(closed,"open_chest",int(closed.revision),{},data,cfg)
	check(E.act(opened,"skip_chest",int(opened.revision),{},data,cfg)==opened,"opened rewards cannot be skipped without confirmation")
	for id in cfg.journey.events: check(Choices.simple(cfg.journey.events[id]),"existing cost-free events are simple")
	var complex: Dictionary=cfg.journey.events.EV01.duplicate(true);complex.choices[0].cost_text="費用の説明"
	check(not Choices.simple(complex),"cost-bearing choice never gets simple E default")
	check(E.validate(repaired,data,cfg)=="" and E.validate(skipped,data,cfg)=="","modified states remain valid")
	print("REVIEW_FIXES_CORE_OK checks="+str(checks));quit()
