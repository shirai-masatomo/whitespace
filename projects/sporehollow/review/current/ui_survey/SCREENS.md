# 画面一覧

すべて今回の実ゲーム描画。素材見本や旧版の画面を混ぜていません。番号の枝番も別画面で、合計64枚です。

静止中の状態や追加個体などは再現用fixtureです。全画面が一回の自然なプレイの連続記録という意味ではありません。各画面のUI文字・矩形・disabled状態は [ui-survey.json](ui-survey.json) にあります。

## 牧場・人物・仕事・建築・動物

### 01_field — 初期牧場・通常HUD

![初期牧場・通常HUD](01_field.png)

通常のseed31。時間停止、画面だけ操作。world tick=0 / calendar=0。

### 02_map — マップ全景

![マップ全景](02_map.png)

通常のseed31。時間停止、画面だけ操作。world tick=0 / calendar=0。

### 03_keeper — 牧場主選択・休息・装備・図鑑・持ち物

![牧場主選択・休息・装備・図鑑・持ち物](03_keeper.png)

通常のseed31。時間停止、画面だけ操作。world tick=0 / calendar=0。

### 04_inventory — 物資の所在

![物資の所在](04_inventory.png)

通常のseed31。時間停止、画面だけ操作。world tick=0 / calendar=0。

### 05_roles — 役割優先順位

![役割優先順位](05_roles.png)

通常のseed31。時間停止、画面だけ操作。world tick=0 / calendar=0。

### 06_architect_0 — アーキテクト / すべて

![アーキテクト / すべて](06_architect_0.png)

通常のseed31。時間停止、画面だけ操作。world tick=0 / calendar=0。

### 06_architect_1 — アーキテクト / 壁と扉

![アーキテクト / 壁と扉](06_architect_1.png)

通常のseed31。時間停止、画面だけ操作。world tick=0 / calendar=0。

### 06_architect_2 — アーキテクト / 床

![アーキテクト / 床](06_architect_2.png)

通常のseed31。時間停止、画面だけ操作。world tick=0 / calendar=0。

### 06_architect_3 — アーキテクト / 飼育

![アーキテクト / 飼育](06_architect_3.png)

通常のseed31。時間停止、画面だけ操作。world tick=0 / calendar=0。

### 06_architect_4 — アーキテクト / 設置

![アーキテクト / 設置](06_architect_4.png)

通常のseed31。時間停止、画面だけ操作。world tick=0 / calendar=0。

### 06_architect_5 — アーキテクト / ゾーン

![アーキテクト / ゾーン](06_architect_5.png)

通常のseed31。時間停止、画面だけ操作。world tick=0 / calendar=0。

### 07_commands — 命令・回収/禁止/許可/解除/採掘/伐採

![命令・回収/禁止/許可/解除/採掘/伐採](07_commands.png)

通常のseed31。時間停止、画面だけ操作。world tick=0 / calendar=0。

### 08_zones — 備蓄・居住ゾーン

![備蓄・居住ゾーン](08_zones.png)

通常マップに居住ゾーンを追加。world tick=0 / calendar=0。

### 09_drafted — 徴兵中の命令制限

![徴兵中の命令制限](09_drafted.png)

通常のseed31。時間停止、画面だけ操作。world tick=0 / calendar=0。

### 10_animals — 動物一覧

![動物一覧](10_animals.png)

鶏・猫を追加したUI確認fixture。world tick=0 / calendar=0。

### 11_shiba — 柴犬選択・対応指示

![柴犬選択・対応指示](11_shiba.png)

鶏・猫追加fixture。world tick=0 / calendar=0。

### 12_training — 柴犬の調教予約

![柴犬の調教予約](12_training.png)

動物一覧の調教コールバック。停止中。world tick=0 / calendar=0。

### 13_hen — 鶏選択・家畜管理

![鶏選択・家畜管理](13_hen.png)

鶏追加fixture。world tick=0 / calendar=0。

### 14_slaughter — 家畜のと殺予約

![家畜のと殺予約](14_slaughter.png)

鶏追加fixture。予約のみ、実行しない。world tick=0 / calendar=0。

### 15_cat — 猫選択・おまかせ／誘導

![猫選択・おまかせ／誘導](15_cat.png)

猫追加fixture。world tick=0 / calendar=0。

### 16_construction_plan — 建築予約・作業一覧

