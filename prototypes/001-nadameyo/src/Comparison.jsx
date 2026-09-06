import { useEffect, useRef, useState } from 'react'
import { comparisonCases } from './data/comparisonCases.js'
import { evaluateDictionary, requestModel } from './lib/comparison.js'
import { INTENT_LABELS } from './lib/responses.js'
import { MODEL } from './lib/modelContract.js'
import './Comparison.css'

const dispositionLabels = { matched: '判定', uncertain: '判断保留', unknown: '未分類' }
const sourceLabels = { generated: '生成ケース', 'review-example': 'レビュー例', manual: '手入力（今回）' }
const ms = (number) => typeof number === 'number' ? `${number.toFixed(number < 1 ? 3 : 1)} ms` : '未取得'
const differs = (row) => row.model && (row.dictionary.intent !== row.model.intent || row.dictionary.disposition !== row.model.disposition)

function Evaluation({ value, isModel = false }) {
  return <div className="evaluation">
    <div className="evaluation-title"><strong>{INTENT_LABELS[value.intent]}</strong><span className={`decision ${value.disposition}`}>{dispositionLabels[value.disposition]}</span></div>
    <p>{value.reason}</p>
    <p className="evidence">{isModel ? 'モデルが抽出した根拠' : '一致表現'}：{value.matches.map(({ text }) => text).join(' / ') || 'なし'}</p>
    <p className="timing">処理時間 {ms(value.elapsedMs)}</p>
    {isModel && <details><summary>時間の内訳・評価方式</summary><p>{value.engine} / {value.promptVersion}</p><p>読込 {ms(value.loadMs)} · 推論 {ms(value.inferenceMs)}</p><p>処理時間はローカルAPI往復を含みます。読込時間が短いことだけではコールド/ウォームを断定できません。</p></details>}
  </div>
}

