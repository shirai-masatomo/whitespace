extends RefCounted
const E=preload("res://core/expedition.gd")
const Party=preload("res://core/party_ui.gd")
const T=preload("res://core/tactics.gd")
const F=preload("res://ui/flow_review.gd")
const A=preload("res://ui/adventure_review.gd")
const UI=preload("res://ui/integration_review.gd")
static var checks: Array=[]
static func check(game: Control, value: bool, name: String) -> bool:
	UI.write(game,{"last_check":name,"passed":value,"run_id":game.smoke_run_id},"party-ui-progress.json")
	if value:checks.append(name)
	return game.smoke_check(value,name)
static func shot(game: Control, name: String) -> void:
	await F.wait(game,.15);await game.capture(name+".png")
static func mouse(game: Control, point: Vector2, button: int, pressed: bool, shift: bool=false) -> void:
	var event:=InputEventMouseButton.new();event.position=point;event.global_position=point;event.button_index=button;event.pressed=pressed;event.shift_pressed=shift
	game.get_viewport().push_input(event,true);await game.get_tree().process_frame
static func click(game: Control, b: Button, button: int=MOUSE_BUTTON_LEFT, shift: bool=false) -> void:
	await F.wait(game,.4)
	if not check(game,is_instance_valid(b),"input target exists"):return
	var point: Vector2=b.get_global_rect().get_center();await mouse(game,point,button,true,shift);await mouse(game,point,button,false,shift);await F.wait(game,.15)
static func cell_index(node: Node, index: int) -> Button:
	if node is Button and node.get_meta("storage_cell",-1)==index:return node
	for child in node.get_children():
		var found: Button=cell_index(child,index)
		if found:return found
	return null
static func motion(game: Control, point: Vector2, held: bool=false) -> void:
	var event:=InputEventMouseMotion.new();event.relative=point-game.get_viewport().get_mouse_position();event.position=point;event.global_position=point;event.button_mask=MOUSE_BUTTON_MASK_LEFT if held else 0
	game.get_viewport().push_input(event,true);await game.get_tree().process_frame
static func drag(game: Control, b: Button, target: Button, half: bool=false) -> void:
	await F.wait(game,.4)
	var start: Vector2=b.get_global_rect().get_center();var finish: Vector2=target.get_global_rect().position+Vector2(3,3)
	var shift:=InputEventKey.new();shift.keycode=KEY_SHIFT;shift.physical_keycode=KEY_SHIFT;shift.pressed=half;Input.parse_input_event(shift)
	await motion(game,start);await mouse(game,start,MOUSE_BUTTON_LEFT,true,half);await motion(game,start+Vector2(20,0),true);await motion(game,finish,true)
	if not check(game,game.get_viewport().gui_is_dragging(),"native framed item drag starts"):return
	await mouse(game,finish,MOUSE_BUTTON_LEFT,false,half)
	shift.pressed=false;Input.parse_input_event(shift);await F.wait(game,.3)
static func reset(game: Control, s: Dictionary) -> void:
	game.selected_actor="hero";game.screen_history=[];game.gear_source="inventory";game.gear_storage={};game.warehouse_state={};await A.reset(game,s)
