extends SceneTree
const Farm=preload("res://game/world.gd")
var g
var out=""
var shots=[]
var checks=[]
func _initialize():call_deferred("run")
func check(ok,note):
 checks.append({"passed":ok,"check":note})
 if not ok:push_error(note)
func fresh(extra=false):
 var c=Farm.new_campaign()
 if extra:
  c.animals.append({"id":2,"name":"こっこ","species":"hen","category":"bird","lv":1,"xp":0,"loyalty":0,"position":[21,21]})
  c.animals.append({"id":3,"name":"みけ","species":"cat","category":"cat","lv":1,"xp":0,"loyalty":0,"position":[24,21]})
 var w=Farm.new(c,31).begin_day();w.story.intro_seen=true;w.paused=true;return w
func scene(w):
 if is_instance_valid(g):g.queue_free();await process_frame
 g=load("res://game/main.tscn").instantiate();g.automated=true;g.world=w;root.add_child(g)
 await process_frame;await process_frame;g.set_process(false);g.audio.set_process(false);g.reset_view();g.neutral();g.refresh()
func texts(node,rows):
 if node is Control and node.is_visible_in_tree():
  if node is Label or node is BaseButton:
   var t=node.text if node is Label or node is Button else ""
   if t!="":rows.append({"name":str(node.name),"text":t,"rect":str(node.get_global_rect()),"disabled":node.disabled if node is BaseButton else false,"tooltip":node.tooltip_text})
 for child in node.get_children():texts(child,rows)
func shot(id,title,fixture="通常のseed31。時間停止、画面だけ操作"):
 g.refresh_jobs();g.queue_redraw();g.hud.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
 check(root.get_texture().get_image().save_png(out+"/"+id+".png")==OK,"capture "+id)
 var rows=[];texts(g,rows)
 shots.append({"file":id+".png","title":title,"fixture":fixture,"tick":g.world.tick,"calendar":g.world.calendar_ticks,"phase":g.world.phase,"group":g.group,"tool":g.tool,"selected":str(g.selected),"visible_controls":rows})
 FileAccess.open(out+"/ui-survey.json",FileAccess.WRITE).store_string(JSON.stringify({"source_commit":OS.get_environment("FARM_REVIEW_COMMIT"),"shots":shots,"checks":checks},"  "))
func settle_book():
 g.clock=g.book_started+1.0;g._process(0.0);await process_frame
