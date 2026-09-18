# Intent Dictionary Review

この文書は「宥めよ」の入力候補を人がレビューするための一覧である。候補を大量に収集しても、自動的にはゲーム判定へ採用しない。

## Review Status

- 総候補数: `144`
- 現在ゲームで有効: `20`
- レビュー待ち: `124`
- confidence: high `86` / medium `44` / low `14`
- `adopted`: 現在のゲーム判定で使う。
- `review`: 候補データとして保持するだけで、ゲーム判定では使わない。
- `medium` / `low`: 文脈依存、短すぎる、複数intentにまたがる等の理由で特に注意して確認する。

## Source And License Notes

- Japanese WordNet: NICTのライセンスに基づく。利用・複製・変更・配布は許可されるが、著作権表示と免責条項を複製物に残す必要がある。今回の `wordnet` 候補は確認したsynsetの見出しだけで、例文は収録していない。
- Japanese WordNet notice: Copyright 2009, 2010 NICT. 詳細な条件と免責事項は下記の公式LICENSEを参照する。
- SudachiDict Synonym: SudachiDictと同じApache License 2.0。今回の `sudachi` 候補は同義語グループの見出しだけで、辞書本体はリポジトリへ同梱していない。
- SudachiDict notice: Copyright 2017-2023 Works Applications Co., Ltd.
- 青空文庫: 著作権が切れている作品は規準に従って活用できるが、保護期間中の作品は別扱い。今回は作品・作者ごとの確認を省略しないため、本文由来候補を採取していない。
- `generated`: 一般的な日本語知識から作ったレビュー候補。外部辞書や作品からの引用ではない。

参照:

- https://github.com/omwn/omw-data/blob/main/wns/jpn/LICENSE
- https://github.com/WorksApplications/SudachiDict/blob/develop/docs/synonyms.md
- https://github.com/WorksApplications/SudachiDict/blob/develop/README.md#licenses
- https://www.aozora.gr.jp/guide/kijyunn.html

## Intent Summary

| intent | 役割 | 候補数 | adopted | review |
| --- | --- | ---: | ---: | ---: |
| rejection | 会話、関係、要求を拒む表現 | 24 | 3 | 21 |
| hostile | 侮辱、非難、敵意を示す表現 | 24 | 3 | 21 |
| command | 行動や感情を一方的に指示する表現 | 24 | 3 | 21 |
| apology | 謝罪、後悔、責任を認める表現 | 24 | 5 | 19 |
| listening | 話を促し、聞く姿勢を示す表現 | 24 | 3 | 21 |
| reassurance | 安心、同伴、猶予を伝える表現 | 24 | 3 | 21 |

## Future Intent Candidates

- `empathy`: 「怖かったね」「つらかったね」のように感情を受け止める。`reassurance` と分ける価値が高い。
- `accountability`: 「私が悪かった」「言い訳しない」のように責任を引き受ける。`apology` のsubtypeから独立できる。
- `offering_space`: 「今は話さなくていい」「待っている」のように距離や猶予を差し出す。`reassurance` と `rejection` の誤判定を減らせる。

今回は既存挙動を維持するため、上記3つをゲーム用intentには追加していない。

## rejection

会話、関係、要求を拒む表現

