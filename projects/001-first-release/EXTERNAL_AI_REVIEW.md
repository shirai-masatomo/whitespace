# DIVE DIVE — EXTERNAL AI REVIEW

更新: 2026-09-26
対象: `codex/dive-dive-playground`
active_head: `47d007cd27367e6222a0517b4f003eb8937375e3`
reviewed_through: 47d007cd27367e6222a0517b4f003eb8937375e3

## 判定: **CHANGES / SELF_CONTINUE**

人間判断はまだ不要。定期自律開発は **PAUSEDのまま**。

前回 `reviewed_through: 1b13ef8b9564e52c8455a0775caaef8c54e46fca` から active branch HEAD までをcatch-up。途中の `8ffe3c1` / `9c12dfd` / `4274567` はレビュー/TASKS/STATEの受け渡しのみ。品質判断に効く新規 implementation/content commit は **`47d007c` — Give DIVE DIVE a shared introduction before branching** の1件。

GitHub Actions DIVE DIVE run #261 は **success**。Rules 586 / Scene 459 / Audio 61 / platform-surface 2688 / actual player collision 689 / Discovery 30 / Playground 163 / Intro 14 / Seabed 9 / Headland 19 / Editor authoring 16 / L1 input 11 / L1 places 18 / Canyon 179 / Biology 35 が失敗0。Windows build/export smokeも成功。PC非干渉方針も維持。

## 前進

- P0〜P1を岩棚→海藻→流木→クラゲの共通導入へ整理し、旧P0/P1の競合する酸素藻・洞窟・巨大泡・岩窓・クラゲ列をP1/P2移行帯以深へ移した。
- 約125〜160mで初めて複数候補を開く構成は、9/26の最新HUMAN_DIRECTION（一本道→段階分岐）と整合。
- navigation候補は序盤1件へ絞るが、不可視壁/自動搬送で自由遊泳を禁止していない。
- `ReefExploration` の保存Transformを基準に洞窟・空気・上昇流・魚群を追従させ、旧位置の不可視補給/空気をテストで除去。

ただし、これは**導線構造の改善**であり、画面品質がHUMAN_REVIEW候補へ上がった証拠にはならない。

## P0-1. 最初の目的地が通常視点で読めていない

route evaluation では共通導入の最初の脚 `to: 1` が全ルートで **`visible_with_mouse: false`**。最新方針の「P0/P1は次の目的地が一つずつ読める」と衝突する。

次:
- 桟橋/入水直後から最初の岩棚をHUD矢印なしで読めるようにする
- 水面光、泡、魚群、岩棚シルエット、近景/中景/遠景で主導線を作る
- カメラ固定・不可視壁で解決しない
- 固定アンカー通常視点でも確認

対応: **DD-064 / DD-055 / DD-067**。

## P0-2. 共通導入が等間隔のランドマーク列に見える危険

主要深度が概ね -30 / -60 / -90 / -125m と規則的で、岩棚→藻→流木→クラゲがチェックポイント列に見える可能性がある。

次:
- 一本道の読みやすさは維持
- 横ずれ、高低差、遮蔽、見え隠れ、地形接続で等間隔感を崩す
- ランドマークを独立オブジェクト列ではなく周囲の地形/生物へ馴染ませる
- P1/P2移行で初めて左右候補が同時に見え始めるよう段階化

対応: **DD-089 / DD-055 / DD-068**。

## P0-3. 現行commitの品質比較画像がない

`REVIEW_PACKET.md` は9/21画像が現在のP0/P1配置を示さないと明記。review/L1-P1, P2, P4, L1-G の6 PNG blob SHAも `1b13ef8` と `47d007c` で全て同一。今回の大きな序盤再配置に対する最新比較画像がないため、**material visual improvementは認定不可**。

次の品質ゲート:
- 現行commitのP0入水固定アンカー通常視点 1枚
- 約125〜160mのP1→P2移行固定アンカー通常視点 1枚
- 必要なら内部通常視点を各1枚追加
- 比較終了後は旧画像を置換/削除し蓄積しない
- 主役、自然密度、遠近、次の目的地、地形の可遊性を評価

対応: **DD-067を最優先継続**。

## P0-4. 既存の大地形品質課題は未解消

今回の主変更は序盤の順序/配置。以下はテスト成功では相殺しない。

- 約160m canyon/cliff enclosure: 2〜4異種の巨大主形状で左右/奥/一部頭上に包まれる構図
- rock-stair / terrace / traversal variation: 歩く→見渡す→泳ぐ、見える棚/穴/張り出しを実利用可能に
- P1/P2の閉じたPROFILE掃引のアーチ/橋模型感
- P2/P3の同一generator familyによる棚反復
- P4の一枚数式盆地 + 装飾
- L1-G/L2-P0の連続管
- stronger ocean-entry quality / playable-density improvement

対応: **DD-064 / 065 / 068 / 070 / 078 / 081 / 082 / 084**。

## P1-1. ReefExplorationと海底cutoutのEditor同期

`ReefExploration` は保存Transformで岩礁/洞窟/空気/魚群/上昇流を追従させる一方、`coastal_seabed.gd::height_at()` の `cavern_bay` / `arch_bay` は固定world座標。Markerを大きく動かすと洞窟と海底の切り欠きがずれる可能性がある。

次:
- cutoutをReefExploration基準へ寄せる、または編集可能範囲を明示して大移動を禁止
- 軽量不整合テストを追加
- 保存Transformを起動時に上書きしない契約は維持

対応: **DD-090 / DD-087運用継続**。

## P1-2. 分岐後の潮流の役割

評価値は `current_seconds_saved: -0.79`。時間短縮を必須にしない判断は妥当だが、潮流が誘導/移動補助/リスクのどれなのかは明確にする。

対応: **DD-072**。

## 同期 / 必須ディレクティブ

9/26 implementation commitでHUMAN_DIRECTIONが一本道→段階分岐へ更新されたため、今回mainの正本へ同期する。古い「入水直後に2〜3候補」へ戻さない。

- obsolete-file cleanup: **維持**
- ~160m canyon/cliff enclosure: **未解消 / DD-065・070**
- rock-stair/terrace/traversal variation: **未解消 / DD-065・068・070**
- stronger ocean-entry quality: **構造前進、視覚未証明 / DD-064・058・067**
- playable-density improvement: **未解消 / DD-055・067・089**
- quality-gate screenshot comparisons: **今回未達 / DD-067**
- collision reliability: **PASS維持（689/0）**
- PC non-interference: **PASS維持**
- human editor authoring: **維持、DD-090で座標同期を補強**

## 次回 HUMAN_REVIEW 条件

まだ不要。P0入水から最初の岩棚が通常視点で自然に読めること、共通導入が等間隔の足場列ではなく一つの海中地形として見えること、P1/P2移行で選択肢が段階的に開くこと、約160m以降の大地形とP4/G/L2-P0の模型感が減ること、現行比較スクショで前回版より明確な視覚改善が確認できること、実衝突/CI/PC非干渉を維持すること。

それまでは **CHANGES / SELF_CONTINUE**。
