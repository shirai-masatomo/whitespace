# 図書館・手前の無人テーブルから本を除去

## 目的・合格条件
2026-10-21。依頼は「手前の人が座っていない机からは本はなくす」。手前の開いた本・本の山を除去し、奥の男女大学生2人と読書中の本、机・椅子・照明、中央〜右の空間を保つ。

## 入力と環境
入力（編集対象・画風・構図）：[修正前](../../media/3843bd2e4c04783c6012.png)。
SHA256: 3843bd2e4c04783c6012483c906017fb73cda769ddd415a1d4c0eaef0bc5bc34。1672×941 RGB。原本保全。
内蔵画像編集を使用。ComfyUI・ゲーム・SDKは未起動。ローカルモデル・GPU設定の変更なし。モデルID・seed・CFG・steps・denoise等はツールから非公開。マスク・骨格・別合成は未使用。

## 試行ごとの記録
新規生成1枚、再利用0枚、目視合格候補1/1。ユーザー最終確認待ち。
出力：[修正版](../../media/96a8ac7ca25fc7dc7c95.png)。1672×941 RGB。
SHA256: 96a8ac7ca25fc7dc7c95e2ab0f804433cb1e83b077b9ba60a788aa7ce891b0a1。
日本語指示：手前の無人テーブル上の本をすべて取り除き、奥の学生が読んでいる本とランプを残す。
実際の指示全文：

~~~text
Use case: precise-object-edit. Edit target: the supplied anime library background. Remove ONLY the books lying on the unoccupied foreground reading table on the left: the stack at the lower left edge, the open book beside it, and the farther closed-book stack on the SAME empty foreground table. Replace these removed books and their shadows with clean continuous wooden tabletop matching the existing perspective, wood grain and warm sunlight. Keep the table lamps. Preserve the two adult university students seated at the separate BACK reading table and preserve the books they are reading. Preserve their faces obscured by hair or rear/side angles. Preserve the entire library layout, furniture, chairs, windows, bookshelves and shelved books, lighting, composition, camera and anime painting style. Keep the center aisle and center-right foreground empty for a heroine sprite. No additional people or objects. Same landscape framing. This is a narrowly localized book-removal edit.
~~~

## 観察・原因仮説・次の比較
目視で手前の本3か所が消え、木製天板が補完されている。奥の学生2人と読書中の本、ランプ、中央通路を確認。原本とコピーのSHA256一致、台帳8画像のハッシュとREADME参照先を検査。マスク外の画素一致は検査していない。1例であり、一般的な成功率・完全保持の保証には使わない。所要時間・メモリ未測定。追加比較なし。

## 片付けと未実施
原画像・自宅画像と設定・ヒロイン立ち絵の前後ハッシュ一致。
ホスト変更はプロジェクト内のPNGコピーと台帳・文書。生成元は標準のgenerated_imagesに保全。専用常駐プロセス・一時ランタイムは作成していない。ホスト全体の既存プロセス調査は未実施。
実行隔離は未使用（画像編集・静的ファイル確認のみ）。隔離内テストなし。ゲーム読込・実機表示・販売前の権利再調査・再生成の再現性は未検証。
