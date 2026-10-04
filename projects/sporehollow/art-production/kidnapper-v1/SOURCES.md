# 原画と参照

内蔵image_gen.imagegenのみを使用。新しい外部有料APIなし。生成原画とゲーム用PNG、reviewの合成確認画像を分離。

木素材：exec-06f4515a-7f4d-4a81-a333-70db85328766.pngをbuildings-v1/originals/wood-kit.pngへ保存。主人公v1は絵柄参照のみ。大きな部屋一枚絵を切り抜いたものではなく、生成した木の面・床・ドア原案から48px規格の接続形状へ整形。床は全面opaque、面の境界と立ち上がりを別に計算。referencesには制作開始時点の最新ART_SPEC/BUILDINGS/ENEMIESを保存。

誘拐者：exec-c410a409-8c95-4d00-85ba-56be94bbacac.pngをkidnapper-v1/originals/idle.pngへ保存。外見の資料は既存main.gdのdraw_enemy_actor（帽子454453・マスク474954・紫上着87768e・ズボン42424c・肌d2b396）、行動はENEMIES.md。未提供の採用敵原画を見たとは扱わない。主人公v1は密度・サイズの参照のみ。

比較用の主人公・柴犬・商人は各採用PNGをそのまま使用。背景はranch-assets-v1/references/implementation-native-scale.pngの保存済み実画面。新しいゲームを起動していない。

各原画フォルダのprompts.jsonに最終プロンプト全文、prepare_*.pyに整形・検査・確認画像の作成処理を保存。

\n修正版v2：exec-d6903252-4708-4f6a-b647-a2844ead6a19.png。内蔵生成の編集で同じ敵の姿勢・表情を強めた。元案は履歴として保管。\n
動作原案：exec-efaa427a-dde6-4488-8fc0-41e4c4bd6dd5.pngをoriginals/motions.pngに保存。採用v2を編集参照とした内蔵生成。納品顔は原案の顔に置換せず、v2の同一ピクセルを再利用。腕と主人公の支持点は最終サイズで分離・整形。
