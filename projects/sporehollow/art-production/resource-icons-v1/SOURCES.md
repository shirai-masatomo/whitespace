# 資源アイコンの出典
内蔵image_gen.imagegenで種類ごとに1回ずつ生成したオリジナル原画。外部有料API・追加サービスは使っていない。
wood: exec-3f035ecb-08cc-4bbc-8c79-885e0e5802df.png
soil: exec-35415685-e7a9-4cbc-ad73-65521112835e.png
stone: exec-f961bb70-958c-48a0-9930-5e9271f0690b.png
gold: exec-078584c6-027f-4088-8546-98c7262092a3.png
各原画をoriginalsへ保管。prompts.jsonに全文。prepare_icons.pyでサイズごとに等比整形、素材別パレット、二値alpha、最終サイズの1px輪郭、24px時の孤立した内部ノイズ処理を行う。
土・木・石は既存rules.gdのRESOURCE_TYPES、goldは既存通貨。新しい資源種類を追加したものではない。
