import test from 'node:test'
import assert from 'node:assert/strict'
import { createCoffeeScene, stepCoffeeScene, choiceInterpretation, sceneSnapshot, visibleScene } from '../src/lib/coffeeScene.js'
import { coffeeLanguageRequest, validateCoffeeInterpretation, validateCoffeeRequest } from '../src/lib/coffeeLanguage.js'
import { coffeeCharacter } from '../src/lib/coffeeCharacter.js'
const act = (s, a) => stepCoffeeScene(s, choiceInterpretation(a))
test('coffee: same apology corrects responsibility in A, repairs acknowledged responsibility in C', () => {
  const a = act(createCoffeeScene('A'), 'apologize'), c = act(createCoffeeScene('C'), 'apologize')
  assert.match(a.reply, /君のせいじゃない/); assert.equal(a.partner.agitation, 3); assert.equal(a.player.knowledge.cause, 'partner')
  assert.match(c.reply, /謝ってくれた/); assert.equal(c.partner.agitation, 2); assert.equal(act(c, 'apologize').partner.agitation, 2)
  assert.equal(a.environment.table, 'wet'); assert.equal(c.environment.table, 'wet')
})
test('coffee: B refuses broad help but accepts specific discreet aid, with refusal history constraining action', () => {
  assert.equal(act(createCoffeeScene('A'), 'offer_help').relationship.consent, 'accepted')
  const refusal = act(createCoffeeScene('B'), 'offer_help'), pushed = act(refusal, 'give_tissue')
  assert.equal(refusal.relationship.consent, 'declined'); assert.match(pushed.reply, /さっき/)
  assert.equal(pushed.environment.tissue, 'player'); assert.equal(pushed.partner.agitation, 5)
  const offer = act(pushed, 'offer_tissue'); assert.equal(offer.relationship.consent, 'accepted'); assert.match(offer.reply, /そっと/)
  assert.equal(act(offer, 'give_tissue').environment.tissue, 'partner')
})
test('coffee: knowledge persists, world facts do not leak into initial player context', () => {
  const initial = createCoffeeScene('B'); assert.equal(initial.relationship.cause, 'partner'); assert.equal(initial.player.knowledge.cause, null)
  const payload = coffeeLanguageRequest(initial, 'どうしたの？'); assert.match(payload.context.cause, /知らない/); assert.match(payload.context.preference, /聞いていない/)
  const one = act(initial, 'ask_event'), two = act(one, 'ask_event'); assert.deepEqual(one.player.knowledge, two.player.knowledge); assert.deepEqual(two.relationship.shared, ['cause', 'preference']); assert.match(two.reply, /さっき/)
  assert.equal(initial.history.length, 0); assert.equal(initial.player.knowledge.cause, null)
})
test('coffee: proposal, transfer, and cleanup are separate, without a required question path', () => {
  for (const condition of ['A', 'B', 'C']) {
    let s = createCoffeeScene(condition)
    assert.equal(act(s, 'give_tissue').environment.tissue, 'player')
    s = act(s, 'offer_tissue'); assert.equal(s.environment.table, 'wet'); assert.equal(s.environment.tissue, 'player')
    s = act(s, 'give_tissue'); assert.equal(s.environment.table, 'wet'); assert.equal(s.environment.tissue, 'partner')
    assert.deepEqual(act(s, 'give_tissue').environment, s.environment)
    s = act(s, 'observe'); assert.equal(s.environment.table, 'dry'); assert.equal(s.environment.tissue, 'used'); assert.equal(s.partner.concern, 'resolved')
    assert.deepEqual(act(s, 'observe').environment, s.environment)
    assert.match(visibleScene(s).table, /乾いた/)
  }
})
test('coffee: stepping away withdraws pending consent without erasing shared knowledge or drying table', () => {
  const s = act(act(act(createCoffeeScene(), 'ask_event'), 'offer_tissue'), 'give_space')
  assert.equal(s.relationship.consent, 'withdrawn'); assert.equal(s.player.knowledge.cause, 'partner'); assert.equal(s.environment.table, 'wet')
  assert.equal(act(s, 'give_tissue').environment.tissue, 'player')
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

test('coffee: after receiving tissue, responses do not request another before wiping', () => {
  const supplied = act(act(createCoffeeScene('C'), 'offer_tissue'), 'give_tissue')
  const apologized = act(supplied, 'apologize')
  for (const s of [act(supplied, 'check_wellbeing'), act(supplied, 'support'), act(apologized, 'apologize')]) {
    assert.match(s.reply, /受け取った|もらった/)
    assert.equal(s.environment.tissue, 'partner'); assert.equal(s.environment.table, 'wet')
  }
})
