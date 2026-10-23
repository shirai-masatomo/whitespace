# ヒロイン専用LoRAの制作手順

**学習済みヒロインを使って生成したいだけなら、この学習工程をやり直す必要はない。** [初回ガイド](COMFYUI_FIRST_STEPS.md)の04を使う。以下は既存LoRAの制作・選択過程を記録した応用資料。

対象は、成人オリジナルヒロインの原画と候補画像からLoRAを学習し、ComfyUIで別衣装やポーズを検証して利用可能にするまで。2026年10月22日のv1で実施した設定、ファイル、結果を基にする。

**今回採用したのは800ステップ時点の重み。上限1200ステップの学習から保存した途中版であり、800ステップが常に十分という結論ではない。** 3課題の比較では800版と1200版の差が小さかったため800版を選んだ。識別語だけでの人物固定や服の丈・色には改善が残る。

工程は、原画を決める → 原本を保全する → 候補を選別する → キャプションを付ける → 専用環境を用意する → 短い試験をする → 学習する → 重みを比較する → ComfyUIへ配置する → 別衣装とポーズを検証する → 結果と残存物を記録する、の順で進める。

## 原画と目的を決める

人物の顔、前髪、髪色、目、体型、成人の年齢感、描き方について最優先の原画を1枚決める。候補画像同士が似ていても、原画から離れていれば学習でその差まで定着するため、原画との比較を優先する。

今回の場所は次のとおり。

| 用途 | 絶対パス |
| --- | --- |
| 作業領域 | `［作業フォルダー］` |
| 最優先原画 | `［作業フォルダー］/projects/local-ai-image-lab/sample/ヒロイン/neutral.png` |
| 候補画像 | `［作業フォルダー］/projects/local-ai-image-lab/sample/ヒロイン/まとまり/Lora用` |
| 今回の学習と検証 | `［作業フォルダー］/projects/local-ai-image-lab/training/heroine_lora_v1_20261022` |

原画が見つからない場合は取得先を確認し、学習を開始しない。完成条件は「人物が原画に近いこと」と「指定した衣装・表情・姿勢へ変更できること」を分けて決める。画像生成が正常終了しただけでは品質合格にしない。

## 実行範囲を確認する

[環境保護規約](../notes/c09b73968e22eebe41d2.md)、[プロジェクトの指示](../notes/978725407db052d12f0b.md)、[実務知識](COMFYUI_KNOWLEDGE.md)を確認する。新しいツールやモデルの取得、通常Windows上での実行に必要な承認範囲を確定する。

