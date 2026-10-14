# 出典・制作記録

- 既存採用アート基準: `codex/sporehollow-art-assets` / `fc9e3646afe8708e5bc06756dcaf0448e77a93b6`。
- 実装参照: `codex/sporehollow-biome01` / `7708cc34fb5da0adbc0e569fed8fcac2649d8c19`。参照時点のrock_view/rock_art/retained_ground/ART_SPECおよび実ゲーム画面をproduction/referencesへ記録。
- 基本接続形状・側面・内角: プロジェクト既存 `biome_connections_v1`。元画像は保持し、今回の別フォルダ内でのみ色調・上面を整えた。
- 原画4点: Codex内蔵画像生成機能で独自生成。既存の外部ゲーム画像の流用・トレースなし。新たな有料APIは使用していない。
- [原画・生成プロンプト](../../art-production/continuous-bedrock-v1/generation.json)。原画は同ディレクトリoriginals/、加工・接続検査・オフライン合成はbuild.py。
- 工程: 生成原画から大きな岩面・鉱脈・乾いた粘土・茶砂を整理、限定パレット化、外周周期の調整、既存形状への上面クリップ、接続・サイズ・透過・通常倍率の確認。原画の単純縮小のみではない。
- 比較の主人公/柴犬はcharacters_v1採用透過PNG。実ゲーム背景01_fieldは既存review/current/ui_surveyの記録。人物・動物・goldAを再生成していない。
- [旧素材ハッシュ記録](../../art-production/continuous-bedrock-v1/prior_hashes.json)。旧素材6点の再利用先とSHA256はmanifest.reuseに記録。重複コピーなし。
