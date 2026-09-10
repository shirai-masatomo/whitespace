import test from 'node:test'
import assert from 'node:assert/strict'
import { exploreCoffee } from '../scripts/coffeeGraph.mjs'
import { COFFEE_RULES } from '../src/lib/coffeeRules.js'
import { coffeeCandidates, createCoffeeScene, choiceInterpretation, stepCoffeeScene } from '../src/lib/coffeeScene.js'
test('coffee: every reachable state and all nine acts preserve disclosure, ownership and event invariants', () => {
  const covered = new Set()
  for (const id of ['A','B','C']) {
    const graph = exploreCoffee(id, (before, choice, after) => {
      const entry = after.history.at(-1); covered.add(entry.branch)
      assert.equal(after.relationship.cause, before.relationship.cause)
      assert.ok(after.partner.agitation >= 0 && after.partner.agitation <= 5)
      for (const [key, value] of Object.entries(before.player.knowledge)) {
        if (value) assert.equal(after.player.knowledge[key], value, `knowledge lost: ${id}/${entry.branch}/${key}`)
        if (after.player.knowledge[key] !== value) assert.ok(entry.disclosures.some(f => f.key === key && f.value === after.player.knowledge[key] && entry.reply.includes(f.quote)))
      }
      if (after.environment.tissue !== before.environment.tissue) {
        assert.ok(choice.act === 'give_tissue' || choice.act === 'observe')
        if (choice.act === 'give_tissue') { assert.equal(before.relationship.consent,'accepted'); assert.equal(before.environment.tissue,'player') }
      }
      for (const e of entry.events) {
        if (e.type === 'receive') { assert.equal(before.environment.tissue,'player'); assert.equal(after.environment.tissue,'partner') }
        if (e.type === 'wipe') { assert.equal(before.environment.table,'wet'); assert.equal(before.environment.tissue,'partner'); assert.equal(after.environment.table,'dry') }
      }
      if (entry.reply?.includes('手伝いはさっきお断り')) assert.equal(before.relationship.helpRefused,true)
      if (entry.reply?.includes('さっきも言った')) assert.equal(before.relationship.confirmationRequested,true)
    })
    assert.equal(graph.transitions, graph.states * 9); assert.equal(graph.minDry,3); assert.equal(graph.dryWays,id === 'B' ? 1 : 2)
  }
  assert.deepEqual([...covered].sort(), COFFEE_RULES.filter(r => r.act !== 'clarify').map(r => r.id).sort())
})
test('coffee: normal candidates reflect possessions while full interpreter still handles disabled acts', () => {
  const step = (s, act) => stepCoffeeScene(s,choiceInterpretation(act))
  const s = step(step(createCoffeeScene(),'offer_tissue'),'give_tissue')
  const items = coffeeCandidates(s)
  assert.equal(items.length,9); assert.equal(items.find(x=>x.act==='give_tissue').disabled,true)
  assert.equal(items.find(x=>x.act==='apologize').disabled,false)
  assert.equal(items.find(x=>x.act==='observe').label,'拭くのを見守る')
  assert.equal(step(s,'give_tissue').history.at(-1).branch,'give-held')
})