| status | text | subtype | confidence | sourceType | notes |
| --- | --- | --- | --- | --- | --- |
| adopted | 知らない | direct-denial | high | generated | 現行ルール。 |
| adopted | 関係ない | disengagement | medium (レビュー注意) | generated | 現行ルール。主語や文脈で意味が変わり得る。 |
| adopted | どうでもいい | dismissal | high | generated | 現行ルール。 |
| review | 知りません | polite-denial | high | generated | 丁寧語の拒否・否認。 |
| review | 知ったことじゃない | dismissal | high | generated | 強い突き放し。 |
| review | 知ったこっちゃない | colloquial-dismissal | high | generated | くだけた強い突き放し。 |
| review | 私には関係ありません | polite-disengagement | high | generated | 主語を含むため単独の「関係ない」より明確。 |
| review | 僕には関係ない | disengagement | high | generated | 日常的な言い回し。 |
| review | 俺には関係ない | colloquial-disengagement | high | generated | くだけた言い回し。 |
| review | 興味ない | disinterest | medium (レビュー注意) | generated | 対象が会話以外の場合もある。 |
| review | 興味ありません | polite-disinterest | medium (レビュー注意) | generated | 対象が会話以外の場合もある。 |
| review | 聞きたくない | refusal-to-listen | high | generated | 会話継続の明確な拒否。 |
| review | 話したくない | refusal-to-speak | high | generated | 会話継続の明確な拒否。 |
| review | 放っておいて | request-for-distance | medium (レビュー注意) | generated | 境界線の提示として尊重すべき場合もある。 |
| review | ほっといて | colloquial-distance | medium (レビュー注意) | generated | 「放っておいて」の口語形。 |
| review | 勝手にして | resignation | high | generated | 会話から降りるニュアンス。 |
| review | もういい | conversation-close | medium (レビュー注意) | generated | 了承や安心の意味にもなり得る。 |
| review | 結構です | polite-refusal | medium (レビュー注意) | generated | 肯定的な評価の意味にもなり得る。 |
| review | お断りします | explicit-refusal | high | generated | 丁寧だが明確な拒否。 |
| review | 無理です | inability-or-refusal | medium (レビュー注意) | generated | 能力不足の説明の場合もある。 |
| review | 拒否 | lexical-seed | low (レビュー注意) | wordnet | Japanese WordNet 07204401-n。単独発話としては不自然。 |
| review | 拒絶 | lexical-seed | low (レビュー注意) | wordnet | Japanese WordNet 07204401-n。単独発話としては不自然。 |
| review | 断る | lexical-seed | medium (レビュー注意) | sudachi | Sudachi 同義語グループ 022497。活用形の扱いは別途検討。 |
| review | 応じない | noncompliance | medium (レビュー注意) | generated | 対象が会話とは限らない。 |

## hostile

侮辱、非難、敵意を示す表現

| status | text | subtype | confidence | sourceType | notes |
| --- | --- | --- | --- | --- | --- |
| adopted | お前 | contemptuous-address | medium (レビュー注意) | generated | 現行ルール。親しい関係では敵意がない場合もある。 |
| adopted | うるさい | insult | high | generated | 現行ルール。 |
| adopted | 面倒 | dismissive-insult | medium (レビュー注意) | generated | 現行ルール。状況説明の可能性もある。 |
| review | おまえ | contemptuous-address | medium (レビュー注意) | generated | ひらがな表記。親しい関係では敵意がない場合もある。 |
| review | てめえ | abusive-address | high | generated | 強い敵意を伴う呼称。 |
| review | あんた | rough-address | low (レビュー注意) | generated | 地域・関係性によっては中立。 |
| review | 馬鹿 | insult | high | generated | 直接的な侮辱。 |
| review | バカ | insult-variant | high | generated | カタカナ表記。 |
| review | ばか | insult-variant | high | generated | ひらがな表記。 |
| review | アホ | insult | medium (レビュー注意) | generated | 地域・関係性で軽い冗談の場合もある。 |
| review | 最低 | condemnation | medium (レビュー注意) | generated | 人ではなく状況への評価の場合もある。 |
| review | うざい | colloquial-insult | high | generated | 口語的な拒絶・侮辱。 |
| review | うぜえ | rough-insult | high | generated | 荒い口語表現。 |
| review | 消えろ | expulsion | high | generated | 強い敵意を伴う命令。 |
| review | 邪魔 | dismissive-insult | medium (レビュー注意) | generated | 対象が物や状況の場合もある。 |
| review | 面倒くさい | dismissive-insult | medium (レビュー注意) | generated | 人ではなく状況への評価の場合もある。 |
| review | めんどくさい | dismissive-insult-variant | medium (レビュー注意) | generated | ひらがな表記。 |
| review | しつこい | criticism | medium (レビュー注意) | generated | 境界線の提示として使われる場合もある。 |
| review | 気持ち悪い | insult | medium (レビュー注意) | generated | 体調説明の場合もある。 |
| review | キモい | colloquial-insult | high | generated | 口語的な侮辱。 |
| review | 嘘つき | accusation | high | generated | 相手を責める表現。 |
| review | 役立たず | insult | high | generated | 直接的な侮辱。 |
| review | 反感 | lexical-seed | low (レビュー注意) | wordnet | Japanese WordNet 07547805-n。単独発話としては意図が不明。 |
| review | 敵意 | lexical-seed | low (レビュー注意) | wordnet | Japanese WordNet 07547805-n。単独発話としては意図が不明。 |

