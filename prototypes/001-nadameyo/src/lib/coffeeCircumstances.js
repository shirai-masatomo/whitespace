// A small authored experiment, not a personality generator. Rules return the
// same contract as coffeeRules; only stepCoffeeScene applies their disclosures.
export const CIRCUMSTANCES = {
  cleanup: 'ただ片付けたい',
  notebook: '大事なノートが濡れた',
  bad_day: '嫌な出来事が重なった',
}
const fact = (key, value, quote) => ({ key, value, quote })
const event = (type, text, actor = 'partner') => ({ actor, type, text })
const result = (id, guard, speech, effect = () => ({})) => ({ id: `circumstance-${id}`, guard, speech, effect })
const calm = s => { s.partner.agitation = Math.max(0, s.partner.agitation - 1) }

export function circumstanceOpening(kind) {
  return kind === 'notebook' ? '相手は、端の濡れたノートを見つめている。' : kind === 'bad_day' ? '相手は濡れた机から目を離し、長く息を吐く。' : '相手は濡れた机を見つめている。'
}

export function resolveCircumstanceRule(s, act) {
  const kind = s.partner.circumstance, e = s.environment, k = s.player.knowledge
  if (act === 'move_notebook') {
    if (e.notebook === 'absent') return result('no-notebook', 'ノートはこの場にない', 'どのノートのこと？')
    if (e.notebookPosition === 'safe') return result('notebook-safe', 'ノートは既に乾いた場所にある', 'そこなら、もうコーヒーはつかないね。')
    if (!s.relationship.notebookConsent) return result('notebook-check', '物を動かす同意がない', '待って、触る前に聞いて。大事なノートなんだ。', () => ({ facts: [fact('notebook', true, '大事なノート')], reaction: 'uncertain' }))
    return result('notebook-move', 'ノートを移す同意がある', 'ありがとう。あとは紙で押さえてみる。', next => {
      next.environment.notebookPosition = 'safe'; next.relationship.notebookConsent = false; calm(next)
      return { events: [event('move-notebook', 'あなたはノートを机の乾いた端へ移す。', 'player')], reaction: 'recovery' }
    })
  }
  if (kind === 'notebook') {
    if (act === 'ask_event') {
      const repeat = k.notebook
      const speech = `${k.cause ? 'さっきのコーヒーで' : '自分でこぼして'}、${repeat ? 'あの' : '大事な'}ノートが濡れたんだ。${e.notebook === 'blotted' ? '水気は取れたけど、染みは残りそう。' : '書いたものが消えないか気になって。'}`
      return result('notebook-ask', '原因とノートへの関心を、現在の物の状態に合わせて開示', speech, () => ({ facts: [fact('cause', 'partner', k.cause ? 'さっきのコーヒー' : '自分でこぼして'), fact('notebook', true, 'ノートが濡れた')] }))
    }
    if (act === 'check_wellbeing') return result('notebook-well', 'けがとノートへの心配を区別', `けがはないよ。${e.notebook === 'blotted' ? 'でも、大事なノートの染みが気になる。' : 'それより、大事なノートが濡れちゃって。'}`, () => ({ facts: [fact('injury', 'none', 'けがはない'), fact('notebook', true, '大事なノート')] }))
    if (act === 'offer_help' && e.notebookPosition === 'spill') return result('notebook-help', '机よりノートの退避を頼む。紙の受取同意とは別', s.relationship.notebookConsent ? 'うん、ノートを乾いた端へお願い。' : 'ノートを乾いた端へ移してもらえる？ 紙で押さえるのは自分でやる。', next => { next.relationship.notebookConsent = true; return {} })
    const alreadyAccepted = s.relationship.consent === 'accepted'
    if (act === 'offer_tissue' && e.tissue === 'player') return result('notebook-paper', 'ノートの水気を取る紙を受諾', s.relationship.consent === 'accepted' ? 'うん、その紙をお願い。' : 'うん、ティッシュがほしい。まずノートの水気を取りたい。', next => { next.relationship.consent = 'accepted'; return alreadyAccepted ? {} : { facts: [fact('tissue', true, 'ティッシュがほしい')] } })
    if (act === 'observe' && e.tissue === 'partner' && e.notebook === 'wet') return result('notebook-blot', '先にノートを保護。机はまだ濡れたまま', 'こすらずに押さえてみるね。', next => {
      const events = []
      if (e.notebookPosition === 'spill') events.push(event('move-notebook', '相手はノートを机の乾いた端へ移す。'))
      next.environment.notebookPosition = 'safe'; next.relationship.notebookConsent = false; next.environment.notebook = 'blotted'; calm(next)
      events.push(event('blot', '相手はティッシュの一部でノートの水気を吸い取る。ページには染みが残る。'))
      return { events, reaction: 'recovery' }
    })
    if (act === 'observe' && e.tissue === 'partner') return result('notebook-table', 'ノートの処置後、紙の未使用部分で机を拭く', '机は拭けたね。ノートは、あとで乾かしてみる。', next => { next.environment.table = 'dry'; next.environment.tissue = 'used'; next.partner.concern = 'notebook_stain'; calm(next); return { events: [event('wipe', '相手はティッシュの未使用部分で机を拭く。ノートの染みは残っている。')], reaction: 'recovery' } })
    if (act === 'support' || act === 'listen') return result('notebook-support', '気持ちは受け止めつつ関心はノートにある', e.notebook === 'wet' ? 'ありがとう。今はノートの水気を先に取りたい。' : 'ありがとう。書いたものが読めるか、乾いてから確かめたい。')
    if (act === 'observe') return result('notebook-observe', '見えるノートの状態を伝える', null, () => ({ events: [event('observe', e.notebook === 'wet' ? '相手の視線は、濡れたノートに戻る。' : '相手は染みの残ったページをそっと開いている。')] }))
  }
  if (kind === 'bad_day') {
    if (act === 'ask_event' || act === 'check_wellbeing') {
      const speech = act === 'ask_event' ? `${k.cause ? 'コーヒーは自分でこぼしたんだ。' : '自分でこぼしちゃって。'}${k.burden ? 'さっき話した通り、今日はほかにもあって。' : '今日はほかにも嫌なことが重なって、ため息が出ちゃった。'}` : `けがはないよ。${k.burden ? 'でも、今日のことがまだ引っかかってる。' : '今日は嫌なことが重なって、ちょっとしんどい。'}`
      return result('day-question', 'けがや事故だけでなく、別の困り事があると開示', speech, () => ({ facts: [act === 'ask_event' ? fact('cause', 'partner', '自分でこぼし') : fact('injury', 'none', 'けがはない'), fact('burden', true, k.burden ? (act === 'ask_event' ? 'ほかにもあって' : '今日のこと') : '嫌なことが重なって')] }))
    }
    if (act === 'support' && s.memory.listened) return result('day-support-heard', '既に傾聴してもらった記憶を保持', 'うん、さっき聞いてくれてありがとう。まだ気にはなるけど、一人で抱えずに済んだよ。')
    if (act === 'support') return result('day-support', '支持を受けて事情を少し開示。問題解決とは扱わない', k.burden ? 'そう言ってくれるのはうれしい。今は、答えより聞いてもらいたい。' : 'ありがとう。来る前にも嫌なことがあって。今は、答えより聞いてもらいたい。', () => ({ facts: [...(!k.burden ? [fact('burden', true, '嫌なことがあって')] : []), fact('listen', true, '聞いてもらいたい')] }))
    if (act === 'listen') {
      if (s.memory.listened) return result('day-listen-again', '既に話したことを踏まえる。回復を繰り返さない', 'さっき聞いてくれてありがとう。まだ整理はつかないけど、少しここで休むよ。')
      return result('day-listen', '傾聴の申し出を受け、本人が事情を話す', '来る前、別の友人と言い合いになって。言い過ぎたかなって気になってる。聞いてくれてありがとう。', next => { next.memory.listened = true; next.partner.concern = 'argument_unresolved'; calm(next); return { facts: [fact('burden', true, '別の友人と言い合い'), fact('argument', true, '別の友人と言い合い')], events: [event('exhale', '相手は顔を上げ、途切れながら話し始める。')], reaction: 'recovery' } })
    }
    if (act === 'observe' && e.tissue === 'partner') return result('day-clean', '机は片付くが、別の出来事への気がかりは残る', 'ありがとう。机は片付いたね。', next => { next.environment.table = 'dry'; next.environment.tissue = 'used'; calm(next); return { events: [event('wipe', '相手は机を拭く。手を止めると、また小さく息を吐く。')], reaction: 'recovery' } })
    if (act === 'offer_help' && e.table === 'dry') return result('day-help-after', '片付け後は物ではなく傾聴を望む', s.memory.listened ? '聞いてもらえたから、今は少し休みたい。' : 'よかったら、少し話を聞いてもらえる？', () => s.memory.listened ? {} : ({ facts: [fact('listen', true, '話を聞いてもらえる')] }))
  }
  if (act === 'listen') return result('listen-cleanup', '今は話より片付けを望む', e.table === 'wet' ? 'ありがとう。話はあとで、まず机を拭きたいな。' : 'ありがとう。今はもう落ち着いたよ。', () => e.table === 'wet' ? ({ facts: [fact('wipe', true, '机を拭きたい')] }) : {})
  return null
}
