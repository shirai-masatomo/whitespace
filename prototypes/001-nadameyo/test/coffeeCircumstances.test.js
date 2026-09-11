import test from 'node:test'
import assert from 'node:assert/strict'
import { CHOICES, createCoffeeScene, stepCoffeeScene, choiceInterpretation, visibleScene, sceneSnapshot, coffeeCandidates } from '../src/lib/coffeeScene.js'
import { coffeeLanguageRequest, validateCoffeeRequest } from '../src/lib/coffeeLanguage.js'
const step = (s, act) => stepCoffeeScene(s, choiceInterpretation(act))
const run = (kind, acts) => acts.reduce(step, createCoffeeScene('A', kind))

test('circumstances: same words change concern, requested help, and subsequent action', () => {
  const clean = run('cleanup', ['offer_help']), book = run('notebook', ['offer_help'])
  assert.equal(clean.relationship.consent, 'accepted')
  assert.equal(book.relationship.consent, 'none'); assert.equal(book.relationship.notebookConsent, true)
  assert.equal(step(book, 'give_tissue').environment.tissue, 'used')
  assert.equal(step(book, 'move_notebook').environment.notebookPosition, 'safe')
  const day = run('bad_day', ['support'])
  assert.equal(day.player.knowledge.listen, true); assert.equal(day.player.knowledge.argument, false)
  assert.equal(run('cleanup', ['support']).player.knowledge.tissue, true)
})

test('circumstances: initial visible information excludes private concern and cause', () => {
  for (const kind of ['cleanup', 'notebook', 'bad_day']) {
    const s = createCoffeeScene('A', kind), payload = coffeeLanguageRequest(s, '大丈夫？')
    assert.deepEqual(validateCoffeeRequest(payload), payload)
    assert.equal(s.player.knowledge.cause, null)
    assert.doesNotMatch(JSON.stringify(payload.context), /大事な|言い合い|嫌な出来事|bad_day/)
    assert.equal(s.relationship.type, 'friend')
  }
  assert.match(visibleScene(createCoffeeScene('A','notebook')).notebook, /端が濡れ/)
})

test('circumstances: physical care and residual concerns are independent', () => {
  const sequence = ['offer_tissue','give_tissue']
  const clean = run('cleanup',sequence), book = run('notebook',sequence), day = run('bad_day',sequence)
  assert.equal(clean.partner.concern,'resolved')
  assert.equal(book.environment.notebook,'blotted'); assert.equal(book.environment.table,'dry')
  assert.equal(book.environment.notebookPosition,'safe')
  assert.match(visibleScene(book).tissue,/使用済み/); assert.equal(book.history.at(-1).automatic[0].after.environment.table,'wet')
  const done = step(book,'observe')
  assert.equal(done.environment.table,'dry'); assert.equal(done.partner.concern,'notebook_stain')
  assert.equal(day.environment.table,'dry'); assert.equal(day.partner.concern,'bad_day')
  const heard = step(day,'listen')
  assert.equal(heard.partner.concern,'argument_unresolved'); assert.equal(heard.player.knowledge.argument,true)
  assert.equal(step(heard,'listen').partner.agitation,heard.partner.agitation)
  assert.match(step(heard,'support').reply,/さっき聞いてくれて/)
  assert.deepEqual(step(done,'observe').environment,done.environment)
})

test('circumstances: disclosure and knowledge are monotone; repeated questions preserve what was said', () => {
  for (const kind of ['notebook','bad_day']) {
    const first = run(kind,['ask_event']), second = step(first,'ask_event')
    assert.deepEqual(second.player.knowledge,first.player.knowledge)
    assert.notEqual(second.reply,first.reply)
    const supplied = run(kind,['offer_tissue'])
    assert.equal(supplied.player.knowledge.tissue,true)
    assert.doesNotMatch(step(step(supplied,'give_tissue'),'support').reply, /ティッシュがほしい/)
  }
})

