# DIVE DIVE — REVIEW PACKET

**2026-09-21 / Phase 3 / CHANGES / 定期自律開発PAUSED**。今回の重点は序盤の地形・密度・探索。比較元3d4760c。人間レビュー要求ではない。

## 現在どう遊べるか

海へ飛び込むと約32mの大岩盤へ着地。左の壁沿いで酸素補給しながら歩く、右の海藻や岩礁へ泳ぐ、崩れた縁から裂け目へ潜ることができます。新しい裂け目は岩盤を貫通し、下にはクラゲ、外へ抜けると既存の流木側の海へ戻れます。

## 案出し・比較・棄却

[AI_REVIEW](AI_REVIEW.md)に12案と評価を記録。3段階を実際に動かして比較しました。

| 案 | 同じW操作で最初に着地した画面 | 結果 |
| --- | --- | --- |
| A: 幅/高さの違う段丘・裂け目 | [A](review/density-trials/a-landing.png) | 進路は増えるが、地形だけでは空虚。中央の盛り上がりと急斜面を修正 |
| A+B: 崩落群・海藻帯 | [B](review/density-trials/b-landing.png) | 縁の密度差と影を採用。地形外の根を除き、歩行面を塞がない配置へ再調整 |
| A+B+C: 局所的な岩屋根 | [C](review/density-trials/c-landing.png) | 通行は可能だが、切断ブロックに見え左の手掛かりを隠すため棄却 |

採用版はA+Bを再調整。歩行側の斜面と沖側の崩れた段差、丸みのある裂け目、側面の浸食、近景の堆積/低い植物、下側のクラゲを組み合わせた。強い斑点模様の材質も不自然だったため外した。試作を残すことを目的にしていない。

## 前版との比較・代表画面

| 場面 | 前3d4760c | 今 | 変化と制限 |
| --- | --- | --- | --- |
| 5m入水 | [前](review/density-before/104-headland-entry.png) | [104](review/headland/104-headland-entry.png) | 同じ入力/位置/pitch=-.35。岩盤に欠けと植生の帯、複数の縁が見える。魚/泡の位相差あり |
| 最初の着地 | [前](review/density-before/105-first-bedrock.png) | [105](review/headland/105-first-bedrock.png) | 同じW操作/pitch=-.35。地形変更で着地位置は約2m変化。左壁・右の植生・沖側の崩れが分かれるが、大面は滑らか |

[初期カメラ角度-.25の着地112](review/headland/112-default-landing-view.png) / [藻から見る106](review/headland/106-bedrock-stairs.png) / [裂け目の縁110](review/headland/110-fissure-lip.png) / [岩盤の下面111](review/headland/111-fissure-exit.png)。106/110/111は対象へ見回した比較視線。110/111の枝経路は、連続操作で到達済みの藻を開始位置に設定して別途試走。

[連続画像](review/sequence/index.html)の先頭17枚は、桟橋→着地→藻へ歩行→登り返し→縁から下降→下面→流木まで34.83秒の同一プレイ。途中位置設定/救助なし。既知の操縦であり、初見プレイヤーの速さではない。他の再生経路は過去サイクル参考。

## 検証

- 全check: format/lint/依存、479ルール・430シーン・57音・689実衝突・30探索・163岩礁・35入水・30新岩盤・179峡谷、2688表面点、11経路、Windows export/配布EXE headless成功。
- 岩盤30検査: 通常/E着地、Space下面、斜め側面60/15Hz、歩行/登り返し/下面、裂け目の入口→出口、Eでの貫通。Forward+/Compatibilityで実GPU成功。[測定](review/headland.json)。
- 通常visualの入水/救助/再挑戦/ゴール成功。全検証は画面外・無音・非捕捉。配布EXEのForward+起動120フレームも確認。
- RTX4070 SUPER/1280×720/VSync無効、各視点180フレーム。新しい30m視点は中央値3.01ms/p95 4.51ms。[全9視点](review/render-forward_plus.json)。GPU単体時間・別PC性能や、前版との厳密な速度差ではない。

再現: `./dev.ps1 check`、`visual-headland`、`visual-headland -Renderer gl_compatibility`、`visual`、`benchmark`、`gpu-smoke`。最新版は `build/windows-agent/DIVE DIVE.exe`。

## 自己批評

大岩盤に寄り道先と密度差ができ、裂け目を通って上下の空間が繋がった。一方、足元の大面と旧アーチの模型感、最初の着地から穴が読み取りにくい点は残る。全体の自然さ/面白さを合格とはしない。**CHANGES / 定期再開は保留**。
