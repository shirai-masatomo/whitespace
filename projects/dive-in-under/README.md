# Dive In Under

**地下へ潜るほど報酬は増えるが、死と装備の消耗を伴う、フルオート戦闘ダンジョンRPG。**

## 現在地：工程1の基幹ループを実装、10F攻略バランスは次の検証

**[今回の確認入口（ローカル起動・ZIP・実画面・素材一覧）](review/current/README.md)** ／ [開発環境](docs/DEVELOPMENT.md) ／ [Draft PR #5](https://github.com/shirai-masatomo/whitespace/pull/5)。探索・初回死亡1回・町・倉庫・装備・成長・保存再開まで実装。通常のソロ10F突破バランスと人間の試遊は後続です。

- **[SPEC.md：全体仕様の正本](SPEC.md)** — ゲームの大枠と確定要件
- **[現行2DドットUI参考3枚](docs/UI_MOCKS.md)** — 探索・戦闘・装備／ステータス。旧4枚は履歴へ
- **[仕様と実装状況の表](docs/IMPLEMENTATION_STATUS.md)** — 何が「今」「次」「後」なのか
- **[設計判断台帳](docs/DESIGN_DECISIONS.md)** — 既に決めたことと確認事項
- **[初期EXE～10Fプロトタイプの進め方](docs/PROTOTYPE_10F.md)**
- **[戦闘シミュレーターの要件](docs/BATTLE_SIMULATION.md)** — 単発戦闘の共通コア・固定seed統計・同条件比較を実装。継続探索は未実装

### 自律開発への引き継ぎ

- **[最初にDotへ送信する指示](docs/dot/00_START.md)** — これをDotのチャットに送信すると自律開発を開始
- **[工程1〜7のプロンプト・完了条件](docs/dot/README.md)** — 工程1は主人公単独で反復探索・10F突破まで。仲間は工程5
- **[工程進捗](docs/dot/PROGRESS.md)** — どの工程が実装・検証されたか
- **[Dot自律運用](AUTONOMY.md)** ／ **[Codex向けAGENTS.md](AGENTS.md)**

### 直近の目標

Windows EXEで **新規開始 → 主人公単独の初回探索（帰還不可） → 必ず死亡 → 町 → 倉庫／所持品／装備の整理 → 再探索・帰還**を、ある程度統一感のあるデザインで体験できるようにする。**工程1の前半で基幹ループを作り、同じ工程1で10Fを単独突破できるまで仕上げる。仲間は工程5まで入れない**。現在は保存を含む基幹ループまで実装・隔離EXE検証済み。

## 将来の主要仕様

- 最大6人：主人公＋人間2名、各人間に動物・魔物の配下1体。
- 人間同士の友好度・連携、配下との忠実度、行動順を決める素早さ。
- 人間の装備は右手・左手（武器／盾）＋防具4＋装飾5＝11枠。
- B100X風のスキル自動選択、Darkest Dungeon II風の関係効果は今後予定。Wizardry風の隊列は候補。
- 10Fごとボス、1F・11F・21F…は到達すると開始地点が解放。

## 詳細台帳

[階層（敵出現率・Lv・宝箱確率）](docs/FLOORS.md) / [敵（基礎能力・EXP・Gold・ドロップ）](docs/ENEMIES.md) / [アイテム](docs/ITEMS.md) / [仲間](docs/ALLIES.md) / [イベント](docs/EVENTS.md) / [戦闘共通仕様](docs/COMBAT.md) / [スキル一覧](docs/SKILLS.md) / [黄金像](docs/SHRINE.md) / [参考資料](docs/RESEARCH.md)

**旧ブラウザ試作**：[過去の試作ZIP](Dive-In-Under-10F-prototype.zip) ／ [ソース](prototype/index.html)。古いパーティ構造・初回帰還可能のルールを使っており、**今回の仕様には対応していない**。参考として無変更で保全し、新しいWindows基盤へ直接移植していません。
