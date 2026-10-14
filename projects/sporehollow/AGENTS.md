# ホイッスル牧場：共通開発ルール

- 現行の開発フォルダを継続利用する。新しいプロジェクトコピーを標準手順にしない。履歴はGitのブランチ・コミットで管理する。
- 通常のゲームEXEはartifacts/autonomy-entry-01/bundle/WhistleRanch-Autonomy-Partial.exeの1本。既存の最新版ショートカットとuser-dataを維持する。Play.cmd/dev.ps1 playも同じEXEを起動する。
- 更新は関連テスト→候補ビルド→隔離起動・正常終了・再開→既存EXEへ反映→候補・旧EXE削除。previous/backup/old EXEを常備しない。唯一動く版を検証前に削除しない。
- 検証領域は固定パスを再利用し、同時実行はロックで拒否する。dev.ps1とisolated_visual.ps1のfinallyで必要なレビュー記録をreview/current/verificationへ保存し、候補・合成セーブ・キャッシュを片づける。
- ユーザーの実行中ゲームを終了・再起動・上書きしない。検証は非対話デスクトップ、Dummy音声、30fps、直列。通常GUIへのfallbackやOS入力はしない。
- 新しくファイル・フォルダを作る前に既存の場所を再利用できないか確認する。用途を終えた自分の一時worktree/コピーは履歴と未保存変更を確認して整理する。
- ソース、正式素材・原画・納品・ライセンス、ユーザーのセーブ、Git履歴、重要なレビュー原本を保護する。.uid/.importは拡張子だけで削除しない。未保存変更のある他のコピーを破棄しない。
- 整理は参照・Git保存・再生成可能性を確認してから。Windowsでは絶対パスを検査し、Remove-Item -LiteralPathを使う。git clean -fdx、force push、履歴書換、未確認のフォルダ一括削除は禁止。
- 作業の終了条件に後片付け、ゲームEXEの本数、容量、残存フォルダ確認を含める。報告は削除内容・容量増減・保留理由を短く書く。無関係な拡張を始めない。
- 詳細な工程はtools/maintenance.ps1とDEVELOPMENT.md。レビューはreview/current/PACKET.mdを入口にGitHubへまとめ、ユーザーを資料の取り次ぎ役にしない。

## 資料の更新・整理（2026-10-14）

- ユーザーが仕様を採用・変更したら、[GAME_SPEC.md](GAME_SPEC.md) に短く反映し、詳細は関係する設計正本（例：[CRAFTING_NEEDS_DESIGN.md](CRAFTING_NEEDS_DESIGN.md)、[WORK_SYSTEMS.md](WORK_SYSTEMS.md)、[ITEMS.md](ITEMS.md)）だけ更新する。READMEは入口・操作概要に限定し、同じ表を無制限に複製しない。
- 資料の各節に **現行実装／採用した将来仕様／未確定案／過去記録** を明記する。ドキュメントへの記載だけでコード・EXE反映済みとは報告しない。
- 現行仕様と過去レビューを同じ場所で「最新」と呼ばない。過去の引継ぎ・古い定点レビューは review/archive へ整理する。重要な検査・素材権利・納品・署名・Git履歴を一括削除しない。
- 詳細な敵・動物・品目はそれぞれ ENEMIES／ANIMALS／ITEMS、建築・物流は BUILDINGS／WORK_SYSTEMS を正本にする。