## command

行動や感情を一方的に指示する表現

| status | text | subtype | confidence | sourceType | notes |
| --- | --- | --- | --- | --- | --- |
| adopted | 落ち着いて | calm-down | medium (レビュー注意) | generated | 現行ルール。言い方によっては支援的。 |
| adopted | 落ち着け | forceful-calm-down | high | generated | 現行ルール。 |
| adopted | 黙って | silencing | high | generated | 現行ルール。 |
| review | 黙れ | forceful-silencing | high | generated | hostileとの境界も要確認。 |
| review | 話せ | forceful-demand | high | generated | 強い発話要求。 |
| review | 言え | forceful-demand | high | generated | 強い発話要求。 |
| review | 答えろ | forceful-answer-demand | high | generated | 強い回答要求。 |
| review | 説明しろ | forceful-explanation-demand | high | generated | 強い説明要求。 |
| review | 早くして | hurry | high | generated | 相手を急かす。 |
| review | 急げ | forceful-hurry | high | generated | 強い命令。 |
| review | 泣くな | emotion-suppression | high | generated | 感情を制止する命令。 |
| review | 怒るな | emotion-suppression | high | generated | 感情を制止する命令。 |
| review | 冷静になって | calm-down | medium (レビュー注意) | generated | 言い方によっては支援的。 |
| review | 冷静になれ | forceful-calm-down | high | generated | 強い命令。 |
| review | 深呼吸して | behavior-direction | medium (レビュー注意) | generated | 支援的な提案にもなり得る。 |
| review | 座って | behavior-direction | medium (レビュー注意) | generated | 状況次第で配慮にも命令にもなる。 |
| review | こっちを見て | attention-demand | medium (レビュー注意) | generated | 注意を強制する表現。 |
| review | 聞け | forceful-attention-demand | high | generated | listeningとは主体が逆。 |
| review | 従って | compliance-demand | high | generated | 服従を求める。 |
| review | 話してください | polite-demand | medium (レビュー注意) | generated | listeningとして受け取れる可能性が高い。 |
| review | 命令 | lexical-seed | low (レビュー注意) | wordnet | Japanese WordNet 07168131-n。単独発話としては不自然。 |
| review | 指図 | lexical-seed | low (レビュー注意) | wordnet | Japanese WordNet 07168131-n。発話意図ではなく話題の場合がある。 |
| review | 指示 | lexical-seed | low (レビュー注意) | sudachi | Sudachi 同義語グループ 001241。単独発話としては不自然。 |
| review | 言いつけ | lexical-seed | low (レビュー注意) | wordnet | Japanese WordNet 07168131-n。会話では名詞として現れる。 |

## apology

謝罪、後悔、責任を認める表現

