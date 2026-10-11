# バイオーム改善01：撮影・視覚レビュー引き継ぎ

実装と非描画検証は完了。**画像原本・見た目合格・実GPU FPSは未取得**です。この資料から別担当が撮影と評価を開始してください。

## 対象と取得

- リポジトリ：`shirai-masatomo/whitespace`
- 作業ブランチ：`codex/sporehollow-biome01`（mainへの統合は別判断）
- 比較前：`b5e9fe5a6b29cedc8646ff72fc809907ed191d52`
- 実装：`428e568cad8669aa9e89a910026c3b8bf22e8b27`
- Godot：`4.7.2.stable.official.ed1daf0bf`
- 比較seed：**31**。補助seed：1、17、97、2026。解像度：1280×800、必要に応じ1920×1080。
- 正式ソース：`C:\Users\masat\Documents\Codex\2026-10-10\task\colony-structure-01-work\projects\sporehollow`
- 通常入口の配布EXEは変更前のまま。最新版ショートカットを開いても今回の景観にはなりません。通常セーブを上書きせず、許可された検証チェックアウトを使用してください。

## 変更箇所

`game/biome_map.gd`に地形場・分布・保存。`board_art.gd`に連続した地面色と小さな草・小石。`world.gd`、`world_story_system.gd`、`colony_tasks.gd`は新規生成と保存への接続のみ。経路探索・移動速度・敵AI・戦闘・建築可能条件の実装は変更していません。

既存の樹木・岩・採集素材を再利用。新画像制作依頼なし。木材は切株の既存採集で現地に出ます。樹木の既存伐採条件を緩めたり、道具を新設したりはしていません。

## 再現と非描画テスト

ゲームフォルダーで、インストール済みGodotを指定して実行します。

```powershell
& .\review\current\biome01\run_headless.ps1 -Godot '実在するGodot実行ファイルの絶対パス' -Suite biome
& .\review\current\biome01\run_headless.ps1 -Godot '実在するGodot実行ファイルの絶対パス' -Suite regression
```

既定では`.tools/Godot_v4.7.2-stable_win64.exe`を使用。ログと専用データは`local-runs/日時/`。同梱の`tests/legacy-fixture`は旧版EXEで新規生成した人工データで、ユーザーの通常セーブではありません。

新規207項目と既存12スイート323項目が成功。[結果](test-summary.json)参照。古い朝保存テスト3失敗、古い敵侵入テスト9失敗＋エラーは変更前EXEでも同一再現。`-Suite known-baseline-failures`はその診断用で、正常終了を期待するセットではありません。

## 撮影手順

既存の承認済み隔離GPU環境と`tools/isolated_desktop.cs`を使用します。**通常デスクトップで直接起動しない**でください。WinSta0以外・NonInteractive・DesktopMatchedを記録し、APPDATA/LOCALAPPDATAを撮影ごとに分離、音Dummy・30fps・直列で実行。隔離失敗時の通常GUIへの切替はありません。この担当環境ではWindow Station作成がWin32 5で拒否され、再試行していません。

別担当の許可された隔離ランチャーへ渡す引数は以下です。これを通常のシェルから直接起動するためのコマンドではありません。

```text
--path "検証用ゲームフォルダー"
--audio-driver Dummy --rendering-method gl_compatibility --max-fps 30
--resolution 1280x800 --log-file "撮影出力/renderer.log"
--script "res://tests/capture_biome01.gd" -- --isolated-review
```

子プロセスの環境変数：

```text
FARM_REVIEW_OUTPUT = 今回専用の出力ディレクトリ（事前作成）
FARM_BIOME_VIEWS = review/current/biome01/views-seed31.json の絶対パス
APPDATA / LOCALAPPDATA = 今回専用のデータディレクトリ
```

撮影フィクスチャは新規seed 31の実ゲームを描画し、通常保存を無効化してPNG原本とmanifestを書き出します。構文確認だけ済み、GPU実行は未確認です。時計とphaseを合わせた制御画面であり、時間進行そのものの試遊結果ではありません。

比較前も同じ構図JSONと撮影スクリプトを外部ファイルとして使用してください。既存配布EXEをリソース元に使う場合のSHA-256は`A10287B62CE93C985891982C3A8B4B2B2CB67BD58722349A8113A8FA22110C1C`。`--path`の代わりに`--main-pack "比較前EXE"`、`--script`は今回の撮影スクリプトの絶対パスにします。比較後は更新ソースから描画してください。EXEやショートカットを増設・置換する必要はありません。

## 必須撮影と操作レビュー

構図JSONは21枚：全景、黄金像、開けた草地、疎林、岩場、草の多い土地、乾いた土地、四辺、四隅、切株の採集対象、採掘対象、および全景・黄金像の朝/夜。基本17枚は昼です。

追加で、採集・採掘対象を実際に選択し、現地の物資生成・運搬・備蓄までの画面を撮影。四辺四隅でカメラ到達、建築・回収・ゾーン指定、敵追跡と端越え連れ去りを操作確認してください。静止撮影だけではこれらは合格にしません。

同じ環境・seed・解像度・時間・カメラで前後比較し、FPSとフレーム時間を記録。30fps上限があるため、上限に張り付くことだけで余裕があるとは判断しないでください。色の連続性、矩形に見える境界、規則的な模様、木や岩の疎密、文字・住人・動物・敵・物資の視認性を朝昼夜で確認します。

原本は`review/current/biome01/before/`と`after/`へ保持。一覧画像は原本から作成し、manifestにseed・コミット・時刻・解像度・隔離記録を対応付けてください。過去レビュー02の画像を新景観の証拠へ流用しないでください。作業ブランチへpushし、REPORTに視覚評価と残件を追記します。

## 保存互換と保全

旧セーブの自然物は再生成しません。景観だけが新しくなるため、旧セーブ上の資源は新地形と完全には対応しないことがあります。新しい分布のレビューには専用の新規seed 31を使用してください。通常セーブを初期化して比較しないでください。

開始前からの`.import`／`.uid`1,341件を保持しています。作業者の既存変更をまとめてstage・resetしないでください。今回のコミットにこれらは含めていません。
