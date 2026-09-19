# DIVE DIVE — PROJECT STATE

更新: 2026-09-19

## 現在地

- **Phase 1 / 中核試作を更新・HUMAN_REVIEW**。海上からの入水、Space浮上、急降下の酸素コスト、接触補給を実装し、4サイクルの自己評価・修正を実施。Vertical Slice完成とは扱わない。
- 核: 下へ進むOnly Up系。自然沈降 → 足場で停止/見渡す → 酸素を瞬時補給 → さらに下へ。酸素0は泡で浅い訪問済み地点へ戻り再挑戦。死亡画面・ロードなし。
- 空/太陽/海面の見える桟橋から、同一シーンで300mへ。11足場・海中の補給5地点、95m分岐、155mの動くコンテナ、岩/遺跡/巨大鎖、深度による照明と霧の変化。
- Godot 4.7.2 / Windows x64 / 日本語 / オフライン。WASD・E急降下・Space浮上・Q減速、Tab候補切替、F俯瞰、V視点切替。
- 最終目標は正式リリース。今はSteamなしでもゲームが成立することを優先。セーブ・音・Steam SDK未実装。

## 検証とレビュー

- `check -BuildFolder windows-preview`: format/lint/依存整合性、ルール274 / シーン30チェック、3経路のevaluate、Windows export・EXE起動を検証。
- `visual`: 海上/入水/浅海の光/広い海/足場/自然沈降/急降下/浮上/補給/深海、救助・クリア・再プレイ・960×540を実GPUで撮影・確認。RTX 4070 SUPER / OpenGL 3.3。
- 通常87.50秒 / 補給直行82.33秒 / 寄り道91.43秒で自動完走。最低酸素24.27%以上。代表救助90→60m・2.27秒で操作復帰。
- CI: [Windows Actions #35421555882](https://github.com/shirai-masatomo/whitespace/actions/runs/35421555882) 成功（最終コード `ea6706d`）。setup/check・配布ZIP・測定ログの保存まで完了。詳細は [REVIEW_PACKET](REVIEW_PACKET.md)、自己レビューは [AI_REVIEW](AI_REVIEW.md)。

## 次の判断と課題

中核操作を変更した節目として「Spaceで修正しつつ急降下と補給を選ぶ遊びに、足場を経由する楽しさがあるか」を人間が評価する。可逆な実装の個別承認は不要。[起動方法](README.md#今すぐ遊ぶwindows)。次は [TASKS](TASKS.md) のDD-025〜027。

- 自動操縦は人間の迷い・入力ミス・面白さを評価しない。通常足場を省く経路が速い点はプレイ感の論点。
- 今回は照明/水面/スケールの試作。プリミティブ・簡易光線・上面だけの着地判定は完成品質ではない。Only Up級へ向けた素材/アニメーション/音/着地感、別PC性能は今後。
- 通常視点では足場が次の目標を隠すことがある。F俯瞰/方向案内で補助。水面下の光は簡易シェーダーで、物理的な体積散乱ではない。

## 再実行メモ

- `./tools/setup.ps1` → `./dev.ps1 check` → `./dev.ps1 visual`。測定のみはevaluate。
- 旧 `build/windows/DIVE DIVE.exe` が起動中のため、今回は **`build/windows-preview/DIVE DIVE.exe`** が最新版。ユーザーの旧プロセスは停止していない。`-BuildFolder windows-preview` で別出力可能。共通ZIPは今回の版。
- Godotはexit 0でもERRORを出すためログを検査。ユーザーデータへのアクセスは実行許可が必要な場合がある。
- exportはゲーム資産をすべて含め、tests/tools/build/artifacts/reviewを除外。日本語フォントの可変軸は整数OpenTypeタグ。
- 明るい空でUIが埋もれたため背景追加。水面の格子状反射を修正。深海で水面メッシュの端が見えるため距離/深度で減衰。

- 深海UI欠けは水面の毎フレームuniform更新で再現。シェーダー内のカメラ座標計算へ移すと解消。visualはクリア時の両ボタンをピクセルでも検証。