func extra_checks():pass
func run():
 out=OS.get_environment("FARM_REVIEW_OUTPUT")
 if out=="" or "--isolated-review" not in OS.get_cmdline_user_args():quit(2);return
 root.size=Vector2i(1280,800);root.content_scale_size=Vector2i(1280,800)
 await scene(fresh());await shot("01_field","初期牧場・通常HUD")
 g.camera.zoom=Vector2.ONE*0.48;g.camera.position=Vector2(1200,714);g.camera.force_update_scroll();await shot("02_map","マップ全景")
 g.reset_view();g.choose_walk();await shot("03_keeper","牧場主選択・休息・装備・図鑑・持ち物")
 g.buttons.inventory.pressed.emit();await shot("04_inventory","物資の所在");g.StoryView.close(g)
 g.neutral();g.colony_page="roles";g.refresh();await shot("05_roles","役割優先順位")
 for category in g.ColonyPanels.Model.ARCHITECT:
  g.neutral();g.select_group(0);g.ColonyPanels.architecture_category(g,category)
  await shot("06_architect_%d"%g.ColonyPanels.Model.ARCHITECT.keys().find(category),"アーキテクト / "+category)
 g.neutral();g.group=4;g.item_commands.select(g,"haul");await shot("07_commands","命令・回収/禁止/許可/解除/採掘/伐採")
 var w=g.world;var z=Vector2i(20,22)
 w.Zones.create(w,"residential",z,z+Vector2i(3,1));g.neutral();g.select_group(0);g.ColonyPanels.architecture_category(g,"ゾーン");await shot("08_zones","備蓄・居住ゾーン","通常マップに居住ゾーンを追加")
 g.neutral();g.choose_walk();g.world.Work.set_drafted(w,"keeper",true);g.refresh();await shot("09_drafted","徴兵中の命令制限");check(g.buttons.keeper_rest.disabled and g.buttons.resume_jobs.disabled,"Drafted ordinary work buttons disabled")
 await scene(fresh(true));g.select_group(1);await shot("10_animals","動物一覧","鶏・猫を追加したUI確認fixture")
 g.choose_animal(1);await shot("11_shiba","柴犬選択・対応指示","鶏・猫追加fixture")
 g.ColonyPanels.animal_action(g,1,"train");await shot("12_training","柴犬の調教予約","動物一覧の調教コールバック。停止中")
 g.choose_animal(2);await shot("13_hen","鶏選択・家畜管理","鶏追加fixture")
 g.LivestockControls.designate(g,2);await shot("14_slaughter","家畜のと殺予約","鶏追加fixture。予約のみ、実行しない")
 g.choose_animal(3);await shot("15_cat","猫選択・おまかせ／誘導","猫追加fixture")
 await scene(fresh());w=g.world
 var pos=w.keeper.pos+Vector2i(-3,0)
 check(w.act("wall",pos),"Reserve construction")
 g.neutral();g.select_group(0);g.select_tool("wall");await shot("16_construction_plan","建築予約・作業一覧")
 w.paused=false
 for i in range(240):
  w.step()
  if w.live_structure(pos):break
 w.paused=true;check(w.live_structure(pos),"Construction completed through World.step")
 if w.live_structure(pos):g.select_building(pos,"structure");await shot("17_structure","完成建物の操作","通常仕事で土壁を完成")
 var big=w.mountains.values().filter(func(r):return r.kind=="large")
 if not big.is_empty():
  g.neutral();g.selected={"kind":"mountain","id":big[0].id};g.camera.position=g.center(big[0].pos+Vector2i(2,2));g.camera.zoom=Vector2.ONE*1.2;g.camera.force_update_scroll();g.refresh();await shot("18_mountain","大岩山の選択・採掘")
 await scene(fresh());w=g.world;g.neutral();g.selected={"kind":"idol","pos":w.Story.at(w)};g.refresh();await shot("19_idol","黄金像・調査")
 w.campaign.day=2;w.calendar_ticks=1728+1100;w.phase="defend";w.story.investigated=true;w.story.idol.hp-=20;g.refresh();await shot("20_prayer","夜の祈り・像の修理","2日目夜、調査済み、像HPを20減らしたfixture")
 await scene(fresh());w=g.world;w.tick=24;w.calendar_ticks=24;g.clock=8;g.arrival_started=0;g.camera.position=g.center(w.MERCHANT_CELL+Vector2i(2,3));g.camera.zoom=Vector2.ONE*1.3;g.camera.force_update_scroll();g.choose_walk();g.merchant_context=true;g.refresh();await shot("21_merchant","商人・吹き出し・交渉","商人来訪中の6ゲーム秒へ設定")
 check(w.request_merchant("keeper"),"Merchant negotiation reserved")
 w.paused=false
 for i in range(400):
  w.step()
  if w.merchant_approach!=null and w.keeper.pos==w.merchant_approach:break
 w.paused=true;g.open_market();check(g.field_shop,"Merchant approach opens choice")
 await shot("22_merchant_choice","商人の買い物／図鑑の選択","交渉仕事で実際に接近、到着後にメニュー")
 g.enter_market();await shot("23_market_home","ショップ入口・買う／売る")
 g.shop_choose("buy","animals");await shot("24_buy_categories","購入カテゴリ")
 for category in g.MARKET_CATEGORIES:
  g.choose_category(category);await shot("25_buy_"+category,"購入一覧 / "+g.MARKET_CATEGORIES[category][0])
  var rows=g.shop_rows(category)
  if not rows.is_empty():
   g.inspect_product(rows[0])
   await shot("26_detail_"+category,"購入詳細 / "+g.product_title(rows[0]))
 g.shop_choose("buy","materials");g.choose_category("materials");var materials=g.shop_rows()
 if not materials.is_empty():
  g.inspect_product(materials[0]);g.trade(materials[0].id,-1);await shot("27_purchase_result","購入後の結果・所持金")
  w.campaign.gold=0;g.refresh();await shot("28_purchase_blocked","購入不能理由","所持金0Gへ設定。取引不能状態のfixture")
 g.shop_choose("sell","materials");await shot("29_sell_categories","売却カテゴリ")
 for category in g.MARKET_CATEGORIES:
  g.choose_category(category);await shot("30_sell_"+category,"売却一覧 / "+g.MARKET_CATEGORIES[category][0])
 g.shop_choose("sell","materials");g.choose_category("materials");materials=g.shop_rows()
 if not materials.is_empty():
  g.inspect_product(materials[0]);await shot("31_sell_detail","売却詳細");g.trade(materials[0].id,-1);await shot("32_sell_result","売却後の結果")
 await scene(fresh(true));g.open_book();g.clock=g.book_started+0.22;g._process(0);await shot("33_book_opening","図鑑を開く途中","UI演出時刻を0.22秒へ設定。鶏・猫追加")
 await settle_book();await shot("34_book_animals","動物図鑑一覧","鶏・猫追加fixture")
 g.book_detail(1);await settle_book();await shot("35_book_shiba","柴犬詳細・Rarity・スキル")
 g.open_name();await shot("36_book_naming","命名入力。未保存");g.rename_open=false;g.refresh()
 g.turn_book(1);g.clock=g.book_started+0.21;g._process(0);await shot("37_book_turn","図鑑ページ送り途中","UI演出時刻を0.21秒へ設定")
 await settle_book();g.switch_book_section("enemies");await shot("38_book_unknown_enemies","未発見の敵一覧")
 for id in g.ProgressView.ENEMY_ORDER:g.world.campaign.enemy_knowledge[id]=2
 g.refresh();await shot("39_book_known_enemies","発見済みの敵一覧","敵知識を全種2にした図鑑確認fixture")
 g.book_detail(0);await settle_book();await shot("40_book_enemy_detail","敵詳細・スキル","敵知識を全種2に設定")
 await scene(fresh());g.toggle_menu();await shot("41_menu","保存・読込・終了メニュー")
 g.buttons.menu_save.pressed.emit();await shot("42_saved","保存完了・読込可能","隔離ユーザーデータだけへ保存")
 g.buttons.menu_load.pressed.emit();await shot("43_loaded","読み込み完了","隔離セーブだけを復元")
 for page in ["help","version","new"]:
  g.ColonyMenu.page(g,page);await shot("44_menu_"+page,"メニュー / "+page)
 await scene(fresh());g.StoryView.open(g,"intro");await shot("45_intro","導入文章")
 await scene(fresh());g.debug_view=true;g.world.debug_enabled=true;g.refresh();await shot("46_debug","F3 DEBUG設定")
 await scene(fresh());w=g.world;w.calendar_ticks=1100;w.phase="defend";w.spawn_schedule.clear();w.early_clear=true;g.refresh();await shot("47_night_safe","夜間・朝まで休む","20時台へ設定。襲撃予定と残敵なし")
 w.spawn_enemy({"entry":Vector2i(0,10),"archetype":"salaryman","role":"fighter"});w.enemies.back().pos=w.keeper.pos+Vector2i(4,0);w.enemies.back().arrival_complete=true;w.early_clear=false;g.refresh();await shot("48_night_threat","夜間の敵・休息制限","サラリーマン1体を近傍へ配置。停止中")
 w.calendar_ticks=1727;w.last_daily_day=1;w.paused=false;w.step();w.paused=true;g.refresh();await shot("49_morning_threat","翌朝に敵が残った状態","通常tickで夜明けを越す")
 await extra_checks()
 check(shots.size()>=50,"Broad screen coverage")
 FileAccess.open(out+"/ui-survey.json",FileAccess.WRITE).store_string(JSON.stringify({"source_commit":OS.get_environment("FARM_REVIEW_COMMIT"),"shots":shots,"checks":checks,"failures":checks.filter(func(c):return not c.passed).size()},"  "))
 g.queue_free();await process_frame;quit(0 if checks.all(func(c):return c.passed) else 4)
