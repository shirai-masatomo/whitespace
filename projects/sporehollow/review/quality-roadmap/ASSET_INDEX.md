# 素材と確認資料の入口

2026-10-09。実体は動かさず、用途と採用記録で探す。`candidates` という名前だけで未使用と判断しない。主人公のデザイン変更は別途承認が必要。

| 探すもの | 正本／入口 | 読み方 |
|---|---|---|
| 全体の納品・採用元 | [art_provenance.json](../../game/art_provenance.json) | 納品commitと受領記録への対応 |
| 図鑑・カードの採用絵 | [adopted_ui/manifest.json](../../assets/adopted_ui/manifest.json) | assets/adopted_ui の実体と採用範囲 |
| 黄金像 | [golden_idol_receipt.json](../../game/golden_idol_receipt.json) | goldAを採用。goldBはユーザー指定で代案として保持 |
| 木・UI・向き | [direction_receipt.json](../../game/direction_receipt.json) | 採用したファイルとハッシュ。候補フォルダにも使用中の絵がある |
| 既存キャラの動作 | [motion_receipt.json](../../game/motion_receipt.json) | 実装側受領・検証の記録 |
| 商人・メイド・舞姫・盗賊・乳牛・闘牛 | [six_motion_receipt.json](../../game/six_motion_receipt.json) | 素材側の古いruntime_verified=falseだけで未統合と判定しない |
| 納品原本と候補 | [art_delivery](../../art_delivery/) | パッケージ内のHANDOFF・manifest・QAを読む。素材の移動や自動削除をしない |
| 制作中の作業資料 | [art-production](../../art-production/) | 採用済みかは上の受領記録と実装参照で判断 |
| 今回の実画面 | [WALKTHROUGH_GALLERY.html](WALKTHROUGH_GALLERY.html) | 新規通しと途中fixture、修正前後を区別 |
| 過去の検証 | [CHECK.md](CHECK.md)、[RESUME.md](../../RESUME.md) | 各日時のソース／EXEを区別。最新の記述を先頭に置く |

新しい画像は `artifacts/isolated/YYYYMMDD-HHMMSS-fff/` の下へ、`YYYYMMDD_連番_場面_before.png` または `after.png`。入力・状態JSON、SCREENSHOTS.tsv、隔離実行記録を同じ場所へ残す。比較一覧から参照し、同じ画像を別フォルダへ複製しない。

試遊版は `artifacts/playtest/日時/` ごとに固定し、BUILD.jsonと専用user-dataを保持。通常Play.cmdの保存へコピーしない。整理は索引追加から始め、未知ファイル・ユーザー素材・セーブを削除しない。削除候補は用途と参照を確認し、必要なら復元可能な隔離を別途行う。
