import test from 'node:test'
import assert from 'node:assert/strict'
import { createCoffeeScene, stepCoffeeScene, choiceInterpretation, coffeeCandidates } from '../src/lib/coffeeScene.js'
import { pickBlindCircumstance, presentedEvents } from '../src/lib/coffeePresentation.js'
import { validateCoffeeInterpretation, coffeeLanguageRequest } from '../src/lib/coffeeLanguage.js'
const act = (s, a) => stepCoffeeScene(s, choiceInterpretation(a))

test('acknowledgment retains a pending request without executing or delegating it', () => {
  const requested = act(createCoffeeScene('A', 'notebook'), 'offer_help')
  for (const input of ['分かった', '了解']) {
    const interpretation = validateCoffeeInterpretation({status:'matched',act:'acknowledge',target:'partner',evidence:input,reason:'了承'}, input)
    const agreed = stepCoffeeScene(requested, interpretation, input)
    assert.deepEqual(agreed.environment, requested.environment)
    assert.deepEqual(agreed.player, requested.player)
    assert.equal(agreed.conversation.promised,true)
    assert.equal(agreed.events.length, 0)
    assert.equal(coffeeCandidates(agreed).find(x=>x.act==='acknowledge').label, '分かった')
    assert.ok(coffeeCandidates(agreed).some(x=>x.act==='entrust'))
    const moved = act(agreed,'move_notebook')
    assert.equal(moved.environment.notebookPosition,'safe')
    assert.equal(moved.events[0].actor,'player')
    const delegated = act(agreed,'entrust')
    assert.equal(delegated.environment.notebookPosition,'safe')
    assert.equal(delegated.events[0].actor,'partner')
    assert.equal(delegated.relationship.notebookConsent,false)
    assert.deepEqual(act(delegated,'entrust').environment,delegated.environment)
  }
})

test('entrusting with no identified job asks for clarification and never moves objects', () => {
  for (const circumstance of ['cleanup','notebook','bad_day']) {
    const initial = createCoffeeScene('A', circumstance)
    assert.deepEqual(act(initial,'entrust').environment, initial.environment)
    assert.deepEqual(act(initial,'entrust').player, initial.player)
    assert.equal(coffeeCandidates(initial).some(x=>x.act==='entrust'),false)
  }
})

test('blind setup varies only existing circumstances and leaves knowledge unspoiled', () => {
  for (const [n, kind] of [[0,'cleanup'],[0.34,'notebook'],[0.999,'bad_day']]) {
    assert.equal(pickBlindCircumstance(()=>n),kind)
    const initial = createCoffeeScene('A',pickBlindCircumstance(()=>n))
    assert.equal(initial.history.length,0)
    assert.equal(initial.player.knowledge.notebook,false)
    assert.equal(initial.player.knowledge.burden,false)
    assert.equal(initial.player.knowledge.cause,null)
    const payload = coffeeLanguageRequest(initial,'どうしたの？')
    assert.equal('circumstance' in payload.context,false)
    assert.equal(payload.context.preference,'どう関わってほしいかはまだ聞いていない')
  }
})

test('presented care follows actual events and disappears on new turns and reset', () => {
  const initial=createCoffeeScene('A','notebook'), done=act(initial,'give_tissue')
  assert.deepEqual(presentedEvents(done).map(e=>e.type),['receive','move-notebook','blot','wipe'])
  assert.equal(done.history.length,1)
  assert.equal(act(done,'give_tissue').environment.tissue,'used')
  assert.equal(presentedEvents(act(done,'give_tissue')).length,0)
  assert.deepEqual(presentedEvents(createCoffeeScene('A','notebook')),presentedEvents(initial))
  assert.deepEqual(initial.environment,createCoffeeScene('A','notebook').environment)
})
