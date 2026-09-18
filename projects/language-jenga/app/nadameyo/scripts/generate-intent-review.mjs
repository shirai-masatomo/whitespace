import { mkdir, readFile, writeFile } from 'node:fs/promises'

const dictionaryUrl = new URL('../src/data/intent-dictionary.json', import.meta.url)
const outputUrl = new URL('../../../docs/INTENT_DICTIONARY_REVIEW.md', import.meta.url)
const dictionary = JSON.parse(await readFile(dictionaryUrl, 'utf8'))

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
  'この文書は「宥めよ」の入力候補を人がレビューするための一覧である。候補を大量に収集しても、自動的にはゲーム判定へ採用しない。',
  '',
  '## Review Status',
  '',
  `- 総候補数: \`${dictionary.expressions.length}\``,
  `- 現在ゲームで有効: \`${adoptedCount}\``,
  `- レビュー待ち: \`${dictionary.expressions.length - adoptedCount}\``,
  `- confidence: high \`${confidenceCounts.high}\` / medium \`${confidenceCounts.medium}\` / low \`${confidenceCounts.low}\``,
  '- `adopted`: 現在のゲーム判定で使う。',
  '- `review`: 候補データとして保持するだけで、ゲーム判定では使わない。',
  '- `medium` / `low`: 文脈依存、短すぎる、複数intentにまたがる等の理由で特に注意して確認する。',
  '',
  '## Source And License Notes',
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
  '| intent | 役割 | 候補数 | adopted | review |',
  '| --- | --- | ---: | ---: | ---: |',
]

for (const intent of dictionary.intents) {
  const entries = dictionary.expressions.filter(
    (entry) => entry.intent === intent.intent,
  )
  const intentAdopted = entries.filter(({ status }) => status === 'adopted').length
  lines.push(
    `| ${intent.intent} | ${intentDescriptions[intent.intent]} | ${entries.length} | ${intentAdopted} | ${entries.length - intentAdopted} |`,
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
    '| status | text | subtype | confidence | sourceType | notes |',
    '| --- | --- | --- | --- | --- | --- |',
  )

  for (const entry of entries) {
    const confidence =
      entry.confidence === 'high'
        ? 'high'
        : `${entry.confidence} (レビュー注意)`
    lines.push(
      `| ${entry.status} | ${escapeCell(entry.text)} | ${escapeCell(entry.subtype)} | ${confidence} | ${entry.sourceType} | ${escapeCell(entry.notes ?? '')} |`,
    )
  }
}

lines.push(
  '',
  '## Known Matching Limitations',
  '',
  '- 現在は部分一致なので、review候補でもadopted語を含む表現は既存ルールに一致する。例: 「ごめんなさい」は「ごめん」に一致する。',
  '- 否定表現を構文解析していない。例: 「大丈夫じゃない」は現在も「大丈夫」に一致する。',
  '- 一文に複数intentがある場合、辞書のintent順で最初に一致したものを採用する。',
  '- これらは辞書候補の人手レビュー後、判定アルゴリズム側の別タスクとして扱う。',
  '',
)

await mkdir(new URL('.', outputUrl), { recursive: true })
await writeFile(outputUrl, lines.join('\n'), 'utf8')
