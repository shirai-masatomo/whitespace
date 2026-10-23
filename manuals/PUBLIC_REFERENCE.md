# GitHubで見る共有資料

**[GitHubの資料入口](https://github.com/shirai-masatomo/whitespace/tree/codex/reference-library)**

2026-10-23、既存の公開リポジトリwhitespaceの資料専用ブランチ `codex/reference-library` へ初回505ファイルをアップロードした。mainとゲームの作業ブランチは変更していない。

- GitHubのREADMEで、ComfyUI操作・衣装と構図・保存の資料本文と、顔の比較・GIFプレビューを閲覧できる。
- 統合素材カタログは215ファイル、描き文字46選択肢、表情46画像候補。2026-10-23の総合入口更新では、納品用一覧24本と、一覧外の完成フォルダー、docの資料もまとめて索引化。件数と対象外の詳細はGitHubの収録範囲を参照。
- HTMLアプリはGitHubのファイル表示では実行されない。Code → Download ZIPで一式を取得するとindex.htmlが入口になる。
- 2026-10-23、ユーザーが「GitHubへの保存だけにする」と指定。GitHub Pagesでの一般公開URLへの配信は行わない。GitHub Pagesの設定は変更していない。
- 表情の採否はブラウザーごとの保存＋JSON書き出し・取り込み。自動同期はしない。

モデル重み・実行環境・認証情報は含めず、テキスト中のPC固有ユーザーパスは置き換えた。元のローカル資料と共有版は区別する。

共有ファイルの作成・公開用Git checkout・検査記録は `［作業フォルダー］/output/reference-git-publication-20261023/`。このフォルダー内の `public-site` だけが配信ブランチの内容で、監査用のパス対応表やスクリプトはGitHubへ上げていない。

次の更新でも、作業リポジトリ全体をgit addせず、共有対象を専用フォルダーへ作成して検査する。共有はGitHubへの保存だけを継続し、GitHub Pagesの有効化を進めない。

[今回の参考シーン・対応状況・拒否記録・GIFのリンク集](REFERENCE_SCENES.md)。最新の配信内容と検査は `output/scene-reference-review-20261023_14/` の記録を参照。

最新版：[どきどきのピンク・小さめ・重なる連続表示](experiments/dokidoki-overlap-pink-20261023.md)。[GitHubの変更内容と3場面のGIF](https://github.com/shirai-masatomo/whitespace/blob/codex/reference-library/reports/DOKIDOKI.md)。

新規追加：[ヒロインのアップ表情4種類](experiments/heroine-closeup-portraits-20261023.md) ／ [GitHubで見る](https://github.com/shirai-masatomo/whitespace/blob/codex/reference-library/reports/PORTRAITS.md)。表情の比較・採否は34候補。

追加：[舌出し・酔い・参照表情と顔大アップ](experiments/heroine-reference-expressions-faceups-20261023.md) ／ [GitHubの追加9画像](https://github.com/shirai-masatomo/whitespace/blob/codex/reference-library/reports/FACEUPS.md)。通常アップ4＋顔大アップ5を保存、表情の管理は43画像候補。

追加：[使用予定の座り酔い原本とアップの比較](experiments/heroine-tipsy-source-reference-20261023.md) ／ [GitHub](https://github.com/shirai-masatomo/whitespace/blob/codex/reference-library/reports/TIPSY_REFERENCE.md)。生成3・追加参照の拒否4。現在は表情46画像候補、統合215ファイル。

## 総合入口と更新運用（2026-10-23）

[GitHub総合入口](https://github.com/shirai-masatomo/whitespace/tree/codex/reference-library)から、[全シーン・素材集](https://github.com/shirai-masatomo/whitespace/blob/codex/reference-library/reports/ALL_SCENES.md)、[資料総目次](https://github.com/shirai-masatomo/whitespace/blob/codex/reference-library/reports/DOCUMENTS.md)、[収録範囲](https://github.com/shirai-masatomo/whitespace/blob/codex/reference-library/reports/COVERAGE.md)、[拒否記録](https://github.com/shirai-masatomo/whitespace/blob/codex/reference-library/reports/REFUSALS.md)へ進む。以前の共有版は最近の参考シーン中心で、過去の全シーン集を掲載したものではなかった。

拒否が発生したら試行名・参照元・段階・通知理由・保存出力の有無を同じ拒否資料へ追記する。未試行・技術的失敗・品質不採用は別枠。素材追加時は総合入口と該当索引も更新し、未掲載分を明記する。定期実行を設定したという意味ではなく、制作・納品時の更新規約。学習入力・外部参照原本・中間ファイル・削除済みファイルは全量掲載の対象外。
