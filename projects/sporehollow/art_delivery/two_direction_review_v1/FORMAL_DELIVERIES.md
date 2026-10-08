# 左右正式モーション納品一覧

2026-10-08。方向確認6枚をユーザー「OK」で採用後に制作。ブランチ `codex/sporehollow-art-assets`。

[動作確認ページ](formal.html)。素材合計320PNG。各フォルダにmanifest.json、HANDOFF.md、QA.json、確認PNG/GIFを収録。

| 対象 | 納品フォルダ | PNG | 納品コミットSHA |
|---|---|---:|---|
| 商人・荷車 | [merchant_motion_v1](../merchant_motion_v1/HANDOFF.md) | 20 | `e5eadbc4f316b0746257a74322f2bea5dd1bfabe` |
| メイド | [maid_motion_v1](../maid_motion_v1/HANDOFF.md) | 92 | `88eff06228805249f4a973fa1e6314525a3f785d` |
| 舞姫 | [dancer_motion_v1](../dancer_motion_v1/HANDOFF.md) | 62 | `cde30569d077344227b515c53736560952fadd03` |
| 盗賊 | [thief_motion_v1](../thief_motion_v1/HANDOFF.md) | 60 | `54c98a6daa268926698039fa48853d9e9009985b` |
| 乳牛 | [cow_motion_v1](../cow_motion_v1/HANDOFF.md) | 30 | `b11def1fdefdb4f5e5832f91558c8116d5379b0c` |
| 闘牛 | [bull_motion_v1](../bull_motion_v1/HANDOFF.md) | 56 | `7e83f40df48d1b32b51ff1c7f37d455f5b7a3af1` |

共通制作原本・採用記録は`8efe0e3`。既存納品1163PNGのハッシュ一致を確認。ゲームコード・本番シーンは変更なし。

## 取り込み上の注意

- 右/左のみ。左右は画素単位の水平反転。
- 商人は48×48、足元(24,44)、闘牛は96×64、足元(48,58)。腕・角などの余白を追加したためで、本体を拡大する指定ではない。
- 他の寸法・時間・イベント目安・レイヤーは各manifestを参照。移動速度や判定は既存ロジックに従う。
- 荷車の奥車輪回転・設営・乗降は未制作。最小コマ構成で、追加の中割りは含まない。
- 原画・ゲーム素材・確認用画像を分離。全GIFと確認ページはオフライン比較であり、ゲーム内確認の証拠ではない。
