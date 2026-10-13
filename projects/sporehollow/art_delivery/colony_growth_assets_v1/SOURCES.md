# 再利用と制作出典

ラジオ等は前回の加工済み採用候補を昇格し、再生成していません。元PNGは art-production/colony-growth-previews-v2/working/、生成原画とプロンプトも同じ制作フォルダに保存済み。各PNGの出典はmanifestのsourceへ記録。

黄金像3損傷の原案だけ内蔵imagegenで編集生成。プロンプト全文は ../../art-production/colony-growth-assets-v1/generation.json、原画は同originals/。最終は採用goldAの画素を基に、生成原案の欠損方向を参考にゲーム解像度で輪郭・破断面・亀裂を調整しました。新しい有料API/外部サービスは不使用。

寝床は採用絵の無損失分離。住人の左は同一衣装の反転。三角アイコンは前回比較に用いたコード原画を再利用。既存goldA・音波・小粒子はmanifestから参照し重複納品しません。

比較背景は前回監査時の01_field（cf004ab時の資料）を継続使用。今回の最新実装参照HEADはef67bc4dfccf468a99939f803d2cf13e1ae4c995。保存画面を現在の実装成功証拠とは扱いません。

