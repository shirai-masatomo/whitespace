# ローカルAI画像モデル比較

同じ成人キャラクター設定を、**3モデル×2シード＝6枚**で生成した確認用ギャラリー。2026-10-19にWindows PCのComfyUIで実機生成。一般向けの服を着た人物のみ。

**今回、新規の有料契約・アカウント登録・無料体験の申込み・支払いはしていない。モデルの取得とローカル生成に従量課金はない。** PCの電気代・契約に応じた通信費、および既存のCodex契約・利用枠は別。詳しくは [料金・利用条件](USAGE.md)。

**別系統の画風も見る:** [Web上の公式参考画像（Animagine / Illustrious / Pony、NoobAIはリンク）](WEB_REFERENCES.md)。モデルを追加取得せずに閲覧できる外部作例で、このPCの生成結果とは区別する。

**現在のPC構成:** 通常用は **Animagine XL 4.0 Opt**。導入済みの無料公開版を使用し、SDXL Baseの重みはユーザーの希望で削除した。下のSDXL画像は過去の比較記録として残している。通常生成は [`09-animagine40-normal.json`](workflows/09-animagine40-normal.json) をComfyUIに読み込む。SDXL Base削除後の一般向け生成に成功。参照一致・ポーズ・InpaintingはAnimagineへの切替後未再検証。

## 画像を比較する

金髪・青い瞳・28歳の成人女性・私服・図書館という共通の文章指示。上段はシード419274、下段は419275。画像をクリックすると原寸で確認できる。

| SDXL Base 1.0 | Animagine XL 3.1 | Animagine XL 4.0 Opt |
| --- | --- | --- |
| [![SDXL Base 1.0 seed 419274](images/sdxl_419274_00002_.png)](images/sdxl_419274_00002_.png) | [![Animagine XL 3.1 seed 419274](images/animagine31_419274_00001_.png)](images/animagine31_419274_00001_.png) | [![Animagine XL 4.0 Opt seed 419274](images/animagine40_419274_00001_.png)](images/animagine40_419274_00001_.png) |
| [![SDXL Base 1.0 seed 419275](images/sdxl_419275_00002_.png)](images/sdxl_419275_00002_.png) | [![Animagine XL 3.1 seed 419275](images/animagine31_419275_00001_.png)](images/animagine31_419275_00001_.png) | [![Animagine XL 4.0 Opt seed 419275](images/animagine40_419275_00001_.png)](images/animagine40_419275_00001_.png) |

今回の出力では、SDXLは柔らかい陰影、Animagine 3.1は明瞭な輪郭線とセル塗り、4.0 Optは強めの彩度・明暗差が出た。単一題材・2シードでの観察であり、モデル全体の優劣や固定の画風とは断定しない。衣装の色や形が指示から変わる例もある。

## 再現と調整

- 共通設定: 832×1216、28 steps、CFG 5、Euler ancestral / normal、batch 1。
- 指示の全文・シード・出力SHA256・処理時間: [生成記録](generation-record.json)。
- モデルの固定版・公式入手先・SHA256: [モデル台帳](model-manifest.json)。
- [workflows](workflows/) の `.json` をComfyUIにドラッグして実行する。`.api.json` はAPI用。
- 保存PNGにもprompt・workflow・使用モデルの版とハッシュを保持しているため、PNGからも設定を読み込める。

全モデルに同じ文章・設定を使った比較。各モデル専用タグで最高品質を追求したものではない。モデルが変われば同じシードでも顔や構図は一致しない。添付された参考画像そのものはモデルへ入力していない。

## このフォルダーの範囲

画像6枚、ワークフロー、生成条件、利用条件の記録だけを収録する。モデル重み・Python・CUDA・ComfyUI本体・APIキー・ローカル環境情報は含めない。既存ゲームへの素材採用・コード統合は行わない。画像は画風確認用の試作で、販売用の権利確認・仕上げを済ませた素材とは扱わない。
