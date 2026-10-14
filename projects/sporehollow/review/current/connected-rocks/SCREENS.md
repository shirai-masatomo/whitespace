# CPU比較画像（実ゲームの撮影ではありません）

- [建築ボタン：選択／選択hover／未選択hover](architect-comparison.png)
- [岩盤全景：修正前／修正後](rocks-comparison.png)
- [岩盤・修正前原寸](rocks-before.png)／[修正後原寸](rocks-after.png)

岩盤は同一seed31・地形・樹木・縮尺。初期採集物を両条件で取り除いた比較fixture。変更前は現行生成からconsolidate_rocksの呼出しだけを除いたもの。両条件の岩数と座標範囲はcpu-visual.json。背景は比較用単色であり、ゲームの土・粘土・砕石シェーダーではない。

`tests/review_connected_rocks_cpu.gd`をheadlessで実行後、出力PNGをこのフォルダへ置き、`tools/render_connected_comparison.ps1`で見出し付き比較を再現できる。ボタン枠と色は本番スタイルの9分割CPU合成、比較画像の文字はSystem.Drawing。UI内部hoverの検証はarchitect-selected.json参照。

実ゲームの自動起動禁止により、GPU画面撮影は未実施。
