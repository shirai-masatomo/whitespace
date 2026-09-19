# DIVE DIVE — PROJECT STATE

更新: 2026-09-19

## 現在地

- **リアル層のVertical Slice制作中 / SELF_CONTINUE**。前回のHUMAN_REVIEWは解除済み。製品品質ゲートは未達で、個別実装の確認待ちにはしない。
- 海上の桟橋から、自然沈降・E急降下・Space浮上・足場・接触酸素補給で300mへ。酸素0は泡で浅い訪問済み地点へ連続救助。死亡/ロードなし。
- 岸壁、自然岩、海藻、流木、クラゲ、動く観測ブイへ更新。潮流の横流れ・クラゲの反発・移動足場の追従。神話/宇宙などの下層は未実装。
- Godot 4.7.2 / Windows x64 / 日本語 / オフライン。Forward+を標準にし、同じEXEをCompatibilityでも起動可能。原作素材の流用なし。
- 主人公はスーツ/マスク/タンク/フィンを持つ独自メッシュと関節アニメーション。光・深度霧・流れる微粒子・用途別の泡を追加。完成アートとは判定しない。

## 検証

- `check -BuildFolder windows-real`: format/lint/依存整合性、ルール381・シーン31、3経路、Windows Release export/EXE headless起動。
- 実GPUのvisual: 入水→足場→急降下/浮上→補給→酸素切れ→救助→再挑戦→300m。Forward+とCompatibilityを実行。クリアボタンの画素検査と960×540も確認。
- 最終経路: 通常86.93秒 / 補給直行82.23秒 / 寄り道90.95秒。最低酸素25.27%以上。代表救助は30m損失・2.27秒。
- RTX 4070 SUPER、1280×720、VSyncなし、静止3場面: Forward+中央値2.02〜2.03ms、P95最大2.76ms。GL中央値0.92〜1.06ms。単体GPU時間ではなく描画フレームの実時間。別GPUは未確認。
- CI: 今回のブランチをpush後に確認して、この行へ証跡を記録する。
- [画面・連続画像・評価](REVIEW_PACKET.md) / [自己レビュー](AI_REVIEW.md)。自動操縦の成功を面白さや製品品質の証明にしない。

## 次

[TASKS](TASKS.md) のDD-032→033→027。通常視点では足場が次目標を隠すためF俯瞰への依存が残る。素材の反復、海面の近景、主人公の姿勢遷移はさらに磨く。音/保存は未実装。Steam SDKはゲームの完成が見えてから。

## 再実行・既知の環境問題

- `./tools/setup.ps1` → `./dev.ps1 check` → `./dev.ps1 visual`。`benchmark -Renderer forward_plus` / `benchmark -Renderer gl_compatibility` で比較。
- このPCの最新版は **build/windows-real/DIVE DIVE.exe**。旧windows-previewを使用中でも別出力できる。配布はbuild/DIVE-DIVE-windows.zip。[起動方法](README.md)。
- GPU確認はローカル、Actionsはheadlessのロジック/build確認。成功範囲を混同しない。配布EXEの通常GPU起動・正常終了も両rendererで確認済み。
- 使用中EXEを上書きするとPCK埋め込みのrenameに失敗する。テストEXE終了後にexportを再実行。ユーザーのプロセスを勝手に停止しない。
- 配布EXEへ外部`--script`を渡す撮影試行はタイムアウトし不採用。通常EXE起動とソース側visualを別々に検証する。
- Godotはexit 0でもERRORを出すためdev.ps1はログ検査。shaderの毎フレームuniform更新は以前UI欠けを起こしたため、waterは組み込みカメラ座標を使用。
- MSAAはproject.godotのrenderingセクション。粒子billboardはscale保持、メッシュ上面はGodotの時計回り頂点順。いずれも初回画面レビューで修正済み。
