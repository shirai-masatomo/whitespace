## 現在の通常入口：0.8.1（2026-10-20）

[通常の起動・版・配布](review/current/README.md)／[今回のレビュー修正01〜09・実画面比較](review/ui-feedback/review-fixes-0.8.1/index.html)／[操作方法](review/ui-feedback/review-fixes-0.8.1/OPERATIONS.md)。mainで開発。確認済み0.8.1へ通常入口を更新。保存なしで、終了時に進行をリセット。E＝左主操作、I＝所持品・装備、C＝ステータス、Space＝停止／再開、X／右クリック＝画面に明示した取消・見送り。詳細は現行PLAYを参照。

CI39408062823成功、実行ソース8b92fd85ffab2b8203ed19a5c785471968d52091。実装・限定確認済み、利用者の見た目・操作感の評価は未評価。旧版・原画像・評価履歴は保持。

## 過去の開発履歴（以下の版・入口・保存説明は当時の記録）

**以下に出てくる「最新」「現在地」「通常版」や自動保存・続きからの説明は現行案内ではありません。現在の正本は冒頭のreview/currentです。**

## 工程2・最初の単位を実装

装備耐久・破損・町の修理と旧保存保全を[PR #6](https://github.com/shirai-masatomo/whitespace/pull/6)へ反映。CI39122064852成功。[画像・別セーブ試遊](review/phase2-equipment/index.html) / [未決事項の一括一覧](docs/PHASE_02_OPEN_DECISIONS.md)。通常入口0.4.6を維持し、工程2全体は進行中。モデル設定は変更しない。

# 工程1受入・工程2へ移行

2026-10-18、既存証拠で[工程1の受入条件](docs/PHASE_01_ACCEPTANCE.md)を達成と判定。試遊待ちで停止せず工程2へ進む。通常入口0.4.6は維持。以下の工程1未完了記述は履歴。

# Dive In Under

> **最新開発版0.4.10**：採用許可済みE06〜E08静止画像を組込み。[比較・別セーブ試遊](review/area1-art-development/index.html)／[実EXE確認と残件](review/area1-art-development/README.md)。通常の起動入口と既存配布は0.4.6を維持。以下の0.4.9以前の画像待ちは履歴。工程1の最終受入・通常画面の人間による実操作は未完了。

> **開発版0.4.9**：毒・暗闇・麻痺と短い表示を先行実装。[状態の契約と検証](docs/STATUS_PILOT_IMPLEMENTATION.md)。確認入口は0.4.6のまま。新敵静止画・人間の実操作確認が残り、工程1全体は未完了。

> **開発ブランチの更新（2026-10-18）**：S105「防御」は初期所持・SP不足時は通常攻撃、手番消費の仮仕様で実装済み。確認入口と配布は0.4.6を維持。新敵E06〜E08の通常遭遇・報酬・旧保存互換は開発版0.4.8で実装・検証済み。静止画3枚は未納品のためID仮表示。[開発版の証拠](review/area1-development/README.md)・[制作依頼](docs/AREA1_ENEMY_IMAGE_REQUEST.md)。[検証方針](docs/dot/TEST_POLICY.md)に従い、工程1の大量統計・難易度分析は打切り。[進捗](docs/dot/PROGRESS.md)。

**地下へ潜るほど報酬は増えるが、死と装備の消耗を伴う、フルオート戦闘ダンジョンRPG。**

## 現在地：初回通常化・ボス床面修正 0.4.6

**[確認入口・ZIP・実画面・ログ](review/current/README.md)** ／ [開発環境](docs/DEVELOPMENT.md) ／ [Draft PR #5](https://github.com/shirai-masatomo/whitespace/pull/5)。初回から1Fの通常探索と帰還が可能。旧セーブの育成・装備を保持して移行。1000固定seed全件10F突破、旧6種の実EXE移行・再起動、通常／ボスの連続床面を隔離確認。**毒・暗闇・麻痺・防御態勢と短いエフェクトは未実装。工程1全体は未完了。**

- **[SPEC.md：全体仕様の正本](SPEC.md)** — ゲームの大枠と確定要件
- **[現行2DドットUI参考3枚](docs/UI_MOCKS.md)** — 探索・戦闘・装備／ステータス。旧4枚は履歴へ
- **[仕様と実装状況の表](docs/IMPLEMENTATION_STATUS.md)** — 何が「今」「次」「後」なのか
- **[設計判断台帳](docs/DESIGN_DECISIONS.md)** — 既に決めたことと確認事項
- **[初期EXE～10Fプロトタイプの進め方](docs/PROTOTYPE_10F.md)**
- **[戦闘シミュレーターの要件](docs/BATTLE_SIMULATION.md)** — 単発戦闘の共通コア・固定seed統計・同条件比較を実装。通常新規1000seedの反復探索も検証済み

### 自律開発への引き継ぎ

- **[最初にDotへ送信する指示](docs/dot/00_START.md)** — これをDotのチャットに送信すると自律開発を開始
- **[工程1〜7のプロンプト・完了条件](docs/dot/README.md)** — 工程1は主人公単独で反復探索・10F突破まで。仲間は工程5
- **[工程進捗](docs/dot/PROGRESS.md)** — どの工程が実装・検証されたか
- **[Dot自律運用](AUTONOMY.md)** ／ **[Codex向けAGENTS.md](AGENTS.md)**

### 直近の目標

Windows EXEで **新規開始 → 主人公単独で1Fから通常探索（最初から帰還可能） → 帰還またはHP0による通常死亡 → 町 → 倉庫・装備・再探索 → 10Fボス突破**を、現行2DドットUIで遊べるようにする。**初回必死イベントと帰還禁止は廃止**。[実装変更依頼](docs/dot/CHANGE_2026-10-17_FIRST_EXPEDITION.md)。仲間は工程5。

## 作業中の工程1

- [Codexブランチのレビュー入口](https://github.com/shirai-masatomo/whitespace/blob/dot/dive-in-under/phase-01/projects/dive-in-under/review/current/README.md) — Godot単発戦闘・検証・UIの進捗。**工程1全体は未完了**。
- mainでは確定仕様と設計を更新中。作業ブランチのコードと設計文書は統合時に照合する。

- **[初期装備・バックパック・父親の風呂敷・死亡ロスト、帰還・出撃制限の検討](SPEC.md#初期装備持ち物死亡時の喪失確定仕様)** — 確定要件と未採用の将来案を区別して記録。詳細は[アイテム](docs/ITEMS.md)／[判断台帳](docs/DESIGN_DECISIONS.md)。
## 将来の主要仕様

- 最大6人：主人公＋人間2名、各人間に動物・魔物の配下1体。
- 人間同士の友好度・連携、配下との忠実度、行動順を決める素早さ。
- **8属性（光／闇は相互弱点・無は中立）、状態異常17種類、追加戦闘能力と能力変化**は[COMBAT](docs/COMBAT.md)。
- **装備の個体差・ランダム追加能力・印による強化**は[ITEMS](docs/ITEMS.md)に将来仕様として登録。
- 人間の装備は右手・左手（武器／盾）＋防具4＋装飾5＝11枠。
- B100X風のスキル自動選択、Darkest Dungeon II風の関係効果は今後予定。Wizardry風の隊列は候補。
- 10Fごとボス、1F・11F・21F…は到達すると開始地点が解放。

## 詳細台帳

[階層（敵出現率・Lv・宝箱確率）](docs/FLOORS.md) / [敵（基礎能力・EXP・Gold・ドロップ）](docs/ENEMIES.md) / [アイテム](docs/ITEMS.md) / [仲間](docs/ALLIES.md) / [イベント](docs/EVENTS.md) / [戦闘共通仕様](docs/COMBAT.md) / [スキル一覧](docs/SKILLS.md) / [黄金像](docs/SHRINE.md) / [参考資料](docs/RESEARCH.md)

**旧ブラウザ試作**：[過去の試作ZIP](Dive-In-Under-10F-prototype.zip) ／ [ソース](prototype/index.html)。古いパーティ構造など現行と異なる仕様を含むため参考として無変更で保全し、新Windows基盤へ直接移植していません。

## 地下1〜10F：青い滝洞窟の敵生態系

[エリア資料・静止画像の制作要件](docs/BIOME_01_10F.md)／[階層別の敵種確率とLv](docs/FLOORS.md)／[敵の仮能力・ドロップ](docs/ENEMIES.md)。**1〜5F＝洞窟小型生物、6〜9F＝水辺の3種、10F＝門番石像**。既存のPC実装へ反映したかはDotの工程1レビューで別途確認。
