# ゲーム開始。場面ごとの会話は story/ に分離しています。
label start:
    play music campus_theme fadein 0.5
    scene bg opening with fade
    "四月。大学二年、二十歳の春が始まった。"
    protagonist "今年は、授業の外でも何かを始めてみたいな。"
    scene bg campus with dissolve
    "掲示板の前で、サークルの案内を眺める。"
    show aoi neutral at aoi_stand with dissolve
    aoi "サークルを探しているの？　私は三年の葵。二十一歳です。"
    aoi "私たちは散策サークル。大学の周りや、海に出かけることもあるよ。"
    protagonist "面白そうですね。まずは見学してもいいですか？"
    show aoi smile with dissolve
    aoi "もちろん。部室にも気軽に寄ってね。"
    hide aoi with dissolve
    "空き時間に、気になる場所へ行ってみよう。"
    jump circle_map_loop
