# Dive In Under

**地下へ潜るほど報酬は増えるが、死と装備の消耗を伴う、フルオート戦闘ダンジョンRPG。**

## 現在地：Dot自律開発の指示・工程準備が完了（ユーザーからDotへの実行指示待ち）

- **[SPEC.md：全体仕様の正本](SPEC.md)** — ゲームの大枠と確定要件
- **[現行2DドットUI参考3枚](docs/UI_MOCKS.md)** — 探索・戦闘・装備／ステータス。旧4枚は履歴へ
- **[仕様と実装状況の表](docs/IMPLEMENTATION_STATUS.md)** — 何が「今」「次」「後」なのか
- **[設計判断台帳](docs/DESIGN_DECISIONS.md)** — 既に決めたことと確認事項
- **[初期EXE～10Fプロトタイプの進め方](docs/PROTOTYPE_10F.md)**
- **[戦闘シミュレーター設計](docs/BATTLE_SIMULATION.md)** — 工程1の単発戦闘コアはCodex作業ブランチに実装・検証結果あり。反復探索まで未完成

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

**旧ブラウザ試作**：[過去の試作ZIP](Dive-In-Under-10F-prototype.zip) ／ [ソース](prototype/index.html)。古いパーティ構造など現行と異なる仕様を含むため、**そのまま現行のWindows版とは扱わない**。新しいWindows EXEは未作成。
