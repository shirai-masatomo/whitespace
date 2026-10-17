# 静止画像候補A — 素材一覧と採否レビュー

**5点すべてcandidate v1・未採用。工程1全体は未完了。** 表示できることと素材採用は別です。採用判断後に残りの敵へ展開し、採用後もモーションは追加しません。

[実EXEとPX参考の比較](index.html#comparison) / [実EXEの通常戦闘](32-visual-goblin.png) / [10Fボス](34-visual-boss.png) / [画像制作チャットへの引継ぎ](../../docs/IMAGE_PRODUCTION_HANDOFF.md) / [来歴・SHA・透明性JSON](../../assets/visual-candidates/v1/manifest.json)

画像は親タスクがimagegenでプロジェクト参考に基づき生成。外部素材パックなしとの制作元報告です。ユーザーが指定tempへ保存した実PNGを読み、ピクセルを確認してコピーしました。原稿を再描画・縮小保存・透過修正していません。コピー前後SHA一致、親のバイト数・寸法・人物アルファ128範囲と一致。親の既知SHAは未提供のため、Library原本とのSHA一致は断定していません。

背景は文字・枠・人物なし。人物は実アルファ透過ですが、薄い縁と内部の部分アルファがあり、厳密な64/96px格子ではない詳細なピクセル調原稿です。縮小表示を見て採否を判断します。

| 候補 | 原稿寸法 | 透過 | 向き／用途 | 状態 |
| --- | --- | --- | --- | --- |
| [通常洞窟](../../assets/visual-candidates/v1/dive-ordinary-cave-candidate-v1.png) | 1672×941 | なし | 独立背景 | 未採用 |
| [10Fボス門](../../assets/visual-candidates/v1/dive-boss-gate-cave-candidate-v1.png) | 1672×941 | なし | 独立背景 | 未採用 |
| [門番石像](../../assets/visual-candidates/v1/dive-b10-gatekeeper-static-candidate-v1.png) | 1254×1254 | あり | 左配置・右向き | 未採用 |
| [主人公](../../assets/visual-candidates/v1/dive-hero-static-candidate-v1.png) | 1254×1254 | あり | 右配置・左向き | 未採用 |
| [坑道ゴブリン](../../assets/visual-candidates/v1/dive-e04-goblin-static-candidate-v1.png) | 1254×1254 | あり | 左配置・右向き | 未採用 |

## 原稿と記録

### 通常洞窟

![通常洞窟](../../assets/visual-candidates/v1/dive-ordinary-cave-candidate-v1.png)

`dive-ordinary-cave-candidate-v1.png` / SHA-256 `bd4596d01a561e6c26d7652e04298c60c17697bedbbc284418a58528d2ed8a7b`

### 10Fボス門

![10Fボス門](../../assets/visual-candidates/v1/dive-boss-gate-cave-candidate-v1.png)

`dive-boss-gate-cave-candidate-v1.png` / SHA-256 `f71f3b070312a91c3d4eee40c212a90385af1fcf652fd52d74f6da93b1b65f33`

### 門番石像

![門番石像](../../assets/visual-candidates/v1/dive-b10-gatekeeper-static-candidate-v1.png)

`dive-b10-gatekeeper-static-candidate-v1.png` / SHA-256 `15111b49424358284893d98c212e82b78e72419c4ad9d0388db526822dd8bd58`

足元原稿座標: [646, 1221]。アルファ128以上の範囲: [86, 88, 1216, 1221]。画像キャンバス下端とは区別します。

### 主人公

![主人公](../../assets/visual-candidates/v1/dive-hero-static-candidate-v1.png)

`dive-hero-static-candidate-v1.png` / SHA-256 `27eda9f13520ea888eeb2e18301c0df1e5b72c582a8f43ea8ba10fff39e91048`

足元原稿座標: [640, 1135]。アルファ128以上の範囲: [108, 212, 1210, 1135]。画像キャンバス下端とは区別します。

### 坑道ゴブリン

![坑道ゴブリン](../../assets/visual-candidates/v1/dive-e04-goblin-static-candidate-v1.png)

`dive-e04-goblin-static-candidate-v1.png` / SHA-256 `c94e1a08ea616fc3176f26282682d9daede8672eab76911f2b8cfa6c3f58df16`

足元原稿座標: [565, 1156]。アルファ128以上の範囲: [205, 309, 1138, 1156]。画像キャンバス下端とは区別します。

## 比較で判断すること

- 主人公／ゴブリン／像の絵柄、縮小後の輪郭、双方の大きさ、足元の接地が合うか。
- 通常洞窟と10F門、深度帯の色調が参考PX-01/02へ近いか。
- 羊皮紙・真鍮枠・日本語・HP/SP・ログ・装備一覧が読みやすいか。UIは実データに同期するGodot部品です。
- E01〜E03/E05はコード仮表示のまま、画面でも仮と明記。正式採用や全敵完成とは扱いません。

判定は各候補について「採用／修正／不採用」。現時点で採用済み・不採用済みの素材はありません。実画面と参考の差や修正案を添えて親タスクからユーザーへ確認します。工程2・仲間・犬・全スキル・耐久・11F内容には進みません。
