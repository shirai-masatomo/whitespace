# 衣装・構図から始めるプロンプト集

更新：2026-10-22。[操作ガイド](COMFYUI_FIRST_STEPS.md) / [保存方法](COMFYUI_STORAGE.md)

プロンプトを一からネットで調べなくても始められる。「誰を・何を着て・どこで・どちらを向いて・どこまで写すか」を日本語で決め、下の部品を使う。ここで日本語の希望を伝えて、ComfyUI向けの文面へ整理することもできる。

この集は一般向けの着衣サンプル。文章の意味を指定するための例であり、各例の出力品質は未検証。[Animagine XL 4.0のモデルカード](https://huggingface.co/cagliostrolab/animagine-xl-4.0)を踏まえ、まず短い英語タグをカンマでつなぐ。正確な複数人配置や手指は文章だけでは難しい場合がある。

## 日本語で決める注文票

```text
人物：成人女性1人／既存ヒロインLoRAを使うか
髪と瞳：金髪のロング、青い瞳
服：白いタートルネック、青いカーディガン、紺の足首丈スカート
表情：穏やかな笑顔
姿勢：絨毯に横座り
視線：画面左を見る
写す範囲：全身
カメラ：目の高さ、斜めから
場所：リビング、後ろにソファ
足元：室内なので素足または靴下
優先順位：服装 → 座り方 → 背景
変えたくない点：髪色と瞳
```

優先順位を決めると、失敗時にどの条件から直すかが分かる。「男子がソファ、女性が絨毯」など人物間の高さ・接触・距離は、人物1人の練習後に分けて検討する。参照画像は人物、画風、構図のどれを参考にするかも明示する。

## 基本の組み立て

```text
[識別語], 1girl, solo, adult woman age 24,
[髪・瞳], [表情], [服装], fully clothed,
[写す範囲], [姿勢], [視線], [場所], [カメラ],
masterpiece, high score, great score
```

角括弧は説明用。実際には括弧ごと削除して具体的な語へ置き換える。通常生成で識別語は不要。ヒロインLoRAを接続した04では `wshrn26` を残し、金髪・長髪・青い瞳も書く。識別語だけで外見が固定されるとは限らない。

## よく使う部品

| 指定したいこと | 入れる語の例 |
| --- | --- |
| 白いタートルネック | `white turtleneck` |
| 青いカーディガン | `blue cardigan` |
| 紺の足首丈プリーツスカート | `navy blue ankle-length pleated skirt` |
| 普段着のパンツ | `beige trousers` |
| 素足／白い靴下 | `bare feet` ／ `white socks`。片方を選ぶ |
| 全身／上半身／顔寄り | `full body` ／ `upper body` ／ `close-up`。1つを選ぶ |
| 正面／斜め／横顔 | `front view` ／ `three-quarter view` ／ `profile` |
| 目の高さ／俯瞰 | `eye level` ／ `from above` |
| 立つ／椅子に座る | `standing` ／ `sitting on a chair` |
| 絨毯に横座り | `sitting sideways on a carpet, legs folded to one side` |
| 両手を前で重ねる | `hands clasped in front` |
| 見る方向 | `looking at viewer` ／ `looking to the left` ／ `looking down` |
| 笑顔／控えめな照れ | `gentle smile` ／ `shy smile, light blush` |
| 眠そう／不安 | `sleepy expression` ／ `worried expression` |
| 白背景／リビング | `white background` ／ `living room, sofa in background` |

服の名前は具体的に、同じ服の相反する色や丈を並べない。長いタグ列より、必要な条件を残す。室内で全身を描く場合は靴・パンプス・スニーカーを引き継がない。

## 例1：服の色だけを比較

01をそのまま1枚作り、02で `navy cardigan` だけを `red cardigan` に変更する。seed、サイズ、モデル、その他の語は固定。服と顔の両方が変化する場合もあるので、色変更に成功したかと人物の維持は別に見る。

## 例2：絨毯に座る全身（03に収録）

```text
1girl, solo, adult woman age 24, long blonde hair, blue eyes,
gentle smile, blue cardigan, white turtleneck, long navy skirt,
fully clothed, full body, sitting sideways on a carpet,
legs folded to one side, bare feet, looking to the left,
living room, sofa in background, eye level,
masterpiece, high score, great score
```

横長1216×832、batch 1。01から題材・姿勢・サイズを同時に変えた練習案なので、単独要因の比較にはしない。足の本数、スカートの丈、家具へのめり込みを確認する。

## 例3：ヒロインの衣装候補（04に収録）

```text
wshrn26, 1girl, adult woman age 24, solo,
blonde hair, long hair, blue eyes,
full body, standing, three-quarter view, looking at viewer,
gentle smile, hands clasped in front,
blue cardigan, white turtleneck, gold necklace,
navy blue ankle-length pleated skirt, bare feet, white background,
masterpiece, best quality, very aesthetic
```

LoRAを接続した04専用。服を替えるなら元の服の語を削除して差し替える。プロンプトに識別語を足すだけではLoRAは接続されない。

## 例4：会話用の上半身

```text
1girl, solo, adult woman age 24, long blonde hair, blue eyes,
gentle smile, blue cardigan, white turtleneck, fully clothed,
upper body, three-quarter view, looking to the left,
living room, eye level, masterpiece, high score, great score
```

01のPositiveを置き換える練習案。ヒロイン本人を狙う場合は04を基に `wshrn26` を加える。視線の左右が守られるかは画像で確認する。

## Negativeと調整の順番

初回のNegativeは以下でよい。

```text
text, watermark, logo, blurry, deformed hands, extra fingers, duplicate people
```

Negativeは避けたい要素の指定であり、修正の保証ではない。最初から大量の語や強い重みを加えない。不要な靴が出るならPositiveの素足指定を確かめ、必要に応じてNegativeへ `shoes, high heels, sneakers` を追加して比較する。

1. 相反する姿勢・画角・服を取り除く。
2. 同じseedで1条件だけ変える。
3. 固定した設定で別seedを試し、偶然の失敗か傾向かを見る。
4. 文章だけで難しい場合は参照／マスク／ポーズ制御を検討する。[応用手順](../notes/306714e6041f9e32.html)と[過去の品質比較](../notes/6d9e782ceb1faaf3.html)を先に読む。

元画像を置くだけで顔が必ず一致するわけではない。ポーズ制御や画像編集は別のワークフローであり、通常の文章生成のdenoiseや接続を適当に変更して代用しない。

ネットのプロンプトを参考にするときは、モデル名・世代・LoRA・解像度・推奨値も見る。SD1.5用や別系列の長い例文を、そのままAnimagine XLへ移さない。追加重み・拡張機能が必要な例は、初回の4ひな形とは別に扱う。
