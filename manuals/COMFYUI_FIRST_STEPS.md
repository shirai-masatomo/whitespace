# はじめてのComfyUI — このPC用の操作ガイド

更新：2026-10-22。[資料の入口](README.md) / [衣装・構図のプロンプト集](COMFYUI_PROMPT_COOKBOOK.md) / [保存と区分](COMFYUI_STORAGE.md)

まずは「既存モデルで1枚出す → 服の色を1つ変える → 構図を試す」の順で進める。追加モデル、拡張機能、LoRAの再学習は初回には不要。以下はこのPCの保存済み構成を読んで作った操作案内で、今回ComfyUIを起動して確認した手順ではない。

## 最初に確認すること

- 作業は承認済みの画像生成環境で行う。専用フォルダー・portable版・localhostは、Windows Sandbox／VMによる実行隔離とは別物。今回、VMの隔離状態は確認していない。
- ゲーム、Ren'Py SDK、Launcher、GUI自動操作を試す手順は含めない。それらの実行には[環境保護規約](../notes/c09b73968e22eebe41d2.md)が適用される。
- 起動済みのComfyUIがあれば二重起動しない。他の作業者のプロセスを停止しない。新規インストール・更新・モデル取得はここでは行わない。
- 最初は1枚ずつ。良い結果のPNGとワークフローJSONは保全し、変更版を別名で保存する。

## 1. 既存の起動方法と画面

既存の起動ファイルは次の場所。上の実行条件を確認したうえで、自分が操作する画像生成環境で使う。

```text
［作業フォルダー］\tools\local-ai-foundation\Start-ComfyUI.cmd
```

コンソールで準備が終わったら、ブラウザーで `http://127.0.0.1:8188` を開く。この起動ファイルはブラウザーを自動で開かない。コンソールはサーバー本体なので、生成中に閉じない。起動・接続できない場合は下の「困ったとき」を見る。

## 2. 最初のワークフローを開く

