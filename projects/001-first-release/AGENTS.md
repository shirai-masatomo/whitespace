# DIVE DIVEの作業開始

このディレクトリに適用する。他作品の自律ルールは変更しない。

1. PROJECT_STATE.md、TASKS.md、AUTONOMY.md、存在すればAI_REVIEW.mdを読む。REVIEW_PACKET.mdも前回の評価として確認。
2. Git状態・最新main・CIを確認。他セッションの変更は上書きしない。
3. `./dev.ps1 check` で基準状態を確認。
4. AI_REVIEWがCHANGESなら修正を優先。PASSまたは未作成なら依存が解決した最優先タスクを選ぶ。
5. 実装 → 自動テスト/自動プレイ → 実画面確認 → 自己批評 → 改善 → 再テストを最低1回、核の節目では数サイクル行う。
6. 見た目や入力を変えたら `./dev.ps1 visual` と画像確認。`./dev.ps1 evaluate` で経路/酸素/救助/カメラの測定を更新。
7. STATE/TASKSと節目のREVIEW_PACKETを更新し、commit/push/CI確認。可逆な改善が残るなら次タスクへ進む。

実装完了だけでは人間確認へ移らない。HUMAN_REVIEWは核・好みだけで分かれる案・AIで判定困難なプレイ感、Vertical Slice/ほぼ完成版/RC、支払い・権利・公開判断に限定。定期監視は共通運用に従い、重複する監視を作らない。

現在の例外: 中核HUMAN_REVIEWは解除済み。リアル層の製品品質ゲートまでSELF_CONTINUE/AI_REVIEWを継続。詳細はAUTONOMYのリアル層規則を優先。
