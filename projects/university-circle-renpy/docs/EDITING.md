# シナリオ・条件・素材の編集

編集はUTF-8の `.rpy` ファイルで行います。JSONへの変換や独自フレームワークは不要です。
編集後は静的レビューを行い、[隔離規約](../../../docs/DEVELOPMENT_ISOLATION.md)を満たす環境でLint・ゲーム操作を確認します。

## 台詞と選択肢

`game/story/campus.rpy` の例:

```renpy
aoi "次の講義まで少し時間があるんだ。一緒に話さない？"
menu:
    "サークルについて話す（好感度＋1）":
        $ affection_aoi += 1
        show aoi smile with dissolve
        aoi "興味を持ってくれてうれしい。"
    "挨拶して別れる":
        protagonist "また部室で会いましょう。"
```

引用符の中が表示文です。字下げは半角スペース4個単位で揃えます。台詞内の引用符は `\"` と書きます。
人物名は `game/characters.rpy` の `Character("葵", ...)` を変更します。`aoi`という内部名はそのまま利用できます。

## 好感度とフラグ

初期値は `game/state.rpy` の `default affection_aoi = 0`。
海の条件は `define beach_affection_required = 2`。実際の分岐は `story/beach.rpy` の `if affection_aoi >= beach_affection_required:` です。
`beach_visited_with_aoi` は一緒に海へ行った履歴、`campus_visits` と `club_visits` は訪問回数です。
保存対象のプレイ状態は `default`、固定設定は `define` に置きます。セーブ管理を独自に作りません。

初期値の変更は既存セーブの値をリセットしません。初期値を確かめるときは隔離ゲスト内で「スタート」から新規ゲームを開始します。

## 地点とイベント

`game/circle_map.rpy` の `circle_locations` に `(表示名, 呼び出すlabel, 説明文)` を登録します。
対応するシナリオファイルに `label cafe_event:` 等を追加し、最後を `return` にします。`start`を別途作らないでください。
マップが `call expression _return` でイベントを呼び、終了後マップへ戻します。外部から任意コードを読み込む仕組みはありません。
将来イラスト地図にするときは、返すlabel名を維持して各ボタンを `imagebutton` に置き換えます。

## 背景・表情・音声

素材の対応は `game/assets.rpy`。例:

```renpy
image bg campus = "images/bg/campus.webp"
image aoi neutral = "images/characters/aoi/neutral.png"
image aoi smile = "images/characters/aoi/smile.png"
define audio.campus_theme = "audio/bgm/campus.ogg"
```

この右辺だけ差し替えると、`scene bg campus`、`show aoi smile`、`play music campus_theme`の記述を保てます。
背景は1280×720、立ち絵は足元・顔・キャンバスサイズを表情間で揃え、透過PNG/WebPを推奨します。
現在の仮立ち絵は400×650です。正式素材の寸法に合わせて `aoi_stand` の表示位置・倍率も調整します。
モデル・利用規約・出典を[素材台帳](../asset-register.json)へ先に記録し、権利未確認の素材を配布物へ混ぜません。

## 標準UIを保つ

`game/screens.rpy`はRen'Py 8.5.3公式生成版を使用しています。
セーブ／ロード・履歴・オート等の機能追加は不要です。見た目の設定変更はまず`gui.rpy`から行います。
セーブの互換性は、変数名・label名・シナリオの構造を大きく変えるほど影響します。公開後は更新前データをゲスト内へコピーしてロードを確認します。
