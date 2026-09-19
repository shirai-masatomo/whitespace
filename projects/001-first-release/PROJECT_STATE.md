# DIVE DIVE — PROJECT STATE

更新: 2026-09-19

## 現在地

**Phase 3 / 面白さの仮説試作 / CHANGES・SELF_CONTINUE**。450m人間試遊DD-050は「まだ面白くない」で完了。岩から岩への反復が主問題。探索・未知・酸素・現象を比較し、すぐ人間へ戻さない。

- 海上から飛び込み、自然沈降/E急降下/Space浮上。450mの既存経路は維持。酸素0は同じ世界で救助される。
- 序盤に入れる巨大泡2個、曲がる潮流、内部を通れる岩アーチ、大型生物を試作。泡は即補給し上へ押す一時避難場所。藻だけが救助地点を更新する。泡/穴を経由しない道も残る。
- 18案から複数仮説を試し、3段階で自己批評・改善。整った輪/エイ拡大/光る玉の列を棄却。流れから自然沈降で落ちる問題を修正。面白さPASSではない。
- 最新ローカルEXE: **build/windows-preview/DIVE DIVE.exe**。人間試遊済み450mのbuild/windowsと旧windows-realは保持。[起動](README.md) / [評価入口](REVIEW_PACKET.md) / [自己レビュー](AI_REVIEW.md)。
- Godot 4.7.2、日本語、Windows x64、Forward+ / Compatibility、独自生成素材。Steam・保存・450m以深は未実装。

## 確認済み

対象コード `bab488e`。`check -BuildFolder windows-preview` 成功: format/lint/依存整合性、ルール479・シーン430・音57・実衝突689・探索比較19、Windows Release build/配布EXE headless起動。上面メッシュ2688点は補助証拠のみ。既存11実経路を維持。

Forward+/GLで泡→潮流→穴→藻へ連続入力、通常操作/失敗/再挑戦/450m、配布EXE120フレーム起動成功。Forward+で岸壁/沖側の連続試走も成功。画面外・無音・非捕捉で実施、人間のプロセスは停止していない。

- 同じ80m地点: 酸素30%で直行失敗/泡経由7.72秒で生還。100%なら泡なし4.37秒で成功。
- 無入力4秒: 流れありは曲がり角まで0.37m、なし40.62m。横へ離脱可能。
- RTX 4070 SUPER / 1280×720 / 6静止場面: Forward+中央値2.04〜3.01ms・P95最大4.21ms、GL1.00〜1.71ms・1.95ms。GPU単体時間/全場面の最悪値ではない。
- CI: 初回試作 `a26bc09` [成功](https://github.com/shirai-masatomo/whitespace/actions/runs/35443019280)。最終コード `bab488e` [成功](https://github.com/shirai-masatomo/whitespace/actions/runs/35444306861)。

## 未解決と次

1. DD-054: 0〜140mの寄り道以降も、最初の数分の判断/景観/操作が変わる構成へ。理想操縦21.68秒を初見5分の証明にしない。
2. DD-055: 桟橋からの手掛かり、生物と岩の重なり、流れの境界を読みやすくする。
3. DD-056: 空気洞で泳ぐ→歩く→別穴へ、または魚群を追う海藻林を比較し、弱い案を捨てる。

面白さ・初見の発見率・音色・別GPU・長時間は未確認。巨大生物は非固体の背景生物で、乗る遊びではない。市販作品同等/1000m完成とはしない。最新方針はHUMAN_DIRECTION/EXTERNAL_AI_REVIEWを読む。別ブランチに届いた外部レビュー`bb79ec7`も取り込み済み（対象は旧450m版、新試作へのPASSではない）。

## 再実行と環境メモ

`./tools/setup.ps1` → `./dev.ps1 check -BuildFolder windows-preview`。画面変更は`visual`/`visual-reef`/`visual-discovery`。詳細ログはartifacts、選別画像/測定はreview。Actionsはheadless、画質はローカル実GPUで確認。

使用中EXEを上書きしない。GPUは画面外・Dummy音声・非捕捉、終了は自分のプロセスのみ。Godotのexit 0でもERRORログを失敗扱い。Dummyでは音の再生を開始しない。外部--scriptによる配布EXE撮影は不採用、ソース画面とEXE起動を分ける。

穴が通れなかった原因は旧岸壁との重なり。テスト閾値ではなく岸壁位置を修正。曲がる潮流は通常沈降を支える浮力が必要、Q固定で運ばれる前提は廃止。実プレイヤーの連続掃引カプセルを使用し、軽量モデルの上面計算を全方向衝突の証明に使わない。
