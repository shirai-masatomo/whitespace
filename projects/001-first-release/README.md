# DIVE DIVE

**海へ飛び込み、海藻林を歩き、洞窟へ泳ぎ、別の口から海へ戻る水中ゲーム。** 「まだ人間がレビューする段階ではない」を受け、海そのものを遊び場にする制作版です。完成版・人間レビュー待ちではありません。

## 開発対象の指定

**L=層 / P=層内フェーズ / G=層間ゲート**。[全体のL/P/G構成](HUMAN_DIRECTION.md) / [現行試作との対応](PROJECT_STATE.md) / [対象別タスク](TASKS.md)。現在はL1-P0〜L1-GとL2-P0/P1、可能ならP2の品質を作る。約680m版は圧縮試作であり、目安深度への到達・品質完成を意味しない。

「L1-P2の岸壁」「L2-P0の暗闇」と指定すれば、その区間に集中する。L2-G/L3以降は構想のみ。定期再開はPAUSED。

## 今すぐ遊ぶ（Windows）

1. このPCの今回の最新版は **`build/windows-agent/DIVE DIVE.exe`** をダブルクリック。
2. 「潜りはじめる」またはEnter。WASDで桟橋の端から海へ飛び込む。
3. 岩棚→光る海藻→流木→クラゲの順に潜る一本道の導入です。約125mから岸壁側の大きな泡と、岩礁側の藻庭が現れ、L1-P2へ進むにつれて寄り道を選べるようになります。藻と泡は接触で即酸素100%。
4. 約450mの砂の海底へ。岩盤の隙間へ入り、暗い曲がり道を光る水球に沿って潜ると、巨大空間でタコに遭遇します。約680mの最後の水球で今回の試作は終了。

入水直後の左の藻庭・右の洞窟への誘導は撤去し、P1/P2移行帯へ配置し直しました。初期の海は開けたまま、主進行を一本にしています。自由な見回し/遊泳、Spaceでの登り返しは維持します。

移行帯の右側に歩ける岩礁と縦穴、その先に二つの入口を持つ洞窟があります。洞内・屋根・外側から選べるのはこの区間以降です。追加した藻庭も、接触した安全位置を救助先として記録します。

側面穴の外には泡の上昇流。乗ると上へ戻され、横に泳げば外へ出られます。Eで潜り抜けることもできますが、酸素を多く使います。

