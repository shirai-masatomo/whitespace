import test from 'node:test'
import assert from 'node:assert/strict'
import { createCoffeeScene, stepCoffeeScene, choiceInterpretation, sceneSnapshot, visibleScene } from '../src/lib/coffeeScene.js'
import { coffeeLanguageRequest, validateCoffeeInterpretation, validateCoffeeRequest } from '../src/lib/coffeeLanguage.js'
import { coffeeCharacter } from '../src/lib/coffeeCharacter.js'
const act = (s, a) => stepCoffeeScene(s, choiceInterpretation(a))
test('coffee: same apology corrects responsibility in A, repairs acknowledged responsibility in C', () => {
  const a = act(createCoffeeScene('A'), 'apologize'), c = act(createCoffeeScene('C'), 'apologize')
  assert.match(a.reply, /君のせいじゃない/); assert.equal(a.partner.agitation, 3); assert.equal(a.player.knowledge.cause, 'partner')
  assert.match(c.reply, /謝ってくれ/); assert.equal(c.partner.agitation, 2); assert.equal(act(c, 'apologize').partner.agitation, 2)
  assert.equal(a.environment.table, 'wet'); assert.equal(c.environment.table, 'wet')
})
test('coffee: declining broad help still allows offered paper, but space is respected', () => {
  const declined = act(createCoffeeScene('B'), 'offer_help')
  assert.equal(declined.relationship.helpRefused,true)
  assert.equal(act(declined,'give_tissue').environment.table,'dry')
  const away = act(declined,'give_space'), refused = act(away,'give_tissue')
  assert.equal(refused.environment.tissue,'player'); assert.match(refused.reply,/そっと/)
  assert.equal(act(refused,'give_tissue').environment.tissue,'player')
  assert.equal(act(refused,'acknowledge').relationship.distance,'away')
  assert.match(visibleScene(refused).preference,/そっとしておいて/)
  assert.equal(act(act(createCoffeeScene('B'),'give_space'),'give_tissue').relationship.helpRefused,false)
  const offered = act(refused,'offer_tissue')
  assert.equal(act(offered,'give_tissue').environment.table,'dry')
})

test('coffee: knowledge persists, world facts do not leak into initial player context', () => {
  const initial = createCoffeeScene('B'); assert.equal(initial.relationship.cause, 'partner'); assert.equal(initial.player.knowledge.cause, null)
  const payload = coffeeLanguageRequest(initial, 'どうしたの？'); assert.match(payload.context.cause, /知らない/); assert.match(payload.context.preference, /聞いていない/)
  const one = act(initial, 'ask_event'), two = act(one, 'ask_event'); assert.equal(two.player.knowledge.cause, one.player.knowledge.cause); assert.equal(two.player.knowledge.quiet, true); assert.equal(two.player.knowledge.wipe, true); assert.deepEqual(two.relationship.shared, ['cause', 'quiet', 'wipe']); assert.match(two.reply, /さっき/)
  assert.equal(initial.history.length, 0); assert.equal(initial.player.knowledge.cause, null)
})
test('coffee: proposal does not transfer paper; an offered paper is accepted and used in separate events', () => {
  for (const condition of ['A','B','C']) {
    const initial=createCoffeeScene(condition), offered=act(initial,'offer_tissue')
    assert.equal(offered.environment.tissue,'player'); assert.equal(offered.environment.table,'wet')
    const done=act(offered,'give_tissue')
    assert.equal(done.environment.tissue,'used'); assert.equal(done.environment.table,'dry')
    assert.deepEqual(done.events.map(e=>e.type),['offer-paper','receive','wipe'])
    assert.equal(done.history.at(-1).automatic[0].before.environment.tissue,'partner')
    assert.equal(act(initial,'give_tissue').environment.table,'dry')
  }
})

test('coffee: distance cancels pending agreement without undoing knowledge; friends can accept a fresh offer in action', () => {
  const s=act(act(act(createCoffeeScene(),'ask_event'),'offer_tissue'),'give_space')
  assert.equal(s.relationship.consent,'withdrawn'); assert.equal(s.environment.table,'wet')
  assert.equal(s.player.knowledge.cause,'partner')
  assert.equal(act(s,'give_tissue').environment.table,'dry')
})

