import test from 'node:test'
import assert from 'node:assert/strict'
import { createServer } from 'node:http'
import { once } from 'node:events'
import { evaluateCoffeeModel } from '../server/coffeeModel.js'
import { createLanguageMiddleware } from '../server/localModel.js'
import { createCoffeeScene, choiceInterpretation, stepCoffeeScene } from '../src/lib/coffeeScene.js'
import { coffeeLanguageRequest } from '../src/lib/coffeeLanguage.js'
const payload = coffeeLanguageRequest(createCoffeeScene(), 'ごめん')
const value = { status: 'matched', act: 'apologize', target: 'incident', evidence: 'ごめん', reason: '謝罪の発言' }
const body = (v = value) => ({ done: true, done_reason: 'stop', message: { content: JSON.stringify(v) }, load_duration: 2000000, prompt_eval_duration: 3000000, eval_duration: 4000000 })
test('coffee transport sends known context/history only and validates model output before returning', async () => {
  let sent
  const result = await evaluateCoffeeModel(payload, { fetchImpl: async (url, options) => { sent = { url, ...JSON.parse(options.body) }; return Response.json(body()) } })
  assert.equal(sent.url, 'http://127.0.0.1:11435/api/chat'); assert.equal(sent.think, false)
  assert.deepEqual(JSON.parse(sent.messages[1].content), payload); assert.equal(result.loadMs, 2); assert.equal(result.inferenceMs, 7)
  await assert.rejects(evaluateCoffeeModel(payload, { fetchImpl: async () => Response.json(body({ ...value, evidence: '秘密の事情' })) }), /入力にない/)
  await assert.rejects(evaluateCoffeeModel(payload, { fetchImpl: async () => Response.json({ ...body(), done_reason: 'length' }) }), /完了/)
})
test('coffee transport fails without substitution on offline, timeout and cancellation; choices still work', async () => {
  await assert.rejects(evaluateCoffeeModel(payload, { fetchImpl: async () => { throw new TypeError('offline') } }), /接続できません/)
  const waiting = (_, { signal }) => new Promise((resolve, reject) => { const timer = setTimeout(() => resolve(Response.json(body())), 100); signal.addEventListener('abort', () => { clearTimeout(timer); reject(signal.reason) }, { once: true }) })
  await assert.rejects(evaluateCoffeeModel(payload, { timeoutMs: 5, fetchImpl: waiting }), /タイムアウト/)
  const controller = new AbortController(), pending = evaluateCoffeeModel(payload, { signal: controller.signal, fetchImpl: waiting }); controller.abort(); await assert.rejects(pending, /中止/)
  assert.equal(stepCoffeeScene(createCoffeeScene(), choiceInterpretation('offer_tissue')).relationship.consent, 'accepted')
})
test('coffee API shares busy gate with comparison, validates request and releases after failure', async t => {
  let release, enter; const entered = new Promise(resolve => { enter = resolve })
  const middleware = createLanguageMiddleware({ evaluateScene: async request => { if (request.input === '待つ') { enter(); await new Promise(resolve => { release = resolve }) }; if (request.input === '失敗') throw new Error('不正な解釈'); return { interpretation: value } } })
  const server = createServer((req, res) => middleware(req, res, () => { res.statusCode = 404; res.end() }))
  server.listen(0, '127.0.0.1'); await once(server, 'listening'); t.after(() => { server.closeAllConnections(); server.close() })
  const base = `http://127.0.0.1:${server.address().port}`
  const post = (body, headers = {}) => fetch(`${base}/api/coffee/evaluate`, { method: 'POST', headers: { 'Content-Type': 'application/json', ...headers }, body: JSON.stringify(body) })
  assert.equal((await post({ input: 'ごめん' })).status, 400); assert.equal((await post(payload, { origin: 'http://elsewhere.example' })).status, 403)
  assert.equal((await post(payload)).status, 200)
  const pending = post({ ...payload, input: '待つ' }); await entered
  assert.equal((await fetch(`${base}/api/language/evaluate`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ input: 'ごめん' }) })).status, 429)
  release(); assert.equal((await pending).status, 200)
  assert.equal((await post({ ...payload, input: '失敗' })).status, 502); assert.equal((await post(payload)).status, 200)
})
