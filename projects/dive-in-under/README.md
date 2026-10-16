# Dive In Under

**地下へ潜るほど報酬は増えるが、仲間・装備を失う危険も増すフルオート戦闘ダンジョンRPG。**

## 現在地：設計整理／Codex実装は未依頼
- **仕様の正本**: [SPEC.md](SPEC.md) — ここだけ読めばゲーム全体が分かるようにする。
- **優先的な未決定事項**: [DESIGN_DECISIONS.md](docs/DESIGN_DECISIONS.md)
- **10F設計検証の目標**: [PROTOTYPE_10F.md](docs/PROTOTYPE_10F.md)
- **Steam向け最終配布**は Windows `.exe`＋必要な同梱アセットを想定。実装はCodexに依頼する段階で別途開始。
- **古い編成ルールのブラウザ試作**: [ZIP](Dive-In-Under-10F-prototype.zip)／[ソース](prototype/index.html)。**主人公＋人間2名＋それぞれの配下／友好度／忠実度の仕様は未実装**。設計検討用の参考。

## 詳細資料

| 分野 | 管理資料 |
| --- | --- |
| 階層・出現範囲・確率 | [FLOORS.md](docs/FLOORS.md) |
| 敵・ボス一覧 | [ENEMIES.md](docs/ENEMIES.md) |
| アイテム・装備・支給品 | [ITEMS.md](docs/ITEMS.md) |
| 仲間（人・動物・魔物）／友好度／忠実度 | [ALLIES.md](docs/ALLIES.md) |
| 階層イベント | [EVENTS.md](docs/EVENTS.md) |
| オート戦闘 | [COMBAT.md](docs/COMBAT.md) |
| 黄金像 | [SHRINE.md](docs/SHRINE.md) |
| 参考作品の調査 | [RESEARCH.md](docs/RESEARCH.md) |

**資料管理の原則**：確定仕様と仮案を分ける。階層帯で候補IDを一覧し、個別の敵・仲間・装備・イベント定義を重複させない。Codexの実装プロンプトは**明示的な依頼後に段階的に作成**する。
