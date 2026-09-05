# Intent Dictionary Review

この文書は辞書JSONから生成する採否記録である。2026-09-05、ユーザーからの明示的な委任に基づきassistantが124件をレビューした。候補の収集やconfidenceだけを理由に自動採用しない。

## Review Status

- 総候補数: `144`
- 現在ゲームで有効: `88`
- 未レビュー: `0`
- 確認済み・保留: `43`
- 直接の発話トリガーから除外: `13`
- confidence: high `86` / medium `44` / low `14`
- `adopted`: 現在のゲーム判定で使う。
- `review`: 未レビュー。ゲーム判定では使わない。
- `deferred`: 確認済みだが、仕様または照合条件の検討待ち。ゲーム判定へ追加しない。
- `excluded`: 直接の発話トリガーには不適切。資料として保持し、ゲーム判定へ追加しない。
- 保留・未レビュー表現を含む入力は聞き返す。同じ位置を覆う、より長い採用表現がある場合は採用表現を優先。除外候補自体は判定に使わない。各行に実際の「現在の判定」を記載する。
- `medium` / `low`: 文脈依存、短すぎる、複数intentにまたがる等の理由で特に注意して確認する。

## Source And License Notes

- 出典内訳 generated: 127件
- 出典内訳 wordnet: 14件
- 出典内訳 sudachi: 3件
- 出典内訳 aozora: 0件

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

| intent | 役割 | 候補数 | adopted | review | deferred | excluded |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| rejection | 会話、関係、要求を拒む表現 | 24 | 10 | 0 | 12 | 2 |
| hostile | 侮辱、非難、敵意を示す表現 | 24 | 10 | 0 | 12 | 2 |
| command | 行動や感情を一方的に指示する表現 | 23 | 11 | 0 | 8 | 4 |
| apology | 謝罪、後悔、責任を認める表現 | 24 | 19 | 0 | 5 | 0 |
| listening | 話を促し、聞く姿勢を示す表現 | 25 | 21 | 0 | 1 | 3 |
| reassurance | 安心、同伴、猶予を伝える表現 | 24 | 17 | 0 | 5 | 2 |

## Future Intent Candidates

- `empathy`: 「怖かったね」「つらかったね」のように感情を受け止める。`reassurance` と分ける価値が高い。
- `accountability`: 「私が悪かった」「言い訳しない」のように責任を引き受ける。`apology` のsubtypeから独立できる。
- `offering_space`: 「今は話さなくていい」「待っている」のように距離や猶予を差し出す。`reassurance` と `rejection` の誤判定を減らせる。

今回は既存挙動を維持するため、上記3つをゲーム用intentには追加していない。

## rejection

会話、関係、要求を拒む表現