export default function Comparison() {
  const [input, setInput] = useState('大丈夫じゃありません')
  const [inputCase, setInputCase] = useState(comparisonCases[0])
  const [rows, setRows] = useState([])
  const [running, setRunning] = useState(false)
  const [progress, setProgress] = useState('')
  const [status, setStatus] = useState('接続状態を確認中…')
  const [differencesOnly, setDifferencesOnly] = useState(false)
  const [error, setError] = useState('')
  const request = useRef(null)
  const progressRef = useRef(null)
  const serial = useRef(0)
  const composing = useRef(false)

  async function refreshStatus() {
    try {
      const response = await fetch('/api/language/status', { signal: AbortSignal.timeout(3000) })
      if (!response.ok) throw new Error('status')
      const data = await response.json()
      setStatus(data.message)
    } catch { setStatus('比較APIに未接続。辞書だけでも使えます。') }
  }
  useEffect(() => {
    let active = true
    fetch('/api/language/status', { signal: AbortSignal.timeout(3000) })
      .then((response) => response.json()).then((data) => { if (active) setStatus(data.message || '比較APIに未接続') })
      .catch(() => { if (active) setStatus('比較APIに未接続。辞書だけでも使えます。') })
    return () => { active = false; request.current?.abort() }
  }, [])

  const update = (id, fields) => setRows((current) => current.map((row) => row.runId === id ? { ...row, ...fields } : row))
  function makeRow(item) { return { ...item, runId: ++serial.current, dictionary: evaluateDictionary(item.input), phase: 'queued' } }

  async function run(items, batch = false) {
    if (running) return
    const controller = new AbortController()
    request.current = controller
    setError('')
    setDifferencesOnly(false)
    const next = items.map(makeRow)
    setRows((current) => batch ? next : [...next, ...current])
    setRunning(true)
    let completed = 0
    let failures = 0
    requestAnimationFrame(() => progressRef.current?.scrollIntoView({ block: 'start' }))
    try {
      for (const row of next) {
        if (controller.signal.aborted) break
        update(row.runId, { phase: 'running' })
        setProgress(`${completed + failures + 1} / ${next.length} 件を比較中。初回は読み込みを含みます。`)
        try {
          const model = await requestModel(row.input, { signal: controller.signal })
          update(row.runId, { model, phase: 'done' })
          completed++
        } catch (failure) {
          failures++
          update(row.runId, { phase: controller.signal.aborted ? 'cancelled' : 'error', error: failure.message, diagnostic: failure.diagnostic })
          setError(failure.message)
          // Keep format failures observable; stop only on transport failure or cancellation.
          if (failure.code !== 'invalid_output') break
        }
      }
    } finally {
      setRows((current) => current.map((row) => next.some((item) => item.runId === row.runId) && row.phase === 'queued'
        ? { ...row, phase: 'skipped' } : row))
      setProgress(`モデル：正常 ${completed} 件 / エラー・中止 ${failures} 件 / 未実行 ${next.length - completed - failures} 件`)
      setRunning(false)
      request.current = null
    }
  }
  function submit(event) {
    event.preventDefault()
    if (composing.current || !input.trim()) return
    run([inputCase ?? { input: input.trim(), source: 'manual', group: '自由入力' }])
  }
  function dictionaryOnly() {
    if (!input.trim()) return
    setDifferencesOnly(false)
    setRows((current) => [{ ...makeRow(inputCase ?? { input: input.trim(), source: 'manual', group: '自由入力' }), phase: 'dictionary-only' }, ...current])
    requestAnimationFrame(() => progressRef.current?.scrollIntoView({ block: 'start' }))
  }
  function exportResults() {
    const blob = new Blob([JSON.stringify({ recordedAt: new Date().toISOString(), model: MODEL, rows }, null, 2)], { type: 'application/json' })
    const url = URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url; link.download = 'whitespace-language-comparison.json'; link.click()
    setTimeout(() => URL.revokeObjectURL(url), 1000)
  }
  const visible = differencesOnly ? rows.filter((row) => differs(row) || row.error) : rows
  return <main className="comparison-shell">
    <header className="comparison-header"><p className="eyebrow">WHITESPACE / LANGUAGE LAB</p><h1>同じ言葉、ふたつの解釈。</h1><p>辞書と小型LLMの違いを観察する実験です。ゲームの信頼度・緊張度は変わりません。</p></header>
    <section className="model-status" aria-label="モデル接続"><div><strong>{MODEL}</strong><p role="status">{status}</p></div><button className="secondary" onClick={refreshStatus}>接続を確認</button></section>
    <form className="comparison-form" onSubmit={submit}>
      <label htmlFor="comparison-input">比較する言葉</label>
      <textarea id="comparison-input" value={input} maxLength={280} rows={2} onChange={(event) => { setInput(event.target.value); setInputCase(null) }}
        onCompositionStart={() => { composing.current = true }} onCompositionEnd={() => { composing.current = false }}
        onKeyDown={(event) => { if (event.key === 'Enter' && (event.nativeEvent.isComposing || event.keyCode === 229)) event.stopPropagation() }} />
      <div className="compare-actions"><button disabled={running || !input.trim()} type="submit">両方で比較する</button><button className="secondary" disabled={!input.trim()} type="button" onClick={dictionaryOnly}>辞書だけ試す</button><span>{input.length}/280 · Enterは改行</span></div>
    </form>
    <section className="case-controls" aria-label="比較ケース">
      <div><h2>少数の例を、まとめて観察</h2><p>28件：レビュー例3件＋生成例25件。実プレイヤーの入力記録ではありません。</p></div>
      <div className="compare-actions"><button className="secondary" disabled={running} onClick={() => run(comparisonCases, true)}>28例を一括比較</button>
        <select aria-label="例を入力欄へ" value="" disabled={running} onChange={(event) => { const example = comparisonCases.find((item) => item.id === event.target.value); if (example) { setInput(example.input); setInputCase(example) } }}><option value="">例を入力欄へ…</option>{comparisonCases.map((item) => <option key={item.id} value={item.id}>{item.id} {item.input}</option>)}</select></div>
      <p className="lab-note">一括比較は表示結果を入れ替え、順番にローカル推論します。接続失敗・タイムアウトで後続を止め、辞書結果を残します。形式不正は記録して次へ進みます。モデルの結論や理由も誤ることがあります。</p>
    </section>
    <div ref={progressRef} className="run-status" role="status" aria-live="polite">{running && <span className="spinner" aria-hidden="true" />}{progress}{running && <button className="secondary" onClick={() => request.current?.abort()}>中止</button>}</div>
    {error && <p className="lab-error" role="alert">{error}</p>}
    {rows.length > 0 && <div className="result-controls"><label><input type="checkbox" checked={differencesOnly} onChange={(event) => setDifferencesOnly(event.target.checked)} />判定の違い・エラーだけ ({rows.filter((row) => differs(row) || row.error).length})</label><button className="secondary" onClick={exportResults}>結果JSONを保存</button></div>}
    <section className="comparison-results" aria-label="比較結果" aria-busy={running}>
      {visible.length === 0 && <p className="empty-results">{rows.length ? 'この条件に合う結果はありません。' : '言葉を送ると、ここに2つの解釈を並べます。'}</p>}
      {visible.map((row) => <article key={row.runId} className={`comparison-row ${differs(row) ? 'different' : ''}`}>
        <header><span className="case-source">{sourceLabels[row.source]} · {row.group}</span><h2>{row.input}</h2>{differs(row) && <span className="difference-label">判定に違いあり</span>}</header>
        <div className="comparison-columns"><section aria-label="辞書の評価"><h3>辞書 <small>{row.dictionary.engine}</small></h3><Evaluation value={row.dictionary} /></section>
          <section aria-label="モデルの評価"><h3>ローカルLLM</h3>{row.model ? <Evaluation value={row.model} isModel /> : <p className={row.error ? 'lab-error' : 'pending-result'}>{row.error || ({ running: '読み込み・推論中…（最大120秒）', queued: '順番待ち', skipped: '未実行（中止または先行エラー）', 'dictionary-only': '未実行（辞書のみ）', cancelled: '中止' }[row.phase] || '未実行')}</p>}</section></div>
        {row.diagnostic && <details className="expected"><summary>失敗したモデル応答と時間（判定には不採用）</summary><p>処理 {ms(row.diagnostic.elapsedMs)} · 読込 {ms(row.diagnostic.loadMs)} · 推論 {ms(row.diagnostic.inferenceMs)}</p><pre>{row.diagnostic.raw || '応答を取得できませんでした。'}</pre></details>}
        {row.expected && <details className="expected"><summary>作成時の暫定期待（正解の保証ではありません）</summary><p>{INTENT_LABELS[row.expected.intent]} / {dispositionLabels[row.expected.disposition]}。期待値はモデルに渡していません。</p></details>}
      </article>)}
    </section>
    <p className="lab-note">推論先はこのPCのOllamaです。クラウド推論は使いません。入力と結果はこの画面だけに保持し、保存ボタンを押した場合にJSONを書き出します。</p>
  </main>
}
