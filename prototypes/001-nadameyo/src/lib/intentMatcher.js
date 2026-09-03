const UNKNOWN_EVALUATION = {
  intent: 'unknown',
  trustChange: 0,
  tensionChange: 1,
  reply: '……それで、何が言いたい。',
}

export function normalizeInput(input) {
  return input
    .normalize('NFKC')
    .toLowerCase()
    .replace(/[\s、。,.!?！？・「」『』（）()[\]【】]/g, '')
}

export function createIntentRules(dictionary) {
  return dictionary.intents.map((intentDefinition) => ({
    ...intentDefinition,
    words: dictionary.expressions
      .filter(
        ({ intent, status }) =>
          intent === intentDefinition.intent && status === 'adopted',
      )
      .map(({ text }) => text),
  }))
}

export function createIntentEvaluator(dictionary) {
  const intentRules = createIntentRules(dictionary)

  return function evaluateLine(line) {
    const normalizedLine = normalizeInput(line)
    const rule = intentRules.find(({ words }) =>
      words.some((word) => normalizedLine.includes(normalizeInput(word))),
    )

    return rule ?? UNKNOWN_EVALUATION
  }
}
