# DIVE DIVE — PROJECT STATE

更新: 2026-09-26

**L1-P0〜L1-G / L2-P0〜P2 圧縮試作・品質CHANGES / 定期自律開発PAUSED**。

## 現在遊べる範囲

海上→岩棚→海藻の泉→流木→約125mのクラゲまでを共通導入に整理。P1/P2移行帯で左の泡/岸壁と右の岩礁/洞窟が開き、約160mから断層/隆起した岸壁へ。約450m砂海底→隙間→暗い狭路→約585m巨大空間→タコ→約680m水球まで接続。一本道は主進行の読みやすさであり、自由遊泳を不可視壁で禁止しない。

自然沈降5m/s、E急降下15m/s、Space浮上6.6m/s、水平7m/s。酸素藻/泡/水球は接触で即補給。

## 最新実装

実装/content HEAD: `47d007cd27367e6222a0517b4f003eb8937375e3` — shared introduction before branching。

- P0/P1の競合する寄り道を後ろへ移し、岩棚→藻→流木→クラゲを共通導入へ。
- 約125〜160mから分岐を段階的に開く。
- ReefExploration Markerを基準に洞窟/空気/上昇流/魚群を追従。
- 旧浅海の不可視補給/空気を除去。
- CI run #261 success。Rules586、Scene459、Audio61、surface2688、actual collision689、Discovery30、Playground163、Intro14、Seabed9、Headland19、Canyon179、Editor16、L1 input11、L1 places18、Biology35、全て失敗0。Windows build/export smoke成功。
- PC非干渉: GPU画面外・無音・非捕捉、人間のアプリを終了しない。

## 品質判定

**CHANGES / SELF_CONTINUE**。HUMAN_REVIEW候補ではない。

最新外部レビューで確認した主課題:
1. 共通導入の最初の脚は評価上 `visible_with_mouse=false`。入水直後から最初の岩棚を自然に読ませる。
2. 岩棚→藻→流木→クラゲが約30/60/90/125mの等間隔チェックポイント列に見える危険。地形接続・横ずれ・高低差・遮蔽で自然化。
3. 47d007c後のreview PNGは旧版と同じで、現行の視覚改善を証明できない。P0入水とP1/P2移行の固定アンカー画像を次の品質ゲートで更新。
4. 約160mの包囲地形、岩階段/段丘/歩く→見渡す→泳ぐ、P1/P2閉PROFILE、P2/P3同型棚、P4一枚盆地、L1-G/L2-P0連続管は未解消。
5. ReefExplorationを大きくEditor移動すると固定world座標の海底cutoutとずれる可能性。

具体タスクはTASKS.mdのDD-089/064/055/067/068/065/070/081/078/082/090/072へ。

## 同期

main `f361de128cefcb055828076ae52b4dd6ef04fcd8` のHUMAN_DIRECTION / EXTERNAL_AI_REVIEWを確認。外部レビューのdurable cursorは
`reviewed_through: 47d007cd27367e6222a0517b4f003eb8937375e3`。

9/26の最新人間方針「P0〜P1は一本道、P1→P2で段階的に選択を開く」を正本として維持。古い「入水直後に2〜3候補」へ戻さない。

branch: `codex/dive-dive-playground` / draft PR #2。次の実装はレビューP0から1フェーズに集中する。
