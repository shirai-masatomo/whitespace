# DIVE DIVE

**海へ飛び込み、足場と酸素を選びながら300mの海底を目指す3Dアクション。** リアル層のVertical Sliceへ向けて制作中のWindows版です。完成品質のビジュアルではありません。

## 今すぐ遊ぶ（Windows）

1. このPCの今回の最新版は **`build/windows-real/DIVE DIVE.exe`** をダブルクリック。
2. 「潜りはじめる」またはEnter。WASDで桟橋の端から海へ飛び込む。
3. マウスで下を見て足場へ。足場上で下を向くと、カメラが前上方へ回り込み次の足場を見渡せます。光る藻は触れた瞬間に酸素100%。
4. 300mの「海底の灯」に着地するとクリア。

旧版が起動中だったため、今回は `windows-real` に出力しました。`build/windows` の旧EXEはそのままです。別PCには `build/DIVE-DIVE-windows.zip` を展開して渡します。Godot/Python不要。[GitHub Actions](https://github.com/shirai-masatomo/whitespace/actions/workflows/dive-dive.yml) の最新成功実行の **DIVE-DIVE-windows** artifactでも配布物を取得できます。

| 操作 | 動作 |
| --- | --- |
| WASD / 矢印 | 水平移動。水中でも軌道修正可能 |
| マウス | 見回す |
| E長押し | 急降下。酸素消費2.5倍 |
| Space長押し | 水中で浮上。離すと自然沈降。Eとの同時押しは浮上優先 |
| Q長押し | 沈降を減速 |
| F長押し / Tab | 俯瞰 / 目標候補の切替 |
| V | 三人称 / 一人称 |
| Esc / Enter | 一時停止 / 再開 |

足場上では沈降が止まりますが、水中の普通の足場では酸素が減ります。光る藻のそばと海上では減りません。酸素0で泡になって浮上し、訪問済みの浅い安全地点で再挑戦。死亡画面・ロード・ワープなし。フォーカスを外すと一時停止。Spaceは水中の浮上操作で、桟橋上のジャンプではありません。

13足場、海中の酸素藻7か所、95/140/225mの補給迂回路、155mの動く観測ブイがあります。岸壁・自然岩・海藻・流木・クラゲを配置。潮流は横へ流し、クラゲは触れると反発します。泡を出す藻の周囲には魚群が集まり、Tabで目指す候補を選べます。遠景の岩は装飾です。セーブ・音・Steam SDK・オンラインは未実装。

**代表画面・連続画像・調整値・性能比較**は [REVIEW_PACKET](REVIEW_PACKET.md)。[現在地](PROJECT_STATE.md) / [次タスク](TASKS.md) / [AIレビュー](AI_REVIEW.md)。

標準はForward+（Vulkan対応GPU）。描画に問題があれば同梱の `Play-Compatibility.ps1`、または `./dev.ps1 play -Renderer gl_compatibility` でOpenGLへ切り替えます。同じゲーム内容で、体積霧は近似光線になります。

## 開発と検証

Windows x64、開発時のみPython 3.12以上。リポジトリルートから:

```powershell
cd projects/001-first-release
./tools/setup.ps1
./dev.ps1 check
./dev.ps1 visual
./dev.ps1 play
```

旧ゲームを終了せず再buildする場合は `./dev.ps1 check -BuildFolder windows-real`。通常の出力は `build/windows`。実行制限がある場合は、この信頼したスクリプトに限り `powershell -NoProfile -ExecutionPolicy Bypass -File ./dev.ps1 check`。マシン全体のポリシーは変更しません。

- `setup`: Godot 4.7.2・Windowsテンプレートを公式SHA512で検証、固定版の開発ツールを専用venvへ導入。
- `check`: format / lint / 開発依存整合性 / import / ルール・シーンテスト / evaluate / release export / EXE headless起動 / 配布zip。
- `evaluate`: 6経路と対照条件の時間・最低酸素・カメラ遮蔽・救助、移動速度・酸素切れ時間を `artifacts/evaluation.json` へ。到達失敗、酸素余裕不足、俯瞰の遮蔽はCI失敗。
- `visual`: 実GPUで海上→入水→各操作→失敗→再挑戦→300mを進め、代表画面・カメラ比較・960×540のUIを `artifacts/<renderer>/` へ。従来の `artifacts/*.png` にも複製。画面外・フォーカスなし・マウス非捕捉で実行し、画像の目視確認も行う。
- `benchmark -Renderer forward_plus` / `benchmark -Renderer gl_compatibility`: 同じ3場面の1280×720フレーム時間と描画数。結果は `artifacts/render-*.json`。
- `format` / `test` / `lint` / `build` / `editor`: 個別実行。生成ログは `artifacts/`、レビュー用の選別画像は `review/`。

GitHub ActionsはWindowsでsetup/checkを実行しZIP・ログ・測定JSONを保存。GPU確認はローカルで実施します。レビュー画像・開発用ファイルは配布ゲームから除外。

## 構造と変更の入口

- `game/dive_config.gd` / `default_config.tres`: 移動・酸素・救助の調整値。
- `game/stage_layout.gd`: 足場の位置・大きさ・補給・往復移動の振幅/速さ。
- `game/dive_model.gd`: 描画と独立した上面着地・移動・酸素・救助。
- `game/diver.gd`: 主人公モデルと姿勢。`ocean_geometry` / `ocean_nature` / `ocean_lighting` / `ocean_effects`: 形状・自然景観・光・泡/粒子。
- `game/main.gd`: 入力/カメラ、`world.gd` / `shaders/`: 水面・深度別照明・リアル層景観、`hud.gd`: 日本語案内。
- `tests/`: ルール、実シーン入力、自動操縦、GPU撮影。`route_driver.gd` はテスト用の操縦のみ。
- 自律作業は [AUTONOMY](AUTONOMY.md)。Godotを継続使用。UE5移行を要する具体的な制約はまだ確認していません。

## 素材と権利

他ゲームの素材・ステージは使用していません。景観・スーツモデルは独自のコード生成メッシュ/シェーダー。日本語フォントは [Noto Sans JP](https://github.com/google/fonts/tree/main/ofl/notosansjp)、[SIL OFL](assets/fonts/OFL.txt)。[Godotの著作権・第三者表示](assets/GODOT_COPYRIGHT.txt)もZIPへ同梱。