| status | text | subtype | confidence | sourceType | 現在の判定 | notes / 採否理由 |
| --- | --- | --- | --- | --- | --- | --- |
| adopted | 知らない | direct-denial | high | generated | rejection | 現行ルール。 2026-09-05: 既存20件として維持。部分一致・文脈依存の課題は次タスクで扱う。 |
| adopted | 関係ない | disengagement | medium (レビュー注意) | generated | rejection | 現行ルール。主語や文脈で意味が変わり得る。 2026-09-05: 既存20件として維持。部分一致・文脈依存の課題は次タスクで扱う。 |
| adopted | どうでもいい | dismissal | high | generated | rejection | 現行ルール。 2026-09-05: 既存20件として維持。部分一致・文脈依存の課題は次タスクで扱う。 |
| deferred | 知りません | polite-denial | high | generated | unknown | 丁寧語の拒否・否認。 2026-09-05: 無知・対象への関心・能力の説明と、相手への拒絶を区別できないため保留。 |
| adopted | 知ったことじゃない | dismissal | high | generated | rejection | 強い突き放し。 2026-09-05: 会話を突き放す発話として既存rejectionに採用。否定・引用の解析は別タスク。 |
| adopted | 知ったこっちゃない | colloquial-dismissal | high | generated | rejection | くだけた強い突き放し。 2026-09-05: 会話を突き放す発話として既存rejectionに採用。否定・引用の解析は別タスク。 |
| adopted | 私には関係ありません | polite-disengagement | high | generated | rejection | 主語を含むため単独の「関係ない」より明確。 2026-09-05: 会話を突き放す発話として既存rejectionに採用。否定・引用の解析は別タスク。 |
| adopted | 僕には関係ない | disengagement | high | generated | rejection | 日常的な言い回し。 2026-09-05: 会話を突き放す発話として既存rejectionに採用。否定・引用の解析は別タスク。 |
| adopted | 俺には関係ない | colloquial-disengagement | high | generated | rejection | くだけた言い回し。 2026-09-05: 会話を突き放す発話として既存rejectionに採用。否定・引用の解析は別タスク。 |
| deferred | 興味ない | disinterest | medium (レビュー注意) | generated | unknown | 対象が会話以外の場合もある。 2026-09-05: 無知・対象への関心・能力の説明と、相手への拒絶を区別できないため保留。 |
| deferred | 興味ありません | polite-disinterest | medium (レビュー注意) | generated | unknown | 対象が会話以外の場合もある。 2026-09-05: 無知・対象への関心・能力の説明と、相手への拒絶を区別できないため保留。 |
| deferred | 聞きたくない | refusal-to-listen | high | generated | unknown | 会話継続の明確な拒否。 2026-09-05: 会話を断る意思や距離の希望を緊張度+2にするか、ゲーム設計として相談する。 |
| deferred | 話したくない | refusal-to-speak | high | generated | unknown | 会話継続の明確な拒否。 2026-09-05: 会話を断る意思や距離の希望を緊張度+2にするか、ゲーム設計として相談する。 |
| deferred | 放っておいて | request-for-distance | medium (レビュー注意) | generated | unknown | 境界線の提示として尊重すべき場合もある。 2026-09-05: 会話を断る意思や距離の希望を緊張度+2にするか、ゲーム設計として相談する。 |
| deferred | ほっといて | colloquial-distance | medium (レビュー注意) | generated | unknown | 「放っておいて」の口語形。 2026-09-05: 会話を断る意思や距離の希望を緊張度+2にするか、ゲーム設計として相談する。 |
| adopted | 勝手にして | resignation | high | generated | rejection | 会話から降りるニュアンス。 2026-09-05: 会話を突き放す発話として既存rejectionに採用。否定・引用の解析は別タスク。 |
| deferred | もういい | conversation-close | medium (レビュー注意) | generated | unknown | 了承や安心の意味にもなり得る。 2026-09-05: 肯定・了承と拒絶の両方に使うため文脈なしでは採用しない。 |
| deferred | 結構です | polite-refusal | medium (レビュー注意) | generated | unknown | 肯定的な評価の意味にもなり得る。 2026-09-05: 肯定・了承と拒絶の両方に使うため文脈なしでは採用しない。 |
| adopted | お断りします | explicit-refusal | high | generated | rejection | 丁寧だが明確な拒否。 2026-09-05: 会話を突き放す発話として既存rejectionに採用。否定・引用の解析は別タスク。 |
| deferred | 無理です | inability-or-refusal | medium (レビュー注意) | generated | unknown | 能力不足の説明の場合もある。 2026-09-05: 無知・対象への関心・能力の説明と、相手への拒絶を区別できないため保留。 |
| excluded | 拒否 | lexical-seed | low (レビュー注意) | wordnet | unknown | Japanese WordNet 07204401-n。単独発話としては不自然。 2026-09-05: 概念名を述べただけでは拒絶の発話と判定できない。候補は資料として保持。 |
| excluded | 拒絶 | lexical-seed | low (レビュー注意) | wordnet | unknown | Japanese WordNet 07204401-n。単独発話としては不自然。 2026-09-05: 概念名を述べただけでは拒絶の発話と判定できない。候補は資料として保持。 |
| deferred | 断る | lexical-seed | medium (レビュー注意) | sudachi | unknown | Sudachi 同義語グループ 022497。活用形の扱いは別途検討。 2026-09-05: 「断る理由」「断る必要はない」等の説明・否定にも一致する。完全一致などの条件を検討後に再評価。 |
| deferred | 応じない | noncompliance | medium (レビュー注意) | generated | unknown | 対象が会話とは限らない。 2026-09-05: 無知・対象への関心・能力の説明と、相手への拒絶を区別できないため保留。 |

## hostile

侮辱、非難、敵意を示す表現

