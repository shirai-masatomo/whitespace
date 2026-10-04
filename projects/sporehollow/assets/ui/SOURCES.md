# UI素材の出典

- `shiba-source.png`：ユーザー提供の「codex-clipboard-3aecb7b7-d219-4fd0-a018-e9eb66c8a676.png」。2508×627の原画像を無改変で保存。左/正面/右の切り出し範囲を描画時に指定し、`shiba-key.gdshader`で白背景を除く。盤面・指示プレビュー・図鑑に使用。
- `market-stall.png`、`book-open.png`：以前のUI改修でOpenAI imagegenから作成した透過PNG。今回の追加修正では再生成していない。第三者の外部素材パック・追加ライブラリは不使用。
- `paper-frame.svg`：本プロジェクト用のオリジナル32pxドット枠。Godot StyleBoxTexture、各辺7pxの9-sliceで使用。ボタン通常/ホバー/押下/無効と札・パネルの共通素材。
- カーソル/小アイコン：`game/ui_style.gd`の既存ピクセルパターンへ本・移動旗等を追加。Godot 4.7.2標準描画のみ。

## 生成に指定した方向

露店：transparent background, pixel art, sage green and cream striped canopy, friendly straw-hat merchant, wooden counter and crates, logs, stones, eggs, warm earthy limited palette, crisp pixel edges, no text, no UI buttons.

見開き：transparent background, open pixel-art book, blank warm parchment pages, brown leather cover visible beyond paper, central stitched binding, layered page thickness and inner shadows, sage bookmark, matching ranch UI palette, no text or symbols, front view.

生成物はそのままテクスチャとして導入し、コード側で表示サイズとページの頂点/UVを指定する。柴犬は新たに生成し直さず、指定された原画を採用。
