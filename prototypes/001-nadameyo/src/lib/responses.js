export const INTENT_LABELS = {
  apology: '謝罪', listening: '傾聴', reassurance: '安心', command: '命令',
  rejection: '拒絶', hostile: '敵意', unknown: '聞き返し',
}

export function describeReply(entry) {
  const { evaluation, repeated, sameIntent, repair, after } = entry
  if (after.endReason === 'tension') return '……今はこれ以上、話せない。少し離れよう。'
  if (after.endReason === 'trust') return '……少しだけなら。何があったか、聞いてくれる？'
  if (after.endReason === 'turns') return '……今日はここまでにしよう。まだ、うまく話せない。'
  if (evaluation.disposition !== 'matched') return repeated
    ? '……同じ言葉だけだと、まだ分からない。別の言い方で伝えてくれる？'
    : '……どういう気持ちで言ったのか、もう少し聞かせて。'
  if (repair) return '……さっきの言葉はつらかった。でも、向き合おうとしてるんだな。'
  if (repeated) return entry.tensionChange > 0
    ? '……繰り返されると、ますます話しづらい。'
    : '……それはもう聞いたよ。今の気持ちを、別の言葉で聞かせて。'
  switch (evaluation.intent) {
    case 'apology': return sameIntent
      ? '……謝ってくれているのは分かった。次は、こちらの話も聞いてほしい。'
      : '……向き合おうとしてくれるのは、伝わった。'
    case 'listening': return after.tension >= 4
      ? '……聞いてくれるの？ まだ警戒してるけど、少しだけ。'
      : after.trust >= 2 ? '……本当は、置いていかれるのが怖かった。' : '……途中で決めつけずに、聞いてくれる？'
    case 'reassurance': return after.trust >= 2
      ? '……少し、肩の力が抜けた。ここにいてもいいのかな。'
      : '……そう言ってくれるんだね。まだ少し、不安だけど。'
    case 'command': return '……急に指図されると、言葉が出なくなる。'
    case 'rejection': return '……話を閉じられると、こちらも遠ざかりたくなる。'
    case 'hostile': return '……その言い方はつらい。もう少し穏やかに話せないかな。'
    default: return '……もう少し聞かせて。'
  }
}

export function describeChange(entry) {
  if (entry.evaluation.disposition !== 'matched') return '聞き返し · 数値はそのまま'
  if (entry.repeated && entry.trustChange === 0 && entry.tensionChange === 0) return '同じ言葉 · 信頼はそのまま'
  const signed = (number) => number > 0 ? `+${number}` : `${number}`
  return [entry.trustChange && `信頼 ${signed(entry.trustChange)}`,
    entry.tensionChange && `緊張 ${signed(entry.tensionChange)}`].filter(Boolean).join(' / ') || '数値はそのまま'
}

export function getReflection(state) {
  const uncertain = state.history.filter(({ evaluation }) => evaluation.disposition !== 'matched').length
  const repeated = state.history.filter((entry) => entry.repeated).length
  const repairs = state.history.filter((entry) => entry.repair).length
  const heard = state.history.filter((entry) => entry.trustChange > 0).length
  let advice = '相手の返答を読んで、謝る・聞く・安心を伝える言葉を試してみよう。'
  if (state.result === 'succeeded') advice = '言葉を重ねて、相手が話せるところまで近づけました。別の伝え方でも試せます。'
  else if (state.endReason === 'tension') advice = '強い言葉が続くと会話が閉じます。直後に謝ると、緊張を1だけ戻せます。'
  else if (repeated) advice = '同じ文の繰り返しでは信頼は増えません。相手の返答に合わせて言葉を変えてみよう。'
  else if (uncertain) advice = '聞き返しは言葉の良し悪しの判定ではありません。今の試作が理解しやすい短い表現を試してみよう。'
  return { uncertain, repeated, repairs, heard, advice }
}