| status | text | subtype | confidence | sourceType | 現在の判定 | notes / 採否理由 |
| --- | --- | --- | --- | --- | --- | --- |
| adopted | お前 | contemptuous-address | medium (レビュー注意) | generated | hostile | 現行ルール。親しい関係では敵意がない場合もある。 2026-09-05: 既存20件として維持。部分一致・文脈依存の課題は次タスクで扱う。 |
| adopted | うるさい | insult | high | generated | hostile | 現行ルール。 2026-09-05: 既存20件として維持。部分一致・文脈依存の課題は次タスクで扱う。 |
| adopted | 面倒 | dismissive-insult | medium (レビュー注意) | generated | hostile | 現行ルール。状況説明の可能性もある。 2026-09-05: 既存20件として維持。部分一致・文脈依存の課題は次タスクで扱う。 |
| deferred | おまえ | contemptuous-address | medium (レビュー注意) | generated | unknown | ひらがな表記。親しい関係では敵意がない場合もある。 2026-09-05: 呼称だけでは敵意を確定できない。既存「お前」の扱いと合わせて相談する。 |
| adopted | てめえ | abusive-address | high | generated | hostile | 強い敵意を伴う呼称。 2026-09-05: 直接的な罵倒・追い払い・非難として既存hostileに採用。引用や自己評価の識別は別タスク。 |
| deferred | あんた | rough-address | low (レビュー注意) | generated | unknown | 地域・関係性によっては中立。 2026-09-05: 呼称だけでは敵意を確定できない。既存「お前」の扱いと合わせて相談する。 |
| deferred | 馬鹿 | insult | high | generated | unknown | 直接的な侮辱。 2026-09-05: 「馬鹿正直」「バカンス」「来たばかり」などにも部分一致するため、短語の照合条件を検討後に再評価。 |
| deferred | バカ | insult-variant | high | generated | unknown | カタカナ表記。 2026-09-05: 「馬鹿正直」「バカンス」「来たばかり」などにも部分一致するため、短語の照合条件を検討後に再評価。 |
| deferred | ばか | insult-variant | high | generated | unknown | ひらがな表記。 2026-09-05: 「馬鹿正直」「バカンス」「来たばかり」などにも部分一致するため、短語の照合条件を検討後に再評価。 |
| deferred | アホ | insult | medium (レビュー注意) | generated | unknown | 地域・関係性で軽い冗談の場合もある。 2026-09-05: 対象・関係性によって敵意の有無が変わるため保留。既存「面倒」に一致する表現もある。 |
| deferred | 最低 | condemnation | medium (レビュー注意) | generated | unknown | 人ではなく状況への評価の場合もある。 2026-09-05: 対象・関係性によって敵意の有無が変わるため保留。既存「面倒」に一致する表現もある。 |
| adopted | うざい | colloquial-insult | high | generated | hostile | 口語的な拒絶・侮辱。 2026-09-05: 直接的な罵倒・追い払い・非難として既存hostileに採用。引用や自己評価の識別は別タスク。 |
| adopted | うぜえ | rough-insult | high | generated | hostile | 荒い口語表現。 2026-09-05: 直接的な罵倒・追い払い・非難として既存hostileに採用。引用や自己評価の識別は別タスク。 |
| adopted | 消えろ | expulsion | high | generated | hostile | 強い敵意を伴う命令。 2026-09-05: 直接的な罵倒・追い払い・非難として既存hostileに採用。引用や自己評価の識別は別タスク。 |
| deferred | 邪魔 | dismissive-insult | medium (レビュー注意) | generated | unknown | 対象が物や状況の場合もある。 2026-09-05: 対象・関係性によって敵意の有無が変わるため保留。既存「面倒」に一致する表現もある。 |
| deferred | 面倒くさい | dismissive-insult | medium (レビュー注意) | generated | unknown | 人ではなく状況への評価の場合もある。 2026-09-05: 対象・関係性によって敵意の有無が変わるため保留。既存「面倒」に一致する表現もある。 |
| deferred | めんどくさい | dismissive-insult-variant | medium (レビュー注意) | generated | unknown | ひらがな表記。 2026-09-05: 対象・関係性によって敵意の有無が変わるため保留。既存「面倒」に一致する表現もある。 |
| deferred | しつこい | criticism | medium (レビュー注意) | generated | unknown | 境界線の提示として使われる場合もある。 2026-09-05: 対象・関係性によって敵意の有無が変わるため保留。既存「面倒」に一致する表現もある。 |
| deferred | 気持ち悪い | insult | medium (レビュー注意) | generated | unknown | 体調説明の場合もある。 2026-09-05: 対象・関係性によって敵意の有無が変わるため保留。既存「面倒」に一致する表現もある。 |
| adopted | キモい | colloquial-insult | high | generated | hostile | 口語的な侮辱。 2026-09-05: 直接的な罵倒・追い払い・非難として既存hostileに採用。引用や自己評価の識別は別タスク。 |
| adopted | 嘘つき | accusation | high | generated | hostile | 相手を責める表現。 2026-09-05: 直接的な罵倒・追い払い・非難として既存hostileに採用。引用や自己評価の識別は別タスク。 |
| adopted | 役立たず | insult | high | generated | hostile | 直接的な侮辱。 2026-09-05: 直接的な罵倒・追い払い・非難として既存hostileに採用。引用や自己評価の識別は別タスク。 |
| excluded | 反感 | lexical-seed | low (レビュー注意) | wordnet | unknown | Japanese WordNet 07547805-n。単独発話としては意図が不明。 2026-09-05: 感情の名称であり、相手に敵意を示した発話とは限らない。候補は資料として保持。 |
| excluded | 敵意 | lexical-seed | low (レビュー注意) | wordnet | unknown | Japanese WordNet 07547805-n。単独発話としては意図が不明。 2026-09-05: 感情の名称であり、相手に敵意を示した発話とは限らない。候補は資料として保持。 |

## command

行動や感情を一方的に指示する表現

