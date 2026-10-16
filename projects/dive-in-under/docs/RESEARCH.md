# 参考作品と戦闘形式 — 2026-10-16調査

これは**引用元を伴う確認事項**であり、Dive In Underへ自動的に採用される仕様ではない。

| 作品 | 確認事項 | Dive In Underの参考点 |
| --- | --- | --- |
| B100 / B100X | B100シリーズはオートダンジョンRPG。B100Xはフルオートバトル、装備合成、オートスキル・ジョブ成長。 | 操作を少なくし、構築と周回に重みを置く |
| 初期Wizardry | 戦闘はラウンドごとに各キャラクターの行動を決める手動方式。隊列の前3人が通常攻撃の中心。 | 前後衛と資源管理、死亡に伴う意思決定。**Wizardry自体はフルオートではない** |
| パワポケ11 裏サクセス「怪奇ハタ人間」 | 主人公は行動を選択し、仲間は作戦に沿って自動で動く。第2章は地下探索と到達階層からのショートカットがある。 | 仲間の個性・成長・レベル差による危険の比較 |
| Slay the Spire | デッキ構築型の戦闘と、経路でイベント・休息・戦闘等を選ぶ構造。 | 危険と報酬の意思決定の方向性（今回は**経路選択を実装しない**） |

## 参考資料
- B100X公式: https://nussygame.com/b100x/about/
- B100公式: https://nussygame.com/b100/
- B100X Steam（操作フロー）: https://store.steampowered.com/app/1258780/B100X__Auto_Dungeon_RPG/
- 初期WizardryマニュアルのHTML転載: https://manualzz.com/doc/64034679/sir-tech-wizardry-proving-grounds-of-the-mad-overlord--kn...
- パワポケ11裏サクセスの戦闘説明（非公式攻略資料）: https://pawapoke.heiseiretrogame.com/grouper-human-battle-basics/
- パワポケ11裏サクセス第2章（非公式攻略資料）: https://w.atwiki.jp/poke11/pages/73.html

## 方針の提案
**ラウンド制を内部で回し、戦闘入力は不要・ログ閲覧は可能にする。** 主人公と仲間の行動優先順位、隊列、回復トリガーのカスタマイズは、基礎ループが楽しいことを確認してから足す。
