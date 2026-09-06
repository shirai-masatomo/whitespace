import { readFile, writeFile, mkdir } from 'node:fs/promises'
import { performance } from 'node:perf_hooks'
import { createIntentEvaluator } from '../src/lib/intentMatcher.js'
import { comparisonCases } from '../src/data/comparisonCases.js'
import { MODEL, PROMPT_VERSION } from '../src/lib/modelContract.js'
import { evaluateLocalModel, OLLAMA_URL } from '../server/localModel.js'

const dictionary = JSON.parse(await readFile(new URL('../src/data/intent-dictionary.json', import.meta.url), 'utf8'))
const evaluate = createIntentEvaluator(dictionary)
const tags = await (await fetch(`${OLLAMA_URL}/api/tags`)).json()
const model = tags.models.find((item) => item.name === MODEL)
if (!model) throw new Error('対象モデルがありません。')
const runtime = await (await fetch(`${OLLAMA_URL}/api/version`)).json()
const output = new URL('../../../docs/experiments/language-comparison-2026-09-06.json', import.meta.url)
const report = { recordedAt: new Date().toISOString(), model, runtime, promptVersion: PROMPT_VERSION,
  settings: { temperature: 0, seed: 42, think: false, num_ctx: 4096, num_predict: 220 },
  method: 'Unload selected model, run first case cold, then remaining cases sequentially, repeat first case warm. Expectations are provisional; none are passed to the model.', rows: [] }
await mkdir(new URL('.', output), { recursive: true })
const unload = await fetch(`${OLLAMA_URL}/api/generate`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ model: MODEL, keep_alive: 0, stream: false }) })
if (!unload.ok) throw new Error('初回読込測定のためのアンロードに失敗')
for (const [index, item] of [...comparisonCases, comparisonCases[0]].entries()) {
  const start = performance.now()
  const dictionaryResult = evaluate({ input: item.input, history: [], state: { trust: 0, tension: 2, turnsLeft: 5 } })
  const row = { ...item, phase: index === 0 ? 'cold' : index === comparisonCases.length ? 'warm-repeat' : 'warm',
    dictionary: { ...dictionaryResult, elapsedMs: performance.now() - start } }
  try { row.model = await evaluateLocalModel(item.input) }
  catch (error) { row.error = error.message; row.errorCode = error.code; row.diagnostic = error.diagnostic }
  report.rows.push(row)
  await writeFile(output, JSON.stringify(report, null, 2) + '\n')
  console.log(`${item.id} ${row.phase}: dictionary=${row.dictionary.intent}/${row.dictionary.disposition}; model=${row.model ? `${row.model.intent}/${row.model.disposition} ${row.model.elapsedMs.toFixed(1)}ms load=${row.model.loadMs?.toFixed(1)}ms` : row.error}`)
}
console.log(`Saved ${report.rows.length} measurements: ${output.pathname}`)