| status | text | subtype | confidence | sourceType | 現在の判定 | notes / 採否理由 |
| --- | --- | --- | --- | --- | --- | --- |
| adopted | 落ち着いて | calm-down | medium (レビュー注意) | generated | command | 現行ルール。言い方によっては支援的。 2026-09-05: 既存20件として維持。部分一致・文脈依存の課題は次タスクで扱う。 |
| adopted | 落ち着け | forceful-calm-down | high | generated | command | 現行ルール。 2026-09-05: 既存20件として維持。部分一致・文脈依存の課題は次タスクで扱う。 |
| adopted | 黙って | silencing | high | generated | command | 現行ルール。 2026-09-05: 既存20件として維持。部分一致・文脈依存の課題は次タスクで扱う。 |
| adopted | 黙れ | forceful-silencing | high | generated | command | hostileとの境界も要確認。 2026-09-05: 行動・感情を指示する発話として既存commandに採用。「黙れ」は既存「黙って」に合わせる。 |
| deferred | 話せ | forceful-demand | high | generated | unknown | 強い発話要求。 2026-09-05: 可能形・条件形にも一致する。「話せる範囲でいい」「言える範囲でいい」「聞けば分かる」の誤検出を避ける。 |
| deferred | 言え | forceful-demand | high | generated | unknown | 強い発話要求。 2026-09-05: 可能形・条件形にも一致する。「話せる範囲でいい」「言える範囲でいい」「聞けば分かる」の誤検出を避ける。 |
| adopted | 答えろ | forceful-answer-demand | high | generated | command | 強い回答要求。 2026-09-05: 行動・感情を指示する発話として既存commandに採用。「黙れ」は既存「黙って」に合わせる。 |
| adopted | 説明しろ | forceful-explanation-demand | high | generated | command | 強い説明要求。 2026-09-05: 行動・感情を指示する発話として既存commandに採用。「黙れ」は既存「黙って」に合わせる。 |
| adopted | 早くして | hurry | high | generated | command | 相手を急かす。 2026-09-05: 行動・感情を指示する発話として既存commandに採用。「黙れ」は既存「黙って」に合わせる。 |
| adopted | 急げ | forceful-hurry | high | generated | command | 強い命令。 2026-09-05: 行動・感情を指示する発話として既存commandに採用。「黙れ」は既存「黙って」に合わせる。 |
| adopted | 泣くな | emotion-suppression | high | generated | command | 感情を制止する命令。 2026-09-05: 行動・感情を指示する発話として既存commandに採用。「黙れ」は既存「黙って」に合わせる。 |
| adopted | 怒るな | emotion-suppression | high | generated | command | 感情を制止する命令。 2026-09-05: 行動・感情を指示する発話として既存commandに採用。「黙れ」は既存「黙って」に合わせる。 |
| deferred | 冷静になって | calm-down | medium (レビュー注意) | generated | unknown | 言い方によっては支援的。 2026-09-05: 配慮・提案と一方的な命令を区別する設計判断が必要。 |
| adopted | 冷静になれ | forceful-calm-down | high | generated | command | 強い命令。 2026-09-05: 行動・感情を指示する発話として既存commandに採用。「黙れ」は既存「黙って」に合わせる。 |
| deferred | 深呼吸して | behavior-direction | medium (レビュー注意) | generated | unknown | 支援的な提案にもなり得る。 2026-09-05: 配慮・提案と一方的な命令を区別する設計判断が必要。 |
| deferred | 座って | behavior-direction | medium (レビュー注意) | generated | unknown | 状況次第で配慮にも命令にもなる。 2026-09-05: 配慮・提案と一方的な命令を区別する設計判断が必要。 |
| deferred | こっちを見て | attention-demand | medium (レビュー注意) | generated | unknown | 注意を強制する表現。 2026-09-05: 配慮・提案と一方的な命令を区別する設計判断が必要。 |
| deferred | 聞け | forceful-attention-demand | high | generated | unknown | listeningとは主体が逆。 2026-09-05: 可能形・条件形にも一致する。「話せる範囲でいい」「言える範囲でいい」「聞けば分かる」の誤検出を避ける。 |
| deferred | 従って | compliance-demand | high | generated | unknown | 服従を求める。 2026-09-05: 「順番に従って進む」等の説明にも一致するため、命令としての条件を検討する。 |
| excluded | 命令 | lexical-seed | low (レビュー注意) | wordnet | unknown | Japanese WordNet 07168131-n。単独発話としては不自然。 2026-09-05: 行為・概念の名称であり、相手への命令を実行した発話とは限らない。候補は資料として保持。 |
| excluded | 指図 | lexical-seed | low (レビュー注意) | wordnet | unknown | Japanese WordNet 07168131-n。発話意図ではなく話題の場合がある。 2026-09-05: 行為・概念の名称であり、相手への命令を実行した発話とは限らない。候補は資料として保持。 |
| excluded | 指示 | lexical-seed | low (レビュー注意) | sudachi | unknown | Sudachi 同義語グループ 001241。単独発話としては不自然。 2026-09-05: 行為・概念の名称であり、相手への命令を実行した発話とは限らない。候補は資料として保持。 |
| excluded | 言いつけ | lexical-seed | low (レビュー注意) | wordnet | unknown | Japanese WordNet 07168131-n。会話では名詞として現れる。 2026-09-05: 行為・概念の名称であり、相手への命令を実行した発話とは限らない。候補は資料として保持。 |

