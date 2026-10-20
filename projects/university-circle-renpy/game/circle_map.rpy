# 場所の登録と行き先 label を一か所にまとめた、最小限のマップです。
# 将来は各ボタンを imagebutton に置換できます。状態はここに持たせません。
define circle_locations = (
    ("大学", "campus_event", "講義の合間に、葵と話す"),
    ("サークル部室", "clubroom_event", "活動の準備を手伝う"),
    ("海", "beach_event", "親しくなると、二人の会話へ"),
)

label circle_map_loop:
    scene bg campus with dissolve
    window hide
    call screen circle_map
    call expression _return
    jump circle_map_loop

screen circle_map():
    # modal を使わず、標準クイックメニューと右クリックを利用可能にする。
    frame:
        xalign 0.5
        yalign 0.40
        xsize 800
        background Solid("#102d3eed")
        padding (42, 30)
        vbox:
            spacing 16
            text "行き先を選ぶ" size 34 color "#ffffff"
            text "葵との好感度: [affection_aoi] / 海の会話条件: [beach_affection_required]" size 21 color "#a3ded9"
            for title, target, description in circle_locations:
                textbutton title:
                    style "circle_location_button"
                    action Return(target)
                text description size 18 color "#c7dbe5" xoffset 16
            text "同じ場所を繰り返し訪問できます。時間制限はありません。" size 17 color "#c7dbe5"
    text "右クリック / Esc：標準メニュー　　下部：履歴・セーブ・設定" xalign 0.5 ypos 650 size 18 color "#142d40"

style circle_location_button is button:
    xfill True
    background Solid("#234c60")
    hover_background Solid("#39748b")
    padding (18, 8)

style circle_location_button_text is button_text:
    color "#ffffff"
    hover_color "#d9fffa"
    size 25