| status | text | subtype | confidence | sourceType | notes |
| --- | --- | --- | --- | --- | --- |
| adopted | ごめん | casual-apology | high | generated | 現行ルール。 |
| adopted | すみません | polite-apology | high | generated | 現行ルール。呼び掛けの場合もあるがゲーム文脈では謝罪寄り。 |
| adopted | すいません | spoken-apology | high | generated | 現行ルール。口語的な表記。 |
| adopted | すまん | rough-apology | high | generated | 現行ルール。 |
| adopted | 申し訳 | formal-apology-stem | high | generated | 現行ルール。複数の丁寧表現を部分一致で吸収する。 |
| review | ごめんなさい | standard-apology | high | generated | 現行の「ごめん」部分一致でも判定される。 |
| review | ごめんね | soft-apology | high | generated | 現行の「ごめん」部分一致でも判定される。 |
| review | 本当にごめん | emphatic-apology | high | generated | 強調を伴う謝罪。 |
| review | ほんとにごめん | colloquial-emphatic-apology | high | generated | くだけた強調表現。 |
| review | すみませんでした | past-polite-apology | high | generated | 丁寧な謝罪。 |
| review | すいませんでした | past-spoken-apology | high | generated | 口語的な丁寧表現。 |
| review | 申し訳ない | formal-apology | high | generated | 現行の「申し訳」部分一致でも判定される。 |
| review | 申し訳ありません | formal-polite-apology | high | generated | 現行の「申し訳」部分一致でも判定される。 |
| review | 申し訳ございません | very-formal-apology | high | generated | 現行の「申し訳」部分一致でも判定される。 |
| review | 悪かった | implicit-apology | medium (レビュー注意) | generated | 評価や引用の場合もあり、主語がないと曖昧。 |
| review | 私が悪かった | responsibility-taking | high | generated | 責任を認める謝罪。 |
| review | 俺が悪かった | casual-responsibility-taking | high | generated | くだけた責任表明。 |
| review | 僕が悪かった | casual-responsibility-taking | high | generated | 日常的な責任表明。 |
| review | 許して | request-for-forgiveness | medium (レビュー注意) | generated | 相手への要求であり、謝罪そのものではない。 |
| review | お詫びします | formal-apology | high | generated | Japanese WordNetの「お詫び」を会話形にした生成候補。 |
| review | 深くお詫びします | formal-emphatic-apology | high | generated | 強い丁寧表現。 |
| review | 詫びる | lexical-seed | medium (レビュー注意) | wordnet | Japanese WordNet 00892923-v。引用や説明の場合もある。 |
| review | 謝罪する | lexical-seed | medium (レビュー注意) | wordnet | Japanese WordNet 00892923-v の「謝罪+する」を表層化。 |
| review | 陳謝する | lexical-seed | medium (レビュー注意) | wordnet | Japanese WordNet 00892923-v の「陳謝+する」を表層化。 |

## listening

話を促し、聞く姿勢を示す表現

| status | text | subtype | confidence | sourceType | notes |
| --- | --- | --- | --- | --- | --- |
| adopted | 聞かせて | invitation-to-share | high | generated | 現行ルール。 |
| adopted | 話して | invitation-to-share | medium (レビュー注意) | generated | 現行ルール。命令として使われる場合もある。 |
| adopted | 教えて | request-for-explanation | medium (レビュー注意) | generated | 現行ルール。質問内容によっては情報要求。 |
| review | 話を聞かせて | invitation-to-share | high | generated | 現行の「聞かせて」部分一致でも判定される。 |
| review | 話を聞くよ | willingness-to-listen | high | generated | 聞く姿勢を明示。 |
| review | 聞いてるよ | active-listening | high | generated | 現在聞いていることを伝える。 |
| review | ちゃんと聞く | commitment-to-listen | high | generated | 聞く姿勢の約束。 |
| review | 最後まで聞く | commitment-to-listen | high | generated | 遮らない姿勢を示す。 |
| review | ゆっくり話して | paced-invitation | medium (レビュー注意) | generated | 支援的だが命令形でもある。 |
| review | よかったら話して | optional-invitation | high | generated | 相手に選択権を残す。 |
| review | 話せる範囲でいい | bounded-invitation | high | generated | 負担を抑えた聞き方。 |
| review | 言いたいことを聞かせて | invitation-to-share | high | generated | 明確な傾聴意図。 |
| review | 君の話を聞きたい | desire-to-listen | high | generated | 呼称「君」の受け取られ方は要確認。 |
| review | あなたの話を聞きたい | desire-to-listen | high | generated | 明確な傾聴意図。 |
| review | 何があったの | open-question | high | generated | 状況を尋ねる自然な質問。 |
| review | どうしたの | open-question | high | generated | 日常的な気遣いを含む質問。 |
| review | どうした | casual-open-question | medium (レビュー注意) | generated | 口調次第で詰問にもなる。 |
| review | 聞かせてもらえる | polite-invitation | high | generated | 相手の許可を求める。 |
| review | 話してもらえる | polite-invitation | high | generated | 相手の許可を求める。 |
| review | 耳を傾ける | lexical-expression | medium (レビュー注意) | generated | 宣言としてはやや説明的。 |
| review | 聞く | lexical-seed | low (レビュー注意) | wordnet | Japanese WordNet 00784342-v。短すぎて誤検出しやすい。 |
| review | 聴く | lexical-seed | low (レビュー注意) | wordnet | Japanese WordNet 00784342-v。音楽を聴く等の意味もある。 |
| review | 尋ねる | lexical-seed | low (レビュー注意) | wordnet | Japanese WordNet 00784342-v。傾聴より質問行為に近い。 |
| review | 説明してくれる | polite-explanation-request | medium (レビュー注意) | generated | 情報要求だが会話を促す。 |

