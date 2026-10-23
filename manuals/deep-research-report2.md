# エグゼクティブサマリ  
ComfyUIはノードベースでワークフローを構築できる強力なローカル画像生成エンジンです。テキスト→画像生成に加え、参照画像やControlNet、IP-Adapter、LoRA、マスクによる局所修正など多彩な制御手段が使えます。提案する手順では、(0) 元画像（基準立ち絵）を用意し、(1) **衣装変更**に向けて背景をあまり変えずに水着化する、(2) **ポーズ変更**に向けて手足を広げる「はしゃぐ」姿勢を作る、(3) **背景合成**で海辺のシーンを追加、(4) **局所修正**で顔・手指・衣装の不具合を微調整、(5) 必要に応じ**アップスケール**するという段階を踏みます。各段階でIP-AdapterやControlNet（OpenPose）、マスク編集ノード、LoRAなどを組み合わせて元のキャラや画風を維持しつつ変更を加えます。RTX 4070 SUPER（12GB）環境でも、モデルの軽量化やタイル処理、バッチサイズ調整等でVRAM使用量を抑えられます。成人向けコンテンツも生成可能ですが、SteamやDLsiteでは**AI生成物であることの明示**が必須です。例えばDLsiteではAI生成作品は専用フロアで取り扱うルールがあります。  

## 段階別ワークフロー（テーブル）  

| ステップ | 内容・ポイント                                            | 主なノード／モデル・設定例       |
|:-------|:------------------------------------------------------|:--------------------------|
| 0. 元画像用意 | 基準立ち絵（顔立ち・髪型・体型など確定）を**Image A**として保存。画風・人物特徴を固定する参照画像になる。 | Image Loader（参照画像読み込み）     |
| 1. 衣装変更   | 背景はほぼ変えずに、水着に変更。**Inpaint**またはImg2Img**で衣装部分のみマスク更新**。IP-Adapterで顔・画風維持。モデルは標準SD1.5やアニメ系モデル使用。| Load Checkpoint（SDモデル選択）、<br> Inpaint（マスク編集）または Img2Img<br> IP-Adapter（顔/画風維持） |
| 2. ポーズ変更 | 背景は未重点。OpenPose ControlNet等で参照姿勢を指定し、「はしゃぐ」ポーズ生成。顔参照は元画像、ポーズは別参照骨格で分離制御。LoRAで画風固定も可。| ControlNet (OpenPose, SD1.5用)<br> CLIP Text Encoder（ポーズ＋シーン記述）|
| 3. 背景合成   | 海岸や青空、波しぶきなどを強化。テキストプロンプトで「海岸」「青空の午後」など背景要素を追加。実写寄りならSDXL＋Realistic系モデル、アニメ寄りなら画風LoRA活用。| 同上+追加のテキストプロンプト<br>（例: “夏の砂浜, 波打ち際”）   |
| 4. 局所修正   | 不自然な顔、手指、衣装袖紐などの**細部**をInpaint。マスク編集ノードで問題箇所を指定し「修正案」を生成。Face Detailerやアプスケーラも併用可能。 | Inpaint Workflow:<br> *Load Image (修正対象)*<br> *Mask Editor（修正箇所描画）*<br> *VAE Encoder (Inpaint用)*+*KSampler* |
| 5. アップスケール・最終調整 | 画像全体を高解像度化してシャープ化。RealESRGAN, GFPGANなどで高精細化し、顔補正やアンチエイリアス処理。必要に応じ手作業微調整。| Upscale（リアルESRGAN等）<br> Face Enhancer（GFPGAN等） |

各段階では生成結果を目視確認し、ネガティブプロンプト（例：歪み、低品質、カートゥーン風不要など）で品質制御を行います。IP-AdapterやLoRAは**元画像の画風・人物特徴を維持しつつ**変更可能な強力ツールです。特にIP-Adapterは「1枚の画像からスタイル/構図を転移する1枚ロラ」のように働きます。ControlNet（Pose）を使えばポーズ参照を忠実に反映できます。

## ComfyUIワークフロー図（ノード接続例）  

