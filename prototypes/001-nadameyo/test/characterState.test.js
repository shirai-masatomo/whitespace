import test from 'node:test'
import assert from 'node:assert/strict'
import { characterState, createReactionController, easePose } from '../src/lib/characterState.js'
import { createInitialState, advanceGame } from '../src/lib/gameEngine.js'
import { evaluateDictionary } from '../src/lib/comparison.js'

test('trust controls orientation/light independently of tension in all four corners', () => {
  const pose = (trust, tension) => characterState({ trust, tension, result: 'playing', history: [] }).pose
  const ll = pose(0, 0), lh = pose(0, 5), hl = pose(4, 0), hh = pose(4, 5)
  assert.equal(ll.yaw, lh.yaw); assert.equal(hl.yaw, hh.yaw)
  assert.ok(hl.yaw > ll.yaw); assert.ok(hl.light > ll.light); assert.ok(hl.spread > ll.spread)
  assert.equal(lh.light, ll.light); assert.equal(hh.light, hl.light)
  assert.ok(hh.shoulder > hl.shoulder); assert.ok(hh.tremor > hl.tremor)
  assert.ok(hh.separation > hl.separation); assert.ok(ll.breath > lh.breath)
})

test('game events select one reaction, endings take priority, reset clears the event', () => {
  const evaluate = ({ input }) => evaluateDictionary(input)
  const initial = createInitialState()
  const unknown = advanceGame(initial, 'ぽよ', evaluate)
  assert.equal(characterState(unknown).event.kind, 'uncertain')
  const hurt = advanceGame(initial, '嘘つき', evaluate)
  const repair = advanceGame(hurt, 'ごめん', evaluate)
  assert.equal(characterState(repair).event.kind, 'recovery')
  const failed = advanceGame(hurt, '嘘つき', evaluate)
  assert.equal(characterState(failed).event.kind, 'failure')
  assert.ok(characterState(failed).pose.light < characterState(initial).pose.light)
  let success = initial
  for (const line of ['ごめん', '話を聞くよ', '一人じゃない', '無理しなくていい']) success = advanceGame(success, line, evaluate)
  const before = structuredClone(success)
  const visual = characterState(success)
  assert.equal(visual.event.kind, 'success'); assert.equal(visual.pose.yaw, 0)
  assert.equal(visual.pose.tremor, 0); assert.equal(visual.pose.breath, 0)
  assert.equal(visual.pose.surfaceMotion, 0)
  assert.deepEqual(success, before)
  assert.equal(characterState(createInitialState()).event, null)
})

test('reaction events do not replay on redraw; new events and new rounds can react', () => {
  const controller = createReactionController()
  const event = { id: 'game:1', kind: 'uncertain' }
  controller.receive(event, 0)
  assert.ok(controller.sample(1).tilt > 0)
  controller.receive({ ...event }, 3)
  assert.equal(controller.sample(4).tilt, 0)
  controller.receive({ ...event, id: 'game:2' }, 5)
  assert.ok(controller.sample(6).tilt > 0)
  assert.equal(controller.sample(6, true).tilt, 0)
  controller.receive(null, 6); assert.equal(controller.sample(6.5).tilt, 0)
  const fresh = createReactionController(); fresh.receive(event, 0)
  assert.ok(fresh.sample(1).tilt > 0)
})

test('recovery settles shoulders briefly and poses ease without overshoot', () => {
  const controller = createReactionController(); controller.receive({ id: 'preview:1', kind: 'recovery' }, 0)
  assert.ok(controller.sample(1).shoulderDrop > 0); assert.equal(controller.sample(3).shoulderDrop, 0)
  assert.deepEqual(controller.sample(1, true), { tilt: 0, shoulderDrop: 0, settle: 0 })
  const from = characterState(createInitialState()).pose
  const to = characterState({ trust: 4, tension: 5, result: 'playing' }).pose
  const eased = easePose(from, to, .016)
  assert.ok(eased.yaw > from.yaw && eased.yaw < to.yaw)
  assert.ok(eased.shoulder > from.shoulder && eased.shoulder < to.shoulder)
  assert.deepEqual(easePose(from, to, 0), from)
})
