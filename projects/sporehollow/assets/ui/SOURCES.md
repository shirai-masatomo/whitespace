# UI素材の出典

- `../reference/legacy-ui/shiba-source.png`：ユーザー提供原画像2508×627を無改変で保存する参照。現行描画では不使用。参照のない旧白抜きshaderは削除。
- 本番の主人公v1・柴犬C：`art_delivery/characters_v1/` の採用済み透過PNG4点。納品元 `f3e4ae82b68c342b928dfb5dfcebb451353f9b8d`、受領 `28f0e3f`。顔・寸法・画素を変更せず使用。manifest/HANDOFFに出典とSHA256を記録。
- `../reference/legacy-ui/market-stall.png`、`../reference/legacy-ui/book-open.png`：以前のUI改修でOpenAI imagegenから作成した透過PNG。今回の追加修正では再生成していない。第三者の外部素材パック・追加ライブラリは不使用。
- `paper-frame.svg`：本プロジェクト用のオリジナル32pxドット枠。Godot StyleBoxTexture、各辺7pxの9-sliceで使用。ボタン通常/ホバー/押下/無効と札・パネルの共通素材。
- カーソル/小アイコン：`game/ui_style.gd`の既存ピクセルパターンへ本・移動旗等を追加。Godot 4.7.2標準描画のみ。

## 生成に指定した方向

露店：transparent background, pixel art, sage green and cream striped canopy, friendly straw-hat merchant, wooden counter and crates, logs, stones, eggs, warm earthy limited palette, crisp pixel edges, no text, no UI buttons.

見開き：transparent background, open pixel-art book, blank warm parchment pages, brown leather cover visible beyond paper, central stitched binding, layered page thickness and inner shadows, sage bookmark, matching ranch UI palette, no text or symbols, front view.

生成物はそのままテクスチャとして導入し、コード側で表示サイズとページの頂点/UVを指定する。柴犬は新たに生成し直さず、指定された原画を採用。

現在はart_delivery/characters_motion_v1、ranch_assets_v1、merchant_cart_v2、merchant_board_v1を使用。出典・原画所在は各HANDOFF/manifest、実際の参照とSHA256はART_SPECとreview/current/asset-usage.json。旧原画は参照用に保全しexportから除外。
