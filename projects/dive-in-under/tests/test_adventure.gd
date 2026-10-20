extends SceneTree
const E=preload("res://core/expedition.gd")
const P=preload("res://core/adventure.gd")
const M=preload("res://core/currency.gd")
const I=preload("res://core/item_instances.gd")
var cfg: Dictionary
var data: Dictionary
var checks: int=0
func check(value: bool, message: String) -> void:
	if not value: push_error("ADVENTURE_CHECK: "+message); quit(1); return
	checks+=1
func act(s: Dictionary, name: String, args: Dictionary={}) -> Dictionary:
	return E.act(s,name,int(s.revision),args,data,cfg)
func _initialize() -> void:
	cfg=E.load_config(); data=E.Catalog.load_data()
	check(not cfg.is_empty(),"current config loads")
	var s: Dictionary=E.fresh(cfg,123)
	check(P.active(s) and s.phase=="town" and s.equipment.values().filter(func(v):return v!="").size()==5 and not s.has("gold"),"five supplied items and no wallet")
	check(E.validate(s,data,cfg)=="","fresh ownership valid")
	M.credit(s,150); check(M.amount(s)==150 and s.inventory.size()==2,"99 stacks")
	var uid: String=s.inventory[0]
	s=act(s,"coin_split",{"uid":uid,"source":"inventory","quantity":30});check(M.amount(s)==150 and s.inventory.size()==3,"split preserves value")
	s=act(s,"coin_combine",{"source":"inventory"});check(M.amount(s)==150 and s.inventory.size()==2,"combine preserves value")
	s=act(s,"coin_move",{"uid":s.inventory[0],"source":"inventory","destination":"cloth","quantity":40});check(M.amount(s,"cloth")==40 and M.amount(s)==110,"explicit partial move")
	check(not M.pay(s,111) and M.amount(s,"cloth")==40,"no implicit cloth payment")
	uid=E.add_item(s,"W02");var profile: Dictionary=s.item_details[uid].duplicate(true)
	s=act(s,"equip",{"uid":uid});s=act(s,"unequip",{"slot":"right_hand"});s=act(s,"organize_bag")
	check(s.item_details[uid]==profile,"roll fixed through equip and organize")
	var exp: int=s.exp; var bag_count: int=s.inventory.size();var protected: String=E.add_item(s,"B01");s.inventory.erase(protected);s.warehouse.append(protected)
	P.finish(s,"death","test death")
	check(s.inventory.is_empty() and s.equipment.values().all(func(v):return v=="") and s.items.has(protected) and M.amount(s,"cloth")==40 and s.exp==exp,"full death with protected storage and growth")
	s=act(s,"town");s=act(s,"supply");check(s.equipment.values().filter(func(v):return v!="").size()==5,"resupply enables retry")
	var cloak: String=s.equipment.head;s=act(s,"unequip",{"slot":"head"});s=act(s,"to_cloth",{"uid":cloak});var count: int=s.items.size();s=act(s,"supply");check(s.items.size()==count and s.equipment.head=="","cloth cannot duplicate supply")
	check(E.Storage.reason(s,cloak,"cloth","warehouse",cfg)!="","supplied warehouse blocked")
	var portal: Dictionary=E.fresh(cfg,456);portal=act(portal,"depart");portal.floor=4;portal.highest_floor=4
	portal=act(portal,"descend");check(portal.phase=="portal" and portal.floor==5 and portal.battle.is_empty(),"portal before encounter")
	var return_state: Dictionary=act(portal,"return_ready");check(return_state.phase=="result" and return_state.result.kind=="return","5F return")
	portal=act(portal,"portal_stay");var node: Dictionary=portal.node.duplicate(true);var revision: int=portal.revision;portal=act(portal,"portal_stay");check(portal.node==node and portal.revision==revision,"portal stay cannot reroll")
	var ten: Dictionary=E.fresh(cfg,789);ten=act(ten,"depart");ten.floor=9;ten.highest_floor=9;ten=act(ten,"descend");ten=act(ten,"return_ready");check(ten.records.boss_kills==0 and not ten.records.first_reward_issued,"10F early return no clear")
	var early: Dictionary=E.fresh(cfg,1);early=act(early,"depart");early=act(early,"descend");check(act(early,"return_ready")==early,"ordinary floors cannot return")
	check(E.validate(return_state,data,cfg)=="" and E.validate(ten,data,cfg)=="","result states valid")
	print("ADVENTURE_CORE_OK checks="+str(checks));quit()
