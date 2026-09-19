# DIVE DIVE — PROJECT STATE

更新: 2026-09-19

## 現在地

- **Phase 3 / リアル層Vertical Slice候補 / HUMAN_REVIEW**。旧中核レビュー待ちとは別の節目。機能単体の完了ではなく、画面・操作・分岐・失敗/再挑戦を一体で評価できる300m区間を用意した。
- 海上の桟橋から、自然沈降・E急降下・Space浮上・足場・接触酸素補給で300mへ。酸素0は泡で浅い訪問済み地点へ連続救助。死亡/ロードなし。
- 岸壁、自然岩、海藻、流木、クラゲ、動く観測ブイへ更新。潮流の横流れ・クラゲの反発・移動足場の追従。神話/宇宙などの下層は未実装。
- Godot 4.7.2 / Windows x64 / 日本語 / オフライン。Forward+を標準にし、同じEXEをCompatibilityでも起動可能。原作素材の流用なし。
- 主人公はスーツ/マスク/タンク/フィンを持つ独自メッシュと関節アニメーション。光・深度霧・流れる微粒子・用途別の泡を追加。市販作品との同等品質や製品版全体の完成を宣言するものではない。

## 検証

- `check -BuildFolder windows-real`: format/lint/依存整合性、ルール396・シーン397・音52、足場メッシュ1,280点、6経路と対照条件/操作中断91ケース、Windows Release export/EXE headless起動。
- 実GPUのvisual: 入水→足場→急降下/浮上→補給→酸素切れ→救助→再挑戦→300m。Forward+とCompatibilityを実行。クリアボタンの画素検査と960×540も確認。
- 最終経路: 通常86.27秒 / 補給直行81.73秒 / 寄り道90.10秒。最低酸素25.00%以上。代表救助は30m損失・2.27秒。
- RTX 4070 SUPER、1280×720、VSyncなし、静止3場面: Forward+中央値2.31〜2.41ms、P95最大4.08ms。GL中央値0.96〜1.09ms。単体GPU時間ではなく描画フレームの実時間。別GPUは未確認。
- 直前CI: [Windows Actions #35434116647](https://github.com/shirai-masatomo/whitespace/actions/runs/35434116647) 成功、main `7aca1a8`（救助・音まで）。以後の岩/クラゲ/ブイの縁修正はローカルcheck・GPU確認済み、次commitでCI再確認。
- [画面・連続画像・評価](REVIEW_PACKET.md) / [自己レビュー](AI_REVIEW.md)。自動操縦の成功を面白さや製品品質の証明にしない。

## 次

1. DD-043: 人間が5〜10分試遊し、狙った足場へ動けるか、酸素を見てルートを選びたくなるか、今の絵づくりを伸ばすかを確認。
2. DD-044: 指摘の優先修正。承認済みの核の中で修正・検証は自律実行。
3. DD-045: オフラインRelease Buildへ最小保存/設定を整備。Steamはその後。

13足場/7補給群落/6経路。E直行33.08秒・最低酸素32.40%、E補給迂回47.30秒・52.60%。潮流は対照より0.56秒速い。マウス操作範囲で目標43/43可視。岩/クラゲ/ブイ1,280点の実メッシュ比較と急降下着地、流木90点の接地差最大0.007m。操作中断91ケースで全失敗が連続救助から復帰、救助最大3.48秒。数値は理想/指定操作であり人間の面白さ・失敗率ではない。

環境/操作音、Mミュート、ポーズ連動は実装。別GPU、音色の主観評価、長時間プレイ、保存/Steamは未確認または未実装。詳しい試遊入口はREVIEW_PACKETだけに集約する。

## 再実行・既知の環境問題

- `./tools/setup.ps1` → `./dev.ps1 check` → `./dev.ps1 visual`。`benchmark -Renderer forward_plus` / `benchmark -Renderer gl_compatibility` で比較。
- このPCの最新版は **build/windows-real/DIVE DIVE.exe**。旧windows-previewを使用中でも別出力できる。配布はbuild/DIVE-DIVE-windows.zip。[起動方法](README.md)。
- GPU確認はローカル、Actionsはheadlessのロジック/build確認。成功範囲を混同しない。配布EXEの通常GPU起動・正常終了も両rendererで確認済み。
- 使用中EXEを上書きするとPCK埋め込みのrenameに失敗する。テストEXE終了後にexportを再実行。ユーザーのプロセスを勝手に停止しない。
- 配布EXEへ外部`--script`を渡す撮影試行はタイムアウトし不採用。通常EXE起動とソース側visualを別々に検証する。
- Godotはexit 0でもERRORを出すためdev.ps1はログ検査。shaderの毎フレームuniform更新は以前UI欠けを起こしたため、waterは組み込みカメラ座標を使用。
- MSAAはproject.godotのrenderingセクション。粒子billboardはscale保持、メッシュ上面はGodotの時計回り頂点順。いずれも初回画面レビューで修正済み。

- 海面の白い筋は浮動小数noise勾配から発生。整数hashへ変更し、旧shaderで78画素の異常を再現→修正後両rendererで0。実GPU画素検査を維持。

- Poly Haven「Rock Boulder Dry」のCC0画像2枚は自動承認レビューで人間の明示承認を要求され、取得していない。承認質問は送信済み。承認なしで再取得せず、今回の候補は独自材質で完成し、外部素材は未導入。追加採用は回答後に判断する。
