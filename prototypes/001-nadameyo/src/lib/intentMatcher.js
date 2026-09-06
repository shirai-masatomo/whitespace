export function normalizeInput(input) {
  return input.normalize('NFKC').toLowerCase()
    .replace(/[\s、。,.!?！？・「」『』（）()[\]【】]/g, '')
}

export function createIntentRules(dictionary) {
  return dictionary.intents.map(({ intent }) => ({
    intent,
    words: dictionary.expressions
      .filter((entry) => entry.intent === intent && entry.status === 'adopted')
      .map(({ text }) => text),
  }))
}

// Narrow guards, not a Japanese parser. Supportive phrases containing ない
// (一人じゃない / 無理しなくていい) still use the reviewed dictionary.
const ambiguityGuards = [
  [/大丈夫(?:じゃ|では|でも)(?:ない|ありません)|大丈夫とは(?:思わない|言えない)/, '安心を否定する表現のため判断を保留'],
  [/(?:ごめん|すみません|すまん|申し訳)(?:とは|と|だとは|だと)?(?:全然|まったく)?思(?:わない|っていない|ってない)|謝(?:りたくない|るつもりはない)/, '謝罪を否定する表現のため判断を保留'],
  [/知らない(?:わけじゃない|わけではない|ことはない)/, '二重否定の解釈に対応していないため保留'],
  [/面倒を(?:見|み)/, '世話をする意味の「面倒」は敵意と判定しない'],
  [/お前の話/, '呼称だけでは敵意か傾聴かを判断できないため保留'],
]

/**
 * Replaceable boundary: { input, history, state } -> evaluation.
 * history and state are read-only context; this local adapter only needs input.
 * No game deltas or reply text cross this boundary.
 */
export function createIntentEvaluator(dictionary) {
  const expressions = dictionary.expressions
    .filter(({ status }) => ['adopted', 'deferred', 'review'].includes(status))
    .map((entry) => ({ ...entry, normalized: normalizeInput(entry.text) }))

  return function evaluate({ input }) {
    const normalizedInput = normalizeInput(input)
    // Short undecided words (<= 2 characters) only match an entire punctuation-
    // delimited segment. This is a conservative boundary, not word segmentation.
    let offset = 0
    const segments = input.normalize('NFKC').split(/[\s、。,.!?！？・「」『』（）()[\]【】]+/u).map((segment) => {
      const start = offset
      offset += normalizeInput(segment).length
      return { start, end: offset }
    })
    const matches = []
    for (const entry of expressions) {
      let start = normalizedInput.indexOf(entry.normalized)
      while (start !== -1) {
        const end = start + entry.normalized.length
        if (entry.status === 'adopted' || [...entry.normalized].length > 2
          || segments.some((segment) => segment.start === start && segment.end === end)) {
          matches.push({ text: entry.text, intent: entry.intent, status: entry.status, start, end })
        }
        start = normalizedInput.indexOf(entry.normalized, start + 1)
      }
    }
    // A reviewed longer phrase supersedes a shorter word inside that same span.
    const effective = matches.filter((match) => !matches.some((other) =>
      other.status === 'adopted' && other.start <= match.start && other.end >= match.end
      && other.end - other.start > match.end - match.start,
    ))
    const result = (disposition, reason, intent = 'unknown') => ({
      intent, disposition, reason, normalizedInput, matches: effective, engine: 'dictionary-v3',
    })
    const guard = ambiguityGuards.find(([pattern]) => pattern.test(normalizedInput))
    if (guard) return result('uncertain', guard[1])
    // Reported quotations are not attributed to the player.
    if (/[「『].+?[」』](?:と|って)(?:言|聞|書)/u.test(input)) {
      return result('uncertain', '引用・伝聞を本人の意図と区別できないため保留')
    }
    if (effective.some(({ status }) => status !== 'adopted')) {
      return result('uncertain', '採否を保留している表現を含むため聞き返す')
    }
    const intents = [...new Set(effective.map(({ intent }) => intent))]
    const positivePriority = ['listening', 'apology', 'reassurance']
    if (intents.length > 1 && intents.every((intent) => positivePriority.includes(intent))) {
      return result('matched', '肯定カテゴリの混在：傾聴→謝罪→安心の順で代表を選択', positivePriority.find((intent) => intents.includes(intent)))
    }
    if (intents.length > 1) return result('uncertain', '複数の意味カテゴリが混在しているため保留')
    if (!intents.length) return result('unknown', '採用済みの表現に一致しない')
    return result('matched', '採用済み表現に一致', intents[0])
  }
}