## apology

謝罪、後悔、責任を認める表現

| status | text | subtype | confidence | sourceType | 現在の判定 | notes / 採否理由 |
| --- | --- | --- | --- | --- | --- | --- |
| adopted | ごめん | casual-apology | high | generated | apology | 現行ルール。 2026-09-05: 既存20件として維持。部分一致・文脈依存の課題は次タスクで扱う。 |
| adopted | すみません | polite-apology | high | generated | apology | 現行ルール。呼び掛けの場合もあるがゲーム文脈では謝罪寄り。 2026-09-05: 既存20件として維持。部分一致・文脈依存の課題は次タスクで扱う。 |
| adopted | すいません | spoken-apology | high | generated | apology | 現行ルール。口語的な表記。 2026-09-05: 既存20件として維持。部分一致・文脈依存の課題は次タスクで扱う。 |
| adopted | すまん | rough-apology | high | generated | apology | 現行ルール。 2026-09-05: 既存20件として維持。部分一致・文脈依存の課題は次タスクで扱う。 |
| adopted | 申し訳 | formal-apology-stem | high | generated | apology | 現行ルール。複数の丁寧表現を部分一致で吸収する。 2026-09-05: 既存20件として維持。部分一致・文脈依存の課題は次タスクで扱う。 |
| adopted | ごめんなさい | standard-apology | high | generated | apology | 現行の「ごめん」部分一致でも判定される。 2026-09-05: 既存の謝罪表現を含む自然な言い換え。既存判定に一致することも確認する。 |
| adopted | ごめんね | soft-apology | high | generated | apology | 現行の「ごめん」部分一致でも判定される。 2026-09-05: 既存の謝罪表現を含む自然な言い換え。既存判定に一致することも確認する。 |
| adopted | 本当にごめん | emphatic-apology | high | generated | apology | 強調を伴う謝罪。 2026-09-05: 既存の謝罪表現を含む自然な言い換え。既存判定に一致することも確認する。 |
| adopted | ほんとにごめん | colloquial-emphatic-apology | high | generated | apology | くだけた強調表現。 2026-09-05: 既存の謝罪表現を含む自然な言い換え。既存判定に一致することも確認する。 |
| adopted | すみませんでした | past-polite-apology | high | generated | apology | 丁寧な謝罪。 2026-09-05: 既存の謝罪表現を含む自然な言い換え。既存判定に一致することも確認する。 |
| adopted | すいませんでした | past-spoken-apology | high | generated | apology | 口語的な丁寧表現。 2026-09-05: 既存の謝罪表現を含む自然な言い換え。既存判定に一致することも確認する。 |
| adopted | 申し訳ない | formal-apology | high | generated | apology | 現行の「申し訳」部分一致でも判定される。 2026-09-05: 既存の謝罪表現を含む自然な言い換え。既存判定に一致することも確認する。 |
| adopted | 申し訳ありません | formal-polite-apology | high | generated | apology | 現行の「申し訳」部分一致でも判定される。 2026-09-05: 既存の謝罪表現を含む自然な言い換え。既存判定に一致することも確認する。 |
| adopted | 申し訳ございません | very-formal-apology | high | generated | apology | 現行の「申し訳」部分一致でも判定される。 2026-09-05: 既存の謝罪表現を含む自然な言い換え。既存判定に一致することも確認する。 |
| deferred | 悪かった | implicit-apology | medium (レビュー注意) | generated | unknown | 評価や引用の場合もあり、主語がないと曖昧。 2026-09-05: 「天気が悪かった」等の評価も含むため、主語のある表現のみ今回採用する。 |
| adopted | 私が悪かった | responsibility-taking | high | generated | apology | 責任を認める謝罪。 2026-09-05: 自分が責任を認める発話として既存apologyに採用。accountability独立は別の設計判断。 |
| adopted | 俺が悪かった | casual-responsibility-taking | high | generated | apology | くだけた責任表明。 2026-09-05: 自分が責任を認める発話として既存apologyに採用。accountability独立は別の設計判断。 |
| adopted | 僕が悪かった | casual-responsibility-taking | high | generated | apology | 日常的な責任表明。 2026-09-05: 自分が責任を認める発話として既存apologyに採用。accountability独立は別の設計判断。 |
| deferred | 許して | request-for-forgiveness | medium (レビュー注意) | generated | unknown | 相手への要求であり、謝罪そのものではない。 2026-09-05: 許しを求める要求と謝罪を同一視するか、ゲーム設計として相談する。 |
| adopted | お詫びします | formal-apology | high | generated | apology | Japanese WordNetの「お詫び」を会話形にした生成候補。 2026-09-05: 相手へ詫びる意思が明示された発話として採用。 |
| adopted | 深くお詫びします | formal-emphatic-apology | high | generated | apology | 強い丁寧表現。 2026-09-05: 相手へ詫びる意思が明示された発話として採用。 |
| deferred | 詫びる | lexical-seed | medium (レビュー注意) | wordnet | unknown | Japanese WordNet 00892923-v。引用や説明の場合もある。 2026-09-05: 説明・予定・引用にも使われる辞書見出し。発話の照合条件を検討してから採用する。 |
| deferred | 謝罪する | lexical-seed | medium (レビュー注意) | wordnet | unknown | Japanese WordNet 00892923-v の「謝罪+する」を表層化。 2026-09-05: 説明・予定・引用にも使われる辞書見出し。発話の照合条件を検討してから採用する。 |
| deferred | 陳謝する | lexical-seed | medium (レビュー注意) | wordnet | unknown | Japanese WordNet 00892923-v の「陳謝+する」を表層化。 2026-09-05: 説明・予定・引用にも使われる辞書見出し。発話の照合条件を検討してから採用する。 |

