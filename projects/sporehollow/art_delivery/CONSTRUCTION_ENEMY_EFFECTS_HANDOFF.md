# 壁・床・ドア／誘拐者／局所演出の納品一覧

素材ブランチ：codex/sporehollow-art-assets  
リポジトリ：shirai-masatomo/whitespace  
制作領域：C:/Users/masat/.codex/worktrees/sporehollow-art/codex_test  
納品基点：projects/sporehollow/art_delivery/

## 今回使えるセット

| セット | PNG数 | 素材・納品書のコミット | 納品書 |
|---|---:|---|---|
| 木壁・木床・縦横ドア・ロック | 73 | e648cf75a288219887733c5fa2d9536a113dae83 | [wood_buildings_v1](wood_buildings_v1/HANDOFF.md) |
| 土・石の壁と床 | 106 | ebe446e5329aa7780b6ef5f13268ceb9433c9796 | [earth_stone_buildings_v1](earth_stone_buildings_v1/HANDOFF.md) |
| 誘拐者の静止・歩行・攻撃・分離運搬 | 28 | 9c7ace86567f6b89e5a9220843ad7fa35286d680 | [kidnapper_basic_v1](kidnapper_basic_v1/HANDOFF.md) |
| 運搬の左右変換情報の補足 | 0 | a038dc062d75e77e6c0c1c1a23d8e65db0c13725 | basic_v1の最新版manifestを使用 |
| 誘拐者の探索・発見・被弾・退散 | 22 | d300d8ae905d5dcedf9d6e022807b51d9a3097d7 | [kidnapper_reactions_v1](kidnapper_reactions_v1/HANDOFF.md) |
| 建築・戦闘・回収・音波・ロック破損演出 | 40 | e6371377565aa71a3b7979e6ee7edd57878048bb | [effects_v1](effects_v1/HANDOFF.md) |

合計269枚のゲーム用PNG。原画と比較画像は数に含めない。各セットにmanifest.jsonがあり、ファイル名・寸法・アンカー・フレーム順と時間・loop・用途・SHA256を記録。上表は段階納品の順番であり、原画／加工用スクリプトのコミットを分けている。基本セットの「次便」「未完成」と記された補助動作は、最後のreactions_v1で納品済み。木のセットの「土・石は後続」もearth_stone_buildings_v1で納品済み。

## 採用と共通規格

木の初回部屋見本の方向を継承。誘拐者は、ユーザーが「コソ泥感・悪者感」を強めたv2を採用。初稿kidnapper_preview_v1は修正前の履歴であり取り込まない。基本動作の顔はv2の同じピクセルを使用し、左右反転以外の別顔へ変えていない。

壁は48×68／(24,34)、セル48×42、N1/E2/S4/W8全16接続、通常／損傷。土・木・石は同じ接続形状で、損傷切替は既存ART_SPECのHP50%以下用。ドアは縦横・開閉・独立ロック部品。床48×42は全不透明、施工土と未舗装地面を区別。
誘拐者32×48／足元(16,44)。主人公v1と柴犬Cの既存PNG・相対サイズは維持。運搬は主人公を別レイヤーで重ね、前面の保持腕と頭を分離。主人公専用の脱力姿勢を新たに作ったという意味ではない。
演出は32×32、実図形約12〜26px、非ループ、終端で非表示。描画サイズを効果範囲にしない。

## 検査済み

- 全269PNGの実寸、通常RGBA、二値alpha、manifestのSHA256を確認。
- 土・木・石の全16接続でalpha形状が一致。接続口に穴がない。床は全面alpha255。
- 開いた縦横ドアの開口に透過領域がある。接続内部の端面を省略。
- 主人公v1・柴犬Cの採用4PNGは納品時のSHA256と一致。
- 誘拐者の基本歩行・攻撃・運搬前層の帽子／顔は、採用v2の頭領域と画素単位で一致。左右の運搬支持点を比較。
- 実寸／拡大、保存済み牧場背景、明暗背景、静止比較と確認GIFを作成。
- 今回の変更はart-production/とart_delivery/だけ。ゲームコード・本番シーン・UID・ゲームルールの変更なし。

## 出典・原画・プロンプト

内蔵image_gen.imagegenで原案を制作。新しい外部有料APIは利用していない。原画を保存し、等比整形・限定色・輪郭／目／手足・二値透過・接続・基準点・連番・レイヤー分離を加工した。

- 木：[出典](../art-production/buildings-v1/SOURCES.md)／[プロンプト](../art-production/buildings-v1/prompts.json)
- 土・石：[出典](../art-production/earth-stone-v1/SOURCES.md)／[プロンプト](../art-production/earth-stone-v1/prompts.json)
- 誘拐者：[出典](../art-production/kidnapper-v1/SOURCES.md)／[プロンプト](../art-production/kidnapper-v1/prompts.json)
- 演出：[出典](../art-production/effects-v1/SOURCES.md)／[プロンプト](../art-production/effects-v1/prompts.json)

## 引き渡しと残る作業

各セットを使える段階で実装担当チャット「other task」へ通知済み。実装担当から敵50枚・演出40枚の受領、およびゲーム取り込み／隔離描画検証前として扱う旨の応答を確認した。

今回の依頼範囲の素材セットは揃っている。残るのは実装担当による取り込み、縦壁の座標・接続・奥行き順、ドア開口／ロック、運搬レイヤー、既存イベントへの演出接続と隔離描画検証。比較PNG/GIFは素材合成で、ゲーム内確認済みの証拠ではない。ユーザーのデスクトップでゲームを起動していない。

