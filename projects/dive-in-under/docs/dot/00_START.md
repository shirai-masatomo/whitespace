# Dotに最初に渡す指示（この文章をそのまま送信できる）

あなたに新規ゲーム「Dive In Under」の**自律開発の管理・実行**を任せます。あなたはこのゲームについて何も知らない前提で、まずGitHubの正本を読んでください。

- リポジトリ：https://github.com/shirai-masatomo/whitespace
- ブランチ：main
- 作品フォルダ：projects/dive-in-under/
- 工程入口：https://github.com/shirai-masatomo/whitespace/blob/main/projects/dive-in-under/docs/dot/README.md
- 自律運用：https://github.com/shirai-masatomo/whitespace/blob/main/projects/dive-in-under/AUTONOMY.md

**ゲームの目的**：B100シリーズ／Wizardry等を参考とした、地下へ潜る完全自動・素早さ順ターン制のダンジョンRPG。最終配布形態はSteam向けWindows EXE。敵・宝・イベント・装備・死亡・帰還を繰り返す。最初の探索は主人公1人で、帰還できず必ず死亡し、町へ戻る。以後の探索は帰還可能。詳細はGitHub正本。過去のブラウザ試作は最新仕様ではない。

**最重要方針**：
1. あなたは工程管理・進捗確認・判断、**Codexは実装・テスト・自己レビュー・修正**を担う。GitHubに工程・証拠・未実装状態を残す。
2. まずSPEC.md、AGENTS.md、AUTONOMY.md、docs/IMPLEMENTATION_STATUS.md、docs/dot/README.mdを読んで、工程別プロンプトと詳細設計書を順に使う。**この文章が実装開始の指示**であり、設計書の「未依頼」は過去の状態を意味する。
3. **工程1はPHASE_01.mdに従い、主人公単独で初回強制死亡→町→倉庫・装備→再探索して10Fボス突破まで実際に動くWindows EXE**を作る。UI_MOCKS.mdと4枚の画像でデザイン方針を合わせる。全将来仕様を一度に実装しない。
4. **ゲーム本体とヘッドレスシミュレーターは同一の戦闘コアを共有**。固定シードで勝率・死亡率・平均ターン数・残HPを比較可能にする。これを工程1から実装する。
5. 最初にGitHubへのアクセス・書込権限・Codexのクラウド環境とWindowsビルド手段を確認。Codexクラウド環境が未設定なら私に必要な1件だけ質問してほしい。利用できれば環境確認後すぐ工程1を開始。私のローカルPCへ勝手にアクセスしない。
6. 工程単位でブランチ・PR・CI・配布アーティファクト・実画面スクリーンショット・シミュレーション結果を確認。小さな修正は承認待ちせず自律継続し、重要な創作判断・費用・権利・公開時だけ私に相談。工程1を終えたら結果を簡潔に報告し、可能であれば工程2以降も順番に進める。
7. **Steam公開・購入・支払い・外部への認証情報公開はしない**。他のWhiteSpace作品を変更しない。未検証を完成と呼ばない。

**今すぐ行うこと**：資料・環境・既存実装を確認 → 重要な矛盾とリスクを短く整理 → 工程1の最小タスクをCodexへ委任して開発開始 → 結果・PR/CIをレビューし、docs/dot/PROGRESS.mdとdocs/IMPLEMENTATION_STATUS.mdを更新して継続してください。私には途中の細かい進捗より、動く成果物と判断が必要な点を知らせてください。
