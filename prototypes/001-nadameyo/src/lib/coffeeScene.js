import { freshConversation, conversationRule, afterConversation } from './coffeeConversation.js'
import { CIRCUMSTANCES, circumstanceOpening } from './coffeeCircumstances.js'
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
  { act: 'listen', label: '話せる範囲で聞くよ', kind: 'speech', target: 'partner' },
  { act: 'acknowledge', label: '分かった', kind: 'speech', target: 'partner' },
  { act: 'entrust', label: 'ノートはそっちで移してもらえる？', kind: 'speech', target: 'partner' },
  { act: 'move_notebook', label: 'ノートを乾いた場所へ移す', kind: 'action', target: 'notebook' },
  { act: 'give_tissue', label: 'ティッシュを差し出す', kind: 'action', target: 'tissue' },
  { act: 'give_space', label: 'そっとしておく', kind: 'action', target: 'partner' },
  { act: 'decline_help', label: '今は手を貸せない', kind: 'speech', target: 'help' },
  { act: 'leave', label: 'じゃあ、またね', kind: 'speech', target: 'partner' },
  { act: 'observe', label: '様子を見る', kind: 'action', target: 'scene' },
]
export function createCoffeeScene(condition = 'A', circumstance = 'cleanup') {
  const setup = CONDITIONS[condition]
  if (!setup) throw new Error('不明な固定条件です。')
  if (!CIRCUMSTANCES[circumstance] || (condition !== 'A' && circumstance !== 'cleanup')) throw new Error('事情の比較は後から来た友人で行います。')
  return { condition, conversation: freshConversation(),
    partner: { circumstance, agitation: circumstance !== 'cleanup' || condition === 'B' ? 4 : 3, concern: circumstance === 'cleanup' ? 'wet_table' : circumstance, preference: setup.preference },
    environment: { coffee: 'spilled', table: 'wet', tissue: 'player', notebook: circumstance === 'notebook' ? 'wet' : 'absent', notebookPosition: circumstance === 'notebook' ? 'spill' : 'absent' },
    player: { wishes: [], role: setup.role, observed: ['spilled_coffee', 'wet_table'], knowledge: { cause: condition === 'C' ? 'player' : null, injury: null, wipe: false, tissue: false, quiet: false, selfWipe: false, notebook: false, burden: false, argument: false, listen: false }, actions: CHOICES.filter(x => x.kind === 'action').map(x => x.act) },
    relationship: { type: setup.relation, cause: setup.cause, shared: condition === 'C' ? ['cause'] : [], consent: 'none', notebookConsent: false, apologized: false, helpRefused: false, distance: 'near' },
    memory: { spaceCalmed: false, listened: false }, history: [], reply: null, events: [{ actor: 'scene', type: 'opening', text: circumstanceOpening(circumstance) }], reason: '場面の開始。原因や望みは、観察と対話で確かめられます。', reaction: null,
  }
}
export function sceneSnapshot(state) {
  return structuredClone({ partner: state.partner, environment: state.environment, player: state.player, relationship: state.relationship, memory: state.memory, conversation: state.conversation })
}
export function visibleScene(state) {
  const k = state.player.knowledge
  return { role: state.player.role, table: state.environment.table === 'wet' ? '机はコーヒーで濡れている' : '相手が机を拭き、乾いた',
    tissue: state.environment.tissue === 'player' ? 'あなたの持ち物：ティッシュ1組' : state.environment.tissue === 'partner' ? (state.environment.notebook === 'blotted' ? 'ティッシュは相手の手元（一部をノートに使用。未使用部分が残る）' : 'ティッシュは相手の手元（まだ使っていない）') : 'ティッシュは使用済み',
    cause: k.cause === 'player' ? 'あなたがぶつかったことを、二人とも知っている' : k.cause === 'partner' ? '相手が自分でこぼしたと聞いた' : 'こぼした原因はまだ知らない',
    injury: k.injury === 'none' ? 'けがはないと聞いた' : 'けがの有無はまだ聞いていない',
    preference: [k.wipe && '机を拭きたいと聞いた', k.tissue && 'ティッシュがほしいと聞いた', k.quiet && '静かに対処したいと聞いた', k.selfWipe && '自分で拭くと聞いた', k.notebook && '大事なノートが気がかりだと聞いた', k.burden && 'ほかにも嫌な出来事があったと聞いた', k.argument && '別の友人と言い合いになったと聞いた', k.listen && '話を聞いてほしいと聞いた', ...state.player.wishes.map(w => w.text)].filter(Boolean).join('。') || 'どう関わってほしいかはまだ聞いていない',
    notebook: state.environment.notebook === 'absent' ? 'ノートは見当たらない' : `${state.environment.notebook === 'wet' ? 'ノートの端が濡れている' : 'ノートの水気は取れ、染みが残る'}。${state.environment.notebookPosition === 'safe' ? '机の乾いた端にある' : 'こぼれたコーヒーのそばにある'}。${state.relationship.notebookConsent ? '移してほしいと頼まれた' : '今は移動の依頼はない'}`,
    consent: { none: '紙の受取についてはまだ話していない', declined: '漠然とした手伝いは断られた', accepted: 'ティッシュを受け取る同意がある', fulfilled: '同意したティッシュを渡した', withdrawn: '距離を取り、以前の同意はいったん解除した' }[state.relationship.consent],
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
  if (previous.conversation.ending) return previous
  const state = structuredClone(previous), before = sceneSnapshot(previous)
  const choice = CHOICES.find(x => x.act === interpretation.act && x.target === interpretation.target)
  const act = interpretation.status === 'matched' && choice ? choice.act : 'clarify'
  const rule = conversationRule(state, act, resolveCoffeeRule(state, act))
  const effect = rule.effect(state)
  const facts = effect.facts ?? []
  for (const { key, value, quote } of facts) {
    if (!rule.speech?.includes(quote)) throw new Error('開示の根拠が台詞にありません。')
    state.player.knowledge[key] = value
    if (!state.relationship.shared.includes(key)) state.relationship.shared.push(key)
  }
  for (const wish of rule.wishes ?? []) {
    if (!rule.speech?.includes(wish.quote)) throw new Error('希望の根拠が台詞にありません。')
    if (!state.player.wishes.some(w => w.topic === wish.topic)) state.player.wishes.push({ ...wish })
  }
  state.player.wishes.sort((a,b) => a.topic.localeCompare(b.topic))
  state.relationship.shared.sort()
  if (act === 'give_space') state.relationship.notebookConsent = false
  const events = [...(effect.events ?? [])]
  // Returning to conversation is an actual movement, not an inferred intention.
  if (!rule.id.startsWith('conversation-') && act !== 'give_space' && act !== 'observe' && act !== 'clarify' && act !== 'acknowledge' && act !== 'entrust' && rule.id !== 'give-space-refusal' && state.relationship.distance === 'away') {
    state.relationship.distance = 'near'
    events.unshift({ actor: 'player', type: 'return', text: 'あなたは相手のそばに戻る。' })
  }
  // Receipt is the partner's consent in action. Continue their own care without
  // another player click; keep each physical step separately reviewable.
  const automatic = []
  let reply = rule.speech
  if (events.some(e => e.type === 'receive')) {
    for (let i = 0; i < 2 && state.environment.tissue === 'partner'; i++) {
      const beforeCare = sceneSnapshot(state), care = resolveCoffeeRule(state, 'observe')
      const result = care.effect(state)
      events.push(...(result.events ?? []))
      automatic.push({ branch: care.id, reason: care.guard, before: beforeCare, after: sceneSnapshot(state), events: result.events ?? [] })
      reply = care.speech
    }
  }
  afterConversation(previous, state, act, rule)
  state.reply = reply; state.events = events; state.reason = [rule.guard, ...automatic.map(x=>x.reason)].join(' → '); state.reaction = effect.reaction ?? null
  state.history.push({ id: state.history.length + 1, input: input || choice?.label || '', act, kind: choice?.kind ?? 'speech', interpretation,
    branch: rule.id, reply, events, disclosures: facts, wishes: rule.wishes ?? [], automatic, reason: state.reason, before, after: sceneSnapshot(state), changes: changes(before, sceneSnapshot(state)) })
  return state
}

export function choiceInterpretation(act) {
  const choice = CHOICES.find(x => x.act === act)
  if (!choice) throw new Error('未対応の選択肢です。')
  return { status: 'matched', act, target: choice.target, reason: 'プレイヤーが選択肢を明示。', source: 'choice' }
}

// Availability is presentation only; the interpreter also guards invalid actions.
export function coffeeCandidates(state) {
  if (state.conversation.ending) return []
  return CHOICES.filter(choice => (choice.act !== 'move_notebook' || state.environment.notebook !== 'absent') && (choice.act !== 'acknowledge' || state.history.length > 0) && (choice.act !== 'entrust' || state.relationship.notebookConsent) && (choice.act !== 'decline_help' || state.relationship.notebookConsent)).map(choice => ({ ...choice,
    secondary: choice.act === 'support' || (choice.act === 'apologize' && state.condition !== 'C'),
    disabled: (choice.act === 'give_tissue' && state.environment.tissue !== 'player') || (choice.act === 'move_notebook' && state.environment.notebookPosition === 'safe'),
    note: choice.act === 'move_notebook' && state.environment.notebookPosition === 'safe' ? 'すでに乾いた場所にある' : choice.act === 'give_tissue' && state.environment.tissue !== 'player' ? '手元にティッシュがない' : '',
    label: choice.act === 'leave' ? (state.conversation.closing === 'rest' ? 'ゆっくり休んでね' : state.relationship.type === 'stranger' ? 'では、失礼します' : 'じゃあ、またね') : choice.act === 'observe' && state.environment.tissue === 'partner' ? (state.environment.notebook === 'wet' ? 'ノートの手当てを見守る' : '拭くのを見守る') : choice.act === 'give_space' && state.relationship.distance === 'away' ? '離れたままにする' : choice.label,
  }))
}
