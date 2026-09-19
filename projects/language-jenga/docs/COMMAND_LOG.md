# Command Log

重要なコマンド・環境問題・変更の節目だけを記録する。日時はJST。秘密情報や生ログは残さない。

## 既存資産の履歴

| 日付 | 内容 |
| --- | --- |
| 2026-05-29 | Node.js 24.16.0 / npm 11.13.0でVite + React試作を作成し、GitHubへ共有。 |
| 2026-06-01 | 宥めよの状態値・会話履歴・成功/失敗・再挑戦を実装。入力正規化と意味カテゴリ判定へ整理。 |
| 2026-09-03 | 仕様・完了条件・TODOを整備。辞書144件（採用20、レビュー待ち124）、判定モジュールと自動テスト6件を用意。日本語の管理文書と案内図を整理。 |
| 2026-09-18 | 最新main 2e798c2を基点に言語ジェンガ配下へ資産を集約。未使用のルートReact練習版3ファイルを削除。案内図の役割を本プロジェクトREADMEへ統合。 |

移動前のコマンドと当時のパスは [Git上の完全な履歴](https://github.com/shirai-masatomo/whitespace/blob/2e798c2/docs/COMMAND_LOG.md) を正本とする。旧版の複製やarchiveは作らない。

## 再調査を避けるための環境メモ

- PowerShellの実行ポリシーで `npm.ps1` が止まる場合は `npm.cmd` を使う。
- Node.jsが見つからない場合は、このシェルだけ `$env:Path = 'C:\Program Files\nodejs;' + $env:Path` を設定する。
- 過去にVite一時ファイルの作成やネットワーク接続がサンドボックス権限で失敗した。書き込み先と権限を確認し、必要な処理だけ許可された実行方法を使う。
- 過去のバックグラウンド起動ではPath/PATH重複や親プロセス終了に伴う停止があった。まずREADMEのコマンドを開いた端末で実行し、ViteのURLとログを確認する。
- Gitのindex.lock操作に権限が必要な環境では、対象リポジトリのGit操作だけ適切な権限で実行する。
- 外部辞書の調査元・利用条件は [辞書レビュー](INTENT_DICTIONARY_REVIEW.md) に保持。青空文庫本文は未採取。

## コマンドと直近の確認

起動・検証コマンドは[アプリREADME](../app/nadameyo/README.md)、直近の結果は[現在地](../PROJECT_STATE.md)へ集約する。

npm auditの既存指摘対象はvite、postcss、nanoid、browserslist、brace-expansion、baseline-browser-mapping。依存更新は別の検証単位で扱う。
