import test from 'node:test'
import assert from 'node:assert/strict'
import { exploreCoffee } from '../scripts/coffeeGraph.mjs'
import { CHOICES, coffeeCandidates, createCoffeeScene, choiceInterpretation, stepCoffeeScene } from '../src/lib/coffeeScene.js'
test('coffee: reachable A/B/C states preserve knowledge, ownership and automatic action ordering', () => {
  for (const id of ['A','B','C']) {
    const graph=exploreCoffee(id,(before,choice,after)=>{
      const entry=after.history.at(-1)
      assert.equal(after.relationship.cause,before.relationship.cause)
      for(const [key,value] of Object.entries(before.player.knowledge)) {
        if(value) assert.equal(after.player.knowledge[key],value)
        if(after.player.knowledge[key]!==value) assert.ok(entry.disclosures.some(f=>f.key===key && entry.reply.includes(f.quote)))
      }
      if(entry.events.some(e=>e.type==='receive')) {
        assert.equal(choice.act,'give_tissue'); assert.equal(before.environment.tissue,'player')
        assert.equal(after.environment.tissue,'used')
        assert.equal(entry.automatic[0].before.environment.tissue,'partner')
        assert.equal(entry.automatic.at(-1).after.environment.table,'dry')
      }
      if(after.environment.table==='dry') assert.equal(after.environment.tissue,'used')
      assert.ok(after.partner.agitation>=0 && after.partner.agitation<=5)
    })
    assert.equal(graph.transitions,graph.states*CHOICES.length)
    assert.equal(graph.minDry,1)
  }
})
test('coffee: normal options include acknowledgment after dialogue; unavailable objects remain guarded',()=>{
  const initial=createCoffeeScene(), done=stepCoffeeScene(initial,choiceInterpretation('give_tissue'))
  assert.equal(coffeeCandidates(initial).some(x=>x.act==='acknowledge'),false)
  assert.equal(coffeeCandidates(done).some(x=>x.act==='acknowledge'),true)
  const proposed=stepCoffeeScene(initial,choiceInterpretation('offer_tissue'))
  const helped=stepCoffeeScene(proposed,choiceInterpretation('give_tissue'))
  assert.equal(coffeeCandidates(helped).find(x=>x.act==='acknowledge').label,'分かった')
  assert.equal(coffeeCandidates(done).find(x=>x.act==='give_tissue').disabled,true)
  assert.equal(coffeeCandidates(done).find(x=>x.act==='observe').label,'様子を見る')
  assert.equal(coffeeCandidates(done).find(x=>x.act==='support').secondary,true)
})