この作業環境の最新出力は `windows-agent` です。別PCには `build/DIVE-DIVE-windows.zip` を展開して渡します。Godot/Python不要。[GitHub Actions](https://github.com/shirai-masatomo/whitespace/actions/workflows/dive-dive.yml) の最新成功実行の **DIVE-DIVE-windows** artifactでも配布物を取得できます。

| 操作 | 動作 |
| --- | --- |
| WASD / 矢印 | 水平移動。水中でも軌道修正可能 |
| マウス | 見回す |
| E長押し | 急降下。酸素消費2.5倍 |
| Space長押し | 水中で浮上。離すと自然沈降。Eとの同時押しは浮上優先 |
| Q長押し | 沈降を減速 |
| F長押し | 俯瞰 |
| H / Tab | 任意の道案内ON・OFF / 案内を表示して目標候補を切替 |
| V | 三人称 / 一人称 |
| M | 音のON/OFF（現在の起動中のみ） |
| Esc / Enter | 一時停止 / 再開 |

足場上では沈降が止まりますが、水中の普通の足場では酸素が減ります。光る藻のそば・巨大泡の内側・海上では減りません。泡は上へ押すためEまたは横移動で抜けられます。救助の帰還地点は藻で更新され、漂う泡は一時的な避難場所です。酸素0で泡になって浮上し、訪問済みの浅い安全地点で再挑戦。死亡画面・ロード・ワープなし。フォーカスを外すと一時停止。Spaceは水中の浮上操作で、桟橋上のジャンプではありません。

序盤には巨大泡2個、内部を抜ける岩アーチ、曲がる潮流、ゆっくり横切る大きな生物。泡を無視して既存の道を進むこともできます。26の既存足場と、歩ける大岩盤・各所の海中補給群落。広い海から岩棚を歩き、岩の屋根を抜けて沖へ出るか、クラゲや動く流木へ進むかを選べます。300m以深は狭い裂け目と、その外側の開けた経路。藻・魚群・エイ・潮流が景観と判断の手掛かりになります。道案内は初期OFFで、困った時だけHを使えます。

足場・岸壁・流木の幹/枝・クラゲの傘は上面以外にも当たります。柔らかい葉・クラゲの細い触手、魚・泡は通過可能。巨大タコの身体と太い腕には当たります。救助中は泡の状態で障害物を通り抜けます。波音/水中音と操作音あり。生物層は導入と遭遇のみ。セーブ・Steam SDK・オンライン・ボス戦は未実装。

**対象別の代表画面・確認条件**は [REVIEW_PACKET](REVIEW_PACKET.md)。[現在地](PROJECT_STATE.md) / [次タスク](TASKS.md) / [AIレビュー](AI_REVIEW.md)。

標準はForward+（Vulkan対応GPU）。描画に問題があれば同梱の `Play-Compatibility.ps1`、または `./dev.ps1 play -Renderer gl_compatibility` でOpenGLへ切り替えます。同じゲーム内容で、体積霧は近似光線になります。

160m前後の岸壁に、棚を囲む大きな岩体と斜めに張り出す天井があります。下をくぐる、岸沿いの段丘を歩く、Spaceで上側へ回り込む、沖へ出る経路を選べます。上側も実際に着地・歩行できますが酸素は減ります。

160m前後では、125mの補給地点から東南の岸壁へ寄れます。段丘を歩き、西岸の張り出しで補給するか、切れ込みへ潜るか、沖の生物を追うかを試せます。下側の入り江では、岩の窓をくぐって速い潮に乗ると既存の岩礁へ再合流できます。岩の上側も登れますが、寄り道中も酸素は減ります。現在も制作中で、初見の誘導と岩の自然さは改善対象です。

## Godot Editorで配置を編集する

1. Godotのプロジェクト一覧で、このフォルダの `project.godot` をインポートして開く（このPCでは `./dev.ps1 editor` でも起動）。
2. FileSystemから **`game/levels/l1_editable.tscn`** をダブルクリック。これが配置の正本です。
3. 左のSceneツリーで下表のNodeを選び、**F**でその場所へ視点を合わせる。**W**で移動、**E**で回転。またはInspector → TransformのPosition / Rotationを数値入力。
4. **Ctrl+S → F5**でゲームを起動。停止はF8。再編集→保存→F5を繰り返せます。配布EXEへ反映するには `./dev.ps1 build` が必要です。

| Sceneツリー | 編集できるもの |
| --- | --- |
| `RocksAndOxygen/Rock_…` | 岩、流木、クラゲ、水球、桟橋の位置・回転。岩の子`OxygenAlgae`は補給位置も一緒に移動 |
| `FaultedCoast` | 岩窓、隆起岩盤、崖。`JoinedTerraces`内の棚・崩落斜面 |
| `ShallowHeadland` | 最初の大岩盤全体 |
| `OxygenGardens/OxygenGarden…` | 独立した酸素藻の群落。補給と救助先も保存位置を使用 |
| `Animals/Ray_…` | エイの配置・向き。保存位置の周辺で泳ぐ |
| `SandFloor` / `GateWestBedrock` / `GateEastBedrock` | 海底全体と入口を囲む岩盤 |

**岩や棚は親Nodeを動かしてください。** 子のMeshだけを動かすと、別の子にあるCollisionとの形がずれます。通常は位置・回転を調整し、非均等拡大や形状編集は別途衝突確認が必要です。グループごとの移動も可能。Nodeの削除/名前変更、通路を塞ぐ配置には注意してください。

保存したTransformは起動・リスタートで初期座標へ戻しません。動く足場は編集した位置・向きを基準に往復します。メッシュは `geometry/*.scn` に保存し、配置はテキストの `l1_editable.tscn` に分離しました。自動再生成は行いません。`stage_layout.gd`等の旧座標は軽量モデル試験用の初期値で、実ゲームの配置を上書きしません。

水面・照明・遠景、魚群の経路、潮流とL2狭路は引き続き手続き生成です。海底/ゲートを大きく移動する場合は潮流も調整する必要があります。Editor内の光は形を見るための補助光で、F5の水中照明とは異なります。

## 開発と検証

通常は軽い起動/対象操作だけ。以下のcheckは節目用。スクショはユーザー/外部AIから対象IDの確認依頼が来た時だけ2〜4枚。`visual-*` は既存の試走を行うが、保存は `-Capture` で選んだラベルのみ（最大4枚）。指定なしならPNG/JPGを生成しない。連続画像は明示的に必要な時だけ `-RecordSequence`。

例: L1-G/L2-P0/L2-P2をまとめて依頼された場合のみ:

```powershell
./dev.ps1 visual-biology -Capture '116-sand-throat','117-dark-throat','118-first-octopus'
```

生成先は無視対象のartifacts。採用分だけ `review/<対象ID>/entry.png` / `middle.png` / `exit.png` / `issue.png` に上書きし、REVIEW_PACKETの条件を更新する。古い画像を追加保存し続けない。

Windows x64、開発時のみPython 3.12以上。リポジトリルートから:

```powershell
cd projects/001-first-release
./tools/setup.ps1
./dev.ps1 check -BuildFolder windows-agent
./dev.ps1 play
```

build内は最新版の `windows-agent/` と配布用 `DIVE-DIVE-windows.zip` に整理しています。`dev.ps1` の標準出力先も `windows-agent` です。使用中のEXEは上書きせず、終了後にビルドしてください。実行制限がある場合は、この信頼したスクリプトに限り `powershell -NoProfile -ExecutionPolicy Bypass -File ./dev.ps1 check`。マシン全体のポリシーは変更しません。

- `setup`: Godot 4.7.2・Windowsテンプレートを公式SHA512で検証、固定版の開発ツールを専用venvへ導入。
- `check`: format / lint / 開発依存整合性 / import / ルール・シーン・音・実プレイヤー全方向衝突テスト / evaluate / release export / EXE headless起動 / 配布zip。
- `evaluate`: 軽量モデル11経路・対照条件・操作中断の見積もり。実衝突の証明には使いません。`test` の実プレイヤー11経路・689検査が別途 `artifacts/player-collision.json` に実測を残します。
- `visual`: 実GPUで入水→各操作→失敗→再挑戦→生物層序盤、カメラ・960×540 UI。`artifacts/<renderer>/` に撮影。
- `visual-biology`: 海底の補給地点から、岩の肩を回って狭路→巨大空間→タコ遭遇。代表3枚だけを画面外で撮影。headless版の `test_biology.gd -- --full` は桟橋から通して移動し、接触/救助も確認。
- `visual-reef`: 岸壁歩行→裂け目、沖側の別経路を連続操作し、`artifacts/reef-<renderer>/` に撮影。どちらも画面外・フォーカスなし・マウス非捕捉。画像を目視確認します。
- `visual-discovery`: 入水→泡→曲がる潮流→岩の穴→藻への連続入力、酸素残量による寄り道比較。`artifacts/discovery-<renderer>/` に撮影。
- `visual-playground`: 桟橋→岩礁歩行→縦穴→内部歩行→別出口。屋根/外側/逆口は別試走、上下側面の実衝突も検証。
- `visual-canyon`: 125mの既存補給地点から峡谷の段丘→橋→内部へ連続入力。内外/酸素比較は別の開始点で試走。`artifacts/canyon-<renderer>/`へ撮影。
- `visual-headland`: 通常の前進入水→大岩盤→段丘を歩いて藻へ→登り返し→縁から下降→下面→流木。新地形の通常/E/Space/斜め接触を60/15Hzで検査。`artifacts/headland-<renderer>/`へ撮影。
- `visual-massif`: 新しい張り出しの実接触と、岸の藻→上側歩行→既存藻への往復だけを画面外で確認。全体は`visual-canyon`で検証。
- `visual-cove`: 入り江の岸/岩窓/上側と、潮流に乗って既存岩礁へ戻る区間だけを画面外で比較。`artifacts/cove-<renderer>/`。全峡谷検査の代用ではありません。
- `visual-entry`: 海上から入水、太陽光、魚群の先の海藻林を撮影。`artifacts/entry-<renderer>/`。
- `gpu-smoke -BuildFolder windows-agent`: 配布EXEを画面外・無音で起動し120フレーム描画。`-Renderer gl_compatibility` でも確認できます。
- `benchmark -Renderer forward_plus` / `benchmark -Renderer gl_compatibility`: 6場面の1280×720フレーム時間。結果は `artifacts/render-*.json`。
- `format` / `test` / `lint` / `build` / `editor`: 個別実行。生成ログは `artifacts/`、レビュー用の選別画像は `review/`。

GitHub ActionsはWindowsでsetup/checkを実行しZIP・ログ・測定JSONを保存。GPU確認はローカルで実施します。レビュー画像・開発用ファイルは配布ゲームから除外。

重要な再現メモ: 使用中のEXEをbuildで置換すると失敗するため、通常の自律検証は `./dev.ps1 check -BuildFolder windows-agent` を使います。Godotは終了コード0でもSCRIPT ERRORを出すことがあるので、ログ存在とERRORなしも必須。EXEへ渡すログパスは絶対パスにします。

## 構造と変更の入口

- `game/dive_config.gd` / `default_config.tres`: 移動・酸素・救助の調整値。
- `game/levels/l1_editable.tscn`: 実ゲームの岩・藻・主要地形・エイの配置。`editable_coast.gd`が保存Transformをゲームへ渡す。
- `game/stage_layout.gd` / `reef_layout.gd` / `rift_layout.gd`: 軽量モデル評価用の初期レイアウト。現行シーンを自動再生成しない。
- `game/discovery_rules.gd` / `discovery_world.gd`: 足場と独立した泡・潮流・穴・生物。調整はconfigのdiscovery/bubble項目、全体比較は`discovery_enabled`。
- `game/canyon_world.gd`: 160〜240mの連続段丘・斜面・岩橋・内外の横断口。描画メッシュをそのまま衝突に使用。
- `game/dive_model.gd`: 移動・酸素・救助。実ゲームは `player_motion.gd` の連続掃引カプセルと `level_collision.gd` の固体メッシュ衝突を使用。上面のみの計算は軽量テスト用。
- `game/diver.gd`: 主人公モデルと姿勢。`ocean_geometry` / `ocean_nature` / `ocean_lighting` / `ocean_effects`: 形状・自然景観・光・泡/粒子。
- `game/main.gd`: 入力/カメラ、`world.gd` / `shaders/`: 水面・深度別照明・リアル層景観、`hud.gd`: 日本語案内。
- `tests/`: ルール、実シーン入力、自動操縦、GPU撮影。`route_driver.gd` はテスト用の操縦のみ。
- 自律作業は [AUTONOMY](AUTONOMY.md)。Godotを継続使用。UE5移行を要する具体的な制約はまだ確認していません。

## 素材と権利

他ゲームの素材・ステージは使用していません。景観・スーツモデルは独自のコード生成メッシュ/シェーダー。音は独自合成PCMで外部録音素材を使用していません。日本語フォントは [Noto Sans JP](https://github.com/google/fonts/tree/main/ofl/notosansjp)、[SIL OFL](assets/fonts/OFL.txt)。[Godotの著作権・第三者表示](assets/GODOT_COPYRIGHT.txt)もZIPへ同梱。

`EditableCoast/ReefExploration` は移設したP2岩礁・洞窟の生成基準です。実行時の洞内空気・上昇流・魚群はこのTransformに追従します。大きく動かす場合は独立した `OxygenGarden0〜4` と周辺海底も合わせて調整してください。
