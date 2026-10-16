# 4画面のUI改善（2026-10-16）

住民詳細・アーキテクト・備蓄・家屋を参考画像に沿って整理。[変更・検証・CPU確認図・残課題](interaction-revision/REPORT.md) / [EXE配布記録](interaction-revision/DELIVERY.json)。以下は改善前の資料。

---

# 現行UIスクリーンショット（2026-10-16）

住民詳細・アーキテクト・備蓄2タブ・家屋の計5枚を保存。1280×800の全画面、30fpsの非対話デスクトップで実描画。家屋のみ撮影用の完成状態。ゲームコード・EXEは変更なし。[画像一覧・撮影条件](interaction-revision/REPORT.md)。

---

# 生活UIと食事の同順位設定（2026-10-16）

実装 176b79af を既存の最新開発版EXEへ反映済み。生活画面の配置と役割からの住民引継ぎを改善し、食事優先は同順位可・他セル交換なし。関連159チェック失敗0、2解像度の実Control座標とCPU確認図を保存。ゲームの自動起動なし。セーブ機能は無効のままで、旧順位データの互換移行のみ検証。[結果・残課題](interaction-revision/REPORT.md)／[配布記録](interaction-revision/DELIVERY.json)。以下は過去記録。

---

# 建築予約済みセルの重複プレビュー抑止（2026-10-16）

実装 1f7d7c87 を既存の最新開発版EXEへ反映済み。床・壁・扉・2×2設備・家具で新規配置の重複表示を抑え、確定済みゴースト・資材待ち・内部の重複拒否を維持。関連168チェック失敗0。通常ゲームの自動起動なし。[検証結果](interaction-revision/REPORT.md)／[配布記録](interaction-revision/DELIVERY.json)。以下は過去記録。

---

# 建築資材待ち・取消回収・壁床接合（2026-10-16）

資材待ちゴースト、中断資材による自現場の閉塞、取消／回収、壁床接合を更新。実装 `104323b9` を既存の最新開発版EXEへ反映済み。関連386チェック失敗0。CPU合成で比較し、通常ゲームの自動起動なし。[結果・比較画像・未検証事項](interaction-revision/REPORT.md)。以下は過去記録。

---

# 食事・住居権限・生活UI・心情（2026-10-16）

実装 `ff50a685` を既存の最新開発版EXEへ反映済み。生活タブ、個人別食事優先度、睡眠中の満腹0起床、部屋別住居、備蓄持出し権限、危険反応・集中・満足度を統合。関連415チェック失敗0。通常デスクトップ起動・GPU負荷試験は実施していない。実機操作感と長期バランスは未検証。

[変更・試験・残課題](interaction-revision/REPORT.md)／[試験一覧](interaction-revision/TEST_SUMMARY.json)／[EXEハッシュ・配布記録](interaction-revision/DELIVERY.json)。入口は従来の「最新開発版.lnk」1本を維持。以下は過去記録。

---

# 建築予約・家屋・時間割・睡眠（2026-10-16）

実装 `328e2add` を既存の最新開発版EXEへ反映済み。資材待ち予約、家屋・ベッド割当、全人間の時間割／睡眠、誘拐者の人間優先・入口探索、壁と床の隙間を更新。関連504チェック失敗0。通常ゲームは自動起動していない。[変更・検証・残課題](interaction-revision/REPORT.md)／[CPU描画比較](interaction-revision/housing-floor-comparison.png)／[配布記録](interaction-revision/DELIVERY.json)。通常デスクトップの操作感と実GPU描画は未検証。以下は過去記録。

---

# 操作・設備・選択表示（2026-10-16）

赤い×の視認性、2×2作業台、ホイール・E/X・1〜3倍速、混在範囲選択、施工と商人の退避を更新。[結果・試験・残課題](interaction-revision/REPORT.md)／[禁止マーク比較](interaction-revision/forbidden-comparison.png)。実画面自動起動なし。コード1aa428f2を既存の最新開発版EXEへ反映済み。関連990チェック失敗0。配布SHA256は同フォルダDELIVERY.jsonを参照。以下は過去記録。

---

# 地形・襲撃・ゾーン・商人・UI（2026-10-15）

コード `420737ad` を既存最新EXEへ反映済み（2026-10-15）。関連1,032チェック失敗0、headless書き出し・配布ハッシュ一致。実ゲームの自動起動なし。森林29%、中央へ進む襲撃経路、マス単位ゾーン編集、昼間に歩いて来訪・帰還する商人、住民装備UI、禁止表示、柴犬の共通倍率、本の0.4秒静止を実装。[検証と残課題](integrated-revision/REPORT.md)。通常画面は自動起動せず、EXEの反映結果は同フォルダDELIVERY.jsonを正本とする。以下は過去記録。

---

# 建築ゴースト・資材補充：現在の確認入口（2026-10-15）

完成画像の半透明プレビュー、設置不可理由、予約時の現物資材確保、F3資材補充を実装。関連335チェック＋正式素材10枚照合を通過。[変更・検証・EXE反映記録](building-preview/REPORT.md)。通常ゲーム自動起動なし。コードbaf16ef0を既存最新EXEへ反映済み。ハッシュとビルド記録は同フォルダDELIVERY.json。以下は過去記録。

---

# 作業モーション・UI：現在の確認入口（2026-10-15）

コードaf4092dcを既存最新EXEへ反映済み。下段固定アーキテクト、独立ゾーン詳細・名称、動物一覧／個体の排他表示、仮道具の弧と加減速を実装。関連413チェック失敗0、CPU図・比較GIF確認。[報告・検証・配布記録](work-ui/REPORT.md)。通常ゲーム自動起動なし、実機の快適さは未確認。EXE反映記録は同フォルダのDELIVERY.json。以下は過去記録。