今回のv1は、ユーザーが承認した通常Windows上で専用venv・プロファイル・キャッシュを使用した。VM隔離ではなく、VM内テストは行っていない。[承認記録](../reports/COVERAGE.md#同梱しないもの)は今回の実験の記録として保存する。次回用に内容を自動複製して承認済みと扱わない。

資料・手順書の編集だけなら学習やComfyUIを起動する必要はない。既存ComfyUIへのpip導入、システム設定・レジストリ・GPUドライバーの変更、他の作業プロセスの停止は避ける。

## 原本を保全して一覧を作る

1. 原画と候補画像を専用の保全フォルダーへ無加工コピーする。
2. 元ファイル名、絶対パス、画像サイズ、透過の有無、SHA256を台帳へ記録する。
3. コピーと原本のハッシュ一致を確認する。
4. 一覧画像を作り、ファイル名と人物を対応させる。

今回の実装は [audit_dataset.py](../reports/COVERAGE.md#同梱しないもの)。原本台帳は [inventory.json](../reports/COVERAGE.md#同梱しないもの)、原画台帳は [canonical-original.json](../reports/COVERAGE.md#同梱しないもの)。保全コピーは学習フォルダーの `audit/sources` にある。

今回の候補は27ファイル。基準の比較画像1ファイルに左右2カットが入っていたため、分割後は28カット相当となった。台帳のB・Aで始まるIDは作業用の識別子であり、ユーザーの丸数字と同じ番号ではない。

## 学習用と検証用を選別する

原画と比べて、顔、前髪、髪の長さ、体格、描き方がずれている画像を探す。衣装の厚みや姿勢による見え方の違いを、すぐ別人・体型不一致と決めつけない。重複候補も目視で確認する。画像ハッシュの近さは人物同一性の評価値ではない。

今回の採否は次のとおり。

| 処理 | 内容 |
| --- | --- |
| 比較画像を分割 | B07を左右へ分け、中央4pxを除く。各885×887px |
| 2人画像を除外 | A08・A09・A13・A19。初回は人物1人の学習を優先 |
| 構図の近い画像を除外 | A05。A14の正面上半身と近いため今回は採用しない |
| 検証用へ取り分け | A06の半閉じ目・照れ、A20の髪に手を添える全身。学習へ入れない |
| 候補から学習へ採用 | 21カット |
| 最優先原画を追加 | N00として1枚追加し、計22枚 |

完全なファイル重複は0組だった。除外画像は削除せず、理由とともに保管する。採否と元ファイルの対応は [selection.csv](../reports/COVERAGE.md#同梱しないもの)、[詳細JSON](../reports/COVERAGE.md#同梱しないもの)を参照する。

今回の検証用2枚も同じ制作群の画像なので、独立した統計的なテストデータとは扱わない。生成による水増しは行わなかった。

## 学習用コピーとキャプションを作る

[prepare_dataset.py](../reports/COVERAGE.md#同梱しないもの)で、採用画像と同名の説明テキストを用意した。透過画像は学習用コピーのみ白背景へ合成する。原本は透過を含め変更しない。左右反転、色変更、人物の再描画は行わない。

保存先は、原画が `dataset/anchor`、他の21枚が `dataset/character`、学習に使わない2枚が `validation/holdout`。原画は2反復、他は各1反復とした。これは原画を少し重視する初回設定で、最適な配分を確定したものではない。

各キャプションの先頭へ識別文字列 `wshrn26` を付け、服、向き、画角、姿勢、手、表情、背景を説明する。衣装や姿勢を説明しておくことで、それらも人物固有の特徴として固定されることを減らす狙いがある。

原画のキャプションは次の内容。

```text
wshrn26, 1girl, adult woman, solo, anime illustration, full body, standing, three-quarter view, looking at viewer, gentle smile, hands clasped in front, blue cardigan, white turtleneck, gold necklace, navy blue ankle-length pleated skirt, black low heel pumps, white background
```

識別文字列は、新しい単語や埋め込みの登録ではない。今回の学習キャプションでは顔・髪・目・体型を人物の特徴へ結び付ける方針にしたが、別衣装で髪色を明記しない追加テストは未達だった。キャプション方針が最適だったと結論せず、生成時は `blonde hair, long hair, blue eyes` を併記する。

## 学習環境を用意する

最初にGPU、空き容量、既存モデル、Pythonと依存の状態を確認する。今回のGPUはRTX 4070 SUPER 12GB。ComfyUI用Pythonと学習用Pythonを分け、既存の基盤モデルを読み取り利用した。

| 項目 | 今回の環境 |
| --- | --- |
| 学習ツール | sd-scripts v0.12.2 |
| 固定コミット | `11d8cedd0c67b93a10f8b2d75f43554f6f12c794` |
| 学習用Python | 3.10.6 |
| PyTorch | 2.8.0+cu128 |
| transformers | 5.17.0 |
| diffusers | 0.40.0 |
| accelerate | 1.15.0 |
| 基盤モデル | 既存Animagine XL 4.0 opt、内蔵VAE |
| 専用venv | `［作業フォルダー］/tools/local-ai-foundation/runtime/lora-v1` |
| キャッシュと一時領域 | 同じ階層の `lora-v1-cache` と `lora-v1-temp` |
| 学習ソース | 今回の学習フォルダー内 `runtime-private/sd-scripts` |

導入実装は [install_runtime.py](../reports/COVERAGE.md#同梱しないもの)、プロセスごとの保存先設定は [runtime_tools.py](../reports/COVERAGE.md#同梱しないもの)。同じPython・CUDA版の既存Torchとtorchvisionを専用venvへ読み取りコピーし、追加依存をその複製へ導入した。バージョンが異なる環境から機械的にコピーしない。

深いパスではTorchのヘッダー、pipの一時ファイル、Hugging FaceキャッシュがWindowsのパス長制限に当たった。今回はvenv・TEMP・キャッシュを短い専用パスへ置いて解決し、OSの設定は変えていない。

`pip check`、CUDA、bf16対応、学習引数、データ定義を確認する。トークナイザーは専用キャッシュへ取得し、学習時はネット接続を無効にする。キャプションの長さも確認し、今回は最大67トークン、設定上限225以内だった。依存一覧は [install-freeze.log](../reports/COVERAGE.md#同梱しないもの)、環境確認は [runtime-verified.json](../reports/COVERAGE.md#同梱しないもの)に保存した。

## 学習と比較の設定を固定する

実行した設定の原本は [train.executed.toml](../reports/COVERAGE.md#同梱しないもの)、画像の読込設定は [dataset.toml](../reports/COVERAGE.md#同梱しないもの)。

| 設定 | 値と意味 |
| --- | --- |
| 学習対象 | UNetのLoRAのみ。Text Encoderは学習しない |
| rankとalpha | rank16、alpha8 |
| optimizerと学習率 | AdamW、5e-5、weight decay 0.01 |
| 学習率の変化 | cosine、warmup60ステップ、全体の上限1200ステップ |
| 精度 | mixed precisionと保存はbf16 |
| 解像度 | 1024相当、縦横比ごとのbucket、512〜1536、64刻み、元画像を拡大しない |
| batchと蓄積 | batch1、gradient accumulation1 |
| 保存 | 400ステップごと、safetensors形式 |
| seed | 学習20261022 |
| メモリー対策 | gradient checkpointing、SDPA、latentとTE出力のディスクcache |
| その他 | VAEは半精度にしない、data loader worker0、max grad norm1.0 |
| 画像と説明の変更 | 反転・色変更・caption shuffle・caption dropoutなし |

latent cacheを使う条件で画像の色変更・ランダムクロップを混ぜない。TE出力cacheを使う間は、caption shuffle/dropoutやTE自体の学習を組み合わせない。画像・説明・tokenizer・TE設定を変える次回実験では、v1のcacheをそのまま再利用しない。

## 比較基準と短い試験を作る

学習後の結果だけを見ず、同じ基盤モデル・文章・seedでLoRAなしの画像を先に作る。今回の基準は6課題×2seedの12枚。環境導入と並行して生成したが、GPU学習とは同時実行していない。

その後、20ステップの試験学習でモデル読込、cache作成、メモリー不足、lossのNaN・Inf、重み保存を確認した。試験は約81秒で正常終了。重みの構造と数値が正常でも、人物が似ていることの証明にはしない。

GPU使用量はPC全体の観測値と、学習プロセスのPyTorch使用量を区別する。Windows venvのlauncherは実際の学習Pythonとは別PIDになることがあり、小さいlauncherのRAM値を学習負荷として報告しない。今回は学習本体内でRAMを測定した。

## 本学習を実行する

今回の本学習は1200ステップまで進め、400・800・1200の途中版と最終ファイルを残した。原本の画像と既存の基盤モデルは上書きせず、専用出力先へ保存する。[run_training.py](../reports/COVERAGE.md#同梱しないもの)が専用環境を付けて実行し、[training_entry.py](../reports/COVERAGE.md#同梱しないもの)が学習本体のメモリーを記録する。

以下は今回実行したコマンドの記録。**完成済みv1のフォルダーで再実行すると、設定・ログ・状態・同名出力を書き換える可能性がある。次回は新しい実験フォルダーと出力名を作り、スクリプト内の固定パス・採否・番号・保存先・実行承認を見直してから使う。** 単に手順を読む目的で実行しない。

```powershell
$WorkspacePath = '［作業フォルダー］'
$ExperimentPath = Join-Path $WorkspacePath 'projects/local-ai-image-lab/training/heroine_lora_v1_20261022'
$ControlPython = '［PC内のパス］'
$PreparationPython = Join-Path $WorkspacePath 'tools/local-ai-foundation/runtime/ComfyUI_windows_portable/python_embeded/python.exe'

# 原本の一覧と学習用コピーを準備
& $PreparationPython -B (Join-Path $ExperimentPath 'audit_dataset.py')
& $PreparationPython -B (Join-Path $ExperimentPath 'prepare_dataset.py')
& $PreparationPython -B (Join-Path $ExperimentPath 'prepare_validation.py')

# 新規取得の承認範囲内で専用環境を導入
& $ControlPython -B -s (Join-Path $ExperimentPath 'install_runtime.py') bootstrap
& $ControlPython -B -s (Join-Path $ExperimentPath 'install_runtime.py') packages

# LoRAなしの比較画像を生成し、サーバー終了を確認
& $ControlPython -B -s (Join-Path $ExperimentPath 'run_validation.py') baseline

# 環境検査、20step試験、本学習の順に進める
& $ControlPython -B -s (Join-Path $ExperimentPath 'run_training.py') preflight
& $ControlPython -B -s (Join-Path $ExperimentPath 'run_training.py') trial
& $ControlPython -B -s (Join-Path $ExperimentPath 'run_training.py') train

# 重みの構造と有限値を検査し、比較対象の台帳を作る
& $PreparationPython -B (Join-Path $ExperimentPath 'inspect_lora.py') train

# 3段階の重みを画像生成して比較
& $ControlPython -B -s (Join-Path $ExperimentPath 'run_validation.py') screen
& $PreparationPython -B (Join-Path $ExperimentPath 'build_review.py') screen
```

各工程の正常終了を確かめてから次へ進む。GPU学習とComfyUIの検証サーバーは同時に動かさない。サンドボックス内でネットワークやローカル接続が制限される実行環境では、承認された実行方法で行い、OSの設定変更で回避しない。

## 重みを画像で比較して採用する

基準衣装、緑のスポーツ服、赤いブラウスの横顔を、seed42006、LoRA強度0.75、同じ文章で400・800・1200版に生成させた。追加生成は9枚。LoRAなしの比較基準は既存の12枚から該当画像を使う。

[重み比較画像](../media/ad1b5267d0eb10665629.jpg)を原画と見比べ、顔、前髪、体格、画風、衣装指定、手足を評価する。今回の800版と1200版の差は小さく、1200版を優先する明確な改善が見られなかったため、800版を初回候補へ選んだ。[選定記録](../reports/COVERAGE.md#同梱しないもの)に判断を残す。

**次回の上限を800へ変えると、cosineの学習率が800に向かって下がるため、今回の1200上限で保存した800版とは学習経路が変わる。** 800版を再現したい場合は、保存済みの重みを使うか、今回の設定全体を保って途中版を選ぶ。上限800の新しい設定は別条件として短い比較を行う。

チェックポイントを読み込むときも、800から学習を継続すれば同じ結果になるとは考えない。今回の保存対象はLoRA重みで、optimizerを含む完全な再開状態は保存していない。

## 採用版をComfyUIへ配置する

目視で採用を決めた後に [install_selected.py](../reports/COVERAGE.md#同梱しないもの)を使い、選んだ重みのハッシュを照合してコピーする。同名の異なるファイルを上書きしない。

| 用途 | 今回のファイル |
| --- | --- |
| 採用した800版の保存原本 | 学習フォルダーの `output/selected/heroine_wshrn26_animagine40_v1.safetensors` |
| ComfyUIで使う800版 | `［作業フォルダー］/tools/local-ai-foundation/runtime/ComfyUI_windows_portable/ComfyUI/models/loras/heroine_wshrn26_animagine40_v1.safetensors` |
| 最終1200版 | 学習フォルダー直下の `output/heroine_wshrn26_animagine40_v1.safetensors` |

**同じファイル名でも、`output/selected` と `output` 直下では中身が異なる。採用版を渡す際はselectedのファイルを使う。** 採用800版は85,430,940byte、SHA256は `2f39815fd629b430cce9e910a800a272e8dc8d7559998c1cdaacd0bb2df68e9f`。[配置記録](../reports/COVERAGE.md#同梱しないもの)で絶対パスとハッシュを確認できる。

## ComfyUIで画像を作る

既存の承認済みの方法でComfyUIを起動し、[画面用ワークフロー](../reports/COVERAGE.md#同梱しないもの)を読み込む。画面用JSONの接続は静的確認済みで、対応するAPIグラフでは生成を確認した。GUIの手動操作自体は今回未検証。

| 項目 | 開始条件 |
| --- | --- |
| Checkpoint | `animagine-xl-4.0-opt.safetensors` |
| LoRA | `heroine_wshrn26_animagine40_v1.safetensors` |
| LoRA model強度 | 0.75 |
| LoRA clip強度 | 0.0。今回TEのLoRAは学習していない |
| 画像サイズ | 832×1216 |
| StepsとCFG | 28、5 |
| SamplerとScheduler | Euler ancestral、normal |
| 比較用seed | 42006と43000 |

基本の文章は、識別語・人物の特徴・今回変える衣装や姿勢の順で指定する。例として、検証に使った別衣装の文章は次の内容。

```text
wshrn26, 1girl, adult woman, solo, blonde hair, long hair, blue eyes, full body, standing, looking at viewer, green zip-up sports jacket, white t-shirt, dark gray jogger pants, white sneakers, white background, masterpiece, best quality, very aesthetic
```

共通Negativeは次の内容。

```text
worst quality, low quality, lowres, bad anatomy, bad hands, extra digits, missing fingers, extra limbs, multiple people, text, watermark
```

髪・目の語を省いた別衣装の1例は暗髪になったため、今は容姿を併記する。閉じ目を作る場合は、今回の追加確認では `looking at viewer` や `blue eyes` などを外し、`closed eyes, laughing` とNegativeの `open eyes` を使って閉じ目が出た。複数語を変更した結果なので、単一語だけで必ず改善するとは扱わない。

## 別衣装とポーズを検証する

初回はIPAdapter・OpenPose・inpaint・顔修復を併用せず、LoRA自体の効果を調べる。同じ文章とseedのLoRAなし画像へ並べ、人物と指定内容を分けて見る。seed固定は人物固定の保証ではない。

今回の基本比較は、基準衣装、緑スポーツ服、赤ブラウスの横顔、黄セーターの椅子座り、照れ笑い、紫の上着で髪に手を添える姿の6課題×2seed。

| 確認 | 観察結果 |
| --- | --- |
| 顔と描き方 | LoRAなしより前髪・顔立ち・体格・描き方が教材へ近づいた |
| 衣装変更 | 緑・赤・黄・紫の衣装を反映し、青い上着へ一律には固定されなかった |
| 識別語だけの固定 | 髪色を省いたスポーツ服の追加1例は暗髪。容姿の併記が必要 |
| 表情 | 初回の閉じ目は2例とも未達。文章調整後の追加1例では閉じ目を確認 |
| 丈と色 | 基準衣装の一方はミニ丈。丈を強めた追加例は長くなったが、紺指定がベージュへ変化 |
| 細部 | 上着の開き、装飾、布の光沢・陰影、手などに差が残る |

追加確認は [prepare_probes.py](../reports/COVERAGE.md#同梱しないもの)で3課題×LoRAなし／ありの6枚を作成した。基本比較24枚、重み比較9枚、追加確認6枚で、**新規生成は計39枚**。原画や学習コピー、一覧画像の作成は生成枚数へ加算しない。

比較結果は [seed42006](../media/0fc95d46848ad9008079.jpg)、[seed43000](../media/188c2027fb4c0178195e.jpg)、[追加確認](../media/9bec77936576ca4c6706.jpg)。少数の選択的な比較を一般的な合格率へ換算しない。

## 構図を固定して表情差分とGIFを作る

LoRAの全体生成だけでは、仰向けの向き・腕・手などを指定画像へ完全一致させる保証はない。構図を保って量産したい場合は、承認した基準画像を1枚固定し、必要な領域だけを編集する。今回の[追加18枚の結果](experiments/heroine-lora-v1-clothes-poses-romance-20261022.md)と[GIFの実験記録](experiments/heroine-lora-v1-gif-20261022.md)を参照。

今回のGIFは、動画生成モデルを使わず、静止画の局所差分と小さな2D変形から作った。

1. **基準画像を保全する。** 原寸PNGのコピーとSHA256を保存し、全フレームで同じ寸法・位置を使う。今回は832×1216の照れた人物画像を使用した。
2. **動かす範囲をマスクにする。** まばたきは左右の目、笑顔は口元だけを指定する。基準画像に合わせて座標を決める。今回の座標を別画像へそのまま流用しない。
3. **ComfyUIで差分の静止画を作る。** CheckpointLoaderSimple → LoRA → CLIPTextEncode、LoadImage＋LoadImageMask → VAEEncodeForInpaint → KSampler → VAEDecode → SaveImageを接続する。モデルは採用800版、LoRA0.75 / CLIP0、28steps、CFG5、Euler ancestral / normal。今回の閉じ目はdenoise0.78、笑顔は0.82を候補にした。これは今回の画像での値であり、別画像の最適値ではない。
4. **編集範囲外を元画像へ戻す。** 生成結果を、境界をぼかしたマスクで基準画像へ合成する。今回は生成マスクの拡張6px、合成マスクのGaussianぼかし3px。マスク値0の画素は必ず元画像を使い、体・髪・背景の不要な変化を防ぐ。固定部分の一致は、この合成で達成している。
5. **動きと表示時間を組む。** 次の3種類をそれぞれ作る。見た目を確認し、不自然な差分を除外する。
6. **PillowでGIFへ保存し、復号して検査する。** 共通256色パレット・ディザなし・無限ループで保存。全フレームの寸法・時間・固定範囲の一致を確認する。GIFは減色されるので、元PNGとのRGB完全一致ではなく、GIFフレーム間で固定範囲が同じかを確認する。編集用の原寸PNG、マスク、生成条件も残す。

| GIF | フレームの作り方 | 今回の表示条件・限界 |
| --- | --- | --- |
| まばたき | 元の開眼画像と、目だけ描き直した閉眼画像を切り替える | 5フレーム、3.77秒ループ。閉眼は100〜120ms。中間の眼形は生成していない |
| 小さな呼吸 | 衣服の限定領域を最大3.2pxだけ縦に動かし、滑らかに戻す。顔・手・髪などは保護する | 24フレーム、各140ms、3.36秒。衣服の2D表現であり、自然な全身呼吸は未検証 |
| 恋愛表情の変化 | 元の微笑みと、口元だけ描き直した笑顔を短くフェードする | 13フレーム、4.1秒。実際の口形を連続的に変形させた動画ではない |

今回の作業ファイルは[GIFフォルダー](../reports/COVERAGE.md#同梱しないもの)へ保存。処理の順序は、親フォルダーの[prepare_gif.py](../reports/COVERAGE.md#同梱しないもの)で入力・マスク・APIを準備 → `gif/run_batch.py batch`で局所生成 → [review_frames.py](../reports/COVERAGE.md#同梱しないもの)で合成・比較 → 目視で採用 → [encode_gifs.py](../reports/COVERAGE.md#同梱しないもの)で3種類のGIF化 → [build_preview.py](../reports/COVERAGE.md#同梱しないもの)で比較表示 → [finalize.py](../reports/COVERAGE.md#同梱しないもの)で原本・出力・終了状態を確認、の順。

これらは今回の入力名・座標・採用フレーム名へ固定した実験スクリプト。別画像では新しい出力フォルダーを作り、入力・マスク・採用名を更新して使う。今回の記録整理ではスクリプトを再実行していない。生成を実行する場合も、既存の環境保護規約と承認範囲を確認し、他のGPU処理やサーバーを無断で停止しない。

[GIF一覧](../archives/19-lora-gif/index.html)と[検査記録](../reports/COVERAGE.md#同梱しないもの)で完成品と固定範囲の検証を確認できる。まばたき・笑顔のAI生成は3候補中2枚を使用。呼吸の24枚やフェード中間像をAIの新規生成枚数へ加算しない。

## 完了時に確認して記録する

原画と候補のハッシュ、保存した重み、コピー先の重み、検証画像を照合する。起動した学習・検証プロセスの終了を確認し、失敗した一時環境は対象の絶対パスと範囲を確認して整理する。専用venv、cache、重み、比較画像を残す場合は場所と容量を記録する。

今回の [最終監査](../reports/COVERAGE.md#同梱しないもの)では原本28ファイル、保護対象3ファイル、39枚の画像、LoRAコピーの一致を確認し、確認対象8PIDはすべて不在だった。既存ComfyUIへ追加したのは採用LoRA1ファイル。既存の依存・設定は変更していない。

本学習は読込込み約25分51秒。学習プロセスの最大Working Setは約20.0GiB、PyTorchの最大reservedは約7.0GiB、10秒間隔で観測したGPU全体は最大約8.7GiBだった。追加領域は当時の最終監査で約8.95GB。これらは今回の設定と環境での実測値で、他の画像枚数・設定の保証値ではない。

結果は [RESULTS.txt](../notes/2ab5bd7d1c95a5677b3d.txt)、実験の詳細は [実験記録](experiments/heroine-lora-v1-20261022.md)へ残す。設定、依存一覧、原本台帳、採否、キャプション、全文プロンプト、APIグラフ、重みのハッシュ、比較画像、失敗、未検証の項目を一緒に保管する。

## 次回の改善を決める

v1は、容姿の語を併記して別衣装・別ポーズを試す段階として利用する。次に改善する場合は、原画と教材の顔・髪・体型の差を再確認し、識別語だけの別衣装テストを先に置く。学習量・強度・識別語と容姿の学習方法は一条件ずつ比較する。

TEの弱い学習も検討候補だが、現在のTE出力cacheとは両立せず、12GB GPUでの実行可否を再検証する必要がある。服の細部や厳密な姿勢には、その後にOpenPoseやinpaintを別工程として試す。LoRA単独の効果と混同しない。今回、v2の追加学習やLoRAとの併用検証は実施していない。

## 参照先

- [sd-scripts固定版](https://github.com/kohya-ss/sd-scripts/tree/v0.12.2)
- [今回保存した学習設定](../reports/COVERAGE.md#同梱しないもの)
- [今回保存したデータ定義](../reports/COVERAGE.md#同梱しないもの)
- [今回の学習実行記録](../reports/COVERAGE.md#同梱しないもの)
- [今回の全文検証計画](../reports/COVERAGE.md#同梱しないもの)
