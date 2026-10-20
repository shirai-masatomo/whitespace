# 素材の配置・差し替え・権利管理

台帳: [asset-register.json](../asset-register.json)。今回の絵は簡易SVG、音は正弦波合成の仮素材です。外部のキャラクター絵や画像生成モデルは使用していません。

| タグ／別名 | 現在のファイル | 用途 |
| --- | --- | --- |
| `bg opening` / `bg campus` | `game/images/bg/opening.svg` / `campus.svg` | 導入・大学 |
| `bg clubroom` / `bg beach` | `game/images/bg/clubroom.svg` / `beach.svg` | 部室・海 |
| `aoi neutral` / `aoi smile` | `game/images/characters/aoi/neutral.svg` / `smile.svg` | 通常・笑顔 |
| `campus_theme` / `beach_theme` | `game/audio/bgm/campus.wav` / `beach.wav` | 8秒の確認用ループ |
| `event_chime` | `game/audio/se/chime.wav` | 好感度上昇の確認用SE |

対応は`game/assets.rpy`へ集約。正式な画像・音声へ差し替える際は、タグと別名を維持し右辺のパスを変更します。
外部素材の配置前に、台帳へ次を登録します。

- 使用箇所、ファイル名、版、ファイルハッシュ
- 作者・提供者・取得元URL・取得日
- 商用ゲームへの組み込み、成人向け利用、改変、再配布、クレジットの条件
- ライセンスの名称・版・確認日・原文を保管した場所
- AI素材ならモデル名・正確なバージョン・ハッシュ、LoRA等の追加モデル、生成日・シード・設定、参照画像の権利
- 配布物への組み込み可否と未解決の確認事項

「無料」「購入済み」「ローカル生成」だけで権利確認を完了にしません。
利用モデルのライセンスと生成物・参照画像の権利は分けて確認します。
制作途中の未確認素材は配布対象から除外します。元モデルや大量の生成途中画像をGitへコミットしません。

## 今回同梱する第三者コンポーネント

- Ren'Py 8.5.3の公式生成GUI・共通翻訳: 主にMIT。エンジンの同梱依存はLGPL等も含む。`RENPY-LICENSE.txt`を維持し、配布時にも公式ライセンス一覧と対応ソースのリンクを記載する。
- `SourceHanSansLite.ttf`: 内部名 `Source Han Sans Lite for RenPy`、内部版 `Version 2.001 October 29, 2020`。フォント内部にAdobe 2014–2019の著作権、Reserved Font Name `Source`、SIL Open Font License 1.1が明記されている。`FONT-LICENSE.txt`を同梱する。フォント単体の販売やフォントの改名・再ライセンスの制約に注意する。
- この仮シナリオ・SVG・合成音の作成コードにはCodexの制作支援を利用している。画像モデル・音声モデルの利用はないが、販売時のAI申告対象を「画像モデル未使用」だけで判断しない。

出典: https://www.renpy.org/doc/html/license.html 、取得済み8.5.3 SDK、および同梱フォントのnameテーブル。
任意の第三者素材を自由に再配布できるとする文書ではありません。正式販売前に最終台帳と配布内容を照合します。