## listening

話を促し、聞く姿勢を示す表現

| status | text | subtype | confidence | sourceType | 現在の判定 | notes / 採否理由 |
| --- | --- | --- | --- | --- | --- | --- |
| adopted | 話してください | polite-demand | medium (レビュー注意) | generated | listening | listeningとして受け取れる可能性が高い。 2026-09-05: 候補のcommand分類をlisteningへ訂正。既存「話して」に一致し従来からlisteningなので、実際の判定は維持する。 |
| adopted | 聞かせて | invitation-to-share | high | generated | listening | 現行ルール。 2026-09-05: 既存20件として維持。部分一致・文脈依存の課題は次タスクで扱う。 |
| adopted | 話して | invitation-to-share | medium (レビュー注意) | generated | listening | 現行ルール。命令として使われる場合もある。 2026-09-05: 既存20件として維持。部分一致・文脈依存の課題は次タスクで扱う。 |
| adopted | 教えて | request-for-explanation | medium (レビュー注意) | generated | listening | 現行ルール。質問内容によっては情報要求。 2026-09-05: 既存20件として維持。部分一致・文脈依存の課題は次タスクで扱う。 |
| adopted | 話を聞かせて | invitation-to-share | high | generated | listening | 現行の「聞かせて」部分一致でも判定される。 2026-09-05: 聞く意思、任意の話題提供、状況への問いかけとして既存listeningに採用。 |
| adopted | 話を聞くよ | willingness-to-listen | high | generated | listening | 聞く姿勢を明示。 2026-09-05: 聞く意思、任意の話題提供、状況への問いかけとして既存listeningに採用。 |
| adopted | 聞いてるよ | active-listening | high | generated | listening | 現在聞いていることを伝える。 2026-09-05: 聞く意思、任意の話題提供、状況への問いかけとして既存listeningに採用。 |
| adopted | ちゃんと聞く | commitment-to-listen | high | generated | listening | 聞く姿勢の約束。 2026-09-05: 聞く意思、任意の話題提供、状況への問いかけとして既存listeningに採用。 |
| adopted | 最後まで聞く | commitment-to-listen | high | generated | listening | 遮らない姿勢を示す。 2026-09-05: 聞く意思、任意の話題提供、状況への問いかけとして既存listeningに採用。 |
| adopted | ゆっくり話して | paced-invitation | medium (レビュー注意) | generated | listening | 支援的だが命令形でもある。 2026-09-05: 聞く意思、任意の話題提供、状況への問いかけとして既存listeningに採用。 |
| adopted | よかったら話して | optional-invitation | high | generated | listening | 相手に選択権を残す。 2026-09-05: 聞く意思、任意の話題提供、状況への問いかけとして既存listeningに採用。 |
| adopted | 話せる範囲でいい | bounded-invitation | high | generated | listening | 負担を抑えた聞き方。 2026-09-05: 聞く意思、任意の話題提供、状況への問いかけとして既存listeningに採用。 |
| adopted | 言いたいことを聞かせて | invitation-to-share | high | generated | listening | 明確な傾聴意図。 2026-09-05: 聞く意思、任意の話題提供、状況への問いかけとして既存listeningに採用。 |
| adopted | 君の話を聞きたい | desire-to-listen | high | generated | listening | 呼称「君」の受け取られ方は要確認。 2026-09-05: 聞く意思、任意の話題提供、状況への問いかけとして既存listeningに採用。 |
| adopted | あなたの話を聞きたい | desire-to-listen | high | generated | listening | 明確な傾聴意図。 2026-09-05: 聞く意思、任意の話題提供、状況への問いかけとして既存listeningに採用。 |
| adopted | 何があったの | open-question | high | generated | listening | 状況を尋ねる自然な質問。 2026-09-05: 聞く意思、任意の話題提供、状況への問いかけとして既存listeningに採用。 |
| adopted | どうしたの | open-question | high | generated | listening | 日常的な気遣いを含む質問。 2026-09-05: 聞く意思、任意の話題提供、状況への問いかけとして既存listeningに採用。 |
| deferred | どうした | casual-open-question | medium (レビュー注意) | generated | unknown | 口調次第で詰問にもなる。 2026-09-05: 「どうしたって」等にも部分一致するため保留。今回は「どうしたの」を採用する。 |
| adopted | 聞かせてもらえる | polite-invitation | high | generated | listening | 相手の許可を求める。 2026-09-05: 聞く意思、任意の話題提供、状況への問いかけとして既存listeningに採用。 |
| adopted | 話してもらえる | polite-invitation | high | generated | listening | 相手の許可を求める。 2026-09-05: 聞く意思、任意の話題提供、状況への問いかけとして既存listeningに採用。 |
| adopted | 耳を傾ける | lexical-expression | medium (レビュー注意) | generated | listening | 宣言としてはやや説明的。 2026-09-05: 聞く意思、任意の話題提供、状況への問いかけとして既存listeningに採用。 |
| excluded | 聞く | lexical-seed | low (レビュー注意) | wordnet | unknown | Japanese WordNet 00784342-v。短すぎて誤検出しやすい。 2026-09-05: 聞く対象・主体・目的を特定できない短い辞書見出し。具体的な発話候補に展開してから扱う。 |
| excluded | 聴く | lexical-seed | low (レビュー注意) | wordnet | unknown | Japanese WordNet 00784342-v。音楽を聴く等の意味もある。 2026-09-05: 聞く対象・主体・目的を特定できない短い辞書見出し。具体的な発話候補に展開してから扱う。 |
| excluded | 尋ねる | lexical-seed | low (レビュー注意) | wordnet | unknown | Japanese WordNet 00784342-v。傾聴より質問行為に近い。 2026-09-05: 聞く対象・主体・目的を特定できない短い辞書見出し。具体的な発話候補に展開してから扱う。 |
| adopted | 説明してくれる | polite-explanation-request | medium (レビュー注意) | generated | listening | 情報要求だが会話を促す。 2026-09-05: 聞く意思、任意の話題提供、状況への問いかけとして既存listeningに採用。 |