## reassurance

安心、同伴、猶予を伝える表現

| status | text | subtype | confidence | sourceType | notes |
| --- | --- | --- | --- | --- | --- |
| adopted | 大丈夫 | general-reassurance | medium (レビュー注意) | generated | 現行ルール。拒否や自己状態の説明にもなる。 |
| adopted | そばにいる | presence | high | generated | 現行ルール。 |
| adopted | 急がない | remove-pressure | medium (レビュー注意) | generated | 現行ルール。主語が不明な場合がある。 |
| review | 安心して | direct-reassurance | medium (レビュー注意) | generated | 命令的に響く場合がある。 |
| review | 心配しないで | direct-reassurance | medium (レビュー注意) | generated | 感情を抑える命令にもなり得る。 |
| review | ここにいるよ | presence | high | generated | 存在を伝える自然な表現。 |
| review | そばにいるよ | presence | high | generated | 現行の「そばにいる」部分一致でも判定される。 |
| review | 一人じゃない | companionship | high | generated | 孤立感を和らげる。 |
| review | 一人にしない | companionship | high | generated | 離れない意思を示す。 |
| review | 味方だよ | alliance | high | generated | 支持を明示する。 |
| review | あなたの味方だ | alliance | high | generated | 支持を明示する。 |
| review | 無理しなくていい | permission-to-pause | high | generated | 負担を下げる。 |
| review | 急がなくていい | remove-pressure | high | generated | 時間的圧力を下げる。 |
| review | ゆっくりでいい | remove-pressure | high | generated | 相手のペースを認める。 |
| review | 今すぐ決めなくていい | remove-decision-pressure | high | generated | 選択の猶予を与える。 |
| review | 話さなくてもいい | permission-not-to-speak | high | generated | 会話ゲーム上の扱いは要設計。 |
| review | 待ってるよ | patience | high | generated | 急かさない姿勢。 |
| review | 逃げないよ | commitment-to-stay | high | generated | 関係を維持する意思。 |
| review | 責めないよ | nonjudgment | high | generated | 否定形の扱いをテストする必要がある。 |
| review | 信じてる | trust-expression | medium (レビュー注意) | generated | 文脈次第で圧力にもなる。 |
| review | きっと大丈夫 | optimistic-reassurance | medium (レビュー注意) | generated | 根拠のない楽観と受け取られる場合がある。 |
| review | 何とかなる | optimistic-reassurance | medium (レビュー注意) | generated | 状況の軽視と受け取られる場合がある。 |
| review | 安堵 | lexical-seed | low (レビュー注意) | sudachi | Sudachi 同義語グループ 023069。単独発話としては不自然。 |
| review | 人心地 | lexical-seed | low (レビュー注意) | wordnet | Japanese WordNet 07493280-n。現代会話の入力候補としては弱い。 |

## Known Matching Limitations

- 現在は部分一致なので、review候補でもadopted語を含む表現は既存ルールに一致する。例: 「ごめんなさい」は「ごめん」に一致する。
- 否定表現を構文解析していない。例: 「大丈夫じゃない」は現在も「大丈夫」に一致する。
- 一文に複数intentがある場合、辞書のintent順で最初に一致したものを採用する。
- これらは辞書候補の人手レビュー後、判定アルゴリズム側の別タスクとして扱う。
