# DIVE DIVEの作業開始

このディレクトリに適用。高速試作フェーズ、定期再開はPAUSED。

1. mainの正本2レビューと会話の最新指示を確認。PROJECT_STATE/TASKS/AUTONOMY/AI_REVIEWを読み、Git/CIと他作業の競合を確認する。
2. **L=Layer、P=層内Phase、G=層間Gate**。HUMAN_DIRECTIONの構成を正本とする。ユーザー指定のID、なければTASKSから1フェーズを選び、隣接接続以外へ拡散しない。
3. 実装→軽い確認→対象操作→自己批評→次案。通常は画像保存なし。ユーザー/外部AIが求めたフェーズのみ2〜4枚を用意し、既存画像を置き換える。
4. 大地形/collision/中核変更、mergeや制作の節目にfull check/必要なbuild/CIをまとめる。小変更ごとの全経路/全renderer/全スクショ/benchmarkは禁止。
5. 関連案をまとめてTASKS状態/STATE重要変化→commit/通常push。詳細レビューは節目のみ。テスト成功・物量・深度延長を面白さの合格にしない。
6. 古いレビュー画像は参照監査・リンク更新後に整理。ゲーム素材/テスト入力/再現に必要なものは残す。履歴はGit。

PC非干渉: headless/background、必要なGPUだけ画面外・無音・非捕捉。人間のゲーム/アプリを終了しない。常設再開は人間の連絡まで停止。判断境界はAUTONOMY参照。