```mermaid
flowchart LR
  subgraph 衣装変更
    A[Load Image (元画像)] --> B[Inpaint (衣装変更)]
    B --> C[IP-Adapter (画風固定)]
    C --> D[Save Image (中間結果1)]
  end
  subgraph ポーズ変更
    D --> E[Load Image (中間結果1)]
    F(OpenPose 参照画像) --> G[OpenPose ノード]
    G --> H[ControlNet (Pose)]
    H --> I[Generate (ポーズ変更)]
    I --> J[Save Image (中間結果2)]
  end
  subgraph 背景合成
    J --> K[Load Image (中間結果2)]
    K --> L[Add Background via Prompt]
    L --> M[Generate (背景追加)]
    M --> N[Save Image (中間結果3)]
  end
  subgraph 局所修正
    N --> O[Load Image (中間結果3)]
    O --> P[Mask Editor (修正箇所描画)]
    P --> Q[VAE Encode]
    Q --> R[Generate (局所 Inpaint)]
    R --> S[Save Image (修正完了)]
  end
  subgraph アップスケール
    S --> T[Upscaler (RealESRGAN等)]
    T --> U[Face Enhancer (GFPGAN等)]
    U --> V[Save Image (完成)]
  end
```

## 具体的プロンプト例  

用途別に日本語でのプロンプト例を示します（Positiveプロンプト、Negativeプロンプト、マスク指示）。各プロンプトは視覚や画風、品質に関するキーワードを含め、必要に応じて係数を用いて重点付けます。

| シナリオ         | プロンプト例（日本語）                                                     |
|:-------------|:---------------------------------------------------------------------|
| 衣装変更        | **Positive:** 「砂浜で本を持ち上げ、笑顔で手を振る女性。黒のビキニ姿、日差しに照らされた肌、爽やかな夏の日差し、リアルなアニメ調」<br>**Negative:** 「ぼやけた、歪み、写実的すぎる、手足や顔の変形、背景ごみ」<br>**マスク指示:** 「**左腕とビキニ水着部分にマスク**をかけ、ビキニに変更してください。」 |
| ポーズ変更       | **Positive:** 「水しぶきを上げながら波打ち際で軽くジャンプしている男性。両腕を広げ、片足を上げている。ビーチサンダルなし、動きのあるポーズ」<br>**Negative:** 「静止、カートゥーン風、手足の余分な指、片脚だけ浮遊、不自然なバランス」<br>**マスク指示:** 「**顔部分にマスク**をかけ、視線はカメラ方向を向けてください。」 |
| 背景合成        | **Positive:** 「青く透き通る海と白い砂浜、青空に白い雲。夏の光が差し込み、波が岸を打つ眩しいシーン。HDR風」<br>**Negative:** 「曇り空、暗い色調、室内風景、都市背景」<br>**マスク指示:** 「**人物以外すべて**がマスク対象です。背景に海岸を追加してください。」 |
| 顔・細部修正     | **Positive:** 「明るく写実的な肌質、血色の良い頬と唇、自然な黒髪の質感。小さな傷やシワなし、目の描写を鮮明に。」<br>**Negative:** 「ぼやけ、化粧濃すぎ、歯が異常、目が合っていない」<br>**マスク指示:** 「**顔全体**をマスクし、表情は笑顔に変えてください。」 |

※プロンプト内では「極彩色、最高品質、4K」などの質向上キーワードや、`(キーワード:1.2)`のような係数指定も併用します。局所修正ではマスクエディタで該当領域を指定し、Positive/Negativeプロンプトで望ましい変更を指示します。

## 推奨モデル一覧と参照URL（表）  

