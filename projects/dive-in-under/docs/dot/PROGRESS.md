# Dive In Under — Dot自律開発 工程進捗

> **実証資料確認（2026-10-17）**：[作業ブランチのレビュー入口](https://github.com/shirai-masatomo/whitespace/blob/dot/dive-in-under/phase-01/projects/dive-in-under/review/current/README.md)（作業ブランチ上）に、Windows Codexによる**単発戦闘コア・142項目テスト／1000seed検証／Windows CI成功**の証拠あり。**工程1全体は未完了**。mainの本台帳は設計同期用で、ブランチの[最新進捗](https://github.com/shirai-masatomo/whitespace/blob/dot/dive-in-under/phase-01/projects/dive-in-under/docs/dot/PROGRESS.md)を優先して作業状態を確認する。工程1〜4は主人公単独、工程5で仲間。
>
> 工程単位の状態を本資料、機能単位の状態を[IMPLEMENTATION_STATUS.md](../IMPLEMENTATION_STATUS.md)で管理する。進捗状況は実際のテスト・成果物がなければ「完了」にしない。

| 工程 | 到達点 | 状態 | 検証証拠（PR／CI／Windows ZIP／実画面／シミュレーション） |
| --- | --- | --- | --- |
| **01** | **主人公単独・繰り返し探索／帰還／死亡→10F突破** | **進行中／基幹ループ0.2.0の実証あり・10F調整と画作りは未達** | [Draft PR #5](https://github.com/shirai-masatomo/whitespace/pull/5)・[検証入口](https://github.com/shirai-masatomo/whitespace/blob/dot/dive-in-under/phase-01/projects/dive-in-under/review/current/README.md)・[成功CI](https://github.com/shirai-masatomo/whitespace/actions/runs/39022931253)。レビュー0.2.0では探索・倉庫・初回死亡・帰還は実証資料あり。**通常育成での10F突破とPX参考に近いビジュアルは未完了** |
| **02** | ソロ用装備11枠・耐久・育成・経済・支給所 | **未着手** | なし |
| **03** | 階層・宝箱・ドロップ・イベント、黄金像のアイテム／装備 | **未着手** | なし |
| **04** | 主人公／敵の自動スキル・SP・状態異常・戦闘AI | **未着手** | なし |
| **05** | **ここで仲間導入**：人間3＋配下3・犬イベント・死亡 | **未着手** | なし |
| **06** | 友好度・忠実度・連携／隊列の評価 | **未着手** | なし |
| **07** | UI・難易度・アート・Windows試遊版の総合調整 | **未着手** | なし |

### 状態と更新方法

未着手 → 進行中 → 検証中 → 完了。またはブロック。DotはPR・CI・ビルドの証拠を記載し、完成していない作業を完了扱いしない。特に工程1は**初回強制死亡だけで終わらず、2回目以降の単独探索で10Fまで攻略・帰還できること**を確認する。

## 工程1の状態異常追加要件（設計のみ・実装未確認）

**毒・暗闇・麻痺・防御態勢**の先行実装、短い状態エフェクトとアイコン、固定シード検証を[PHASE_01.md](PHASE_01.md)の受入条件へ追加。**現時点でゲーム実装・検証済みとはみなさない**。10Fソロ攻略と2D参考画風の条件は維持。

## 次のタスク

PC Codexの工程1ブランチで、**通常の反復探索・成長・装備による10F突破の実測と、[2Dドット画作り受入基準](PHASE_01_VISUAL_TARGET.md)の達成**を優先する。今回mainの戦闘／装備追加仕様（[COMBAT](../COMBAT.md)、[ITEMS](../ITEMS.md)）は**将来設計であり現工程の前倒し実装ではない**。変更の取り込みは競合を確認して行う。
