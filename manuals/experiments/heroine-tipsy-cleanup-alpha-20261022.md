# 酔い画像の周囲エフェクト除去・白背景透過

## 目的・合格条件

- 日付：2026-10-22（日本時間）。
- 先行依頼：酔い02.pngの周囲の湯気、ピンクの丸・揺れ線だけを除去し、人物と顔の赤みを残す。
- 追加依頼：酔い_座り姿_参照_20261022.jpgの背景を透過する。人物とピンクの記号を残す。
- 合格条件：指定の背景／周囲効果が除去され、顔・服・手・髪の描画と元のサイズが保たれること。原本を上書きしない。

## 入力と環境

| 対象 | 原本 | SHA256（前後一致） | サイズ |
| --- | --- | --- | --- |
| 周囲効果の除去 | [酔い02.png](../../reports/COVERAGE.md#同梱しないもの) | f82c97f05e7ac5fbefe2a80f7753fed12761f72685089923e0622bc830932eb7 | 1084×1451 RGBA |
| 白背景透過 | [参照JPG](../../media/d22b7a750ad204e5c29a.jpg) | d22b7a750ad204e5c29abc8cf3e1765c28981b4f220510ee94820d0ffceef513 | 956×1280 RGB |

- 人物・画風・構図・衣装参照はいずれも各原本自身。別人物／画風の転写なし。
- 内蔵画像編集で周囲効果除去を2回試したが、両方とも出力段階の安全判定で拒否。画像出力0枚。
- 以前許可された通常の画像処理へ切り替えた。既存のバンドルPython、Pillow、NumPyを使用し、画素のRGBを変えず透明度のみ編集。
- ComfyUI、ローカル生成モデル、ゲーム、SDK、GUI自動操作は未起動。モデル／ノード版、CFG、denoise等は通常処理に非該当。内蔵ツールのモデルID・seedは非公開。
- VM等の実行隔離は不使用（静的画像処理のみ）。GPU／VRAM・システム・共通ランタイム設定の変更、新規取得、インストールなし。

## 試行ごとの記録

| ID | 方式・変更 | seed等 | 出力 | 採否 |
| --- | --- | --- | --- | --- |
| E1 | 内蔵画像編集で湯気・浮遊記号の除去 | 非公開 | なし | 出力判定で拒否 |
| E2 | E1と同一指示で再試行 | 非公開 | なし | 出力判定で拒否 |
| E3 | 人物上半分の髪・青い服の色から境界を取り、外側の効果のalphaを0へ変更。上下2px・左右4pxの保護余白 | 非生成処理 | [酔い02_エフェクトなし.png](../../reports/COVERAGE.md#同梱しないもの) | 目視候補。ユーザー最終確認待ち |
| B1 | 白背景の除去。輪郭で囲まれた白い衣服を保護し、外側とピンクの丸の内側の白を透過 | 非生成処理 | [背景透過PNG](../../media/f5cf8c85b2d509b525d0.png) | 目視候補。ユーザー最終確認待ち |

- E3：[処理スクリプト](../../reports/COVERAGE.md#同梱しないもの)、[keepマスク](../../media/ad219fafb105c160ea3a.png)、[確認画像](../../media/a8fa818b76a764c86cbc.png)、[機械検査](../../reports/COVERAGE.md#同梱しないもの)。
- B1：[処理スクリプト](../../reports/COVERAGE.md#同梱しないもの)、[確認画像](../../media/2a20bc3b0526dec8fd40.png)、[機械検査](../../reports/COVERAGE.md#同梱しないもの)。
- クロップ、リサイズ、反転なし。E3の編集範囲は0〜879行、880行以下はRGBA一致。B1はRGB各成分235以上・成分間差24以下を白候補とし、青い服から連結した人物の囲まれた内部を保護した。
- 非生成処理はalphaのみの変更。マスク外の一致を、生成モデルの再現能力とは扱わない。
- E3の出力SHA256：386cc9d8677da19c56bba80a9819e46e7ab33b1f44ee7e8077057c109dee6933。
- B1の出力SHA256：f5cf8c85b2d509b525d0d32f98a80b3fb07362b97df6c6dcae03d7862f40837a。
- 所要時間・VRAM／RAM使用量は未測定。生成用DAG・骨格・生成後のマスク合成はなし。

内蔵ツールへ渡した指示全文（E1・E2共通、生成出力なし）：

~~~text
Use case: precise-object-edit. Edit the supplied transparent PNG. Remove ONLY the decorative effects surrounding the adult woman: both white/light-gray steam wisps beside her head and shoulders, all floating pink circular bubbles, the pink wavy squiggle above the left side of her head, and stray detached effect marks outside her silhouette. Replace those effects with genuine alpha transparency. Keep the woman herself unchanged as faithfully as possible: the exact same tipsy half-open blue eyes and smiling open mouth, pink facial blush, skin color, head tilt, blonde hair and fine strands, body proportions, blue cardigan, white high-neck shirt, gold necklace, dark skirt, shoes, fingers, hands, seated pose, original edge crops, scale, placement, colors, outlines and shading. The blush is part of the character and MUST remain. Do not change her expression or sober her up. Do not remove hair or parts of clothing while erasing effects near the edges. Do not add or redesign anything. Same canvas composition, character only, transparent PNG. No steam, bubbles, motion symbols, haze, background, checkerboard texture, ground shadow or added objects.
~~~

## 観察・原因仮説・次の比較

- E3：湯気・浮遊する丸と揺れ線が消え、酔った笑顔、頬の赤み、髪・衣服・手指が残ることを目視確認。変更alphaは64,545画素。RGB全画素一致、保護領域のRGBA一致、下半身880行以降のRGBA一致を機械検査。
- B1：市松確認画像で白背景が消え、ピンクの丸と揺れ線、白いインナーが残ることを確認。透明画素689,558、alphaは0と255。RGB全画素が原JPGのデコード結果と一致し、保護した人物内部は不透明。
- 元JPGの圧縮や輪郭には限界があり、任意背景での縁の品質や全ポーズでの一般的な成功は保証しない。
- 新規生成0枚／失敗した生成呼出2回／既存入力2枚の通常加工2枚／最終目視比較2枚／今回の目視候補2枚。再生成の成功率とは数えない。
- 内蔵ツール拒否の原因は切り分けていない。拒否分類は内容の評価や通常処理の品質証明に転用しない。追加の生成試行は行わない。

## 片付けと未実施

- 原本2枚は前後SHA256一致。別名のPNGのみ追加し、既存ファイルを置き換えていない。
- 自分が起動した通常処理のシェル／Pythonコマンドは正常終了。ComfyUI・ゲーム・SDK用プロセス、常駐サーバー、モデルキャッシュは作成していない。無関係な既存プロセスの全体調査は未実施。
- 残存物：上記完成PNG2枚、output内のスクリプト・マスク・QA画像・JSON、本文書と入口の追記。QA画像は透過PNGの代わりに使用しない。
- ゲーム読込、隔離内テスト、実機表示、販売条件・利用規約の再調査、他画像への一般化は未実施。

