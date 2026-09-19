# DIVE DIVEの作業開始

このディレクトリだけに適用する。WhiteSpace全体や他作品へ自律ルールを広げない。

1. PROJECT_STATE.md、TASKS.md、AUTONOMY.mdを読む。
2. Git状態と最新mainを確認。他セッションの変更は上書きしない。
3. `./dev.ps1 check` を実行して基準状態を確認する。
4. 依存が解決した最優先タスクを実装し、再テスト・自己レビューする。
5. 見た目や入力を変えたら `./dev.ps1 visual` と画像確認を行う。
6. PROJECT_STATEとTASKSを更新し、commit・GitHub更新・CI確認を行う。

中核試作の初回完了後は、人間のプレイ感レビューで一区切りにする。未依頼の定期実行は設定しない。
