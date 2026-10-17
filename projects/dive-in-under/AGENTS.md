# Dive In Under — Codex向け常設指示

このファイルは Dive In Under 配下の実装・レビュー作業に適用する。WhiteSpaceの他プロジェクトには手を触れない。

1. 最初に [SPEC.md](SPEC.md)、[自律運用](AUTONOMY.md)、[工程案内](docs/dot/README.md)、[実装状態](docs/IMPLEMENTATION_STATUS.md)を読む。実行対象工程はDotが指定した [工程ファイル](docs/dot/README.md) を読む。何も指定されなければ [進捗台帳](docs/dot/PROGRESS.md) で未完了の最初の工程を確認する。
2. 確定仕様を守り、データの正本を尊重する。FLOORS＝階層出現率・出現Lv・宝箱、ENEMIES＝敵基礎値・EXP・Gold・ドロップ・固有AI、COMBAT＝共通戦闘・レベル補正・状態異常、SKILLS＝スキルの全効果、ALLIES＝味方個体と固有行動、EVENTS＝イベント詳細、ITEMS＝装備とアイテム。
3. **現在の工程に含まれない先行実装は禁止**。**工程1〜4は主人公単独で遊べることを必須とし、仲間システムは工程5に延期**。工程1では初回強制死亡は一度だけで、通常探索が何度も続けられ10Fまで主人公単独で突破できる。仕様に記載されていても「後」「候補」は原則まだ作らない。独自判断の数値・UIは「試作用仮値」と明示して調整可能にする。
4. 画面イメージは [UI_MOCKS.md](docs/UI_MOCKS.md) と assets/ui-mocks/ を参照。画像に描かれた数値やテキストは確定仕様ではない。画像全体をボタンとして用いず、クリック可能なUIを実装する。
5. **戦闘処理を単一コアにまとめ**、ゲームと [ヘッドレスシミュレーター](docs/BATTLE_SIMULATION.md) が同じロジックを使う。再現可能な固定シード・テストを用意する。
6. 変更ごとにテスト・ビルド・自己レビュー・改善を最低1回実施。Windows EXE/ZIP、実画面のスクリーンショット、テスト結果、コミット/PRの証拠が揃わない限り「完成」「動作確認済み」と書かない。検証不能ならその事実を明示する。
7. 作業対象は原則 projects/dive-in-under/ と、本作品用の .github/workflows/ のファイルだけ。DIVE DIVE・ホイッスル牧場・言語ジェンガ・共通GitHub設定を勝手に変更しない。
8. 各工程の結果・残課題を [PROGRESS.md](docs/dot/PROGRESS.md) と [IMPLEMENTATION_STATUS.md](docs/IMPLEMENTATION_STATUS.md) に証拠付きで記録する。確定要件を勝手に変更せず、衝突・重大判断だけ人間へ報告する。
9. 正式なSteam公開、支払い、外部有料素材購入、認証情報の共有、本番データ破壊、他プロジェクトへの影響のある操作は行わない。
