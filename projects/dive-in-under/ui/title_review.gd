extends RefCounted
## Explicit title-only isolated review; actual native Button input, no combat or audio tests.
const UI=preload("res://ui/integration_review.gd")
static func run(game: Control) -> void:
	if not UI.check(game,DisplayServer.get_name()!="headless" and not game.legacy_persistence_mode and game.save_store==null and game.campaign.is_empty(),"Fresh title in rendered normal mode"): return
	var view: Control=game.play_view
	var backdrop: TextureRect=view.get_node("TownBackdrop")
	var dimmer: ColorRect=view.get_node("TitleBackgroundDimmer")
	var menu: Control=view.get_node("TitleMenu")
	var logo: TextureRect=menu.get_node("TitleLogo")
	var subtitle: Label=menu.get_node("JapaneseSubtitle")
	if not UI.check(game,backdrop.texture.resource_path=="res://assets/interface/v2/surface-title.png" and backdrop.get_index()<dimmer.get_index() and dimmer.get_index()<menu.get_index(),"Original background, independent dimmer, then all UI"): return
	if not UI.check(game,dimmer.color==Color(0,0,0,0.12) and dimmer.mouse_filter==Control.MOUSE_FILTER_IGNORE and menu.modulate==Color.WHITE and logo.modulate==Color.WHITE,"12 percent background dimmer never tints UI or intercepts input"): return
	if not UI.check(game,logo.texture.resource_path=="res://assets/title/v1/dive-in-under-logo-gold-deep-shadow.png" and logo.texture.get_size()==Vector2(2172,724) and is_equal_approx(logo.size.x/logo.size.y,3.0) and logo.stretch_mode==TextureRect.STRETCH_KEEP_ASPECT_CENTERED,"Selected lowercase-r PNG, uncropped original aspect"): return
	if not UI.check(game,logo.position.x>=32 and logo.get_rect().end.x<=menu.size.x-32 and logo.get_rect().end.y+6<=subtitle.position.y and subtitle.text=="ダイブ・イン・アンダー","Logo and downward ornament have margins without subtitle overlap"): return
	await UI.shot(game,"title-start-focused")
	var layout: Dictionary={"logo_rect":str(logo.get_global_rect()),"subtitle_rect":str(subtitle.get_global_rect()),"original_background":backdrop.texture.resource_path,"logo":logo.texture.resource_path,"dimmer_alpha":dimmer.color.a,"logo_aspect":3.0,"ui_untinted":true,"layer_order":true,"lower_ornament_unclipped":true}
	await UI.click(game,"start"); game.auto_play=false
	if not UI.check(game,game.campaign.phase=="town" and game.play_view.mode=="hub" and game.campaign.floor==0,"Start Button opens adventure preparation"): return
	await UI.click(game,"title")
	if not UI.check(game,game.title_visible and game.play_view.mode=="title","Return to title for Exit Button check"): return
	var quit: Button=UI.find_nav(game.screen,"quit")
	quit.grab_focus(); await UI.shot(game,"title-quit-focused")
	# The real Exit handler quits at frame end. Record its signal before that happens;
	# the external isolated harness must independently observe exit code 0 without timeout.
	quit.pressed.connect(func(): UI.write(game,{"complete":true,"rendered":true,"no_save_store":game.save_store==null,"run_id":game.smoke_run_id,"title_shown":true,"start_button":true,"exit_button_pressed":true,"layout":layout},"title-review.json"))
	await game.click_control(quit)
