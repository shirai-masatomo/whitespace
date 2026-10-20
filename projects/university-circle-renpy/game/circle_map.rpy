# 画像を用意しなくても操作できる仮マップ画面。
# 将来的には背景画像＋imagebutton/hotspotに置換可能。

screen circle_map():
    modal True
    add Solid("#1f2d44")

    frame:
        xalign 0.5
        yalign 0.5
        xsize 720
        ysize 570
        background Solid("#f5f2ec")
        padding (48, 40)

        vbox:
            xalign 0.5
            spacing 20

            text "行き先を選ぶ" xalign 0.5 size 42 color "#23334d"
            text "大学生活 / 仮マップ" xalign 0.5 size 20 color "#556c80"
            text "葵との好感度: [affection_aoi]" xalign 0.5 size 24 color "#8a486b"

            null height 12

            textbutton "大学のキャンパス" action Return("campus") xalign 0.5
            textbutton "サークルの部室" action Return("clubroom") xalign 0.5
            textbutton "海辺" action Return("beach") xalign 0.5

            null height 10
            text "どの場所も繰り返し訪問できます。" xalign 0.5 size 18 color "#556c80"
            text "セーブ・ロードはRen'Py標準メニューで確認。" xalign 0.5 size 18 color "#556c80"
