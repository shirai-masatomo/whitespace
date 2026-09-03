import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import test from 'node:test'

import {
  createIntentEvaluator,
  createIntentRules,
  normalizeInput,
} from '../src/lib/intentMatcher.js'

const dictionaryUrl = new URL(
  '../src/data/intent-dictionary.json',
  import.meta.url,
)
const dictionary = JSON.parse(await readFile(dictionaryUrl, 'utf8'))
const evaluateLine = createIntentEvaluator(dictionary)

test('dictionary contains reviewable metadata for 100 to 500 expressions', () => {
  assert.ok(dictionary.expressions.length >= 100)
  assert.ok(dictionary.expressions.length <= 500)

  for (const expression of dictionary.expressions) {
    assert.equal(typeof expression.text, 'string')
    assert.equal(typeof expression.intent, 'string')
    assert.equal(typeof expression.subtype, 'string')
    assert.ok(['high', 'medium', 'low'].includes(expression.confidence))
    assert.ok(
      ['wordnet', 'sudachi', 'aozora', 'generated'].includes(
        expression.sourceType,
      ),
    )
    assert.ok(['adopted', 'review'].includes(expression.status))
  }
})

test('only adopted expressions become active rules', () => {
  const activeWords = createIntentRules(dictionary).flatMap(({ words }) => words)
  const adoptedWords = dictionary.expressions
    .filter(({ status }) => status === 'adopted')
    .map(({ text }) => text)

  assert.deepEqual(activeWords, adoptedWords)
  assert.equal(activeWords.length, 20)
  assert.ok(!activeWords.includes('悪かった'))
  assert.ok(!activeWords.includes('拒否'))
})

test('normalization absorbs width, spaces, and common punctuation', () => {
  assert.equal(normalizeInput('　大 丈 夫！？ '), '大丈夫')
  assert.equal(normalizeInput('ＳＯＲＲＹ。'), 'sorry')
})

test('existing positive intent behavior is unchanged', () => {
  assert.deepEqual(
    {
      intent: evaluateLine('すみません').intent,
      tensionChange: evaluateLine('すみません').tensionChange,
      trustChange: evaluateLine('すみません').trustChange,
    },
    { intent: 'apology', tensionChange: 0, trustChange: 1 },
  )
  assert.equal(evaluateLine('聞かせて').intent, 'listening')
  assert.equal(evaluateLine('大丈夫').intent, 'reassurance')
})

test('existing negative intent behavior and priority are unchanged', () => {
  assert.deepEqual(
    {
      intent: evaluateLine('知らない').intent,
      tensionChange: evaluateLine('知らない').tensionChange,
      trustChange: evaluateLine('知らない').trustChange,
    },
    { intent: 'rejection', tensionChange: 2, trustChange: 0 },
  )
  assert.equal(evaluateLine('お前').intent, 'hostile')
  assert.equal(evaluateLine('落ち着いて').intent, 'command')
  assert.equal(evaluateLine('知らないけど、ごめん').intent, 'rejection')
})

test('review-only expressions do not automatically become active', () => {
  assert.equal(evaluateLine('拒否').intent, 'unknown')
  assert.equal(evaluateLine('悪かった').intent, 'unknown')
  assert.equal(evaluateLine('安心して').intent, 'unknown')
})
