# ローカルモデルの起動と実測

2026-09-06、`codex/local-language-comparison` で確認。ゲームは辞書方式を維持し、モデルは比較ラボだけで使う。

## PCと選定

| 項目 | 実機確認 |
| --- | --- |
| CPU | AMD Ryzen 7 5700X、8コア16スレッド |
| RAM | 34,284,916,736 bytes（約31.93 GiB、32 GB相当） |
| GPU | NVIDIA GeForce RTX 4070 SUPER、VRAM 12,282 MiB、確認時空き9,556 MiB |
| ドライバー | 591.86、OllamaでCUDA利用を確認 |
| Cドライブ | 開始時空き397,576,347,648 bytes（約397.6 GB） |
| 既存環境 | Ollama / LM Studio / llama-serverのコマンド・代表的な配置場所・稼働プロセスは見つからなかった |

選定は公式 [Qwen3.5-2Bモデルカード](https://huggingface.co/Qwen/Qwen3.5-2B) と [Ollamaの量子化タグ](https://ollama.com/library/qwen3.5:2b-q4_K_M) を参照。日本語を含む多言語対応、軽量な2B級、3 GB以下で取得でき、このGPUでローカル実験できるため採用した。モデルカードはApache-2.0。今回はテキストだけを使う。

- モデル: `qwen3.5:2b-q4_K_M`、GGUF / Q4_K_M。APIのparameter_size表記は2.3B。
- 取得サイズ: **1,945,323,638 bytes（約1.945 GB）**。
- 取得時digest: `124a03c347777e8e4e5955c33610ae01d9d90d8c2a718bfba069c498d5c7f3c9`。タグは将来変わり得るので再取得時はdigestを照合する。
- 実行環境: [Ollama v0.33.3公式リリース](https://github.com/ollama/ollama/releases/tag/v0.33.3)、Windows amd64 standalone。
- 実行環境ZIP: **1,469,175,900 bytes（約1.469 GB）**。モデル容量とは別で、展開にも空き容量が必要。
- ZIP SHA256: `52cb36a62e7e501f61514f60212dec7117b6c098811357585e02fffe32d2fcd7`。公式リリースのsha256sum.txtと一致を確認してから展開・実行した。

## このworktreeで起動

モデルとランタイムはルートの `.local-llm/` に配置済みでGit対象外。他のcheckoutには自動で共有しない。[Windows公式手順](https://docs.ollama.com/windows) と [API仕様](https://docs.ollama.com/api/chat) を参照した。

1つ目のPowerShell（アプリフォルダ）:

```powershell
cd prototypes/001-nadameyo
./start-local-model.ps1
```

2つ目のPowerShell（同じアプリフォルダ）:

```powershell
npm.cmd ci
npm.cmd run dev -- --host 127.0.0.1 --port 5174 --strictPort
```

[比較ラボ](http://127.0.0.1:5174/#compare) を開く。各サーバーはCtrl+Cで停止。スクリプトは `OLLAMA_HOST=127.0.0.1:11435`、モデル保存先をworktree内に固定し、`OLLAMA_NO_CLOUD=1`、並列1・ロードモデル1に設定する。自動起動サービスは登録していない。

新環境では公式リリースの `ollama-windows-amd64.zip` と `sha256sum.txt` を取得し、SHA256照合後、`.local-llm/ollama/ollama.exe` になるよう展開する。サーバーを上の手順で起動してから、別PowerShellで次を実行する。

```powershell
./start-local-model.ps1 -Pull
Invoke-RestMethod http://127.0.0.1:11435/api/tags
```

タグ・digest・サイズを上記と比較する。スクリプト自体はモデルを自動取得しない。Vite previewでもAPIは動くが、distだけを静的配信した場合は辞書のみ利用可能。

## 再測定

アプリフォルダから `npm.cmd run compare:language`。対象モデルを一度アンロードし、28例を逐次評価後、c01を再送する。他の比較処理を止めて実行する。現在のスクリプトは `docs/experiments/language-comparison-2026-09-06.json` を上書きするので、別条件の実験は先に出力名を変更する。

同一の実装・入力を使い、期待値はモデルへ渡さない。温度0、seed42、コンテキスト4096、最大生成220トークン、think=false、JSON schema指定。seedを固定しても環境間の完全な再現性は保証しない。

| 測定（最終保存JSON） | 時間 |
| --- | ---: |
| 明示アンロード後、最初のc01（形式不正応答） | 4,867.4 ms |
| その内訳: モデル読込 / 推論 | 3,932.1 / 925.5 ms |
| 読込後28呼出しの中央値（形式不正も含む） | 614.4 ms |
| 同最小〜最大 | 501.9〜899.1 ms |
| c01のウォーム再送（形式不正応答） | 859.9 ms、読込1.5 ms |
| 辞書28例の中央値 / 最大（Node実行） | 0.072 / 0.572 ms |

これはモデルをアンロードした測定であり、OSキャッシュやCUDA初期化まで完全に冷えた状態ではない。最初の環境立ち上げ時には30秒制限で2回タイムアウトし、初回初期化の完了時間を測れなかった。初回試行は `language-comparison-initial-attempt.json` に別保存し、最終測定と混ぜて集計していない。観察を受け、サーバー待機上限を120秒に変更した。

有効形式17/28、形式不正11/28。形式が有効でも正解ではない。評価結果・誤解例は [操作と実験記録](PLAYTEST_2026-09-06.md)、応答原文と時間は [実測JSON](experiments/language-comparison-2026-09-06.json)。入力はレビュー例と生成例で、実プレイヤーのログではない。