test('coffee: ambiguous and unsupported acts change no facts; trace explains each actual change', () => {
  const s = createCoffeeScene(); const u = stepCoffeeScene(s, { status: 'uncertain', act: 'clarify', target: 'unknown', reason: '対象が不明' }, 'それ')
  assert.deepEqual(sceneSnapshot(s), sceneSnapshot(u)); assert.deepEqual(u.history[0].changes, [])
  const invalid = stepCoffeeScene(s, { status: 'matched', act: 'give_tissue', target: 'incident' }); assert.deepEqual(sceneSnapshot(s), sceneSnapshot(invalid))
  const a = act(s, 'ask_event'); assert.ok(a.history[0].changes.find(x => x.field === 'player.knowledge.cause')); assert.ok(a.history[0].reason)
})
test('coffee: restart creates independent shells, clears events and keeps game scores out', () => {
  const used = act(createCoffeeScene('C'), 'apologize'), fresh = createCoffeeScene('A')
  assert.equal(fresh.history.length, 0); assert.equal(fresh.player.knowledge.cause, null); assert.equal(fresh.environment.tissue, 'player')
  assert.equal(coffeeCharacter(fresh).event, null); assert.equal(coffeeCharacter(used).event.kind, 'recovery')
  assert.equal('trust' in fresh, false); assert.equal('turnsLeft' in fresh, false)
})
test('coffee model contract rejects invented evidence, extra facts, conflicting targets and forced uncertain actions', () => {
  const valid = { status: 'matched', act: 'offer_tissue', target: 'tissue', evidence: 'ティッシュ', reason: '受け取りの提案' }
  assert.equal(validateCoffeeInterpretation(valid, 'ティッシュいる？').act, 'offer_tissue')
  for (const output of [{ ...valid, evidence: '見られたくない' }, { ...valid, table: 'dry' }, { ...valid, target: 'incident' }, { ...valid, status: 'uncertain' }]) assert.throws(() => validateCoffeeInterpretation(output, 'ティッシュいる？'))
  assert.equal(validateCoffeeInterpretation({ status: 'unsupported', act: 'clarify', target: 'unknown', evidence: '', reason: '対応外' }, '店員を呼ぶ').status, 'unsupported')
})
test('coffee request carries only player knowledge and five recent exchanges; validates limits', () => {
  let s = createCoffeeScene('B'); for (let i = 0; i < 8; i++) s = act(s, 'observe')
  const payload = coffeeLanguageRequest(s, 'ティッシュいる？'); assert.equal(payload.history.length, 5); assert.deepEqual(validateCoffeeRequest(payload), payload)
  assert.equal('partner' in payload, false); assert.equal('relationship' in payload, false)
  assert.throws(() => validateCoffeeRequest({ ...payload, input: 'x'.repeat(281) }))
  assert.throws(() => validateCoffeeRequest({ ...payload, context: { ...payload.context, hidden: 'secret' } }))
})

test('coffee: after care, questions and support do not request another paper or undo cleanup', () => {
  const supplied=act(createCoffeeScene('C'),'give_tissue')
  for(const action of ['check_wellbeing','support','apologize','offer_help','offer_tissue','ask_event']) {
    const next=act(supplied,action)
    assert.doesNotMatch(next.reply,/ティッシュがほしい|拭きたい/)
    assert.equal(next.environment.tissue,'used'); assert.equal(next.environment.table,'dry')
  }
})

test('coffee: only spoken wishes are learned; wiping does not disclose a tissue request', () => {
  const a = act(createCoffeeScene('A'), 'ask_event')
  assert.equal(a.player.knowledge.wipe, true); assert.equal(a.player.knowledge.tissue, false); assert.equal(a.player.knowledge.quiet, false)
  assert.match(visibleScene(a).preference, /机を拭きたい/); assert.doesNotMatch(visibleScene(a).preference, /ティッシュ|手短/)
  for (const f of a.history.at(-1).disclosures) assert.ok(a.reply.includes(f.quote))
})
test('coffee: repeated offers do not invent refusal, repeat receipt or consume more paper', () => {
  const first=act(createCoffeeScene(),'give_tissue'), second=act(first,'give_tissue')
  assert.equal(second.relationship.helpRefused,false)
  assert.equal(second.events.length,0); assert.deepEqual(second.environment,first.environment)
  assert.match(second.reply,/もう使わせて/)
})

test('coffee: automatic actions have actors and intermediate snapshots, and never become extra player turns', () => {
  const given=act(createCoffeeScene(),'give_tissue')
  assert.equal(given.history.length,1)
  assert.deepEqual(given.events.map(e=>[e.actor,e.type]),[['player','offer-paper'],['partner','receive'],['partner','wipe']])
  assert.equal(given.history[0].automatic[0].before.environment.table,'wet')
  assert.equal(given.history[0].automatic[0].after.environment.table,'dry')
  assert.equal(act(given,'observe').events.some(e=>e.type==='wipe'),false)
})

test('coffee: first question after cleanup explains the past without asking to clean again', () => {
  for (const id of ['A','B']) {
    const done = act(act(act(createCoffeeScene(id),'offer_tissue'),'give_tissue'),'observe')
    const asked = act(done,'ask_event')
    assert.match(asked.reply,/もう拭け/); assert.doesNotMatch(asked.reply,/拭きたい/)
    assert.equal(asked.player.knowledge.wipe, false); assert.equal(asked.environment.table,'dry')
  }
})
