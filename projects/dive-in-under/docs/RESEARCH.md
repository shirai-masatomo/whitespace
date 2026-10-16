# 参考作品の調査（設計段階／採用未決）

公式説明・開発者の設計解説を優先。下表の特徴は**その作品の事実**であり、Dive In Underへの採用はまだ決定していない。

| 参考作品 | 事実・確認できた特徴 | Dive In Underへの示唆 |
| --- | --- | --- |
| **B100 / B100X** | フルオートバトルと装備合成が主軸。B100Xでは事前セットしたスキルから条件を満たすものを自動選択。余計なスキルを増やすほど主力行動が出にくくなる場合がある。 | **何を装備し、どの行動を優先させるか**をプレイヤーの戦略にする。スキル構成は単なる上位互換でない |
| **Wizardry（初期作）** | 毎ラウンドの行動をプレイヤーが指定する**手動戦闘**。前列・後列で役割と攻撃可能範囲が違う。 | 自動戦闘としては流用せず、編成・前後列・資源管理・死亡リスクの考え方を参考にする |
| **パワプロクンポケット11 裏サクセス** | 『怪奇ハタ人間』は主人公の行動を選び、仲間が作戦に沿って行動するターン制。地下100階の攻略・仲間育成がある。 | 仲間の役割・作戦・危険な探索を参考に。今回は主人公の行動も自動化する |
| **Slay the Spire** | 経路を選ぶことで強敵・イベント・休息・報酬のリスクを取捨選択する構造。 | 経路選択は今回採らないが、**リスクを見てから進む意思決定**は必要 |
| **Darkest Dungeon II** | 「Affinity System」では旅で仲間同士の関係が良くも悪くも変わり、戦闘の相乗効果／障害になる。 | **人間同士の友好度→見える連携**の具体的な参考例 |

## 出典
- [B100X 概要（公式）](https://nussygame.com/b100x/about/)
- [B100X デザイン：ジョブとスキル（開発者解説）](https://nussygame.com/b100x/611631856282222592-html/)
- [B100X デザイン：アイテム合成（開発者解説）](https://nussygame.com/b100x/190908662048-html/)
- [Wizardry 初期作の戦闘説明（マニュアル転載）](https://manualzz.com/doc/64034679/sir-tech-wizardry-proving-grounds-of-the-mad-overlord--kn...)
- [パワポケ11 裏サクセス・戦闘解説（非公式）](https://pawapoke.heiseiretrogame.com/grouper-human-battle-basics/)
- [Darkest Dungeon II・Affinity System（開発元公式）](https://www.darkestdungeon.com/darkest-dungeon-2/about/)
- [Steamworks: Steamへのビルドアップロード（公式）](https://partner.steamgames.com/doc/sdk/uploading)
- [Steamworks API概要（公式）](https://partner.steamgames.com/doc/sdk/api)

## EXE配布についての確認
- Steamではゲームの実行ファイルと必要なデータを**ビルド（Depot）としてアップロード**する。したがって配布物はEXE「だけ」に限らなくてよい。
- Steamworks APIとの連携はSteamで公開する際の**必須条件ではない**（実績・クラウド等の機能では有用）。
- **選定エンジン・出力形式・セーブ移行戦略は未決定**。現時点で新しいゲーム実装は行わない。
