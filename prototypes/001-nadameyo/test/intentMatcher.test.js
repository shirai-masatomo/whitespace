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
const evaluate = createIntentEvaluator(dictionary)
const evaluateLine = (input) => evaluate({ input, history: [], state: {} })

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
    assert.ok(['adopted', 'review', 'deferred', 'excluded'].includes(expression.status))
    assert.ok(dictionary.intents.some(({ intent }) => intent === expression.intent))
    assert.ok(normalizeInput(expression.text).length > 0)
    if (expression.status !== 'review') {
      assert.ok(expression.review?.date)
      assert.ok(expression.review?.reviewer)
      assert.ok(expression.review?.reason)
    }
  }
})

test('only adopted expressions become active rules', () => {
  const activeWords = createIntentRules(dictionary).flatMap(({ words }) => words)
  const adoptedWords = dictionary.expressions
    .filter(({ status }) => status === 'adopted')
    .map(({ text }) => text)

  assert.deepEqual(activeWords, adoptedWords)
  assert.ok(!activeWords.includes('悪かった'))
  assert.ok(!activeWords.includes('拒否'))
  assert.ok(!activeWords.includes('話せ'))
})

test('normalization absorbs width, spaces, and common punctuation', () => {
  assert.equal(normalizeInput('　大 丈 夫！？ '), '大丈夫')
  assert.equal(normalizeInput('ＳＯＲＲＹ。'), 'sorry')
})

test('positive categories remain available without game rules in evaluation', () => {
  assert.equal(evaluateLine('すみません').intent, 'apology')
  assert.equal(evaluateLine('すみません').trustChange, undefined)
  assert.equal(evaluateLine('聞かせて').intent, 'listening')
  assert.equal(evaluateLine('大丈夫').intent, 'reassurance')
})

test('negative categories work while conflicting categories defer', () => {
  assert.equal(evaluateLine('知らない').intent, 'rejection')
  assert.equal(evaluateLine('お前').intent, 'hostile')
  assert.equal(evaluateLine('落ち着いて').intent, 'command')
  assert.equal(evaluateLine('知らないけど、ごめん').disposition, 'uncertain')
})

test('deferred and excluded expressions without adopted substrings remain unknown', () => {
  assert.equal(evaluateLine('拒否').intent, 'unknown')
  assert.equal(evaluateLine('悪かった').intent, 'unknown')
  assert.equal(evaluateLine('安心して').intent, 'unknown')
})

test('every adopted phrase reaches its intended category without priority collisions', () => {
  for (const expression of dictionary.expressions.filter(({ status }) => status === 'adopted')) {
    assert.equal(evaluateLine(expression.text).intent, expression.intent, expression.text)
    assert.equal(evaluateLine(`\u3000${expression.text}！？`).intent, expression.intent, expression.text)
  }
})

test('newly adopted phrases work in representative utterances', () => {
  const cases = [
    ['そんなの知ったこっちゃない', 'rejection'],
    ['本当に嘘つきだ', 'hostile'],
    ['ちゃんと説明しろ', 'command'],
    ['今回は私が悪かった', 'apology'],
    ['君の話を聞きたい', 'listening'],
    ['今は無理しなくていい', 'reassurance'],
    ['一人じゃない', 'reassurance'],
    ['責めないよ', 'reassurance'],
    ['話さなくてもいい', 'reassurance'],
  ]
  for (const [line, intent] of cases) {
    assert.equal(evaluateLine(line).intent, intent, line)
  }
})

test('short deferred words do not introduce false hostile or command matches', () => {
  const cases = [
    ['話せる範囲でいい', 'listening'],
    ['言える範囲でいい', 'unknown'],
    ['聞けば分かる', 'unknown'],
    ['今来たばかり', 'unknown'],
    ['バカンス', 'unknown'],
    ['馬鹿正直', 'unknown'],
    ['どうしたって無理', 'unknown'],
    ['音楽を聴く', 'unknown'],
    ['天気が悪かった', 'unknown'],
    ['最低気温', 'unknown'],
  ]
  for (const [line, intent] of cases) {
    assert.equal(evaluateLine(line).intent, intent, line)
  }
})

test('deferred phrases take precedence over shorter adopted substrings', () => {
  assert.equal(evaluateLine('面倒くさい').disposition, 'uncertain')
  assert.equal(evaluateLine('きっと大丈夫').disposition, 'uncertain')
})

test('scoped negation guards do not reject supportive negative wording', () => {
  for (const input of ['大丈夫じゃない', '大 丈 夫 じゃない！？', '大丈夫ではない', '大丈夫とは思わない',
    'ごめんとは思わない', 'ごめんと思ってない', '知らないわけじゃない', '面倒を見たい']) {
    assert.equal(evaluateLine(input).disposition, 'uncertain', input)
    assert.equal(evaluateLine(input).intent, 'unknown', input)
  }
  for (const input of ['一人じゃない', '無理しなくていい', '話さなくてもいい', '責めないよ', '大 丈 夫！？']) {
    assert.equal(evaluateLine(input).intent, 'reassurance', input)
  }
})

test('mixed and reported words defer, and diagnostic evidence is returned', () => {
  for (const input of ['お前の話を聞きたい', 'ごめん。でも知らない', '「嘘つき」と言われた']) {
    const result = evaluateLine(input)
    assert.equal(result.disposition, 'uncertain', input)
    assert.ok(result.reason)
    assert.ok(result.matches.length)
  }
  assert.equal(evaluateLine('話してください').intent, 'listening')
  assert.equal(evaluateLine('話してください').matches[0].text, '話してください')
  assert.equal(evaluateLine('星空がきれい').disposition, 'unknown')
})