---

# 作業モーション：現在の確認入口

コードc88c1fc2・既存EXE反映済み。[配布記録](work-motion/DELIVERY.json) / [報告・不足素材](work-motion/REPORT.md) / [左右比較画像・GIF](work-motion/SCREENS.md)。
確認画像は共通描画命令のCPU再現であり、ゲーム画面の撮影ではない。以下は過去記録。

---

# 製作・備蓄・生活基盤：現在の確認入口

コード70d9d802・関連394チェック通過・既存EXE反映済み。[今回の変更・検証・残課題](crafting/REPORT.md) / [EXE反映記録](crafting/DELIVERY.json) / [現行設計](../../CRAFTING_NEEDS_DESIGN.md)。通常ゲーム画面・GPU試験は自動起動していません。以下は過去記録。

---

# 岩盤外縁・ログスクロール：現在の確認入口

[変更・検証・未確認事項](geology/RIM_LOG.md) / [比較画像](geology/SCREENS.md) / [EXE反映](geology/RIM_LOG_DELIVERY.json)。通常ゲーム画面・GPU試験は自動起動していない。以下は過去記録。

---

# 大規模岩盤・地層：現在の確認入口

[今回の変更・テスト・未確認範囲](geology/REPORT.md) / [画像一覧](geology/SCREENS.md) / [EXE反映記録](geology/DELIVERY.json)。通常デスクトップ起動・GPU負荷試験なし。以下は過去の配布記録。

---

# 最新配布4f16b50：建築現場表示・壁コスト5

[変更と関連検証109項目](construction-sites/REPORT.md) / [配布記録](construction-sites/DELIVERY.json)。正式資材アイコン、工程表示と現場クリック情報、壁3種各5個。通常画面の自動起動・GPU試験なし。以下は過去の配布記録。

---

# 最新配布：建築二段階・運搬20（d2595d3）

[今回の実装・検証](construction-groups/REPORT.md)。施工グループ単位の搬入先行と運搬合計20を追加。追加指示により全更新を既存EXEへ反映済み。[配布記録](construction-groups/DELIVERY.json)。ロード39項目と書出EXEのheadless起動終了に合格。通常画面・GPUは自動起動していない。以下は過去の配布記録。

---

# 横壁の量感・仕事継続性

[変更と検証](wall-work-continuity/REPORT.md)。正式素材の描画形状のみ更新。追加予約での担当切替は再現せず、仕事AI変更なし。関連ロジック296項目合格、実画面未確認。配布版は同フォルダのDELIVERY.json参照。

---

# 最新配布：建築候補表示・岩盤外縁（99a33de）

[最小改善と検証結果](minimal-visual/REPORT.md) / [配布記録](minimal-visual/DELIVERY.json)。指定2点のみ。ユーザー承認で既存EXEへ99a33deを反映。関連ロジック141項目、ロード39項目と書出EXEのheadless起動・終了に合格。通常画面は自動起動せず、実画面未確認。最新開発版の入口は同じ。以下は過去の配布・監査記録。

---

# 最新配布：大量建築・選択改善＋通常60fps上限（2026-10-14）

ユーザー承認により既存の「最新開発版」EXEへ `e125d2b` を反映した。性能修正 `e4e406a` を含む。ショートカットは同じ。通常データは変更していない。

- [配布対応・ハッシュ・検査結果](verification/scalability-delivery.json)
- [今回のheadless検査・exportログ](verification/last-run.json)
- 前回の性能試験対象8ソースのハッシュ一致を確認。今回追加した60fps設定とロードをheadlessで検査し、書出EXEもheadlessで起動・終了した。GPU／通常画面は起動していない。
- 長時間履歴の蓄積・背景負荷制御など、下記監査の残課題は未修正。PC全体フリーズの解消や実操作の快適さを検証済みとはしない。
- 以下は監査・過去配布時点の記録。「EXE未更新」はその時点の状態であり、最新は上記配布記録を参照。

---

# 追加：リソース・長時間安定性監査（実行試験なし）

[監査結果・蓄積リスク・承認前の実測計画](scalability/RESOURCE_AUDIT.md)。ソースと既存ログのみ確認。ゲーム起動・GPU試験・EXE更新・ファイル削除は実施していない。通常60fpsの明示上限、履歴／退役敵の保持に課題あり。現在の実CPU/GPU/メモリ使用率と長時間安定性は未測定。

---

# 最新：大量建築・選択の性能監査（EXE未更新）

[報告・計測値・残課題](scalability/REPORT.md)。コード変更とheadlessロジック試験のみ。通常EXEは下記caf02f8のまま。

---

# 現在：診断撤去・保存機能なし

ユーザーのPC全体の停止報告と撤去指示を受け、診断前 a519450 の描画・音声・ローディングに戻した。保存／読込／自動保存も撤去し、起動は毎回新規。

- headless検査・ビルド結果：[verification/last-run.json](verification/last-run.json)
- EXE対応：[verification/session-only-delivery.json](verification/session-only-delivery.json)
- 過去の診断結果：[performance-diagnosis/REPORT.md](performance-diagnosis/REPORT.md)（撤去済み。現在の起動手順には使わない）

通常画面・GPUを使った検査は実施しない。フリーズの原因と解消は未確認。以前のセーブファイルは残すが、ゲームから読み書きしない。ゲーム内進行とUI設定は維持。
