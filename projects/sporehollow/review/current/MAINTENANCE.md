# 開発環境の整理

ゲーム関連フォルダ（Git領域を除く）：10.33 → 3.72 GiB。
旧ゲームEXE23本、重複ツール36ファイル、再生成可能なキャッシュを個別削除。通常ゲームEXEは1本、Godotは1セット。
ユーザー承認後、release-2c0182a / release-35038b6 / release-536005cを削除。複製Git領域も含めた追加削減は0.61 GiB。履歴・取り残された110コミットは現行Gitへ保全。

恒久ルールをAGENTS.mdへ記録。dev.ps1と配布・隔離描画で固定作業領域を再利用し、必要なレビュー結果保存後に候補・キャッシュをfinallyで自動整理。安全境界12項目、関連60項目、起動解析、隔離描画、実ビルド→隔離終了再開→既存EXE反映→候補削除が成功。
セーブ・素材・ゲームソースのハッシュ一致、最新版ショートカット保持。Play.cmd/dev.ps1 playも同じEXEを開く。

残件：その他の旧フォルダ・古い確認入口の全体削除は審査で保留。未保存ソースのあるrelease-92d1048、release-c5c2833、research-three-encountersと保存データを保護。フォルダ全体削除まで完了したとは扱わない。

[検証・容量](verification/maintenance.json) / [承認済み3フォルダの記録](verification/approved-folder-cleanup.json) / [共通工程](../../DEVELOPMENT.md)