![建築予約・作業一覧](16_construction_plan.png)

通常のseed31。時間停止、画面だけ操作。world tick=0 / calendar=0。

### 17_structure — 完成建物の操作

![完成建物の操作](17_structure.png)

通常仕事で土壁を完成。world tick=21 / calendar=21。

### 18_mountain — 大岩山の選択・採掘

![大岩山の選択・採掘](18_mountain.png)

通常のseed31。時間停止、画面だけ操作。world tick=21 / calendar=21。

### 19_idol — 黄金像・調査

![黄金像・調査](19_idol.png)

通常のseed31。時間停止、画面だけ操作。world tick=0 / calendar=0。

### 20_prayer — 夜の祈り・像の修理

![夜の祈り・像の修理](20_prayer.png)

2日目夜、調査済み、像HPを20減らしたfixture。world tick=0 / calendar=2828。

## 行商人・購入・売却

### 21_merchant — 商人・交渉（このフレームに台詞は出ていません）

![商人・交渉（このフレームに台詞は出ていません）](21_merchant.png)

商人来訪中の6ゲーム秒へ設定。world tick=24 / calendar=24。

### 22_merchant_choice — 商人の買い物／図鑑の選択

![商人の買い物／図鑑の選択](22_merchant_choice.png)

交渉仕事で実際に接近、到着後にメニュー。world tick=74 / calendar=74。

### 23_market_home — ショップ入口・買う／売る

![ショップ入口・買う／売る](23_market_home.png)

通常のseed31。時間停止、画面だけ操作。world tick=74 / calendar=74。

### 24_buy_categories — 購入カテゴリ

![購入カテゴリ](24_buy_categories.png)

通常のseed31。時間停止、画面だけ操作。world tick=74 / calendar=74。

### 25_buy_animals — 購入一覧 / 動物

![購入一覧 / 動物](25_buy_animals.png)

通常のseed31。時間停止、画面だけ操作。world tick=74 / calendar=74。

### 26_detail_animals — 購入詳細 / 鶏 Lv1

![購入詳細 / 鶏 Lv1](26_detail_animals.png)

通常のseed31。時間停止、画面だけ操作。world tick=74 / calendar=74。

### 25_buy_materials — 購入一覧 / 資材

![購入一覧 / 資材](25_buy_materials.png)

通常のseed31。時間停止、画面だけ操作。world tick=74 / calendar=74。

### 26_detail_materials — 購入詳細 / 土 50

![購入詳細 / 土 50](26_detail_materials.png)

通常のseed31。時間停止、画面だけ操作。world tick=74 / calendar=74。

### 25_buy_facilities — 購入一覧 / 施設

![購入一覧 / 施設](25_buy_facilities.png)

通常のseed31。時間停止、画面だけ操作。world tick=74 / calendar=74。

### 25_buy_items — 購入一覧 / 小物と恵み

![購入一覧 / 小物と恵み](25_buy_items.png)

通常のseed31。時間停止、画面だけ操作。world tick=74 / calendar=74。

### 26_detail_items — 購入詳細 / 木の長柄

![購入詳細 / 木の長柄](26_detail_items.png)

通常のseed31。時間停止、画面だけ操作。world tick=74 / calendar=74。

### 27_purchase_result — 購入後の結果・所持金

![購入後の結果・所持金](27_purchase_result.png)

通常のseed31。時間停止、画面だけ操作。world tick=74 / calendar=74。

### 28_purchase_blocked — 購入不能理由

![購入不能理由](28_purchase_blocked.png)

所持金0Gへ設定。取引不能状態のfixture。world tick=74 / calendar=74。

### 29_sell_categories — 売却カテゴリ

![売却カテゴリ](29_sell_categories.png)

通常のseed31。時間停止、画面だけ操作。world tick=74 / calendar=74。

### 30_sell_animals — 売却一覧 / 動物

![売却一覧 / 動物](30_sell_animals.png)

通常のseed31。時間停止、画面だけ操作。world tick=74 / calendar=74。

### 30_sell_materials — 売却一覧 / 資材

![売却一覧 / 資材](30_sell_materials.png)

通常のseed31。時間停止、画面だけ操作。world tick=74 / calendar=74。

### 30_sell_facilities — 売却一覧 / 施設

![売却一覧 / 施設](30_sell_facilities.png)

