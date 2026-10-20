label campus_event:
    $ campus_visits += 1
    scene bg campus with dissolve
    play music campus_theme fadein 0.4
    show aoi neutral at aoi_stand with dissolve
    if campus_visits == 1:
        aoi "次の講義まで少し時間があるんだ。一緒に話さない？"
    else:
        aoi "また会えたね。今日はどんな一日だった？"
    menu:
        "サークルについて話す（好感度＋1）":
            $ affection_aoi += 1
            play sound event_chime
            show aoi smile with dissolve
            aoi "興味を持ってくれてうれしい。次の活動が楽しみだね。"
        "挨拶して別れる":
            protagonist "また部室で会いましょう。"
            aoi "うん、またね。"
    hide aoi with dissolve
    return