test('circumstances: consent, physical possession, and restart are distinct', () => {
  const initial = createCoffeeScene('A','notebook')
  const rejected = step(initial,'move_notebook')
  assert.equal(rejected.environment.notebookPosition,'spill'); assert.equal(rejected.player.knowledge.notebook,true)
  const away = run('notebook',['offer_help','give_space'])
  assert.equal(away.relationship.notebookConsent,false)
  assert.equal(step(away,'move_notebook').environment.notebookPosition,'spill')
  const moved = run('notebook',['offer_help','move_notebook'])
  assert.equal(moved.environment.notebook,'wet')
  assert.equal(coffeeCandidates(moved).find(x=>x.act==='move_notebook').disabled,true)
  assert.deepEqual(sceneSnapshot(createCoffeeScene('A','notebook')),sceneSnapshot(initial))
  const fresh = createCoffeeScene('A','bad_day')
  assert.equal(fresh.memory.listened,false); assert.equal(fresh.history.length,0); assert.equal(fresh.environment.notebook,'absent')
  assert.throws(()=>createCoffeeScene('B','notebook'))
})

test('circumstances: seeded mixed sequences preserve facts, evidence, ownership and actual events', () => {
  let seed = 781
  for (const kind of ['notebook','bad_day']) for (let trial=0;trial<60;trial++) {
    let s=createCoffeeScene('A',kind)
    for(let turn=0;turn<25;turn++) {
      seed=(Math.imul(seed,1664525)+1013904223)>>>0
      const previous=s; s=step(s,CHOICES[seed%CHOICES.length].act)
      const entry=s.history.at(-1)
      for(const f of entry.disclosures) assert.ok(entry.reply.includes(f.quote))
      for(const [key,value] of Object.entries(previous.player.knowledge)) if(value) assert.equal(s.player.knowledge[key],value)
      if(s.environment.table==='dry') { assert.equal(s.environment.tissue,'used'); if(kind==='notebook') assert.equal(s.environment.notebook,'blotted') }
      if(previous.environment.notebookPosition==='safe') assert.equal(s.environment.notebookPosition,'safe')
      if(entry.events.some(e=>e.type==='receive')) { assert.equal(previous.environment.tissue,'player'); assert.equal(s.environment.tissue,'used') }
      if(entry.events.some(e=>e.actor==='player' && e.type==='move-notebook')) assert.equal(previous.relationship.notebookConsent,true)
      assert.ok(s.partner.agitation>=0 && s.partner.agitation<=5)
      assert.deepEqual(validateCoffeeRequest(coffeeLanguageRequest(s,'どうしたの？')).input,'どうしたの？')
    }
  }
})

test('circumstances: wishes retain exact spoken evidence, without inferring importance or background', () => {
  const support=run('notebook',['support']), help=run('notebook',['offer_help']), paper=run('notebook',['offer_tissue'])
  for(const s of [support,help,paper]) {
    assert.equal(s.player.knowledge.notebook,false)
    assert.doesNotMatch(visibleScene(s).preference,/大事な|まだ聞いていない/)
    for(const w of s.player.wishes) assert.ok(s.reply.includes(w.quote))
  }
  assert.match(visibleScene(support).preference,/水気を先に取りたい/)
  assert.match(visibleScene(help).preference,/乾いた端へ移して/)
  const learned=step(support,'ask_event')
  assert.equal(learned.player.knowledge.notebook,true)
  assert.match(visibleScene(learned).preference,/大事な/)
  assert.deepEqual(step(support,'support').player.wishes,support.player.wishes)
})

test('circumstances: paper is not permission to touch the notebook; entrusting permits the owner to move it', () => {
  const untouched=run('notebook',['move_notebook'])
  assert.equal(untouched.environment.notebookPosition,'spill')
  const requested=run('notebook',['offer_help'])
  const entrusted=step(requested,'entrust')
  assert.equal(entrusted.environment.notebookPosition,'safe')
  assert.equal(entrusted.environment.table,'wet'); assert.equal(entrusted.environment.notebook,'wet')
  assert.deepEqual(entrusted.events.map(e=>[e.actor,e.type]),[['partner','move-notebook']])
  const direct=run('notebook',['give_tissue'])
  assert.deepEqual(direct.events.map(e=>e.type),['offer-paper','receive','move-notebook','blot','wipe'])
  assert.equal(direct.player.knowledge.notebook,false)
  assert.equal(direct.history.length,1)
})

test('circumstances: concrete disclosure never rewinds to vague undisclosed circumstances', () => {
  const heard=run('bad_day',['listen']), again=step(heard,'ask_event')
  assert.match(again.reply,/言い合い/)
  assert.equal(again.player.knowledge.argument,true)
  assert.equal(step(heard,'acknowledge').memory.listened,true)
  const cleaned=run('bad_day',['give_tissue'])
  assert.equal(cleaned.partner.concern,'bad_day')
  assert.match(step(cleaned,'offer_help').reply,/話を聞いて/)
})
