label beach_event:
    scene bg beach with fade
    play music beach_theme fadeout 0.4 fadein 0.4
    if affection_aoi >= beach_affection_required:
        show aoi smile at aoi_stand with dissolve
        if not beach_visited_with_aoi:
            $ beach_visited_with_aoi = True
            aoi "一緒に来られてうれしい。海の風、気持ちいいね。"
            protagonist "次のサークル活動も、楽しみになりました。"
        else:
            aoi "また二人で来られたね。今日は少し遠くまで歩こうか。"
        hide aoi with dissolve
    else:
        protagonist "今日は一人で下見だ。もう少し葵さんと親しくなったら、誘ってみよう。"
    "潮風の中でひと息ついて、大学へ戻った。"
    play music campus_theme fadeout 0.4 fadein 0.4
    return
