# DIVE DIVE — PROJECT STATE

更新: 2026-09-19

## 現在地

- **リアル層のVertical Slice制作中 / SELF_CONTINUE**。前回のHUMAN_REVIEWは解除済み。製品品質ゲートは未達で、個別実装の確認待ちにはしない。
- 海上の桟橋から、自然沈降・E急降下・Space浮上・足場・接触酸素補給で300mへ。酸素0は泡で浅い訪問済み地点へ連続救助。死亡/ロードなし。
- 岸壁、自然岩、海藻、流木、クラゲ、動く観測ブイへ更新。潮流の横流れ・クラゲの反発・移動足場の追従。神話/宇宙などの下層は未実装。
- Godot 4.7.2 / Windows x64 / 日本語 / オフライン。Forward+を標準にし、同じEXEをCompatibilityでも起動可能。原作素材の流用なし。
- 主人公はスーツ/マスク/タンク/フィンを持つ独自メッシュと関節アニメーション。光・深度霧・流れる微粒子・用途別の泡を追加。完成アートとは判定しない。

## 検証

- `check -BuildFolder windows-real`: format/lint/依存整合性、ルール404・シーン174、6経路と対照条件、Windows Release export/EXE headless起動。
- 実GPUのvisual: 入水→足場→急降下/浮上→補給→酸素切れ→救助→再挑戦→300m。Forward+とCompatibilityを実行。クリアボタンの画素検査と960×540も確認。
- 最終経路: 通常86.93秒 / 補給直行82.23秒 / 寄り道90.95秒。最低酸素25.27%以上。代表救助は30m損失・2.27秒。
- RTX 4070 SUPER、1280×720、VSyncなし、静止3場面: Forward+中央値2.04〜2.13ms、P95最大3.98ms。GL中央値0.89〜1.00ms。単体GPU時間ではなく描画フレームの実時間。別GPUは未確認。
- 直前CI: [Windows Actions #35429850992](https://github.com/shirai-masatomo/whitespace/actions/runs/35429850992) 成功。コード `9b4d1bc`（足場カメラ・素材・姿勢まで）、setup/check/配布ZIP/ログ保存まで確認。
- [画面・連続画像・評価](REVIEW_PACKET.md) / [自己レビュー](AI_REVIEW.md)。自動操縦の成功を面白さや製品品質の証明にしない。

## 次

[人間方針](HUMAN_DIRECTION.md)の酸素藻と複数ルートを反映。13足場/7補給群落、泡/発光する葉と魚群。急降下直行33.37秒・最低酸素30.83%、同じ急降下で補給迂回47.60秒・52.63%。潮流は無潮流対照より0.58秒速い。海上/流木側など残る遮蔽と着地形状はDD-035、海面/遠景はDD-034、最後にDD-027品質ゲート。音/保存/Steamは未実装。

補給地点の葉先が判定外に出る試作と、迂回路でカメラが岸壁へ入る試作を修正済み。岸壁にもカメラ用メッシュ衝突を追加。通常視点の目標35/43、主人公43/43、F43/43（6経路合計）。メッシュの画素上の読みやすさは別に画面確認する。


## 再実行・既知の環境問題

- `./tools/setup.ps1` → `./dev.ps1 check` → `./dev.ps1 visual`。`benchmark -Renderer forward_plus` / `benchmark -Renderer gl_compatibility` で比較。
- このPCの最新版は **build/windows-real/DIVE DIVE.exe**。旧windows-previewを使用中でも別出力できる。配布はbuild/DIVE-DIVE-windows.zip。[起動方法](README.md)。
- GPU確認はローカル、Actionsはheadlessのロジック/build確認。成功範囲を混同しない。配布EXEの通常GPU起動・正常終了も両rendererで確認済み。
- 使用中EXEを上書きするとPCK埋め込みのrenameに失敗する。テストEXE終了後にexportを再実行。ユーザーのプロセスを勝手に停止しない。
- 配布EXEへ外部`--script`を渡す撮影試行はタイムアウトし不採用。通常EXE起動とソース側visualを別々に検証する。
- Godotはexit 0でもERRORを出すためdev.ps1はログ検査。shaderの毎フレームuniform更新は以前UI欠けを起こしたため、waterは組み込みカメラ座標を使用。
- MSAAはproject.godotのrenderingセクション。粒子billboardはscale保持、メッシュ上面はGodotの時計回り頂点順。いずれも初回画面レビューで修正済み。
