// Conversation boundaries are separate from physical care and factual disclosure.
export const freshConversation = () => ({ counts: {}, pressure: 0, promised: false, stalled: 0, closing: null, ignored: 0, repairUsed: false, ending: null })
const response = (id, speech, effect = () => ({})) => ({ id: `conversation-${id}`, guard: id, speech, effect })
const topics = { ask_event: 'incident', check_wellbeing: 'wellbeing', offer_help: 'help', offer_tissue: 'paper', support: 'support', listen: 'listening', acknowledge: 'agreement', apologize: 'apology', entrust: 'delegation', move_notebook: 'touch', give_tissue: 'paper-action' }
export function finishConversation(s, kind) {
  const physical = s.environment.table === 'wet' ? '机はまだ濡れている。' : '机は片付いた。'
  const concern = s.environment.notebook === 'blotted' ? 'ノートの染みは残る。' : s.memory.listened ? '話した気がかりは、まだ解決していない。' : ''
  const relation = kind === 'refused' ? '相手は会話を打ち切った。' : kind === 'rest' ? '相手は休むことを選んだ。' : kind === 'complete' ? '礼を交わし、ひと区切りついた。' : 'あなたはここで会話を終えた。'
  s.conversation.ending = { kind, text: [relation, physical, concern].filter(Boolean).join('') }
  s.relationship.distance = 'away'
  s.relationship.notebookConsent = false
  if (s.environment.tissue === 'player') s.relationship.consent = 'withdrawn'
  return { events: [{ actor: kind === 'left' ? 'player' : 'partner', type: 'end-conversation', text: kind === 'refused' ? '相手は顔を背け、会話を終える。' : kind === 'left' ? 'あなたは別れを告げ、その場を離れる。' : '相手は小さくうなずき、会話を終える。' }] }
}
export function conversationRule(s, act, base) {
  const c = s.conversation
  if (act === 'leave') return response('leave', c.closing === 'rest' ? 'うん。少し休むね。' : s.relationship.type === 'stranger' ? 'では、失礼します。' : 'うん、またね。', next => finishConversation(next, c.closing === 'rest' ? 'rest' : s.environment.table === 'dry' && s.partner.circumstance === 'cleanup' ? 'complete' : 'left'))
  if (act === 'decline_help' && !c.closing) return response('decline-help', '分かった。少し一人で考えさせて。', next => { next.relationship.notebookConsent = false; next.conversation.promised = false; next.conversation.closing = 'rest'; return {} })
  const useful = (act === 'give_tissue' && s.environment.tissue === 'player' && base.id !== 'give-space-refusal') || (['move_notebook','entrust'].includes(act) && s.relationship.notebookConsent)
  // A concrete act can repair a repetition warning, but cannot override a request to rest.
  if (c.closing) {
    if (['acknowledge','give_space','observe'].includes(act) || act === 'apologize' || act === 'decline_help') return response('last-word', c.closing === 'rest' ? 'うん。少し休むね。' : 'うん、ここまでにしよう。', next => finishConversation(next, c.closing === 'rest' ? 'rest' : 'refused'))
    if (c.closing === 'repetition' && useful) return base
    if (c.ignored++ === 0) return response('boundary-again', c.closing === 'rest' ? '今は休みたいんだ。続きはまたにしてもらえる？' : 'もう同じやり取りは続けたくない。ここまでにしよう。')
    return response('refuse', '今日はもう話さないよ。', next => finishConversation(next, 'refused'))
  }
  if (act === 'acknowledge' && s.environment.table === 'dry' && s.partner.circumstance === 'cleanup') return response('thanks', 'うん、ありがとう。またね。', next => finishConversation(next, 'complete'))
  if (!topics[act]) return base // Observing and temporary silence do not accumulate pressure.
  if (c.promised && s.relationship.notebookConsent && !useful && act !== 'apologize') {
    c.stalled = Math.min(3, c.stalled + 1)
    if (c.stalled === 1) return response('promise-reminder', 'さっきお願いしたノート、移してもらえる？ 難しければそう言って。')
    if (c.stalled === 3) { c.closing = 'repetition'; return response('promise-boundary', '返事だけだと困るな。手を貸せないなら、ここまでにしよう。') }
    return response('promise-wait', '先にノートを移したい。話はそのあとにしよう。')
  }
  if (useful) return base
  // One apology can soften a repetition warning before the partner asks to stop.
  if (act === 'apologize' && c.pressure >= 2 && !c.repairUsed) {
    c.repairUsed = true; c.pressure = 0; c.counts = {}; c.stalled = 0
    if (s.relationship.cause === 'player' && !s.relationship.apologized) return base
    return response('repair', 'うん、分かった。何度も確かめなくて大丈夫だよ。')
  }
  const topic = act === 'offer_help' && s.partner.circumstance === 'cleanup' && s.condition !== 'B' ? 'paper' : topics[act]
  c.counts[topic] = Math.min(4, (c.counts[topic] ?? 0) + 1)
  const n = c.counts[topic]
  if (n === 1) return base
  c.pressure = Math.min(5, c.pressure + 1)
  if (n >= 4 || c.pressure >= 5) { c.closing = 'repetition'; return response('repeat-boundary', '同じ話が続いて、少し疲れた。ここまでにしたい。') }
  if (topic === 'paper' && s.relationship.consent === 'accepted') return response('paper-repeat', n === 2 ? 'うん、さっきお願いした紙をもらえる？' : '紙を差し出してくれたら助かる。確認はもう大丈夫。')
  // The first recheck retains fact-backed wording, including genuinely new disclosure.
  if (n === 2) return base
  return response('repeat-reminder', s.environment.table === 'dry' ? 'そのことはもう話したよ。今は、少し静かにしていたい。' : 'さっきの話に戻っているね。今は、目の前のことに手を貸してほしい。')
}
export function afterConversation(previous, s, act, rule) {
  const c = s.conversation
  if (c.ending) return
  const progress = JSON.stringify(previous.environment) !== JSON.stringify(s.environment) || (!previous.memory.listened && s.memory.listened)
  if (progress) { c.counts = {}; c.pressure = 0; c.stalled = 0; c.promised = false; if (c.closing === 'repetition') { c.closing = null; c.ignored = 0 } }
  if (act === 'acknowledge' && s.relationship.notebookConsent && !rule.id.startsWith('conversation-')) c.promised = true
  if (!s.relationship.notebookConsent) c.promised = false
  const rest = (rule.id === 'circumstance-ack' && s.memory.listened) || rule.id === 'circumstance-day-listen-again' || (rule.id === 'circumstance-day-help-after' && s.memory.listened)
  if (rest) { c.closing = 'rest'; c.ignored = 0 }
  if (rule.id === 'give-space-refusal') { c.closing = 'space'; c.ignored = 0 }
}
