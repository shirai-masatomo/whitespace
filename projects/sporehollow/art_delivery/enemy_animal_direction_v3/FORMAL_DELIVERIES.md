# 採用後の正式動作・納品一覧

ブランチ: `codex/sporehollow-art-assets`。2026-10-06。
修正5体の採用と、サラリーマン確認後の「他もお願い」に基づく追加納品です。
残り8体、左右55動作セット（左右を同じ動作として数える）、本番RGBA PNG396枚。静止は採用元と完全同一です。

| 素材 | 納品フォルダ・説明 | 納品コミットSHA（最新補正含む） | PNG数 |
|---|---|---|---:|
| デストロイマン | [destroyer_motion_v1](../destroyer_motion_v1/HANDOFF.md) | `13674fb364d0697711b51e8f541a2eb938527834` | 78 |
| 武闘家 | [martial_artist_motion_v1](../martial_artist_motion_v1/HANDOFF.md) | `335ebc44a1775a1eb92b5c51658d3f57bf122053` | 54 |
| 忍者 | [ninja_motion_v1](../ninja_motion_v1/HANDOFF.md) | `6dede82e1b5fbdd6d44dd8d914ad23ec56b556ff` | 56 |
| ムッツゴロウ | [animal_tamer_motion_v1](../animal_tamer_motion_v1/HANDOFF.md) | `c2296eb44590f15fc94cf29fe8e193becc957dda` | 48 |
| ランナー | [runner_motion_v1](../runner_motion_v1/HANDOFF.md) | `bfd62008579d7ba22351228f2c0ea2c63d21da64` | 48 |
| ドーベルマン | [doberman_motion_v1](../doberman_motion_v1/HANDOFF.md) | `5026a91ec06d7876db63bed57e92c1468abd3161` | 36 |
| ウシガエル | [bullfrog_motion_v1](../bullfrog_motion_v1/HANDOFF.md) | `10269ec50ebc5b6dd0edf26612f7d5054eb27458` | 44 |
| ハリネズミ | [hedgehog_motion_v1](../hedgehog_motion_v1/HANDOFF.md) | `a8a427c490a0915027cbc2cbedebcdbf76a8010b` | 32 |

サラリーマンは `../salaryman_motion_v1/`（ea06d76c9a6f6e5505dc013ad0ae9f5a9699d83f）、首輪・きのみは `../equipment_icons_v1/`（ef12e658aa7279900adf3d9deb3e0282b78c4aaf）を維持。

## 完成範囲と取り込み

各セットのmanifest.assetsだけが本番一覧。actionsがフレーム順・時間・ループ、sockets/partsが握り・口元と独立部品。正面・背面の専用動作やレベル差分は今回の横向き契約外です。

デストロイマン: 歩行・鉄球振りかぶり/接触・被弾・退散。武器レイヤーを別アンカーで重ねる。握り接続の補正コミット13674fbを含める。
武闘家: 礼の開始/終了・構え・突き・蹴り。忍者: 手裏剣と短剣を独立、煙なし、生存退散。
ムッツゴロウ: 実装ID animal_tamer、懐柔/先導時の動物は別レイヤー。
ランナー: 走行・息切れ・回復・攻撃。同行犬は別マス。
ドーベルマン: 歩行/走行・噛み付き・被弾・既存仕様の流血なし死亡。
ウシガエル: 移動・舌の伸び/保持/戻し・鳴き・被弾。背面巻き付き→対象→前面巻き付き。見本3マスは既存4マス射程の変更指示ではない。
ハリネズミ: 移動・棘を立てる/保持/解除・被弾。採用した迎撃シルエットを維持。

## 確認画像と限界

[8セット動作GIF](preview/formal_motion_overview.gif)、[比較画像](preview/formal_motion_overview.png)。個別セットのpreviewには全コマ・暗明背景・実寸比較・動作GIF。複数部品の例にはspecial_motion.gifも用意。
いずれも保存済み牧場背景へのオフライン合成であり、ゲームの動作検証ではありません。overviewは同期比較用の固定140ms、正式時間は各manifestに従う。

全396PNGのハッシュ・RGBA・二値透過・寸法・左右反転・必要ActionID・武器握り接続・GIF復号を検査済み。監査記録: `../../art-production/motion-pipeline-v1/audit-results.json`。

ゲームへの取り込み・描画順・座標・隔離描画検証は実装担当。ゲームコード・本番シーン・UID・能力ルールは未編集。ユーザーのゲームは起動していません。原画・プロンプト・加工履歴は各art-productionの*-motion-v1に保存。
