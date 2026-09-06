import { mkdir, readFile, writeFile } from 'node:fs/promises'
import { createIntentEvaluator } from '../src/lib/intentMatcher.js'

const dictionaryUrl = new URL('../src/data/intent-dictionary.json', import.meta.url)
const outputUrl = new URL('../../../docs/INTENT_DICTIONARY_REVIEW.md', import.meta.url)
const dictionary = JSON.parse(await readFile(dictionaryUrl, 'utf8'))
const evaluateLine = createIntentEvaluator(dictionary)
const statuses = ['adopted', 'review', 'deferred', 'excluded']
const countStatus = (entries, status) =>
  entries.filter((entry) => entry.status === status).length

const intentDescriptions = {
  apology: '謝罪、後悔、責任を認める表現',
  listening: '話を促し、聞く姿勢を示す表現',
  reassurance: '安心、同伴、猶予を伝える表現',
  command: '行動や感情を一方的に指示する表現',
  rejection: '会話、関係、要求を拒む表現',
  hostile: '侮辱、非難、敵意を示す表現',
}

const confidenceCounts = Object.fromEntries(
  ['high', 'medium', 'low'].map((confidence) => [
    confidence,
    dictionary.expressions.filter((entry) => entry.confidence === confidence)
      .length,
  ]),
)
const adoptedCount = dictionary.expressions.filter(
  ({ status }) => status === 'adopted',
).length

function escapeCell(value) {
  return String(value).replaceAll('|', '\\|').replaceAll('\n', '<br>')
}

const lines = [
  '# Intent Dictionary Review',
  '',
  'この文書は辞書JSONから生成する採否記録である。2026-09-05、ユーザーからの明示的な委任に基づきassistantが124件をレビューした。候補の収集やconfidenceだけを理由に自動採用しない。',
  '',
  '## Review Status',
  '',
  `- 総候補数: \`${dictionary.expressions.length}\``,
  `- 現在ゲームで有効: \`${adoptedCount}\``,
  `- 未レビュー: \`${countStatus(dictionary.expressions, 'review')}\``,
  `- 確認済み・保留: \`${countStatus(dictionary.expressions, 'deferred')}\``,
  `- 直接の発話トリガーから除外: \`${countStatus(dictionary.expressions, 'excluded')}\``,
  `- confidence: high \`${confidenceCounts.high}\` / medium \`${confidenceCounts.medium}\` / low \`${confidenceCounts.low}\``,
  '- `adopted`: 現在のゲーム判定で使う。',
  '- `review`: 未レビュー。ゲーム判定では使わない。',
  '- `deferred`: 確認済みだが、仕様または照合条件の検討待ち。ゲーム判定へ追加しない。',
  '- `excluded`: 直接の発話トリガーには不適切。資料として保持し、ゲーム判定へ追加しない。',
  '- 保留・未レビュー表現は聞き返す。ただし正規化後2文字以下の保留語は空白・句読点で区切った区間全体との一致だけを使う。同じ位置を覆う、より長い採用表現は優先。除外候補自体は判定に使わない。各行に実際の「現在の判定」を記載する。',
  '- 肯定カテゴリだけの混在は傾聴→謝罪→安心の順で代表を選ぶ。肯定と敵意・拒絶等の混在は保留する。',
  '- `medium` / `low`: 文脈依存、短すぎる、複数intentにまたがる等の理由で特に注意して確認する。',
  '',
  '## Source And License Notes',
  '',
  ...['generated', 'wordnet', 'sudachi', 'aozora'].map((sourceType) =>
    `- 出典内訳 ${sourceType}: ${dictionary.expressions.filter((entry) => entry.sourceType === sourceType).length}件`,
  ),
  '',
  '- Japanese WordNet: NICTのライセンスに基づく。利用・複製・変更・配布は許可されるが、著作権表示と免責条項を複製物に残す必要がある。今回の `wordnet` 候補は確認したsynsetの見出しだけで、例文は収録していない。',
  '- Japanese WordNet notice: Copyright 2009, 2010 NICT. 詳細な条件と免責事項は下記の公式LICENSEを参照する。',
  '- SudachiDict Synonym: SudachiDictと同じApache License 2.0。今回の `sudachi` 候補は同義語グループの見出しだけで、辞書本体はリポジトリへ同梱していない。',
  '- SudachiDict notice: Copyright 2017-2023 Works Applications Co., Ltd.',
  '- 青空文庫: 著作権が切れている作品は規準に従って活用できるが、保護期間中の作品は別扱い。今回は作品・作者ごとの確認を省略しないため、本文由来候補を採取していない。',
  '- `generated`: 一般的な日本語知識から作ったレビュー候補。外部辞書や作品からの引用ではない。',
  '',
  '参照:',
  '',
  '- https://github.com/omwn/omw-data/blob/main/wns/jpn/LICENSE',
  '- https://github.com/WorksApplications/SudachiDict/blob/develop/docs/synonyms.md',
  '- https://github.com/WorksApplications/SudachiDict/blob/develop/README.md#licenses',
  '- https://www.aozora.gr.jp/guide/kijyunn.html',
  '',
  '## Intent Summary',
  '',
  '| intent | 役割 | 候補数 | adopted | review | deferred | excluded |',
  '| --- | --- | ---: | ---: | ---: | ---: | ---: |',
]

