import dictionary from '../data/intent-dictionary.json' with { type: 'json' }
import { createIntentEvaluator } from './intentMatcher.js'
const evaluate = createIntentEvaluator(dictionary)
export function evaluateDictionary(input) {
  const start = performance.now()
  const result = evaluate({ input, history: [], state: { trust: 0, tension: 2, turnsLeft: 5 } })
  return { ...result, elapsedMs: performance.now() - start }
}
export async function requestModel(input, { signal, fetchImpl = fetch, timeoutMs = 122000 } = {}) {
  const timeout = AbortSignal.timeout(timeoutMs)
  try {
    const response = await fetchImpl('/api/language/evaluate', { method: 'POST',
      headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ input }),
      signal: signal ? AbortSignal.any([signal, timeout]) : timeout })
    const data = await response.json()
    if (!response.ok) throw Object.assign(new Error(data.error || `比較APIのエラー（${response.status}）`), { code: data.code, diagnostic: data.diagnostic })
    return data
  } catch (error) {
    if (signal?.aborted) throw new Error('比較を中止しました。', { cause: error })
    if (timeout.aborted) throw new Error('応答待ちがタイムアウトしました。辞書の結果は利用できます。', { cause: error })
    if (error instanceof TypeError || error instanceof SyntaxError) throw new Error('比較APIに接続できません。開発サーバーまたはpreviewで開いてください。', { cause: error })
    throw error
  }
}
