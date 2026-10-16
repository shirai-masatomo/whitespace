# Dive In Under

**地下へ潜るほど報酬は増えるが、仲間と装備を失う危険も増していくオート戦闘ダンジョンRPG。**

- 参考作品: B100シリーズ / Slay the Spire / パワプロクンポケット11 裏サクセス / Wizardry
- 現在地: 仕様整理＋地下1〜10Fの試作
- **親仕様（まずここ）**: [SPEC.md](SPEC.md)
- **10Fプロトタイプを遊ぶ**: [試遊用ZIPを取得](Dive-In-Under-10F-prototype.zip) → 展開して index.html をChrome / Edgeで開く。 [ソース](prototype/index.html)（試作値は未確定）
- **試作の検証項目**: [docs/PROTOTYPE_10F.md](docs/PROTOTYPE_10F.md)

## 詳細資料

| 分野 | 管理資料 |
| --- | --- |
| 階層別の配置・出現範囲・確率 | [階層](docs/FLOORS.md) |
| 敵・ボスの一覧 | [敵](docs/ENEMIES.md) |
| アイテム・装備・支給品 | [アイテム](docs/ITEMS.md) |
| 味方（人・動物・魔物） | [仲間](docs/ALLIES.md) |
| イベント・発生条件 | [イベント](docs/EVENTS.md) |
| オート戦闘と成長 | [戦闘](docs/COMBAT.md) |
| 黄金像の祈り・到達深度依存 | [黄金像](docs/SHRINE.md) |
| 参考作品の仕様調査 | [参考調査](docs/RESEARCH.md) |

**運用**: 固定済み要件とプロトタイプ用の仮置き値を区別。個別データはIDで紐付けし、1〜5Fなど区間から横断参照できるようにする。企画上の数字はバランス調整前の試作値。コードと資料の不一致は都度解消する。
