// A small authored experiment, not a personality generator. Rules return the
// same contract as coffeeRules; only stepCoffeeScene applies their disclosures.
export const CIRCUMSTANCES = {
  cleanup: 'ただ片付けたい',
  notebook: '大事なノートが濡れた',
  bad_day: '嫌な出来事が重なった',
}
const fact = (key, value, quote) => ({ key, value, quote })
const event = (type, text, actor = 'partner') => ({ actor, type, text })
const result = (id, guard, speech, effect = () => ({}), wishes = []) => ({ id: `circumstance-${id}`, guard, speech, effect, wishes })
const wish = (topic, quote) => ({ topic, quote, text: `「${quote}」と聞いた` })
const calm = s => { s.partner.agitation = Math.max(0, s.partner.agitation - 1) }

export function circumstanceOpening(kind) {
  return kind === 'notebook' ? '相手は、端の濡れたノートを見つめている。' : kind === 'bad_day' ? '相手は濡れた机から目を離し、長く息を吐く。' : '相手は濡れた机を見つめている。'
}

export function resolveCircumstanceRule(s, act) {
  const kind = s.partner.circumstance, e = s.environment, k = s.player.knowledge
  if (act === 'entrust') {
    if (s.relationship.notebookConsent) return result('entrust-notebook', '任せるという返答を受け、本人が物を動かす', 'うん、じゃあ自分で移すね。', next => {
      next.environment.notebookPosition = 'safe'; next.relationship.notebookConsent = false
      return { events: [event('move-notebook', '相手はノートを机の乾いた端へ移す。')] }
    })
    return result('entrust-unspecified', '委ねる対象が未確定なら物を動かさない', e.table === 'dry' ? '片付けはもう大丈夫だよ。' : '何をお願いしたい？')
  }
  if (act === 'acknowledge') {
    return result('ack', '了解だけで物や気持ちを解決したことにはしない', s.relationship.type === 'stranger' ? 'ありがとうございます。' : s.memory.listened ? 'うん。聞いてくれてありがとう。少し休むよ。' : e.table === 'dry' ? 'うん、ありがとう。' : 'うん。', () => ({}))
  }
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
    if (act === 'check_wellbeing' && k.injury) return result('notebook-well-again', 'けががないことは共有済み。心配の対象はノート', e.notebook === 'wet' ? 'うん、けがはないよ。今はノートの方が心配。' : 'けがはないよ。ノートの染みが気になるだけ。')
    if (act === 'check_wellbeing') return result('notebook-well', 'けがとノートへの心配を区別', `けがはないよ。${e.notebook === 'blotted' ? 'でも、大事なノートの染みが気になる。' : 'それより、大事なノートが濡れちゃって。'}`, () => ({ facts: [fact('injury', 'none', 'けがはない'), fact('notebook', true, '大事なノート')] }))
    if (act === 'offer_help' && e.notebookPosition === 'spill') {
      const request = 'ノートを乾いた端へ移してもらえる？'
      return result('notebook-help', 'ノートの退避を頼む。大切さや背景はまだ説明していない', s.relationship.notebookConsent ? 'さっきお願いしたノートを、乾いた端へ。' : request + ' 紙で押さえるのは自分でやる。', next => { next.relationship.notebookConsent = true; return {} }, s.relationship.notebookConsent ? [] : [wish('move', request), wish('selfCare', '紙で押さえるのは自分でやる')])
    }
    const alreadyAccepted = s.relationship.consent === 'accepted'
    if (act === 'offer_tissue' && e.tissue === 'player') return result('notebook-paper', 'ノートの水気を取る紙を受諾', s.relationship.consent === 'accepted' ? 'うん、その紙をお願い。' : 'うん、ティッシュがほしい。まずノートの水気を取りたい。', next => { next.relationship.consent = 'accepted'; return alreadyAccepted ? {} : { facts: [fact('tissue', true, 'ティッシュがほしい')] } }, alreadyAccepted ? [] : [wish('blot', 'まずノートの水気を取りたい')])
    if (act === 'observe' && e.tissue === 'partner' && e.notebook === 'wet') return result('notebook-blot', '先にノートを保護。机はまだ濡れたまま', 'こすらずに押さえてみるね。', next => {
      const events = []
      if (e.notebookPosition === 'spill') events.push(event('move-notebook', '相手はノートを机の乾いた端へ移す。'))
      next.environment.notebookPosition = 'safe'; next.relationship.notebookConsent = false; next.environment.notebook = 'blotted'; calm(next)
      events.push(event('blot', '相手は紙の一部で、ノートの水気を取る。'))
      return { events, reaction: 'recovery' }
    })
    if (act === 'observe' && e.tissue === 'partner') return result('notebook-table', 'ノートの処置後、紙の未使用部分で机を拭く', 'ありがとう。染みは残っちゃったね。', next => { next.environment.table = 'dry'; next.environment.tissue = 'used'; next.partner.concern = 'notebook_stain'; calm(next); return { events: [event('wipe', '続けて、紙の未使用部分で机を拭く。ノートには染みが残る。')], reaction: 'recovery' } })
    if (act === 'support' || act === 'listen') {
      const request = e.notebook === 'wet' ? '今はノートの水気を先に取りたい' : '書いたものが読めるか、乾いてから確かめたい'
      return result('notebook-support', '具体的に話した希望だけを記録。大切さや背景を推測で補わない', 'ありがとう。' + request + '。', () => ({}), [wish(e.notebook === 'wet' ? 'blot' : 'read', request)])
    }
    if (act === 'observe') return result('notebook-observe', '見えるノートの状態を伝える', null, () => ({ events: [event('observe', e.notebook === 'wet' ? '相手の視線は、濡れたノートに戻る。' : '相手は染みの残ったページをそっと開いている。')] }))
  }
  if (kind === 'bad_day') {
    if (act === 'ask_event' && k.argument) return result('day-known-story', '既に具体的な出来事を共有済み', k.cause ? 'さっき話した、友人との言い合いのことがまだ気になってる。' : 'コーヒーは自分でこぼしたんだ。さっき話した言い合いのことが頭から離れなくて。', () => k.cause ? {} : ({ facts: [fact('cause', 'partner', '自分でこぼした')] }))
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