for (const intent of dictionary.intents) {
  const entries = dictionary.expressions.filter(
    (entry) => entry.intent === intent.intent,
  )
  lines.push(
    `| ${intent.intent} | ${intentDescriptions[intent.intent]} | ${entries.length} | ${statuses.map((status) => countStatus(entries, status)).join(' | ')} |`,
  )
}

lines.push(
  '',
  '## Future Intent Candidates',
  '',
  '- `empathy`: 「怖かったね」「つらかったね」のように感情を受け止める。`reassurance` と分ける価値が高い。',
  '- `accountability`: 「私が悪かった」「言い訳しない」のように責任を引き受ける。`apology` のsubtypeから独立できる。',
  '- `offering_space`: 「今は話さなくていい」「待っている」のように距離や猶予を差し出す。`reassurance` と `rejection` の誤判定を減らせる。',
  '',
  '今回は既存挙動を維持するため、上記3つをゲーム用intentには追加していない。',
)

for (const intent of dictionary.intents) {
  const entries = dictionary.expressions.filter(
    (entry) => entry.intent === intent.intent,
  )
  lines.push(
    '',
    `## ${intent.intent}`,
    '',
    intentDescriptions[intent.intent],
    '',
    '| status | text | subtype | confidence | sourceType | 現在の判定 | notes / 採否理由 |',
    '| --- | --- | --- | --- | --- | --- | --- |',
  )

  for (const entry of entries) {
    const confidence =
      entry.confidence === 'high'
        ? 'high'
        : `${entry.confidence} (レビュー注意)`
    lines.push(
      `| ${entry.status} | ${escapeCell(entry.text)} | ${escapeCell(entry.subtype)} | ${confidence} | ${entry.sourceType} | ${evaluateLine({ input: entry.text, history: [], state: {} }).intent} | ${escapeCell([entry.notes, entry.review && `${entry.review.date}: ${entry.review.reason}`].filter(Boolean).join(' '))} |`,
    )
  }
}

lines.push(
  '',
  '## Known Matching Limitations',
  '',
  '- 採用表現は部分一致で照合するが、長い保留表現を短い採用語で加点・減点しない。「面倒くさい」「きっと大丈夫」は判断保留。',
  '- 「大丈夫じゃない」「ごめんとは思わない」など限定した否定形は判断保留。「一人じゃない」「無理しなくていい」は安心。一般的な構文解析はしない。',
  '- 一文に複数intentが残る場合は、優先順位で断定せず判断保留にする。',
  '- 引用の伝聞形、二重否定、面倒を見たい、お前の話は限定的に保留。対応範囲と未対応例は [仕様](../SPEC.md) を参照。',
  '- 再現例、相談事項、次タスクは [今回のレビュー結果](INTENT_REVIEW_OUTCOME.md) と [TODO](../TODO.md) に記載する。',
  '',
)

await mkdir(new URL('.', outputUrl), { recursive: true })
await writeFile(outputUrl, lines.join('\n'), 'utf8')
