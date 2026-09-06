import { performance } from 'node:perf_hooks'
import { MODEL, OUTPUT_SCHEMA, PROMPT_VERSION, SYSTEM_PROMPT, validateModelOutput } from '../src/lib/modelContract.js'

export const OLLAMA_URL = 'http://127.0.0.1:11435'
export const TIMEOUT_MS = 120000

export async function evaluateLocalModel(input, { fetchImpl = fetch, signal, timeoutMs = TIMEOUT_MS } = {}) {
  const started = performance.now()
  let diagnostic
  const combined = signal ? AbortSignal.any([signal, AbortSignal.timeout(timeoutMs)]) : AbortSignal.timeout(timeoutMs)
  try {
    const response = await fetchImpl(`${OLLAMA_URL}/api/chat`, {
      method: 'POST', headers: { 'Content-Type': 'application/json' }, signal: combined,
      body: JSON.stringify({ model: MODEL, stream: false, think: false, keep_alive: '10m', format: OUTPUT_SCHEMA,
        options: { temperature: 0, seed: 42, num_ctx: 4096, num_predict: 220, presence_penalty: 0 },
        messages: [{ role: 'system', content: SYSTEM_PROMPT }, { role: 'user', content: JSON.stringify({ input }) }],
      }),
    })
    if (!response.ok) throw new Error(`ローカルモデルの応答失敗（HTTP ${response.status}）。モデルの取得・起動を確認してください。`)
    const data = await response.json()
    const toMs = (value) => typeof value === 'number' && Number.isFinite(value) && value >= 0 ? value / 1e6 : null
    diagnostic = { elapsedMs: performance.now() - started, loadMs: toMs(data.load_duration),
      inferenceMs: typeof data.prompt_eval_duration === 'number' && typeof data.eval_duration === 'number'
        ? toMs(data.prompt_eval_duration + data.eval_duration) : null,
      totalMs: toMs(data.total_duration), raw: String(data.message?.content ?? '').slice(0, 4000) }
    if (data.done !== true || data.done_reason === 'length') throw new Error('モデルの応答が完了しませんでした。再試行してください。')
    let output
    try { output = JSON.parse(data.message?.content) } catch { throw new Error('モデルが有効なJSONを返しませんでした。') }
    const valid = validateModelOutput(output, input)
    return { intent: valid.intent, disposition: valid.disposition, reason: valid.reason,
      matches: valid.evidence.map((text) => ({ text, intent: valid.intent, status: 'model-evidence' })),
      engine: MODEL, promptVersion: PROMPT_VERSION,
      elapsedMs: performance.now() - started, loadMs: toMs(data.load_duration),
      inferenceMs: diagnostic.inferenceMs,
      totalMs: toMs(data.total_duration), generatedTokens: data.eval_count ?? null,
    }
  } catch (error) {
    if (combined.aborted) throw Object.assign(new Error(signal?.aborted ? '比較を中止しました。' : `${timeoutMs / 1000}秒でタイムアウトしました。モデル起動状態を確認してください。`, { cause: error }), { code: 'timeout', diagnostic: { elapsedMs: performance.now() - started } })
    if (error instanceof TypeError) throw Object.assign(new Error('ローカルモデルに接続できません。start-local-model.ps1で起動してください。辞書は引き続き使えます。', { cause: error }), { code: 'unavailable', diagnostic: { elapsedMs: performance.now() - started } })
    error.code = diagnostic ? 'invalid_output' : 'unavailable'
    error.diagnostic = diagnostic ?? { elapsedMs: performance.now() - started }
    throw error
  }
}

export function createLanguageMiddleware({ evaluate = evaluateLocalModel, fetchImpl = fetch } = {}) {
  let busy = false
  return async (req, res, next) => {
    const path = req.url?.split('?')[0]
    if (!['/api/language/status', '/api/language/evaluate'].includes(path)) return next()
    const send = (status, value) => { res.statusCode = status; res.setHeader('Content-Type', 'application/json; charset=utf-8'); res.setHeader('Cache-Control', 'no-store'); res.end(JSON.stringify(value)) }
    // This bridge only serves the same loopback origin; it is not an open proxy.
    if (!/^(127\.0\.0\.1|localhost|\[::1\])(?::\d+)?$/.test(req.headers.host ?? '')
      || (req.headers.origin && req.headers.origin !== `http://${req.headers.host}`)) return send(403, { error: '同じローカル画面から利用してください。' })
    if (path.endsWith('/status')) {
      if (req.method !== 'GET') return send(405, { error: 'GETのみ利用できます。' })
      try {
        const response = await fetchImpl(`${OLLAMA_URL}/api/tags`, { signal: AbortSignal.timeout(2000) })
        if (!response.ok) throw new Error('status')
        const data = await response.json()
        const model = data.models?.find((item) => item.name === MODEL)
        return send(200, { available: Boolean(model), model: MODEL, digest: model?.digest ?? null, size: model?.size ?? null,
          message: model ? 'モデル取得済み・推論時に読み込み' : 'Ollamaは起動済みですが対象モデルがありません。' })
      } catch { return send(200, { available: false, model: MODEL, message: 'モデル未起動。辞書だけでも比較できます。' }) }
    }
    if (req.method !== 'POST') return send(405, { error: 'POSTのみ利用できます。' })
    if (!req.headers['content-type']?.startsWith('application/json')) return send(415, { error: 'JSONで送信してください。' })
    if (busy) return send(429, { error: 'モデルが他の入力を処理中です。少し待って再試行してください。' })
    const chunks = []
    let size = 0
    try {
      for await (const chunk of req) {
        chunks.push(chunk)
        size += chunk.length
        if (size > 4096) return send(413, { error: '入力が大きすぎます。' })
      }
      const parsed = JSON.parse(Buffer.concat(chunks).toString('utf8'))
      if (typeof parsed.input !== 'string' || !parsed.input.trim() || parsed.input.length > 280) return send(400, { error: '1〜280文字で入力してください。' })
      if (busy) return send(429, { error: 'モデルが他の入力を処理中です。少し待って再試行してください。' })
      const controller = new AbortController()
      const onClose = () => { if (!res.writableEnded) controller.abort() }
      res.on('close', onClose)
      busy = true
      try { return send(200, await evaluate(parsed.input, { signal: controller.signal })) }
      catch (error) { if (!res.destroyed) return send(502, { error: error.message, code: error.code, diagnostic: error.diagnostic }) }
      finally { busy = false; res.off('close', onClose) }
    } catch { return send(400, { error: '入力JSONを読み取れませんでした。' }) }
  }
}

export function languageApiPlugin() {
  return { name: 'local-language-api',
    configureServer(server) { server.middlewares.use(createLanguageMiddleware()) },
    configurePreviewServer(server) { server.middlewares.use(createLanguageMiddleware()) },
  }
}
