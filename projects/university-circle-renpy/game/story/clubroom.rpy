label clubroom_event:
    $ club_visits += 1
    scene bg clubroom with dissolve
    play music campus_theme fadein 0.4
    show aoi neutral at aoi_stand with dissolve
    aoi "ここが部室。今は次の散策の準備をしているところだよ。"
    menu:
        "準備を手伝う（好感度＋1）":
            $ affection_aoi += 1
            play sound event_chime
            show aoi smile with dissolve
            aoi "ありがとう。二人だと、準備も早く終わりそう。"
        "活動について聞く":
            aoi "気軽に歩いて、気に入った景色を記録するんだ。"
    if affection_aoi >= beach_affection_required:
        aoi "今度、海にも行ってみよう。きっと気持ちいいよ。"
    hide aoi with dissolve
    return
