# DIVE DIVE

WhiteSpaceの初期リリースを目指す、3D水中アクション。**早く深く潜りたい。でも急ぐと深度を失う。**
現在は300mの縦型空間で、この核を試す最小プロトタイプ。まず人間が触って面白さを判断する。

## 今すぐ遊ぶ（Windows）

1. このPCでは `build/windows/DIVE DIVE.exe` をダブルクリック。
2. 「潜りはじめる」またはEnter。
3. Eで潜り、圧力が高くなったらEを離して待つ。300mへ到達するとクリア。

別PCへ渡す場合は `build/DIVE-DIVE-windows.zip` を展開して起動する。Godot・Pythonのインストールは不要。GitHub Actionsの **DIVE-DIVE-windows** artifactからも取得できる。

| 操作 | 動作 |
| --- | --- |
| WASD / 矢印 | 水平移動 |
| マウス | 視点 |
| E / Q | 潜る / 浮上 |
| Shift + E | 急降下（圧力が速く上がる） |
| Esc / Enter | 一時停止 / 再開 |

負荷100%で最大55m強制浮上し、自動で操作が戻る。死亡画面・ロード・シーン再生成は使わない。フォーカスを外すと一時停止。セーブ・酸素・Steam SDK・オンラインは未導入。

## 開発と検証

Windows x64、開発時のみPython 3.12以上が必要。リポジトリルートから:

```powershell
cd projects/001-first-release
./tools/setup.ps1
./dev.ps1 check
./dev.ps1 play
```

PowerShellでスクリプト実行が制限される場合は、この信頼したスクリプトだけ `powershell -NoProfile -ExecutionPolicy Bypass -File ./dev.ps1 check` のように実行する。マシン全体のポリシーは変更しない。

- `setup`: Godot 4.7.2とWindowsテンプレートを公式SHA512で検証して取得。専用venvへ固定バージョンの開発ツールを導入。初回テンプレート取得は約1.3GB。
- `check`: format / lint / 開発依存整合性 / import / ルールとシーンのテスト / Windows release build / 出力EXEのheadless起動 / 配布zip。
- `visual`: GPU描画で危険・強制浮上・回復・ゴール・再挑戦・960×540表示を再現。`artifacts/*.png` を目視確認する。
- `format` / `test` / `lint` / `build` / `editor`: 個別実行。重要な実行ログは `artifacts/*.log`（Git対象外）。

GitHub ActionsはWindows上でsetupとcheckを実行し、ビルドとログをartifactに保存する。GPU画面確認はローカルで行う。

## 構造と仮のルール

- `game/dive_model.gd`: 深度・圧力・強制浮上・ゴールの独立したルール。
- `game/dive_config.gd` / `default_config.tres`: 速度・回復・失う深度等の調整値。
- `game/main.gd`: 入力・カメラ・進行。`world.gd`: オリジナルのプリミティブ3D空間。`hud.gd`: 日本語表示。
- `tests/`: headlessルール検証、実シーンの入力と一時停止、GPU描画検証。
- [PROJECT_STATE](PROJECT_STATE.md) / [TASKS](TASKS.md) / [AUTONOMY](AUTONOMY.md): 再開時に読む。

潜降14m/s、急降下約23m/s、圧力は潜った距離と速度で増える。停止・浮上で毎秒13回復、限界で55m戻され、負荷20から再挑戦する。これらはプレイ感レビューで変えてよい。海底ゴールと世界の形はこの300m試験用で、任意の深度のステージ生成は次段階の対象。

Godotを採用した理由は、小さな3D試作をテキスト資産とCLIで反復できるため。UE5の大規模環境機能は、この核の検証には不要と判断した。[Godot CLI公式資料](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html)

## 素材と権利

他ゲームの素材・ステージ・演出は使用していない。コード生成のプリミティブ空間のみ。
日本語フォントは [Noto Sans JP](https://github.com/google/fonts/tree/main/ofl/notosansjp)、[SIL OFL](assets/fonts/OFL.txt)を同梱。Godotの [著作権・第三者ライセンス表示](assets/GODOT_COPYRIGHT.txt)も配布zipへ同梱する。フォントは2026-09-19に取得したファイルをGitで固定。
