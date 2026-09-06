import assert from 'node:assert/strict'
import test from 'node:test'
import { createServer } from 'node:http'
import { once } from 'node:events'
import { validateModelOutput, MODEL } from '../src/lib/modelContract.js'
import { createLanguageMiddleware, evaluateLocalModel } from '../server/localModel.js'
import { evaluateDictionary, requestModel } from '../src/lib/comparison.js'

// Synthetic responses only for transport/contract tests. Never used in the app or measurements.
const valid = { intent: 'apology', disposition: 'matched', evidence: ['ごめん'], reason: '謝罪を伝えている。' }
const responseBody = (output = valid) => ({ message: { content: JSON.stringify(output) }, done: true,
  done_reason: 'stop', load_duration: 2000000, prompt_eval_duration: 3000000, eval_duration: 4000000, total_duration: 9000000 })

test('model contract rejects contradictions, hallucinated evidence, extra fields and malformed output', () => {
  assert.deepEqual(validateModelOutput(valid, 'ごめん'), valid)
  for (const value of [null, [], { ...valid, intent: 'empathy' }, { ...valid, disposition: 'uncertain' },
    { ...valid, evidence: ['申し訳ない'] }, { ...valid, reason: '' }, { ...valid, extra: 1 }, { ...valid, reason: 'あ'.repeat(161) }]) {
    assert.throws(() => validateModelOutput(value, 'ごめん'))
  }
})

test('adapter pins local model, disables thinking and sends only input, with independently measured timings', async () => {
  let request
  const result = await evaluateLocalModel('ごめん', { fetchImpl: async (url, options) => {
    request = { url, ...JSON.parse(options.body) }
    return Response.json(responseBody())
  } })
  assert.equal(request.url, 'http://127.0.0.1:11435/api/chat')
  assert.equal(request.model, MODEL)
  assert.equal(request.think, false)
  assert.equal(request.stream, false)
  assert.equal(request.options.num_ctx, 4096)
  assert.deepEqual(JSON.parse(request.messages[1].content), { input: 'ごめん' })
  assert.equal(result.loadMs, 2)
  assert.equal(result.inferenceMs, 7)
  assert.ok(result.elapsedMs >= 0)
})

test('malformed output remains an error and exposes diagnostics, not an invented category', async () => {
  await assert.rejects(evaluateLocalModel('ごめん', { fetchImpl: async () => Response.json(responseBody({ ...valid, disposition: 'uncertain' })) }), (error) => {
    assert.equal(error.code, 'invalid_output')
    assert.equal(error.diagnostic.loadMs, 2)
    assert.match(error.diagnostic.raw, /uncertain/)
    return true
  })
  await assert.rejects(evaluateLocalModel('ごめん', { fetchImpl: async () => Response.json({ ...responseBody(), done_reason: 'length' }) }), /完了/)
})

test('unavailable model and timeout produce clear failures', async () => {
  await assert.rejects(evaluateLocalModel('ごめん', { fetchImpl: async () => { throw new TypeError('offline') } }), /接続できません/)
  await assert.rejects(evaluateLocalModel('ごめん', { timeoutMs: 5, fetchImpl: (_, { signal }) => new Promise((resolve, reject) => {
    const timer = setTimeout(() => resolve(Response.json(responseBody())), 100)
    signal.addEventListener('abort', () => { clearTimeout(timer); reject(signal.reason) }, { once: true })
  }) }), (error) => error.code === 'timeout')
})

test('client failures do not prevent dictionary evaluation and preserve invalid-output details', async () => {
  assert.equal(evaluateDictionary('ごめん、今来たばかり').intent, 'apology')
  await assert.rejects(requestModel('ごめん', { fetchImpl: async () => Response.json({ error: '不正', code: 'invalid_output', diagnostic: { raw: '{}' } }, { status: 502 }) }), (error) => error.code === 'invalid_output' && error.diagnostic.raw === '{}')
  await assert.rejects(requestModel('ごめん', { fetchImpl: async () => new Response('<html>') }), /比較API/)
  assert.equal(evaluateDictionary('ごめん、話を聞くよ').intent, 'listening')
})

test('HTTP bridge validates input and origin, limits concurrency, and recovers from errors', async (t) => {
  let release
  let announce
  const entered = new Promise((resolve) => { announce = resolve })
  const middleware = createLanguageMiddleware({
    fetchImpl: async () => { throw new TypeError('offline') },
    evaluate: async (input) => {
      if (input === '待つ') { announce(); await new Promise((resolve) => { release = resolve }) }
      if (input === '失敗') throw Object.assign(new Error('応答失敗'), { code: 'invalid_output' })
      return { ...valid, input }
    },
  })
  const server = createServer((req, res) => middleware(req, res, () => { res.statusCode = 404; res.end() }))
  server.listen(0, '127.0.0.1'); await once(server, 'listening')
  t.after(() => { server.closeAllConnections(); server.close() })
  const base = `http://127.0.0.1:${server.address().port}`
  const post = (input, headers = {}) => fetch(`${base}/api/language/evaluate`, { method: 'POST', headers: { 'Content-Type': 'application/json', ...headers }, body: JSON.stringify({ input }) })
  assert.equal((await (await fetch(`${base}/api/language/status`)).json()).available, false)
  assert.equal((await post('')).status, 400)
  assert.equal((await post('あ'.repeat(281))).status, 400)
  assert.equal((await post('ごめん', { Origin: 'http://unrelated.example' })).status, 403)
  assert.equal((await post('ごめん', { 'Content-Type': 'text/plain' })).status, 415)
  assert.equal((await post('ごめん')).status, 200)
  const pending = post('待つ'); await entered
  assert.equal((await post('ごめん')).status, 429)
  release(); assert.equal((await pending).status, 200)
  assert.equal((await post('失敗')).status, 502)
  assert.equal((await post('ごめん')).status, 200)
})