static func run(game: Control) -> void:
	await F.nav(game,"start");await shot(game,"01-normal-preparation")
	var s: Dictionary=E.fresh(game.cfg,22)
	for id in ["B","C"]:Party.add_dummy(s,id,"検証仲間"+id,{"max_hp":30,"max_sp":5,"atk":4,"def":2,"spd":8})
	for value in s.tactics.sets:
		for id in ["B","C"]:value.order.append(id);value.characters[id]={"rank":"back" if id=="C" else "front","rows":[{"skill":"attack","conditions":[],"target":"enemy_front"}]}
	var cloak: String=E.add_item(s,"A02");var shield: String=E.add_item(s,"A06");s.inventory.erase(shield);s.warehouse.append(shield)
	preload("res://core/currency.gd").credit(s,5);await reset(game,s)
	game.open_town_page("equipment");await F.wait(game)
	await click(game,F.meta_button(game.screen,"party_actor","B"));await shot(game,"02-equipment-companion")
	await click(game,F.cell(game.screen,"inventory",cloak),MOUSE_BUTTON_LEFT,true)
	if not check(game,game.campaign.companions.B.equipment.head==cloak and game.campaign.equipment.head!=cloak,"Shift left equips selected companion only"):return
	await click(game,F.meta_button(game.screen,"gear_source","warehouse"))
	await drag(game,F.cell(game.screen,"equipment",cloak,"head"),cell_index(game.screen,5))
	if not check(game,game.campaign.companions.B.equipment.head=="" and E.Storage.uid_at(game.campaign,5)==cloak,"drag full frame unequips to exact warehouse cell"):return
	await shot(game,"03-equipment-warehouse")
	await drag(game,F.cell(game.screen,"warehouse",cloak),F.cell(game.screen,"equipment","","head"))
	if not check(game,game.campaign.companions.B.equipment.head==cloak,"warehouse drag equips companion"):return
	game.gear_storage.filter="armor";game.gear_storage.slot="left_hand";game.show_campaign();await F.wait(game);await shot(game,"04-equipment-filter")
	await click(game,F.meta_button(game.screen,"party_actor","hero"));await shot(game,"05-equipment-hero")
	game.open_status();await F.wait(game,.4);await shot(game,"06-status-hero")
	await click(game,F.meta_button(game.screen,"party_actor","B"));await F.wait(game,.3)
	await click(game,F.meta_button(game.screen,"status_tab","abilities"));await shot(game,"07-status-companion-abilities")
	await F.nav(game,"status-equipment")
	if not check(game,game.selected_actor=="B" and game.town_page=="equipment","status equipment link retains character"):return
	await mouse(game,Vector2(800,690),MOUSE_BUTTON_RIGHT,true);await mouse(game,Vector2(800,690),MOUSE_BUTTON_RIGHT,false);await F.wait(game,.4)
	if not check(game,game.town_page=="status" and game.selected_actor=="B","right click returns one screen with selected actor"):return
	await F.nav(game,"status-tactics");await shot(game,"08-tactics-overview")
	await F.nav(game,"tactics-page-edit");await shot(game,"09-tactics-individual")
	if not check(game,game.modal_owner.actor=="B","status tactics link retains character"):return
	await F.nav(game,"tactics-page-saved");await shot(game,"10-tactics-save-select");await F.nav(game,"tactics-apply");await F.key(game,KEY_ESCAPE)
	game.open_town_page("warehouse");await F.wait(game);await shot(game,"11-items")
	var coins: String=game.campaign.inventory.filter(func(k):return game.campaign.items[k]=="C01")[0]
	await drag(game,F.cell(game.screen,"inventory",coins),cell_index(game.screen,8),true)
	if not check(game,preload("res://core/currency.gd").amount(game.campaign)==3 and preload("res://core/currency.gd").amount(game.campaign,"warehouse")==2,"Shift drag floors odd stack and preserves total"):return
	await shot(game,"12-items-half-stack")
	var ware_coin: String=game.campaign.warehouse.filter(func(k):return game.campaign.items[k]=="C01")[0]
	await click(game,F.cell(game.screen,"warehouse",ware_coin),MOUSE_BUTTON_RIGHT,true)
	if not check(game,game.town_page=="warehouse" and preload("res://core/currency.gd").amount(game.campaign)==5,"Shift right moves once and does not go back"):return
	await drag(game,F.cell(game.screen,"warehouse",shield),cell_index(game.screen,7))
	if not check(game,E.Storage.uid_at(game.campaign,7)==shield,"manual warehouse placement is exact"):return
	await shot(game,"13-items-manual-cells")
	# Fixed normal-world fixtures: pending reward acquisition and cancel, not a claimed playthrough.
	s=E.fresh(game.cfg,33);s.phase="treasure";s.floor=2;s.highest_floor=2;s.node={"kind":"treasure","resolved":false,"started":true};E.Adventure.reward(s,"A01");s.reward_origin="宝箱"
	await reset(game,s);await shot(game,"14-chest-before");await F.key(game,KEY_E)
	if not check(game,game.campaign.pending_rewards.is_empty() and game.campaign.inventory.size()==1 and game.campaign.floor==2,"one acquire opens and receives without skipping floor"):return
	await shot(game,"15-chest-acquired")
	await F.wait(game,.4);await F.key_event(game,KEY_E,true);await F.wait(game,.04);await game.capture("16-descent.png");await F.key_event(game,KEY_E,false);await shot(game,"16-exploration")
	s=E.fresh(game.cfg,44);s.phase="reward";s.floor=2;s.highest_floor=2;s.node={"kind":"enemy","resolved":true,"started":true};s.reward_origin="戦利品"
	for i in 15:E.add_item(s,"I10")
	E.Adventure.reward(s,"A01");await reset(game,s);await shot(game,"17-loot-full-before")
	await F.key(game,KEY_E);await shot(game,"18-loot-replace")
	if not check(game,is_instance_valid(game.modal_owner) and game.campaign.pending_rewards.size()==1,"only full acquisition opens replacement UI"):return
	await F.key(game,KEY_ESCAPE)
	if not check(game,game.campaign.pending_rewards.size()==1 and game.campaign.inventory.size()==15,"cancel preserves unreceived reward and bag"):return
	await shot(game,"19-loot-cancelled")
	s=E.fresh(game.cfg,55);s=E.act(s,"depart",int(s.revision),{},game.data,game.cfg);s.floor=4;s.phase="explore";s=E.act(s,"descend",int(s.revision),{},game.data,game.cfg)
	await reset(game,s);await shot(game,"20-portal-five")
	var before: Dictionary=game.campaign.duplicate(true);await mouse(game,Vector2(600,300),MOUSE_BUTTON_RIGHT,true);await mouse(game,Vector2(600,300),MOUSE_BUTTON_RIGHT,false);await F.wait(game,.4)
	if not check(game,game.campaign==before,"portal right click chooses neither return nor stay"):return
	# A real normal battle keeps its action ledger through the new strategy UI.
	s=E.fresh(game.cfg,10000);s=E.act(s,"depart",int(s.revision),{},game.data,game.cfg);s=E.act(s,"descend",int(s.revision),{},game.data,game.cfg)
	await reset(game,s);game.tactics_page="battle";game.open_services("tactics");await F.wait(game);await shot(game,"21-tactics-battle-switch")
	var ledger: Array=game.campaign.battle.current.acted.duplicate();await F.nav(game,"tactics-apply")
	if not check(game,game.campaign.battle.current.acted==ledger,"new strategy UI preserves battle action ledger"):return
	await F.key(game,KEY_ESCAPE)
	game.show_title();await F.wait(game)
	UI.write(game,{"complete":true,"rendered":true,"version":ProjectSettings.get_setting("application/config/version"),"run_id":game.smoke_run_id,"no_save_store":game.save_store==null,"checks":checks,"exit_button_pressed":true,"fixtures_labelled":true,"user_evaluation":"not_reviewed"},"party-ui-review.json")
	await F.nav(game,"exit")
