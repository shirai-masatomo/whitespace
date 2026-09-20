# DIVE DIVE — PROJECT STATE

更新: 2026-09-20

**Phase 3 / リアル層の場所づくり / CHANGES・SELF_CONTINUE**。人間レビュー待ちではない。最終目標はSteam公開可能なWindowsゲーム。現在はSteamなしでゲームを成立させる段階。

## 現在動くもの

- 海上から入水、自然沈降5m/s、E15m/s・酸素2.5倍、Space6m/s。藻で即補給、酸素切れは同じ世界で救助。450mの既存経路。
- 浅海の連続岩礁・海藻林・縦穴・空気洞、洞内/屋根/外側の周回、泡上昇流。
- 160〜240mの東側に段丘・斜面・岩橋・橋の下の藻庭・壁を横断する内外経路。125mの既存補給地点から連続試走。歩いて下降/登り返し、泳いで横断、橋の下へ潜れる。
- 入水済みの泳者と追従カメラの水中判定を合わせ、大きな泡の遮蔽を減らした。
- 最新ビルド出力は `build/windows-agent/DIVE DIVE.exe`。人間の `windows-preview` 等は置換しない。[起動方法](README.md) / [比較と測定](REVIEW_PACKET.md)。

## 検証と同期

`git fetch origin main` 後、正本2文書は `origin/main` の `8b49a60` を確認。HUMAN_DIRECTIONは正本本文と会話補足を分離、EXTERNAL_AI_REVIEWは正本と一致。未実装指示はDD-064〜067のP0/P1へ。

最終コードで `./dev.ps1 check -BuildFolder windows-agent` 成功。format/lint/依存、ルール479・シーン430・音57・実衝突689・探索19・岩礁/藻庭救助147・入水7・峡谷32、補助の表面2688点、既存11経路、Windows export/EXE headless起動。逆向き歩行の速度消失も修正。Forward+/Compatibilityの峡谷32検査・入水撮影、標準visualの救助/ゴール、配布EXEの両方式120フレーム描画も成功。GPUは画面外・無音・非捕捉で行い、Codexが起動したプロセスのみ終了。

GitHubは既存[下書きPR #2](https://github.com/shirai-masatomo/whitespace/pull/2)。remoteの探索commit `dec6b4a86696daea3294b76742c3580ee894af86` のCIは成功。今回の変更のCIはpush後に確認する。今回のpush実行は承認されたがremote先行で拒否されたため、`be1b24c` の管理文書更新を通常merge。タスクID衝突は内容を統合しDD-068へ分離。再push/CI確認を続ける。

## 未解決と次の作業

1. DD-064: 入水の藻へ向かう一択感。横穴/沖側/深部を、近景の葉を減らすだけでなく行く理由と見通しで比較。
2. DD-065: 段丘と岩橋はまだ人工的。自然写真の層状の欠け・窪み・生物密度差を使い、平面の廊下感を減らす。階段の小刻みな段差や狭い棚は未完成。
3. DD-067: 前版との画面比較を継続。景観密度とプレイアブル密度を分け、行った先の見返りも確認。テスト成功から面白さを認定しない。

旧レビューPNG70枚と孤立した旧東側アーチを整理。最新証跡・再現コード・履歴・使用中ビルドは保持。別GPU/初見探索/長時間プレイは未確認。保存/Steam SDK/450m以深は未実装。