通常のseed31。時間停止、画面だけ操作。world tick=74 / calendar=74。

### 30_sell_items — 売却一覧 / 小物と恵み

![売却一覧 / 小物と恵み](30_sell_items.png)

通常のseed31。時間停止、画面だけ操作。world tick=74 / calendar=74。

### 31_sell_detail — 売却詳細

![売却詳細](31_sell_detail.png)

通常のseed31。時間停止、画面だけ操作。world tick=74 / calendar=74。

### 32_sell_result — 売却後の結果

![売却後の結果](32_sell_result.png)

通常のseed31。時間停止、画面だけ操作。world tick=74 / calendar=74。

## 図鑑・開閉・ページ送り

### 33_book_opening — 図鑑を開く途中

![図鑑を開く途中](33_book_opening.png)

UI演出時刻を0.22秒へ設定。鶏・猫追加。world tick=0 / calendar=0。

### 34_book_animals — 動物図鑑一覧

![動物図鑑一覧](34_book_animals.png)

鶏・猫追加fixture。world tick=0 / calendar=0。

### 35_book_shiba — 柴犬詳細・Rarity・スキル

![柴犬詳細・Rarity・スキル](35_book_shiba.png)

通常のseed31。時間停止、画面だけ操作。world tick=0 / calendar=0。

### 36_book_naming — 命名入力。未保存

![命名入力。未保存](36_book_naming.png)

通常のseed31。時間停止、画面だけ操作。world tick=0 / calendar=0。

### 37_book_turn — 図鑑ページ送り途中

![図鑑ページ送り途中](37_book_turn.png)

UI演出時刻を0.21秒へ設定。world tick=0 / calendar=0。

### 38_book_unknown_enemies — 未発見の敵一覧

![未発見の敵一覧](38_book_unknown_enemies.png)

通常のseed31。時間停止、画面だけ操作。world tick=0 / calendar=0。

### 39_book_known_enemies — 発見済みの敵一覧

![発見済みの敵一覧](39_book_known_enemies.png)

敵知識を全種2にした図鑑確認fixture。world tick=0 / calendar=0。

### 40_book_enemy_detail — 敵詳細・スキル

![敵詳細・スキル](40_book_enemy_detail.png)

敵知識を全種2に設定。world tick=0 / calendar=0。

## 保存・ヘルプ・デバッグ・昼夜

### 41_menu — 保存・読込・終了メニュー

![保存・読込・終了メニュー](41_menu.png)

通常のseed31。時間停止、画面だけ操作。world tick=0 / calendar=0。

### 42_saved — 保存完了・読込可能

![保存完了・読込可能](42_saved.png)

隔離ユーザーデータだけへ保存。world tick=0 / calendar=0。

### 43_loaded — 読み込み完了

![読み込み完了](43_loaded.png)

隔離セーブだけを復元。world tick=0 / calendar=0。

### 44_menu_help — メニュー / help

![メニュー / help](44_menu_help.png)

通常のseed31。時間停止、画面だけ操作。world tick=0 / calendar=0。

### 44_menu_version — メニュー / version

![メニュー / version](44_menu_version.png)

通常のseed31。時間停止、画面だけ操作。world tick=0 / calendar=0。

### 44_menu_new — メニュー / new

![メニュー / new](44_menu_new.png)

通常のseed31。時間停止、画面だけ操作。world tick=0 / calendar=0。

### 45_intro — 導入文章

![導入文章](45_intro.png)

通常のseed31。時間停止、画面だけ操作。world tick=0 / calendar=0。

### 46_debug — F3 DEBUG設定

![F3 DEBUG設定](46_debug.png)

通常のseed31。時間停止、画面だけ操作。world tick=0 / calendar=0。

### 47_night_safe — 夜間・朝まで休む

![夜間・朝まで休む](47_night_safe.png)

20時台へ設定。襲撃予定と残敵なし。world tick=0 / calendar=1100。

### 48_night_threat — 夜間の敵・休息制限

![夜間の敵・休息制限](48_night_threat.png)

サラリーマン1体を近傍へ配置。停止中。world tick=0 / calendar=1100。

### 49_morning_threat — 翌朝に敵が残った状態

![翌朝に敵が残った状態](49_morning_threat.png)

通常tickで夜明けを越す。world tick=1 / calendar=1728。