## reassurance

安心、同伴、猶予を伝える表現

| status | text | subtype | confidence | sourceType | 現在の判定 | notes / 採否理由 |
| --- | --- | --- | --- | --- | --- | --- |
| adopted | 大丈夫 | general-reassurance | medium (レビュー注意) | generated | reassurance | 現行ルール。拒否や自己状態の説明にもなる。 2026-09-05: 既存20件として維持。部分一致・文脈依存の課題は次タスクで扱う。 |
| adopted | そばにいる | presence | high | generated | reassurance | 現行ルール。 2026-09-05: 既存20件として維持。部分一致・文脈依存の課題は次タスクで扱う。 |
| adopted | 急がない | remove-pressure | medium (レビュー注意) | generated | reassurance | 現行ルール。主語が不明な場合がある。 2026-09-05: 既存20件として維持。部分一致・文脈依存の課題は次タスクで扱う。 |
| deferred | 安心して | direct-reassurance | medium (レビュー注意) | generated | unknown | 命令的に響く場合がある。 2026-09-05: 安心の提供と感情の抑制・根拠のない楽観の区別を相談する。既存「大丈夫」に一致する表現もある。 |
| deferred | 心配しないで | direct-reassurance | medium (レビュー注意) | generated | unknown | 感情を抑える命令にもなり得る。 2026-09-05: 安心の提供と感情の抑制・根拠のない楽観の区別を相談する。既存「大丈夫」に一致する表現もある。 |
| adopted | ここにいるよ | presence | high | generated | reassurance | 存在を伝える自然な表現。 2026-09-05: 同伴・支持・猶予・負担軽減が明示された発話として既存reassuranceに採用。offering_space独立は別タスク。 |
| adopted | そばにいるよ | presence | high | generated | reassurance | 現行の「そばにいる」部分一致でも判定される。 2026-09-05: 同伴・支持・猶予・負担軽減が明示された発話として既存reassuranceに採用。offering_space独立は別タスク。 |
| adopted | 一人じゃない | companionship | high | generated | reassurance | 孤立感を和らげる。 2026-09-05: 同伴・支持・猶予・負担軽減が明示された発話として既存reassuranceに採用。offering_space独立は別タスク。 |
| adopted | 一人にしない | companionship | high | generated | reassurance | 離れない意思を示す。 2026-09-05: 同伴・支持・猶予・負担軽減が明示された発話として既存reassuranceに採用。offering_space独立は別タスク。 |
| adopted | 味方だよ | alliance | high | generated | reassurance | 支持を明示する。 2026-09-05: 同伴・支持・猶予・負担軽減が明示された発話として既存reassuranceに採用。offering_space独立は別タスク。 |
| adopted | あなたの味方だ | alliance | high | generated | reassurance | 支持を明示する。 2026-09-05: 同伴・支持・猶予・負担軽減が明示された発話として既存reassuranceに採用。offering_space独立は別タスク。 |
| adopted | 無理しなくていい | permission-to-pause | high | generated | reassurance | 負担を下げる。 2026-09-05: 同伴・支持・猶予・負担軽減が明示された発話として既存reassuranceに採用。offering_space独立は別タスク。 |
| adopted | 急がなくていい | remove-pressure | high | generated | reassurance | 時間的圧力を下げる。 2026-09-05: 同伴・支持・猶予・負担軽減が明示された発話として既存reassuranceに採用。offering_space独立は別タスク。 |
| adopted | ゆっくりでいい | remove-pressure | high | generated | reassurance | 相手のペースを認める。 2026-09-05: 同伴・支持・猶予・負担軽減が明示された発話として既存reassuranceに採用。offering_space独立は別タスク。 |
| adopted | 今すぐ決めなくていい | remove-decision-pressure | high | generated | reassurance | 選択の猶予を与える。 2026-09-05: 同伴・支持・猶予・負担軽減が明示された発話として既存reassuranceに採用。offering_space独立は別タスク。 |
| adopted | 話さなくてもいい | permission-not-to-speak | high | generated | reassurance | 会話ゲーム上の扱いは要設計。 2026-09-05: 同伴・支持・猶予・負担軽減が明示された発話として既存reassuranceに採用。offering_space独立は別タスク。 |
| adopted | 待ってるよ | patience | high | generated | reassurance | 急かさない姿勢。 2026-09-05: 同伴・支持・猶予・負担軽減が明示された発話として既存reassuranceに採用。offering_space独立は別タスク。 |
| adopted | 逃げないよ | commitment-to-stay | high | generated | reassurance | 関係を維持する意思。 2026-09-05: 同伴・支持・猶予・負担軽減が明示された発話として既存reassuranceに採用。offering_space独立は別タスク。 |
| adopted | 責めないよ | nonjudgment | high | generated | reassurance | 否定形の扱いをテストする必要がある。 2026-09-05: 同伴・支持・猶予・負担軽減が明示された発話として既存reassuranceに採用。offering_space独立は別タスク。 |
| deferred | 信じてる | trust-expression | medium (レビュー注意) | generated | unknown | 文脈次第で圧力にもなる。 2026-09-05: 安心の提供と感情の抑制・根拠のない楽観の区別を相談する。既存「大丈夫」に一致する表現もある。 |
| deferred | きっと大丈夫 | optimistic-reassurance | medium (レビュー注意) | generated | unknown | 根拠のない楽観と受け取られる場合がある。 2026-09-05: 安心の提供と感情の抑制・根拠のない楽観の区別を相談する。既存「大丈夫」に一致する表現もある。 |
| deferred | 何とかなる | optimistic-reassurance | medium (レビュー注意) | generated | unknown | 状況の軽視と受け取られる場合がある。 2026-09-05: 安心の提供と感情の抑制・根拠のない楽観の区別を相談する。既存「大丈夫」に一致する表現もある。 |
| excluded | 安堵 | lexical-seed | low (レビュー注意) | sudachi | unknown | Sudachi 同義語グループ 023069。単独発話としては不自然。 2026-09-05: 状態を表す名詞であり、相手を安心させる発話とは限らない。候補は資料として保持。 |
| excluded | 人心地 | lexical-seed | low (レビュー注意) | wordnet | unknown | Japanese WordNet 07493280-n。現代会話の入力候補としては弱い。 2026-09-05: 状態を表す名詞であり、相手を安心させる発話とは限らない。候補は資料として保持。 |

## Known Matching Limitations

- 採用表現は部分一致で照合するが、長い保留表現を短い採用語で加点・減点しない。「面倒くさい」「きっと大丈夫」は判断保留。
- 「大丈夫じゃない」「ごめんとは思わない」など限定した否定形は判断保留。「一人じゃない」「無理しなくていい」は安心。一般的な構文解析はしない。
- 一文に複数intentが残る場合は、優先順位で断定せず判断保留にする。
- 引用の伝聞形、二重否定、面倒を見たい、お前の話は限定的に保留。対応範囲と未対応例は [仕様](../SPEC.md) を参照。
- 再現例、相談事項、次タスクは [今回のレビュー結果](INTENT_REVIEW_OUTCOME.md) と [TODO](../TODO.md) に記載する。
