extends SceneTree
const E=preload("res://core/expedition.gd")
const Catalog=preload("res://core/catalog.gd")
var checks:=0
func check(value: bool, message: String) -> void:
	if not value: push_error(message); quit(1)
	assert(value,message); checks+=1
func _initialize() -> void:
	var cfg:=E.load_config(); var data:=Catalog.load_data()
	var s:=E.fresh(cfg,10000); E.Journey.enable(s); s.phase="explore"; s.floor=1; s.highest_floor=1
	var a:=E.act(s,"advance_ready",int(s.revision),{},data,cfg)
	check(a.floor==2 and a.phase=="treasure" and a.revision==s.revision+1,"one action reaches one node")
	check(E.act(a,"advance_ready",int(s.revision),{},data,cfg)==a,"stale transition cannot advance twice")
	a=E.act(a,"open_chest",int(a.revision),{},data,cfg)
	var before: int=a.items.size(); var token: String=a.pending_rewards[0].token
	var b:=E.act(a,"claim_all_advance",int(a.revision),{},data,cfg)
	check(b.floor==3 and b.phase=="event" and b.items.size()==before+1 and b.pending_rewards.is_empty(),"claim all and exactly one descend")
	check(E.act(b,"claim_all_advance",int(a.revision),{},data,cfg)==b,"duplicate primary has no reward/effect")
	var choice: Dictionary=cfg.journey.events[b.event].choices[-1]
	b=E.act(b,"journey_event",int(b.revision),{"choice":choice.id},data,cfg)
	var c:=E.act(b,"advance_ready",int(b.revision),{},data,cfg)
	check(c.floor==4 and c.phase=="battle","event result advances once without explore interstitial")
	check(E.act(c,"claim_all_advance",int(c.revision),{},data,cfg)==c,"battle rejects hidden E")
	var full:=a.duplicate(true)
	while full.inventory.size()<15: E.add_item(full,"I02")
	check(E.act(full,"claim_all_advance",int(full.revision),{},data,cfg)==full,"full receipt rejects entire transaction")
	var uid: String=full.inventory[0]; var slot: String=cfg.items[full.items[uid]].slot
	if slot=="": uid=full.inventory[-1]; slot=cfg.items[full.items[uid]].slot
	var occupied: String=E.add_item(full,full.items[uid]); full.inventory.erase(occupied); full.equipment[slot]=occupied
	var swapped:=E.act(full,"equip",int(full.revision),{"uid":uid,"slot":slot},data,cfg)
	check(swapped.equipment[slot]==uid and occupied in swapped.inventory and swapped.inventory.size()==15,"full one-for-one swap")
	check(swapped.item_condition[uid]==full.item_condition[uid] and swapped.item_condition[occupied]==full.item_condition[occupied],"swap preserves both condition records")
	check(E.act(full,"equip",int(full.revision),{"uid":uid,"slot":"eyes"},data,cfg)==full,"incompatible target is atomic no-op")
	check(E.act(swapped,"unequip",int(swapped.revision),{"slot":slot},data,cfg)==swapped,"full bag blocks unequip")
	var direct:=a.duplicate(true); var id: String=direct.pending_rewards[0].id; var target: String=cfg.items[id].slot
	while direct.inventory.size()<15: E.add_item(direct,"I02")
	direct.equipment[target]="" # starter is head, chest reward is body/feet
	var equipped:=E.act(direct,"equip_reward",int(direct.revision),{"token":token},data,cfg)
	check(equipped.pending_rewards.is_empty() and equipped.inventory.size()==15 and equipped.equipment[target]!="","receive directly into empty slot with full bag")
	check(E.act(equipped,"equip_reward",int(direct.revision),{"token":token},data,cfg)==equipped,"direct equip receipt exactly once")
	var occupied_receipt:=direct.duplicate(true); var old: String=E.add_item(occupied_receipt,id); occupied_receipt.inventory.erase(old); occupied_receipt.equipment[target]=old
	check(E.act(occupied_receipt,"equip_reward",int(occupied_receipt.revision),{"token":token},data,cfg)==occupied_receipt,"pending swap requires old gear destination")
	var last:=a.duplicate(true); last.pending_rewards=[]; last.floor=10; last.highest_floor=10; last.reward_return="clear"
	var result:=E.act(last,"advance_ready",int(last.revision),{},data,cfg)
	check(result.phase=="result" and result.result.kind=="clear" and result.floor==10,"boss confirmation does not skip to 11F")
	for state in [a,b,c,swapped,equipped,result]: check(E.validate(state,data,cfg)=="","result is valid: "+E.validate(state,data,cfg))
	print("FLOW_CORE_OK checks="+str(checks)); quit()