最初は [01-first-image.json](../reports/COVERAGE.md#同梱しないもの) を使う。ファイルをComfyUI画面へドラッグするか、ワークフローの「Open／開く」から読み込む。`.api.json` はプログラム用で、初回の画面読み込みには使わない。

読み込み時は現在の作業が置き換わるため、先に自分の未保存ワークフローをExport／保存する。一般的な操作は[公式の初回生成ガイド](https://docs.comfy.org/get_started/first_generation)に対応するが、導入済みフロントエンドの版でメニュー名や位置が異なる場合がある。

ひな形は次のフォルダーにある。

```text
［作業フォルダー］\projects\local-ai-image-lab\workflows\beginner
```

| 画面用ファイル | 練習すること | 確認状況 |
| --- | --- | --- |
| [01-first-image.json](../reports/COVERAGE.md#同梱しないもの) | 図書館・私服の成人女性を1枚 | 過去に生成した09の設定を使用。今回のコピーは未実行 |
| [02-clothing-color.json](../reports/COVERAGE.md#同梱しないもの) | 01の紺カーディガンを赤へ | 色の語だけ変更。新しい結果は未検証 |
| [03-composition-carpet.json](../reports/COVERAGE.md#同梱しないもの) | 横長・絨毯の横座り・素足 | 複数条件を変更した新しい練習案。品質未検証 |
| [04-heroine-lora.json](../reports/COVERAGE.md#同梱しないもの) | 学習済みのヒロインLoRAを使う | 800step選択版を使用。素足を指定した新プロンプトは未検証 |

01は通常の人物生成で、ヒロイン本人の再現用ではない。04も顔・服・手・ポーズの完全一致は保証できない。これまで内蔵画像生成で制作した素材と、ComfyUIの出力は別系統。

## 3. まず変更しない設定

読み込んだノードの日本語タイトルと、次の値を照らし合わせる。

| ノード | 初回の値・役割 |
| --- | --- |
| モデル | `animagine-xl-4.0-opt.safetensors` |
| Positive | 描きたい人物・服装・構図の文章。まず01のまま |
| Negative（01〜03） | `text, watermark, logo, blurry, deformed hands, extra fingers, duplicate people` |
| 画像サイズ・枚数 | 幅832、高さ1216、batch_size 1。03だけ横長1216×832 |
| KSamplerのseed | `42006`、生成後の制御は `fixed`（固定） |
| steps / CFG | `28` / `5.0` |
| sampler / scheduler | `euler_ancestral` / `normal` |
| denoise | `1.0`。今回は文章からの新規生成用 |
| VAE Decode | 変更不要。潜在データを画像へ変換する |
| SaveImage | 画像保存。初回prefixは `general/20261022/first-run/image` |

28steps・CFG5・Euler ancestralと上記の解像度は[Animagine XL 4.0の公式モデルカード](https://huggingface.co/cagliostrolab/animagine-xl-4.0)も参照した。今回はこのPCの過去の通常設定を優先している。モデルを変えた場合に同じ設定が適切とは限らない。

04のLoRAは `heroine_wshrn26_animagine40_v1.safetensors`、strength_model **0.75**、strength_clip **0.0**、識別語 **wshrn26**。Text Encoderを学習していないためCLIPを不用意に上げない。学習し直す必要はない。詳しい学習履歴は[LoRA制作記録](HEROINE_LORA_WORKFLOW.md)へ。

04のNegativeは元のLoRA検証用の語を保っているため、01〜03とは異なる。初回はそれぞれ読み込んだ値を保つ。LoRAは `tools/local-ai-foundation/runtime/ComfyUI_windows_portable/ComfyUI/models/loras/` に配置済み。見つからない表示が出たらファイル名を確認し、再学習や別の重みの取得はせず状況を記録する。

## 4. 実行して保存を確かめる

1. Positiveを01のままにし、SaveImageのprefixだけ日付・題材に合わせる。例：`general/20261022/first-run/image`。
2. 「Run／実行」ボタンを1回押す。対応する版では `Ctrl+Enter` も使える。完了前に何度も押すと待ち行列が増える。
3. 実行中はコンソールと画面にエラーがないかを見る。初回のモデル読み込み時間は環境次第。所要秒数は保証しない。
4. SaveImageの画像表示を確認し、実ファイルも次のフォルダーで確認する。

```text
［作業フォルダー］\tools\local-ai-foundation\outputs\images\general\20261022\first-run
```

ファイル名の例は `image_00001_.png`。連番は既存ファイルにより変わる。ブラウザーの右クリック保存はDownloads等へ入る場合があり、サーバーのSaveImage保存とは別。

5. ワークフローをExport／保存し、同じ試行のPNGと対応づける。[記録の雛形](../reports/COVERAGE.md#同梱しないもの)を自分の作業記録へコピーし、プロンプト、seed、変更点、結果を書いておく。
6. 画像が出たことと、採用できることは別に評価する。顔、手指、服の色・丈、座り方、室内の靴なし、背景との接地を確認する。

## 5. 衣装と構図を変えてみる

まず02で01と比較する。seedを固定し、カーディガン色だけ変える。意図した変更ができたら、同じやり方で服の種類、表情、背景を1条件ずつ試す。同じseedでも人物や形が変わることはある。

03は床座りと横長構図の練習用。01と複数条件が違うため、色だけの比較には使わない。室内は男女とも素足か靴下。構図を増やすときは[プロンプト集](COMFYUI_PROMPT_COOKBOOK.md)から短い指定を選ぶ。

候補を増やす段階では、良い設定を別名保存してからseedを変更する。生成後にseedを自動変更するモードでは、再現用に実際の結果PNG／履歴のseedを記録する。初回は固定のままが分かりやすい。

## 困ったときの戻り方

| 症状 | まずすること |
| --- | --- |
| ブラウザーが接続できない | 自分の起動コンソールに準備完了・URLが出たか確認。既存サーバーやポートの利用者を調べず終了しない |
| モデルが見つからない／赤いノード | モデル欄を再選択。下の既存ファイルの有無を確認。別モデルを適当に選ばず、無ければエラー文と画面を記録する |
| ノードがないと言われる | まず01を開き直す。4ひな形は標準ノードのみ。Managerや拡張機能の一括導入はしない |
| GPUメモリ不足 | 自分の待ち行列を止め、batch_sizeが1か確認。次に画像サイズを小さくして試す場合は変更値を記録。ほかの人のGPUプロセスを終了しない |
| 処理が止まって見える | コンソールの進捗・エラーを確認。連続実行を追加せず、必要なら自分のジョブをInterrupt／中断し、自分の待ち行列を消す |
| 意図した服・姿勢にならない | 語を増やす前に矛盾を除く。正面と横向き、立位と座位などを同時に指定しない。まず人物1人で試す |
| どこを変えたか分からなくなった | 今の版を別名保存してから01を再読込。元のひな形は上書きしない |
| 保存先が分からない | 下記のoutputs/imagesとSaveImageのprefixを確認。portable本体内のComfyUI/outputではない |

既存モデルの場所：

```text
［作業フォルダー］\tools\local-ai-foundation\models\checkpoints\animagine-xl-4.0-opt.safetensors
```

終了時は自分の生成を止め、待ち行列と保存を確認する。自分で起動したコンソールの `Ctrl+C` で終了し、終了したことを確認する。ブラウザーを閉じるだけではサーバーは終了しない。Python全体の一括終了はしない。

## このガイドで確認した範囲

2026-10-22に既存起動スクリプト、保存処理、モデルの存在・サイズ、選択LoRAのハッシュ、ひな形のJSON構造を静的に確認した。今回の新規画像生成は0枚。新しいUIでの読み込み、GPU動作、出力の品質は未検証。[検証記録](experiments/comfyui-beginner-guide-20261022.md)に区別して残す。
