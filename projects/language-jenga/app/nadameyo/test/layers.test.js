import test from 'node:test'
import assert from 'node:assert/strict'
import { LAYERS, original, interpret, renderReply, createGame, changeLayer, undo, finish, accomplished, removedCount } from '../src/lib/layers.js'

test('three removals can preserve the explicit promise; no-op does not farm removals', () => {
  let game = createGame()
  for (const id of ['soft', 'rain', 'bond']) game = changeLayer(game, id, null)
  assert.equal(accomplished(game.layers), true)
  assert.equal(interpret(game.layers).scene, 'shared')
  assert.equal(changeLayer(game, 'soft', null), game)
  assert.equal(removedCount(game.layers), 3)
})
test('same missing offer is sustained by friendship and rain, not by a stranger relationship', () => {
  const s = { ...original(), offer: null }
  assert.equal(interpret(s).kind, 'kept')
  assert.equal(interpret({ ...s, bond: 1 }).kind, 'broken')
  assert.equal(interpret({ ...s, rain: null }).kind, 'broken')
  assert.equal(interpret({ ...s, rain: 1 }).kind, 'changed')
})
test('removing companionship changes sharing into lending; removing both blocks the next step', () => {
  assert.equal(interpret({ ...original(), walk: null }).scene, 'lent')
  assert.equal(interpret({ ...original(), walk: null, offer: null }).kind, 'broken')
  assert.equal(interpret({ ...original(), walk: 1, offer: 1 }).scene, 'apart')
})
test('refusal contradicts sharing a single umbrella, not walking under two umbrellas', () => {
  const s = { ...original(), offer: 1 }
  assert.equal(interpret(s).kind, 'broken')
  assert.equal(interpret({ ...s, umbrellas: 1 }).scene, 'parallel')
})
test('rain stopping takes precedence over two umbrellas; two owners do not transfer an umbrella', () => {
  const s = { ...original(), umbrellas: 1 }
  assert.match(interpret({ ...s, rain: 1 }).reply, /雨、止んだ/)
  for (const walk of [null, 1]) assert.equal(interpret({ ...s, walk }).scene, 'apart')
})
test('withdrawing an umbrella does not magically let the other person walk through rain', () => {
  const result = interpret({ ...original(), offer: 1, walk: 1 })
  assert.match(result.reply, /雨宿り/)
  assert.equal(result.scene, 'apart')
  assert.doesNotMatch(interpret({ ...original(), offer: null }).reply, /いつも/)
})
test('urgency cannot promise an action that is still blocked or explicitly waiting', () => {
  for (const walk of [0, 1]) {
    const s = { ...original(), offer: 1, soft: 1, walk }
    assert.doesNotMatch(renderReply(s, interpret(s)), /急ぐね/)
  }
})
test('undo restores the whole prior scene; finish rejects late changes; reset is independent', () => {
  const before = createGame()
  const after = changeLayer(before, 'bond', 1)
  assert.deepEqual(before.layers, original())
  assert.deepEqual(undo(after), before)
  const ended = finish(after)
  assert.equal(changeLayer(ended, 'offer', null), ended)
  assert.equal(undo(ended), ended)
  assert.equal(finish(ended), ended)
  assert.deepEqual(createGame(), before)
})
test('invalid operations are ignored without adding history', () => {
  const game = createGame()
  for (const [id, value] of [['missing', 0], ['rain', 3], ['rain', undefined], ['rain', false]]) assert.equal(changeLayer(game, id, value), game)
})
test('all 729 authored combinations resolve with reasons; an actionless scene cannot achieve the goal', () => {
  for (let n = 0; n < 3 ** LAYERS.length; n++) {
    let index = n
    const layers = Object.fromEntries(LAYERS.map(l => { const v = [0, 1, null][index % 3]; index = Math.floor(index / 3); return [l.id, v] }))
    const result = interpret(layers)
    assert.ok(['kept', 'changed', 'broken'].includes(result.kind))
    assert.ok(result.reason && result.reply && result.evidence.length)
    assert.ok(result.evidence.every(id => Object.hasOwn(layers, id)))
    if (layers.offer === null && layers.walk === null) assert.equal(result.kind, 'broken')
    if (accomplished(layers)) assert.ok(removedCount(layers) >= 3 && layers.walk === 0)
  }
})
