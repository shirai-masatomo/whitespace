import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import test from 'node:test'
import { createIntentEvaluator } from '../src/lib/intentMatcher.js'
import { advanceGame, createInitialState } from '../src/lib/gameEngine.js'
import { describeReply, getReflection } from '../src/lib/responses.js'

const dictionary = JSON.parse(await readFile(new URL('../src/data/intent-dictionary.json', import.meta.url), 'utf8'))
const evaluate = createIntentEvaluator(dictionary)
const play = (...lines) => lines.reduce((state, line) => advanceGame(state, line, evaluate), createInitialState())

test('empty input is ignored and uncertain input consumes one turn without changing meters', () => {
  const initial = createInitialState()
  assert.equal(advanceGame(initial, '　 ', evaluate), initial)
  for (const input of ['星空がきれい', '悪かった', '大丈夫じゃない', 'ごめんとは思わない', '面倒くさい']) {
    const state = play(input)
    assert.deepEqual([state.trust, state.tension, state.turnsLeft], [0, 2, 4], input)
    assert.match(describeReply(state.history[0]), /聞かせて/)
  }
})

test('varied supportive utterances succeed; last-turn success precedes exhaustion', () => {
  for (const lines of [
    ['私が悪かった', '話を聞くよ', '一人じゃない', '無理しなくていい'],
    ['星空がきれい', '私が悪かった', '話を聞くよ', '一人じゃない', '無理しなくていい'],
  ]) {
    const state = play(...lines)
    assert.equal(state.result, 'succeeded')
    assert.equal(state.trust, 4)
    assert.equal(state.tension, 2)
    assert.equal(advanceGame(state, '嘘つき', evaluate), state)
  }
})

test('tension failure clamps values and unknown-only exhaustion is distinct', () => {
  const tense = play('嘘つき', 'お断りします')
  assert.equal(tense.endReason, 'tension')
  assert.equal(tense.tension, 5)
  assert.equal(tense.result, 'failed')
  const exhausted = play(...Array(5).fill('星空がきれい'))
  assert.deepEqual([exhausted.endReason, exhausted.tension, exhausted.trust, exhausted.turnsLeft], ['turns', 2, 0, 0])
  assert.deepEqual(createInitialState().history, [])
})

test('normalized repeats anywhere in the conversation do not farm trust', () => {
  const repeated = play('ごめん', '話を聞くよ', 'ご め ん！？')
  assert.equal(repeated.trust, 2)
  assert.equal(repeated.turnsLeft, 2)
  assert.equal(repeated.history.at(-1).repeated, true)
  assert.match(describeReply(repeated.history.at(-1)), /それはもう聞いた/)
  const spammed = play(...Array(5).fill('ごめん'))
  assert.equal(spammed.result, 'failed')
  assert.equal(spammed.trust, 1)
})

test('a fresh apology immediately after hurt repairs one tension point', () => {
  const state = play('嘘つき', 'ごめん')
  assert.deepEqual([state.tension, state.trust, state.turnsLeft], [3, 1, 3])
  assert.equal(state.history.at(-1).repair, true)
  assert.match(describeReply(state.history.at(-1)), /さっきの言葉/)
  const delayed = play('落ち着いて', '星空がきれい', 'ごめん')
  assert.equal(delayed.tension, 3)
  const reused = play('ごめん', '落ち着いて', 'ごめん')
  assert.equal(reused.tension, 3)
  assert.equal(reused.trust, 1)
})

test('responses reflect preceding intent and state, without invented quotations', () => {
  assert.doesNotMatch(describeReply(play('ここにいるよ').history[0]), /大丈夫/)
  assert.doesNotMatch(describeReply(play('お断りします').history[0]), /知らない/)
  assert.doesNotMatch(describeReply(play('嘘つき').history[0]), /呼び方/)
  const first = describeReply(play('話を聞くよ').history.at(-1))
  const trusted = describeReply(play('ごめん', '話を聞くよ').history.at(-1))
  const tense = describeReply(play('嘘つき', '話を聞くよ').history.at(-1))
  assert.notEqual(first, trusted)
  assert.notEqual(trusted, tense)
  assert.match(describeReply(play('ごめん', 'すみません').history.at(-1)), /次は/)
})

test('evaluation adapter receives input, recent history and state without changing previous state', () => {
  const state = play('星空がきれい')
  const snapshot = structuredClone(state)
  let received
  const stub = (context) => {
    received = context
    return { intent: 'listening', disposition: 'matched', normalizedInput: 'hello', matches: [], reason: 'test', engine: 'stub' }
  }
  const next = advanceGame(state, ' hello ', stub)
  assert.equal(received.input, 'hello')
  assert.equal(received.history.length, 1)
  assert.equal(received.state.turnsLeft, 4)
  assert.equal(next.trust, 1)
  assert.deepEqual(state, snapshot)
})

test('reflection summarizes actual player behavior and explains uncertain outcomes', () => {
  const reflection = getReflection(play('ごめん', 'ごめん', '星空がきれい'))
  assert.equal(reflection.heard, 1)
  assert.equal(reflection.repeated, 1)
  assert.equal(reflection.uncertain, 1)
  assert.match(reflection.advice, /繰り返し/)
  assert.equal(getReflection(play('嘘つき', 'ごめん')).repairs, 1)
})