| 用途           | モデル名・説明                                              | 参照・ダウンロード先                     |
|:-------------|:-------------------------------------------------------|:----------------------------------|
| 画像生成       | **Stable Diffusion v1.5**（SD1.5, 汎用）<br>**SDXL**（最新高性能、写実向け）<br>**WVAnimation/Animagine**（アニメ風）<br>**Realistic Vision 4.0**（写実強化） | HuggingFace: [stable-diffusion-v1-5](https://huggingface.co/runwayml/stable-diffusion-v1-5), [sdxl-base](https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0), [realistic-vision-v4](https://huggingface.co/SG161222/Realistic_Vision_V4.0_noVAE), [animagine](https://huggingface.co/AUTOMATIC1111/animagine-v1) |
| 参照固定       | **IP-Adapter**（画風・人物固定）<br>**LoRAモデル**（スタイル調整: 例「dreamshaper」） | IP-Adapter: [GitHub/diffusers](https://github.com/huggingface/diffusers/tree/main/models/community/ip_adapter) 、<br>LoRA: [CivitAI 例](https://civitai.com/models/4418/lora-dreamshaper-8) |
| ポーズControl  | **ControlNet OpenPose**（骨格制御）<br>**ControlNet Canny/Depth**（輪郭/遠近） | HF: [control_sd15_openpose](https://huggingface.co/lllyasviel/ControlNet-v1-1/tree/main) 等 |
| 顔・詳細補正    | **GFPGAN**（顔修復）<br>**CodeFormer**（顔詳細） | GitHub: [GFPGAN](https://github.com/TencentARC/GFPGAN) 、[CodeFormer](https://github.com/sczhou/CodeFormer) |
| アップスケール  | **RealESRGAN**（汎用高解像度化）<br>**Lanczos法**（シンプル高画質） | ComfyUI組込Upscaleノード（RealESRGAN2.0推奨） |
| 画像補完・修正  | **Stable Diffusion 512-inpainting**（修復モデル） | HF: [sd-inpainting](https://huggingface.co/runwayml/stable-diffusion-inpainting) |

※表中モデルは一例です。用途や画風に応じて、コミュニティモデル（例：アニメ調LoRA、フィルター付きSDモデル等）を追加導入します。モデル選択・組み合わせで人物の同一性・画風保持度が大きく変わります。

## 実践チェックリスト  

- ComfyUIをローカルに導入・起動済み（拡張機能マネージャでIP-Adapter等をインストール）。  
- RTX4070SUPER（12GB）環境では**半精度モデル**（fp16/4bit量子化）や**VAEテイリング**でメモリ節約を有効化。`encode_batch_size`を増やすなどバッチ処理も利用。  
- **ステップ0〜5**の大枠ワークフローを準備し、各段階で出力を別名保存して比較。必要なモデル（SD1.5、ControlNet、IP-Adapter等）をあらかじめモデルフォルダに配置。  
- **プロンプトの微調整**を徹底：Positive/Negativeプロンプトで画質・構図・雰囲気を指定し、ネガティブで望まない要素を排除。骨格はOpenPose参照画像、顔は元画像、服はキーワードで指定。  
- **IP-Adapter/LoRA併用**でキャラ固定：IP-Adapterで元画像特徴を条件付ける。必要に応じLoRAやCLIPコンディショニングでキャラの顔立ちや画風を強化。  
- **ControlNet(OpenPose)**で構図制御：WavePoseやOpenPose等を利用し、ポーズ変更の基準骨格を設定。  
- **局所修正**ではマスクエディタで不具合箇所を指定。顔・手・衣装ディテールを高精度に修正する。Face Enhancerで顔品質を確認。  
- **成人向け利用**時はプラットフォーム規約を遵守。例えばDLsiteでは「AI生成作品」タグの明示と専用フロアへの出品が必要。Steamでも「完全AI生成」・「二次創作」等の区分をチェックし、ルール違反の無いよう管理する。  

以上の手順・ポイントを踏まえてComfyUIでワークフローを構築すれば、元画像を踏まえつつ衣装・ポーズ・背景を順次変え、最終的に滑らかな海辺シーンを生成できます。各種チュートリアルや公式ドキュメントに沿いながら、実際にワークフローを動かして結果を確認・修正していくことが肝要です。  

**参考資料:** ComfyUI公式ドキュメント、IP-Adapter開発元GitHub、ControlNet OpenPose解説、DLsiteガイドラインなど。