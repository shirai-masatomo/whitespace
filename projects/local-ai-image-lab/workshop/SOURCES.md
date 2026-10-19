# 手順と候補モデルの参考資料

確認日: 2026-10-20。モデルの宣伝上の性能と、このPCで確認した結果を区別する。下記から新しいモデルや外部サービスを取得・契約してはいない。

| 一次資料 | 用途 |
| --- | --- |
| [ComfyUI Inpainting](https://docs.comfy.org/tutorials/basic/inpaint) | Mask Editor、VAEEncodeForInpaintのpixels・mask・grow_mask_by |
| [ComfyUI Pose ControlNet](https://docs.comfy.org/tutorials/controlnet/pose-controlnet-2-pass) | 骨格ガイドによる姿勢制御。掲載のSD1.5用モデルを、このSDXL環境へ混ぜない |
| [IPAdapter Plus開発元](https://github.com/cubiq/ComfyUI_IPAdapter_plus) | 画像による人物・画風の条件付け。導入版はenvironment.jsonで固定 |
| [Impact Pack開発元](https://github.com/ltdrdata/ComfyUI-Impact-Pack) | Face Detailer等の追加ノードと検出器の依存関係。今回は未導入 |
| [ComfyUI Upscale](https://docs.comfy.org/tutorials/basic/upscale) | 通常拡大と学習済みモデルによる拡大の使い分け |
| [Animagine XL 4.0公式カード](https://huggingface.co/cagliostrolab/animagine-xl-4.0) | 現在のチェックポイントの系統と条件。取得したOpt版のハッシュは台帳を参照 |
| [OpenAI公式の画像生成・編集操作](https://learn.chatgpt.com/docs/image-generation) | 参照画像、変更箇所と維持箇所の指示、段階的編集。内蔵機能は既存利用枠を消費する |
| [OpenAI公式の画像プロンプト例](https://developers.openai.com/cookbook/examples/multimodal/image-gen-models-prompting-guide) | 人物の維持と複数画像の役割指定。API用設定を内蔵ツールの設定として扱わない |
| [Qwen Image Edit 2511公式カード](https://huggingface.co/Qwen/Qwen-Image-Edit-2511) | 人物の一貫性を改善したとされる画像編集モデル。Apache-2.0、20B/BF16。未導入・未測定 |
| [FLUX.2 klein 4B公式カード](https://huggingface.co/black-forest-labs/FLUX.2-klein-4B) | 複数参照による画像編集、Apache-2.0。カードの目安は約13GB VRAMで、このPCの12GBへそのまま収まると保証しない。未導入・未測定 |
| [FLUX.2 klein 9B公式カード](https://huggingface.co/black-forest-labs/FLUX.2-klein-9B) | 9Bは非商用ライセンス。4Bと条件を混同しない。未導入・未測定 |

この手順の数値は導入済み構成に対する調整開始案であり、上記資料がこのキャラの最適値を保証するものではない。外部候補を採用する場合は、対応ワークフロー、VRAM、量子化による差、ライセンスを確認し、同じ基準画像で実測してから判断する。
