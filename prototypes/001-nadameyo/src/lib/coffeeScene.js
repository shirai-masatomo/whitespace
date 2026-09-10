import { resolveCoffeeRule } from './coffeeRules.js'
export const CONDITIONS = {
  A: { label: 'A · 後から来た友人', relation: 'friend', cause: 'partner', preference: 'brief', role: '後から来た友人', intro: '友人の席へ来ました。倒れたカップとコーヒーで濡れた机が見えます。こぼした瞬間は見ていません。ティッシュを持っています。' },
  B: { label: 'B · 近くにいた他人', relation: 'stranger', cause: 'partner', preference: 'quiet', role: '近くの席の客', intro: '知らない人の席に、倒れたカップとコーヒーで濡れた机が見えます。こぼした瞬間は見ていません。ティッシュを持っています。' },
  C: { label: 'C · ぶつかった友人', relation: 'friend', cause: 'player', preference: 'brief', role: 'カップにぶつかった友人', intro: 'あなたがカップにぶつかり、友人がコーヒーをこぼしました。二人ともその瞬間を見ています。机は濡れ、あなたはティッシュを持っています。' },
}
export const CHOICES = [
  { act: 'ask_event', label: 'どうしたの？', kind: 'speech', target: 'incident' },
  { act: 'check_wellbeing', label: '大丈夫？', kind: 'speech', target: 'partner' },
  { act: 'apologize', label: 'ごめん', kind: 'speech', target: 'incident' },
  { act: 'support', label: 'あなたの味方だ', kind: 'speech', target: 'partner' },
  { act: 'offer_help', label: '手伝おうか？', kind: 'speech', target: 'help' },
  { act: 'offer_tissue', label: 'ティッシュいる？', kind: 'speech', target: 'tissue' },
  { act: 'give_tissue', label: 'ティッシュを渡す', kind: 'action', target: 'tissue' },
  { act: 'give_space', label: 'そっとしておく', kind: 'action', target: 'partner' },
  { act: 'observe', label: '様子を見る', kind: 'action', target: 'scene' },
]
export function createCoffeeScene(condition = 'A') {
  const setup = CONDITIONS[condition]
  if (!setup) throw new Error('不明な固定条件です。')
  return { condition,
    partner: { agitation: condition === 'B' ? 4 : 3, concern: 'wet_table', preference: setup.preference },
    environment: { coffee: 'spilled', table: 'wet', tissue: 'player' },
    player: { role: setup.role, observed: ['spilled_coffee', 'wet_table'], knowledge: { cause: condition === 'C' ? 'player' : null, injury: null, wipe: false, tissue: false, quiet: false, selfWipe: false }, actions: CHOICES.filter(x => x.kind === 'action').map(x => x.act) },
    relationship: { type: setup.relation, cause: setup.cause, shared: condition === 'C' ? ['cause'] : [], consent: 'none', apologized: false, helpRefused: false, confirmationRequested: false, distance: 'near' },
    memory: { spaceCalmed: false }, history: [], reply: null, events: [{ actor: 'scene', type: 'opening', text: '相手は濡れた机を見つめている。' }], reason: '場面の開始。原因や望みは、観察と対話で確かめられます。', reaction: null,
  }
}
export function sceneSnapshot(state) {
  return structuredClone({ partner: state.partner, environment: state.environment, player: state.player, relationship: state.relationship, memory: state.memory })
}
export function visibleScene(state) {
  const k = state.player.knowledge
  return { role: state.player.role, table: state.environment.table === 'wet' ? '机はコーヒーで濡れている' : '相手が机を拭き、乾いた',
    tissue: state.environment.tissue === 'player' ? 'あなたの持ち物：ティッシュ1組' : state.environment.tissue === 'partner' ? 'ティッシュは相手の手元（まだ使っていない）' : 'ティッシュは使用済み',
    cause: k.cause === 'player' ? 'あなたがぶつかったことを、二人とも知っている' : k.cause === 'partner' ? '相手が自分でこぼしたと聞いた' : 'こぼした原因はまだ知らない',
    injury: k.injury === 'none' ? 'けがはないと聞いた' : 'けがの有無はまだ聞いていない',
    preference: [k.wipe && '机を拭きたいと聞いた', k.tissue && 'ティッシュがほしいと聞いた', k.quiet && '静かに対処したいと聞いた', k.selfWipe && '自分で拭くと聞いた'].filter(Boolean).join('。') || 'どう関わってほしいかはまだ聞いていない',
    consent: { none: '援助の同意はまだない', declined: '漠然とした手伝いは断られた', accepted: 'ティッシュを受け取る同意がある', fulfilled: '同意したティッシュを渡した', withdrawn: '距離を取り、以前の同意はいったん解除した' }[state.relationship.consent],
  }
}
function changes(before, after, prefix = '') {
  return Object.entries(before).flatMap(([key, value]) => {
    const field = prefix ? `${prefix}.${key}` : key, next = after[key]
    if (value && typeof value === 'object' && !Array.isArray(value)) return changes(value, next, field)
    return JSON.stringify(value) === JSON.stringify(next) ? [] : [{ field, before: value, after: next }]
  })
}
// Both explicit choices and validated language interpretations enter this boundary.
// Only this function changes facts; a language model never supplies state patches.
export function stepCoffeeScene(previous, interpretation, input = '') {
  const state = structuredClone(previous), before = sceneSnapshot(previous)
  const choice = CHOICES.find(x => x.act === interpretation.act && x.target === interpretation.target)
  const act = interpretation.status === 'matched' && choice ? choice.act : 'clarify'
  const rule = resolveCoffeeRule(state, act)
  const effect = rule.effect(state)
  const facts = effect.facts ?? []
  for (const { key, value, quote } of facts) {
    if (!rule.speech?.includes(quote)) throw new Error('開示の根拠が台詞にありません。')
    state.player.knowledge[key] = value
    if (!state.relationship.shared.includes(key)) state.relationship.shared.push(key)
  }
  state.relationship.shared.sort()
  const events = [...(effect.events ?? [])]
  // Returning to conversation is an actual movement, not an inferred intention.
  if (act !== 'give_space' && act !== 'observe' && act !== 'clarify' && state.relationship.distance === 'away') {
    state.relationship.distance = 'near'
    events.unshift({ actor: 'player', type: 'return', text: 'あなたは相手のそばに戻る。' })
  }
  state.reply = rule.speech; state.events = events; state.reason = rule.guard; state.reaction = effect.reaction ?? null
  state.history.push({ id: state.history.length + 1, input: input || choice?.label || '', act, kind: choice?.kind ?? 'speech', interpretation,
    branch: rule.id, reply: rule.speech, events, disclosures: facts, reason: rule.guard, before, after: sceneSnapshot(state), changes: changes(before, sceneSnapshot(state)) })
  return state
}

export function choiceInterpretation(act) {
  const choice = CHOICES.find(x => x.act === act)
  if (!choice) throw new Error('未対応の選択肢です。')
  return { status: 'matched', act, target: choice.target, reason: 'プレイヤーが選択肢を明示。', source: 'choice' }
}

// Normal candidates differ from supported acts: all nine remain available to verification.
export function coffeeCandidates(state) {
  return CHOICES.map(choice => ({ ...choice,
    disabled: choice.act === 'give_tissue' && state.environment.tissue !== 'player',
    note: choice.act === 'give_tissue' && state.environment.tissue !== 'player' ? '手元にティッシュがない' : '',
    label: choice.act === 'observe' && state.environment.tissue === 'partner' ? '拭くのを見守る' : choice.act === 'give_space' && state.relationship.distance === 'away' ? '離れたままにする' : choice.label,
  }))
}
