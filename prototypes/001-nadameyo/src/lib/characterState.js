// Pure game -> visual boundary. No rendering library, score updates or model calls.
const clamp = (value, max) => Math.max(0, Math.min(max, Number.isFinite(value) ? value : 0))

export function characterState(game, source = 'game') {
  const trust = clamp(game.trust, 4) / 4
  const tension = clamp(game.tension, 5) / 5
  const succeeded = game.result === 'succeeded'
  const failed = game.result === 'failed'
  const last = game.history?.at(-1)
  const kind = succeeded ? 'success' : failed ? 'failure' : last?.repair ? 'recovery'
    : last && last.evaluation.disposition !== 'matched' ? 'uncertain' : null
  return {
    pose: {
      yaw: failed ? -.85 : succeeded ? 0 : -.55 * (1 - trust),
      pitch: failed ? .19 : succeeded ? 0 : .055 * tension,
      shoulder: .105 * tension,
      light: failed ? .08 : succeeded ? 1 : .18 + .72 * trust,
      spread: failed ? .2 : .3 + .7 * trust,
      breath: succeeded || failed ? 0 : .017 * (1 - tension),
      tremor: succeeded || failed ? 0 : .008 * tension ** 2,
      separation: .002 + .026 * tension,
      surfaceMotion: succeeded || failed ? 0 : 1,
    },
    event: game.history?.length ? { id: `${source}:${game.history.length}`, kind } : null,
    description: `${failed ? '顔を背け、光が弱まっている' : succeeded ? '正面を向き、光が安定している' : trust >= .5 ? 'こちらへ向き、胸の光が広がっている' : '少し顔を背け、胸に小さな光がある'}。${tension >= .6 ? '肩が上がり、姿勢がこわばっている' : '肩を下ろし、静かにたたずんでいる'}。`,
  }
}

export const REACTION_LABELS = { uncertain: '聞き返し · 首をかしげる', recovery: '歩み寄り · 肩がほどける', success: '成功 · 向き合う', failure: '失敗 · 距離を置く' }

// A consumed event stays consumed even after its animation ends. A new round
// creates a new controller; null clears a reaction when returning from preview.
export function createReactionController() {
  let id = null
  let kind = null
  let started = 0
  return {
    receive(event, now) {
      if (!event) { id = null; kind = null; return }
      if (event.id === id) return
      id = event.id; kind = event.kind; started = now
    },
    sample(now, reduced = false) {
      const age = Math.max(0, now - started)
      const wave = !reduced && age < 2 ? Math.sin(Math.PI * age / 2) ** 2 : 0
      return { tilt: kind === 'uncertain' ? .17 * wave : 0,
        shoulderDrop: kind === 'recovery' ? .13 * wave : 0,
        settle: kind === 'recovery' ? wave : 0 }
    },
  }
}

export function easePose(current, target, seconds) {
  const amount = 1 - Math.exp(-Math.min(Math.max(seconds, 0), .1) * 5)
  return Object.fromEntries(Object.entries(target).map(([key, value]) => [key, current[key] + (value - current[key]) * amount]))
}
