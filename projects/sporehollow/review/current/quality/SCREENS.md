# 修正前後の実ゲーム画面

修正前64枚は `../ui_survey/`（cf004ab）、修正後は本フォルダ。1280×800、seed31・同じ撮影シナリオ。9匹・2住人・別解像度は追加fixtureです。自然プレイ連続写真ではありません。

撮影時はコミット前の作業ツリー。全game GDScriptのSHA256を保存し、実装コミットとの一致を照合しました。差はinventory_view.gdの空行のタブ除去だけです（DELIVERY.json）。画像を合成していません。

| 画面／条件 | 修正前 | 修正後 |
|---|---|---|
| 牧場主選択・休息・装備・図鑑・持ち物 | [前](../ui_survey/03_keeper.png) | [後](03_keeper.png) |
| 物資の所在 | [前](../ui_survey/04_inventory.png) | [後](04_inventory.png) |
| アーキテクト / すべて | [前](../ui_survey/06_architect_0.png) | [後](06_architect_0.png) |
| 備蓄・居住ゾーン | [前](../ui_survey/08_zones.png) | [後](08_zones.png) |
| 徴兵中の命令制限 | [前](../ui_survey/09_drafted.png) | [後](09_drafted.png) |
| 動物一覧 | [前](../ui_survey/10_animals.png) | [後](10_animals.png) |
| 柴犬選択・対応指示 | [前](../ui_survey/11_shiba.png) | [後](11_shiba.png) |
| 家畜のと殺予約 | [前](../ui_survey/14_slaughter.png) | [後](14_slaughter.png) |
| 夜の祈り・像の修理 | [前](../ui_survey/20_prayer.png) | [後](20_prayer.png) |
| 購入詳細 / 土 50 | [前](../ui_survey/26_detail_materials.png) | [後](26_detail_materials.png) |
| 購入詳細 / 木の長柄 | [前](../ui_survey/26_detail_items.png) | [後](26_detail_items.png) |
| 購入後の結果・所持金 | [前](../ui_survey/27_purchase_result.png) | [後](27_purchase_result.png) |
| 購入不能理由 | [前](../ui_survey/28_purchase_blocked.png) | [後](28_purchase_blocked.png) |
| 売却後の結果 | [前](../ui_survey/32_sell_result.png) | [後](32_sell_result.png) |
| 動物図鑑一覧 | [前](../ui_survey/34_book_animals.png) | [後](34_book_animals.png) |
| 柴犬詳細・Rarity・スキル | [前](../ui_survey/35_book_shiba.png) | [後](35_book_shiba.png) |
| 翌朝に敵が残った状態 | [前](../ui_survey/49_morning_threat.png) | [後](49_morning_threat.png) |
| 9匹の管理・選択カード分離 | 追加条件 | [後](50_animals_nine.png) |
| 9匹の管理・末尾へスクロール | 追加条件 | [後](53_animals_scroll.png) |
| 2人の役割表 | 追加条件 | [後](51_two_workers.png) |
| 追加住人の共通状態カード | 追加条件 | [後](54_worker.png) |
| 人物選択1600×1000 | 追加条件 | [後](52_keeper_1600.png) |

実画像で確認：3匹が全行表示、9匹末尾へのホイール、個体カードとの分離、黄金像を覆わない用途別操作、材料不足、人物ゲージ・装備・徴兵の集約、売買結果と所持数。

既存の本・商人・正式動物は維持。汎用管理アイコン、空いた中央景観、夜の光などは最終品質ではありません。静止画は人間の操作の快適さ・音・面白さの合格証拠ではありません。
