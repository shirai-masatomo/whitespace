import { MODEL } from '../src/lib/modelContract.js'
import { COFFEE_SCHEMA, COFFEE_PROMPT, COFFEE_PROMPT_VERSION, validateCoffeeRequest, validateCoffeeInterpretation } from '../src/lib/coffeeLanguage.js'
export async function evaluateCoffeeModel(request, { fetchImpl = fetch, signal, timeoutMs = 45000 } = {}) {
  const payload = validateCoffeeRequest(request), start = performance.now()
  const combined = signal ? AbortSignal.any([signal, AbortSignal.timeout(timeoutMs)]) : AbortSignal.timeout(timeoutMs)
  let diagnostic
  try {
    const response = await fetchImpl('http://127.0.0.1:11435/api/chat', { method: 'POST', headers: { 'Content-Type': 'application/json' }, signal: combined,
      body: JSON.stringify({ model: MODEL, stream: false, think: false, keep_alive: '10m', format: COFFEE_SCHEMA,
        options: { temperature: 0, seed: 42, num_ctx: 4096, num_predict: 300 },
        messages: [{ role: 'system', content: COFFEE_PROMPT }, { role: 'user', content: JSON.stringify(payload) }] }) })
    if (!response.ok) throw new Error(`モデル応答失敗（HTTP ${response.status}）`)
    const data = await response.json()
    diagnostic = { elapsedMs: performance.now() - start, loadMs: (data.load_duration ?? 0) / 1e6, inferenceMs: ((data.prompt_eval_duration ?? 0) + (data.eval_duration ?? 0)) / 1e6, raw: String(data.message?.content ?? '').slice(0, 4000) }
    if (data.done !== true || data.done_reason === 'length') throw new Error('解釈の生成が完了しませんでした。')
    const interpretation = validateCoffeeInterpretation(JSON.parse(data.message.content), payload.input)
    return { interpretation, model: MODEL, promptVersion: COFFEE_PROMPT_VERSION, ...diagnostic }
  } catch (error) {
    const message = combined.aborted ? '解釈を中止、または45秒でタイムアウトしました。' : error instanceof TypeError ? 'モデルに接続できません。選択肢は引き続き使えます。' : error.message
    throw Object.assign(new Error(message), { code: diagnostic ? 'invalid_output' : 'unavailable', diagnostic: diagnostic ?? { elapsedMs: performance.now() - start } })
  }
}
