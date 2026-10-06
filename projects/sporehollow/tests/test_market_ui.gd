extends SceneTree
const Farm=preload("res://game/world.gd")
const Market=preload("res://game/market_view.gd")
var game
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(value: bool, message: String):
	checks+=1
	if not value:failures+=1;push_error(message)
func click(id: String):
	if not game.buttons.has(id):
		push_error("Missing market button: "+id);quit(2);return
	var p=game.buttons[id].get_global_rect().get_center()
	var motion=InputEventMouseMotion.new();motion.position=p;Input.parse_input_event(motion)
	await process_frame
	for pressed in [true,false]:
		var e=InputEventMouseButton.new();e.position=p;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=pressed
		Input.parse_input_event(e);await process_frame
func run():
	root.size=Vector2i(1280,800)
	game=load("res://game/main.tscn").instantiate();game.automated=true;root.add_child(game)
	game.world=Farm.new({},17);game.arrival_started=game.clock-5;game.refresh()
	await process_frame;await process_frame
	var world=game.world
	await click("open_market");await click("shop_buy");await click("category_materials")
	var left=game.buttons["trade_soil_-1"].position.x
	await click("trade_wood_-1")
	check(not game.buttons.confirm_trade.disabled,"12G purchase enabled at 40G")
	await click("confirm_trade")
	check(world.campaign.gold==28 and world.resource_amount("wood")==20,"UI purchase preserves 12G / 20 wood unit")
	check(game.shop_notice=="木材 ×20を購入しました　−12G（40G → 28G）","Single concrete purchase receipt")
	await click("shop_back");await click("shop_back");await click("category_animals")
	check(game.buttons["trade_hen_-1"].position.x==left,"Two/three products share fixed left edge")
	check(not game.buttons["trade_hen_-1"].disabled,"Unavailable purchase can still be inspected")
	check(Market.reason(world,"buy",{"id":"hen","count":1})=="あと2G","List computes exact shortfall")
	await click("trade_hen_-1")
	check(game.buttons.confirm_trade.disabled,"Insufficient gold disables action, not details")
	await click("confirm_trade")
	check(world.campaign.gold==28 and world.jobs.is_empty(),"Disabled button has no trade/board side effect")
	await click("close_market");await click("open_market");await click("shop_sell");await click("category_materials")
	await click("trade_wood_-1");await click("confirm_trade")
	check(world.campaign.gold==32 and world.resource_amount("wood")==0,"Sale preserves 4G / 20 wood unit")
	check(game.shop_notice=="木材 ×20を売却しました　＋4G（28G → 32G）","Single concrete sale receipt")
	check(game.buttons.confirm_trade.disabled and game.buttons.confirm_trade.tooltip_text=="売却できる分はありません","Depleted sale is not store sold out")
	check(world.shop_log.size()==2,"One transaction per explicit click")
	# UI edge-state fixture: display partial bundles, never change sale rules.
	world.add_resource("wood",19);game.refresh()
	var row=Market.live_row(game)
	check(row.count==0 and Market.owned(world,row)==19,"Partial bundle remains inspectable with 0 sellable sets")
	check(game.buttons.confirm_trade.disabled,"Partial bundle cannot be sold")
	check(Market.reason(world,"sell",row)=="売却には木材 ×20が必要","Partial bundle states actual required quantity")
	world.add_resource("wood",1);game.refresh()
	check(not game.buttons.confirm_trade.disabled,"Complete bundle becomes sellable")
	check(Market.empty_message(game,"animals")=="売却できる仲間はいません。","Animal sell empty reason")
	check(Market.empty_message(game,"items")=="売れる品を持っていません。","Item sell empty reason")
	game.shop_side="buy"
	check(Market.empty_message(game,"facilities")=="今日はこの品の入荷がありません。","Purchase empty reason")
	check(Market.reason(world,"buy",{"id":"whistle","count":0})=="売り切れ","Store depleted remains sold out")
	for id in ["hen","cat","soil","wood","stone","whistle","hammer","basket"]:
		var texture=Market.texture_for(id)
		check(texture!=null and texture.get_image().get_used_rect().has_area(),"Visible referenced artwork: "+id)
	check(world.tick==0 and world.phase=="shop","All UI operations leave morning world stopped")
	game.close_morning_screen();game.refresh()
	await click("advance");await create_timer(1.5).timeout
	check(game.world.phase=="day","Morning preparation goes to day, never directly to night")
	print("MARKET_UI: ",checks," checks failures=",failures)
	quit(1 if failures else 0)
