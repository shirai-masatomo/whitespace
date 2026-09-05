export const LIMITS = { tension: 5, trust: 4, turns: 5 }
export const INITIAL_REPLY = '……もういい。全部、わかってるんだろ。'

export function createInitialState() {
  return { tension: 2, trust: 0, turnsLeft: LIMITS.turns, result: 'playing',
    endReason: null, history: [] }
}

const effects = {
  apology: [1, 0], listening: [1, 0], reassurance: [1, 0],
  command: [0, 1], rejection: [0, 2], hostile: [0, 2],
}
const clamp = (value, max) => Math.max(0, Math.min(max, value))

// All game rules live here. Evaluators may be replaced without changing React.
export function advanceGame(state, input, evaluate) {
  const line = input.trim()
  if (!line || state.result !== 'playing') return state
  const evaluation = evaluate({ input: line, history: state.history.slice(-5), state: {
    tension: state.tension, trust: state.trust, turnsLeft: state.turnsLeft,
  } })
  const previous = state.history.at(-1)
  const repeated = state.history.some((entry) =>
    entry.evaluation.normalizedInput === evaluation.normalizedInput)
  const sameIntent = previous?.evaluation.intent === evaluation.intent
  const repair = evaluation.disposition === 'matched' && evaluation.intent === 'apology'
    && !repeated && previous?.tensionChange > 0
  let [trustChange, tensionChange] = evaluation.disposition === 'matched'
    ? effects[evaluation.intent] ?? [0, 0] : [0, 0]
  if (repeated && trustChange > 0) trustChange = 0
  if (repair) tensionChange = -1
  const tension = clamp(state.tension + tensionChange, LIMITS.tension)
  const trust = clamp(state.trust + trustChange, LIMITS.trust)
  const turnsLeft = state.turnsLeft - 1
  const endReason = tension >= LIMITS.tension ? 'tension'
    : trust >= LIMITS.trust ? 'trust' : turnsLeft === 0 ? 'turns' : null
  const result = endReason === 'trust' ? 'succeeded' : endReason ? 'failed' : 'playing'
  const entry = { line, evaluation, repeated, sameIntent, repair,
    trustChange: trust - state.trust, tensionChange: tension - state.tension,
    after: { tension, trust, turnsLeft, result, endReason } }
  return { tension, trust, turnsLeft, result, endReason, history: [...state.history, entry] }
}
