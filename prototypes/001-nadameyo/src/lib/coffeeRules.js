import { resolveCircumstanceRule } from './coffeeCircumstances.js'
// Rules are ordered per act. A stable branch ID joins runtime, tests and review maps.
// Disclosures carry the exact spoken evidence; private preferences are never copied.
const rule = (id, act, guard, when, speech, effect = () => ({})) => ({ id, act, guard, when, speech, effect })
const dry = s => s.environment.table === 'dry'
const held = s => s.environment.tissue === 'partner'
const quiet = s => s.partner.preference === 'quiet'
const known = s => s.player.knowledge.cause !== null
const fact = (key, value, quote) => ({ key, value, quote })
const event = (actor, type, text) => ({ actor, type, text })
const calm = s => { s.partner.agitation = Math.max(0, s.partner.agitation - 1) }
const disclose = (facts) => ({ facts })
export const COFFEE_RULES = [
  rule('ask-known-dry', 'ask_event', '原因を既知・机が乾いている', s => known(s) && dry(s), 'さっきのコーヒーのことだよ。もう大丈夫。'),
  rule('ask-known-wet', 'ask_event', '原因を既知・机が濡れている', known, 'さっきのコーヒーのこと。まず机を拭きたいんだ。', () => disclose([fact('wipe', true, '机を拭きたい')])),
  rule('ask-new-dry-quiet', 'ask_event', '原因を未知・机が乾いている・他人', s => dry(s) && quiet(s), '私がこぼしたんです。でも、もう拭けました。', () => disclose([fact('cause', 'partner', '私がこぼした')])),
  rule('ask-new-dry', 'ask_event', '原因を未知・机が乾いている・友人', dry, '自分でこぼしたんだ。もう拭けたよ。', () => disclose([fact('cause', 'partner', '自分でこぼした')])),
  rule('ask-new-quiet', 'ask_event', '原因を未知・静かな対処を望む', quiet, '自分でこぼしただけです。あまり目立ちたくなくて。', () => disclose([fact('cause', 'partner', '自分でこぼした'), fact('quiet', true, '目立ちたくなくて')])),
  rule('ask-new', 'ask_event', '原因を未知・手短な対処を望む', () => true, '自分でこぼしちゃって。先に机を拭きたいんだ。', () => disclose([fact('cause', 'partner', '自分でこぼし'), fact('wipe', true, '机を拭きたい')])),
  rule('well-known', 'check_wellbeing', 'けがなしを既に共有', s => s.player.knowledge.injury !== null, 'うん、けがはないよ。気にかけてくれてありがとう。'),
  rule('well-new', 'check_wellbeing', 'けがの有無が未知', () => true, 'けがはないよ。びっくりしただけ。', () => disclose([fact('injury', 'none', 'けがはない')])),
  rule('apology-c-repeat', 'apologize', '主人公が原因・謝罪済み', s => s.relationship.cause === 'player' && s.relationship.apologized, '謝ってくれたのは分かってるよ。', () => ({})),
  rule('apology-c-first', 'apologize', '主人公が原因・未謝罪', s => s.relationship.cause === 'player', '謝ってくれてありがとう。びっくりしたけど、わざとじゃないよね。', s => { s.relationship.apologized = true; calm(s); return { reaction: 'recovery' } }),
  rule('apology-other-quiet', 'apologize', '相手が原因・他人', quiet, 'あなたのせいじゃありません。私がこぼしたんです。', () => ({ facts: [fact('cause', 'partner', '私がこぼした')], reaction: 'uncertain' })),
  rule('apology-other', 'apologize', '相手が原因・友人', () => true, '君のせいじゃないよ。自分でこぼしたんだ。', () => ({ facts: [fact('cause', 'partner', '自分でこぼした')], reaction: 'uncertain' })),
  rule('support-dry', 'support', '机が乾いている', dry, 'ありがとう。気にかけてくれたんだね。'),
  rule('support-quiet', 'support', '机が濡れ・静かな対処を望む', quiet, 'ありがとう。でも、あまり目立ちたくなくて。', () => disclose([fact('quiet', true, '目立ちたくなくて')])),
  rule('support-held', 'support', '相手がティッシュを所持', held, 'ありがとう。これで拭くね。'),
  rule('support-need', 'support', '主人公がティッシュを所持', () => true, 'ありがとう。今は、拭くためのティッシュがほしいな。', () => disclose([fact('wipe', true, '拭くため'), fact('tissue', true, 'ティッシュがほしい')])),
  ...['offer_help', 'offer_tissue'].flatMap(act => [
    rule(`${act}-dry`, act, '机が乾いている', dry, 'もう大丈夫。ありがとう。'),
    rule(`${act}-held`, act, '相手がティッシュを所持', held, 'さっきもらったので足りるよ。ありがとう。'),
    ...(act === 'offer_help' ? [rule('help-declined', act, '机が濡れ・主人公所持・静かな対処を望む', quiet, 'いえ、自分で拭きます。あまり目立ちたくないので。', s => { s.relationship.consent = 'declined'; s.relationship.helpRefused = true; return disclose([fact('selfWipe', true, '自分で拭きます'), fact('quiet', true, '目立ちたくない')]) })] : []),
    rule(`${act}-already`, act, '受け取りに同意済み', s => s.relationship.consent === 'accepted', 'うん、お願い。'),
    ...(act === 'offer_tissue' ? [rule(`${act}-accept-quiet`, act, '同意なし・静かな対処を望む', quiet, 'じゃあ、ティッシュを。そっとお願いします。拭くのは自分で。', s => { s.relationship.consent = 'accepted'; return disclose([fact('tissue', true, 'ティッシュを'), fact('quiet', true, 'そっとお願いします'), fact('selfWipe', true, '拭くのは自分で')]) })] : []),
    rule(`${act}-accept`, act, '同意なし・手短な対処を望む', () => true, 'うん、ティッシュがほしい。拭くのは自分でできるから。', s => { s.relationship.consent = 'accepted'; return disclose([fact('tissue', true, 'ティッシュがほしい'), fact('selfWipe', true, '拭くのは自分で')]) }),
  ]),
  rule('give-used', 'give_tissue', 'ティッシュは使用済み', dry, 'もう使わせてもらったよ。'),
  rule('give-held', 'give_tissue', '相手が既に所持', held, 'もうもらったよ。ありがとう。'),
  rule('give-accepted', 'give_tissue', '主人公所持・同意あり', s => s.relationship.consent === 'accepted', 'ありがとう、助かる。', s => { s.environment.tissue = 'partner'; s.relationship.consent = 'fulfilled'; calm(s); return { reaction: 'recovery', events: [event('player', 'handover', 'あなたはティッシュを差し出す。'), event('partner', 'receive', '相手はティッシュを受け取る。')] } }),
  rule('give-after-refusal', 'give_tissue', '同意なし・援助を実際に断った履歴あり', s => s.relationship.helpRefused, '手伝いはさっきお断りしました。ティッシュだけか、先に聞いてもらえますか。', s => { s.relationship.confirmationRequested = true; s.partner.agitation = Math.min(5, s.partner.agitation + 1); return { reaction: 'uncertain', events: [event('player', 'attempt', 'あなたはティッシュを渡そうとするが、手元に戻す。')] } }),
  rule('give-after-check', 'give_tissue', '同意なし・事前確認を既に要求', s => s.relationship.confirmationRequested, 'さっきも言ったけど、渡す前に聞いてもらえる？', s => { s.partner.agitation = Math.min(5, s.partner.agitation + 1); return { reaction: 'uncertain', events: [event('player', 'attempt', 'あなたはティッシュを持った手を引っ込める。')] } }),
  rule('give-no-consent', 'give_tissue', '同意なし・拒否も確認要求もなし', () => true, '待って。渡す前に、必要か聞いてもらえる？', s => { s.relationship.confirmationRequested = true; s.partner.agitation = Math.min(5, s.partner.agitation + 1); return { reaction: 'uncertain', events: [event('player', 'attempt', 'あなたはティッシュを渡そうとして、手を止める。')] } }),
  rule('space-again', 'give_space', '既に距離を取っている', s => s.relationship.distance === 'away', null, () => ({ events: [event('player', 'stay-away', 'あなたは少し離れたまま、そっとしておく。')] })),
  rule('space-first', 'give_space', '近くにいる', () => true, 'ありがとう。少し落ち着きたい。', s => { s.relationship.distance = 'away'; if (s.environment.tissue === 'player') s.relationship.consent = 'withdrawn'; if (!s.memory.spaceCalmed) calm(s); s.memory.spaceCalmed = true; return { events: [event('player', 'step-back', 'あなたは一歩下がる。')] } }),
  rule('observe-clean', 'observe', '相手がティッシュ所持・机が濡れている', held, 'これで大丈夫。ありがとう。', s => { s.environment.table = 'dry'; s.environment.tissue = 'used'; s.partner.concern = 'resolved'; calm(s); return { reaction: 'recovery', events: [event('partner', 'wipe', '相手はティッシュで机のコーヒーを拭き取る。')] } }),
  rule('observe-dry', 'observe', '机が乾いている', dry, null, () => ({ events: [event('scene', 'observe', '机には拭いた跡と、使い終えたティッシュが残っている。')] })),
  rule('observe-wet', 'observe', '主人公がティッシュ所持・机が濡れている', () => true, null, () => ({ events: [event('scene', 'observe', 'こぼれたコーヒーが、机の上に溜まっている。')] })),
  rule('clarify', 'clarify', '曖昧・未対応・形式不一致', () => true, '何をしたいのか、もう少し具体的に教えてもらえる？', () => ({ reaction: 'uncertain' })),
]
export function resolveCoffeeRule(state, act) { return resolveCircumstanceRule(state, act) ?? COFFEE_RULES.find(r => r.act === act && r.when(state)) }
