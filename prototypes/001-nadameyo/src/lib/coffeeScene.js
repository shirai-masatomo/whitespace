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
    player: { role: setup.role, observed: ['spilled_coffee', 'wet_table'], knowledge: { cause: condition === 'C' ? 'player' : null, injury: null, preference: null }, actions: CHOICES.filter(x => x.kind === 'action').map(x => x.act) },
    relationship: { type: setup.relation, cause: setup.cause, shared: condition === 'C' ? ['cause'] : [], consent: 'none', apologized: false, refusalCount: 0 },
    history: [], reply: '相手は濡れた机を見つめています。', reason: '場面の開始。原因や望みは、観察と対話で確かめられます。', reaction: null,
  }
}
export function sceneSnapshot(state) {
  return structuredClone({ partner: state.partner, environment: state.environment, player: state.player, relationship: state.relationship })
}
export function visibleScene(state) {
  const k = state.player.knowledge
  return { role: state.player.role, table: state.environment.table === 'wet' ? '机はコーヒーで濡れている' : '相手が机を拭き、乾いた',
    tissue: state.environment.tissue === 'player' ? 'あなたの持ち物：ティッシュ1組' : state.environment.tissue === 'partner' ? 'ティッシュは相手の手元（まだ使っていない）' : 'ティッシュは使用済み',
    cause: k.cause === 'player' ? 'あなたがぶつかったことを、二人とも知っている' : k.cause === 'partner' ? '相手が自分でこぼしたと聞いた' : 'こぼした原因はまだ知らない',
    injury: k.injury === 'none' ? 'けがはないと聞いた' : 'けがの有無はまだ聞いていない',
    preference: k.preference === 'quiet' ? '人目を集めず、自分で対処したいと聞いた' : k.preference === 'brief' ? '手短にティッシュを渡してほしいと聞いた' : 'どう関わってほしいかはまだ聞いていない',
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
  const { partner: p, environment: e, relationship: r } = state
  const quiet = p.preference === 'quiet', dry = e.table === 'dry', supplied = e.tissue !== 'player'
  const repeated = previous.history.some(x => x.act === act)
  const reveal = (key, value) => { state.player.knowledge[key] = value; if (!r.shared.includes(key)) r.shared.push(key) }
  const preference = () => reveal('preference', p.preference)
  let reply, reason, reaction = null
  switch (act) {
    case 'ask_event':
      reply = state.player.knowledge.cause ? (dry ? 'さっきのコーヒーのこと。もう机は拭けたよ。' : 'さっきのコーヒーのこと。まだ机を拭けていなくて。') : (quiet ? '自分でこぼしただけです。大ごとにしないでください。' : '自分でコーヒーをこぼしちゃって。先に机を拭きたいんだ。')
      if (r.cause === 'player') reply = dry ? 'さっきぶつかった時のことだよ。机はもう拭けた。' : 'さっき君がぶつかった時にこぼれたんだ。まず机を拭きたい。'
      reveal('cause', r.cause); preference(); reason = '事故の事実を共有。既知なら再説明し、知識を巻き戻さない。'; break
    case 'check_wellbeing':
      reply = repeated ? (dry ? 'けがはないよ。机も片付いた。' : 'けがはないよ。まだ机が濡れているだけ。') : (quiet ? 'けがはありません。静かに片付けたいだけです。' : dry ? 'けがはないよ。机も拭けた、ありがとう。' : supplied ? 'けがはないよ。受け取ったティッシュで、これから拭くね。' : 'けがはないけど、机が……。ティッシュがほしいな。')
      reveal('injury', 'none'); preference(); reason = '身体の無事と、机の状態を分けて説明。心配だけでは片付かない。'; break
    case 'apologize':
      if (r.cause === 'player') {
        reply = r.apologized ? (dry ? '謝ってくれたのは分かってる。もう片付いたよ。' : supplied ? '謝ってくれたのは分かってる。もらったティッシュで拭くね。' : '謝ってくれたのは分かってる。今はティッシュがほしい。') : (dry ? '謝ってくれてありがとう。ぶつかったこと、気にしてくれたんだね。' : 'ぶつかったこと、謝ってくれたんだね。ありがとう。まず机を拭こう。')
        if (!r.apologized) { p.agitation = Math.max(0, p.agitation - 1); reaction = 'recovery' }
        r.apologized = true; reason = '双方が知る主人公の責任への謝罪。初回だけ気持ちが落ち着く。'
      } else { reply = quiet ? 'あなたのせいではありません。私がこぼしたので。' : '君のせいじゃないよ。自分でこぼしたんだ。'; reveal('cause', r.cause); reason = '主人公に事故の責任がないため、謝罪の前提を確認する。'; reaction = 'uncertain' }
      break
    case 'support':
      reply = dry ? '気にかけてくれてありがとう。机はもう大丈夫。' : quiet ? 'お気持ちはありがたいですが、目立ちたくないんです。' : supplied ? 'ありがとう。もらったティッシュで先に机を拭くね。' : 'ありがとう。でも先に机を拭きたい。ティッシュをもらえる？'
      preference(); reason = '味方という表明だけでは具体的な困り事は解決しない。望む接し方を共有。'; break
    case 'offer_help':
    case 'offer_tissue':
      preference()
      if (dry || e.tissue !== 'player') { reply = dry ? 'もう拭けたので大丈夫。ありがとう。' : 'ティッシュはもう受け取ったよ。これから拭くね。'; reason = '物の現状を優先し、二重に受け取らない。' }
      else if (quiet && act === 'offer_help') { r.consent = 'declined'; r.refusalCount++; reply = '手伝いは大丈夫です。自分で拭くので。ティッシュだけの援助なら、受け取れそうです。'; reason = '人目を避けたいので漠然とした援助は断る。具体的な静かな援助は提案し直せる。' }
      else { const already = r.consent === 'accepted'; r.consent = 'accepted'; reply = already ? 'うん、ティッシュを待っています。' : quiet ? 'ティッシュだけ、そっとお願いします。拭くのは自分でします。' : 'お願い。ティッシュを渡してくれる？ 拭くのは自分でできる。'; reason = 'ティッシュ受け取りへの同意だけを更新。提案では物を動かさない。' }
      break
    case 'give_tissue':
      if (e.tissue !== 'player') { reply = dry ? 'もう使って机を拭けたよ。' : 'もう受け取ったよ。ありがとう。'; reason = '持っていない物は渡せない。' }
      else if (r.consent !== 'accepted') { reply = r.refusalCount ? 'さっき手伝いは断りました。ティッシュだけか、先に確認してください。' : '待って。渡す前に、必要か聞いてもらえる？'; p.agitation = Math.min(5, p.agitation + 1); r.refusalCount++; reaction = 'uncertain'; reason = '同意がない、または断られた履歴がある。物を移さず境界を説明。' }
      else { e.tissue = 'partner'; r.consent = 'fulfilled'; reply = quiet ? 'ありがとうございます。これで自分で拭けます。' : 'ありがとう、受け取ったよ。これで拭ける。'; p.agitation = Math.max(0, p.agitation - 1); reaction = 'recovery'; reason = '同意と所持を確認して受け渡しだけ実行。机はまだ濡れたまま。' }
      break
    case 'give_space':
      if (e.tissue === 'player') r.consent = 'withdrawn'
      if (!repeated) p.agitation = Math.max(0, p.agitation - 1)
      reply = dry ? 'ありがとう。もう片付いたので大丈夫。' : quiet ? '少し距離を取ってもらえて助かります。' : '分かった。必要ならこちらから声をかけるね。'
      reason = '距離を取り、未実行の援助同意を解除。落ち着くことと片付けを区別。'; break
    case 'observe':
      if (e.tissue === 'partner' && !dry) { e.table = 'dry'; e.tissue = 'used'; p.concern = 'resolved'; p.agitation = Math.max(0, p.agitation - 1); reply = '相手は受け取ったティッシュで机を拭いた。「これで大丈夫。ありがとう」'; reason = '受け渡し後の時間経過で、相手が実際に拭く。'; reaction = 'recovery' }
      else { reply = dry ? '机は乾き、相手の手が止まっています。' : '相手は濡れた机を見ています。まだ拭く物が手元にありません。'; reason = '観察だけでは物や問題を都合よく変えない。' }
      break
    default: reply = '何をしたいのか、もう少し具体的に教えてもらえる？ この場面でできることは下の選択肢でも試せます。'; reason = interpretation.reason || '曖昧、または対応していない発言。事実を更新しない。'; reaction = 'uncertain'
  }
  state.reply = reply; state.reason = reason; state.reaction = reaction
  state.history.push({ id: state.history.length + 1, input: input || choice?.label || '', act, kind: choice?.kind ?? 'speech', interpretation, reply, reason, before, after: sceneSnapshot(state), changes: changes(before, sceneSnapshot(state)) })
  return state
}
export function choiceInterpretation(act) {
  const choice = CHOICES.find(x => x.act === act)
  if (!choice) throw new Error('未対応の選択肢です。')
  return { status: 'matched', act, target: choice.target, reason: 'プレイヤーが選択肢を明示。', source: 'choice' }
}
