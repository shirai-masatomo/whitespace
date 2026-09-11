import { useEffect, useRef, useState } from 'react'
import Character from './Character.jsx'
import CoffeeTable from './CoffeeTable.jsx'
import { CONDITIONS, CHOICES, createCoffeeScene, stepCoffeeScene, choiceInterpretation, visibleScene, sceneSnapshot, coffeeCandidates } from './lib/coffeeScene.js'
import { coffeeCharacter } from './lib/coffeeCharacter.js'
import { coffeeLanguageRequest } from './lib/coffeeLanguage.js'
import './CoffeeScene.css'
import { CIRCUMSTANCES } from './lib/coffeeCircumstances.js'
import { COFFEE_ENTRIES, pickBlindCircumstance, presentedEvents } from './lib/coffeePresentation.js'
const actorName = actor => ({ player: 'あなた', partner: '相手', scene: '情景' })[actor]
export default function CoffeeScene() {
  const [scene, setScene] = useState(() => createCoffeeScene())
  const [settingsOpen, setSettingsOpen] = useState(true), [blind, setBlind] = useState(false), [revealed, setRevealed] = useState(false)
  const [comparison, setComparison] = useState('cleanup')
  const [round, setRound] = useState(0), [reduced, setReduced] = useState(false)
  const [input, setInput] = useState(''), [pending, setPending] = useState(false), [result, setResult] = useState(null), [error, setError] = useState('')
  const request = useRef(null), dialogue = useRef(null)
  useEffect(() => () => request.current?.abort(), [])
  const known = visibleScene(scene), last = scene.history.at(-1), candidates = coffeeCandidates(scene), events = presentedEvents(scene)
  const sequence = Boolean(last?.automatic.length)
  function cancel() { request.current?.abort(); request.current = null; setPending(false) }
  function restart(condition, circumstance = condition === scene.condition ? scene.partner.circumstance : 'cleanup') { cancel(); setRevealed(false); setComparison(circumstance); setScene(createCoffeeScene(condition, circumstance)); setRound(x => x + 1); setInput(''); setResult(null); setError('') }
  function apply(interpretation, text, focusScene = true) { cancel(); setSettingsOpen(false); setScene(current => stepCoffeeScene(current, interpretation, text)); setResult(null); setInput(''); setError(''); if (focusScene) requestAnimationFrame(() => { if (dialogue.current?.getBoundingClientRect().top < -60) dialogue.current.scrollIntoView({ block: 'start' }) }) }
  async function interpret(event) {
    event.preventDefault(); if (!input.trim() || pending) return
    const controller = new AbortController(); request.current = controller
    setPending(true); setError(''); setResult(null)
    try {
      const response = await fetch('/api/coffee/evaluate', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(coffeeLanguageRequest(scene, input)), signal: AbortSignal.any([controller.signal, AbortSignal.timeout(50000)]) })
      const data = await response.json()
      if (!response.ok) throw new Error(data.error || 'モデルの応答に失敗しました。')
      if (request.current === controller) setResult({ ...data, input })
    } catch (err) { if (request.current === controller) setError(err.name === 'TimeoutError' ? '50秒で待機を終了しました。選択肢を使えます。' : err.name === 'AbortError' ? '解釈を中止しました。' : err.message) }
    finally { if (request.current === controller) { request.current = null; setPending(false) } }
  }
  return <main className="coffee-page">
    <header className="coffee-header"><div><p className="coffee-eyebrow">WHITESPACE / CAFÉ</p><h1>こぼれたコーヒー</h1></div><button className="secondary" onClick={() => restart(scene.condition)}>やり直す</button></header>
    <details className="coffee-settings" open={settingsOpen} onToggle={e => setSettingsOpen(e.currentTarget.open)}>
      <summary><span>あなたは誰？</span><span>{COFFEE_ENTRIES[scene.condition].label}{blind ? ' · 事情は伏せて' : ''}</span></summary>
      <fieldset className="coffee-entry" aria-label="立場を選ぶ"><div className="coffee-entry-options">{Object.entries(COFFEE_ENTRIES).map(([id, entry]) => <label key={id}><input type="radio" name="coffee-entry" value={id} checked={scene.condition === id} onChange={() => { setBlind(false); restart(id) }} /><span>{entry.label}</span></label>)}</div></fieldset>
      <div className="coffee-start-options"><button className="secondary" onClick={() => { restart('A', pickBlindCircumstance()); setBlind(true); setSettingsOpen(false) }}>事情を知らずに始める</button><small>友人の席へ。選び直すと最初から。</small></div>
      {blind && <div className="coffee-secret"><button className="secondary" onClick={() => { setBlind(false); setRevealed(true) }}>今回の事情を確かめる</button></div>}
      {revealed && <p className="coffee-revealed">今回の事情：{CIRCUMSTANCES[scene.partner.circumstance]}</p>}
    </details>
    <div ref={dialogue} className="coffee-focus">
      {!last && <p className="coffee-setting">{COFFEE_ENTRIES[scene.condition].intro}</p>}
      <div className={`coffee-set ${scene.relationship.distance} ${reduced ? 'reduced' : ''}`}><Character key={round} displayState={coffeeCharacter(scene)} manualReduced={reduced} onReducedChange={setReduced} /><CoffeeTable scene={scene} reduced={reduced} /></div>
      <section className="coffee-response" aria-label="最新のやり取り" aria-live="polite">
        {last && <p className="coffee-your-line">あなた{last.kind === 'speech' ? '：「' + last.input + '」' : ' · ' + last.input}</p>}
        {sequence ? <ol className="coffee-action-sequence" aria-label="起きた動作の順番">{events.map((event, index) => <li key={index}>{event.text}</li>)}</ol> : <div className="coffee-stage-directions">{events.map((event, index) => <p key={index}><span>{actorName(event.actor)}</span>{event.text}</p>)}</div>}
        {scene.reply && <blockquote><span>{scene.relationship.type === 'friend' ? '友人' : '近くの席の人'}</span><p>「{scene.reply}」</p></blockquote>}
      </section>
      <section className="coffee-action-area" aria-label="次の対応"><p className="coffee-action-prompt">あなたはどうする？</p><div className="coffee-controls"><div><h2>声をかける</h2><div className="coffee-choices">{candidates.filter(x => x.kind === 'speech' && !x.secondary).map(x => <button key={x.act} data-act={x.act} onClick={() => apply(choiceInterpretation(x.act), x.label)}>{x.label}</button>)}</div><details className="coffee-language"><summary>自分の言葉で話す <small>実験中</small></summary><p>言葉の受け取り方を確認してから、会話に反映します。</p>
        <form onSubmit={interpret}><label htmlFor="coffee-input">あなたの発言・行動</label><textarea id="coffee-input" maxLength={280} rows={2} value={input} onChange={e => { setInput(e.target.value); setResult(null) }} disabled={pending} placeholder="例：ティッシュ、使いますか？" /><div className="coffee-choices"><button disabled={pending || !input.trim()}>{pending ? '解釈を待っています…' : '解釈を確認する'}</button>{pending && <button type="button" className="secondary" onClick={() => { cancel(); setError('解釈を中止しました。') }}>中止</button>}</div></form>
        {error && <p role="alert">{error}</p>}
        {result && <div className="coffee-interpretation" role="status"><p><strong>{result.interpretation.status === 'matched' ? CHOICES.find(x => x.act === result.interpretation.act)?.label : result.interpretation.status === 'unsupported' ? '未対応の行為' : '確認が必要'}</strong></p><p>{result.interpretation.reason}</p><p>根拠：「{result.interpretation.evidence || 'なし'}」 · {(result.elapsedMs / 1000).toFixed(2)}秒</p><button onClick={() => apply(result.interpretation, result.input)}>{result.interpretation.status === 'matched' ? 'この解釈で進める' : '聞き返しとして会話に残す'}</button><button className="secondary" onClick={() => setResult(null)}>採用しない</button></div>}
      </details></div>
        <div><h2>動く</h2><div className="coffee-choices actions">{candidates.filter(x => x.kind === 'action').map(x => <button key={x.act} data-act={x.act} className="secondary" disabled={x.disabled} title={x.note || undefined} onClick={() => apply(choiceInterpretation(x.act), x.label)}>{x.label}{x.note && <small>{x.note}</small>}</button>)}</div></div>
      </div></section>
    </div>
    <div className="coffee-drawers">
      <details className="coffee-notes"><summary>見聞きしたこと</summary><ul>{Object.entries(known).filter(([key]) => key !== 'role').map(([key,value]) => <li key={key}>{value}</li>)}</ul></details>
      <details className="coffee-history"><summary>やり取りを振り返る · {scene.history.length}件</summary>{!last ? <p>まだやり取りはありません。</p> : <ol>{scene.history.map(x => <li key={x.id}><strong>{x.id}. あなた / {x.kind === 'action' ? '行動の選択' : '発言'}：{x.input}</strong>{x.events.map((e,i) => <p className="coffee-history-event" key={i}>{actorName(e.actor)} / {e.text}</p>)}{x.reply && <p>相手：「{x.reply}」</p>}<small>{x.interpretation.source === 'choice' ? '選択肢' : 'モデル解釈を確認して採用'}</small></li>)}</ol>}</details>
      <details className="coffee-lab"><summary>操作と内部情報を検証する</summary>
        {blind ? <p>事情は伏せています。確認するには、上の「あなたは誰？」を開いてください。</p> : <details className="coffee-circumstances"><summary>事情を選んで比べる</summary><label htmlFor="circumstance">再現する事情（後から来た友人）</label><select id="circumstance" value={comparison} onChange={e => setComparison(e.target.value)}>{Object.entries(CIRCUMSTANCES).map(([id, label]) => <option key={id} value={id}>{label}</option>)}</select><button className="secondary" onClick={() => restart('A', comparison)}>この事情でやり直す</button></details>}<p>現在の条件：{CONDITIONS[scene.condition].label}。通常画面は手元にない物の操作を無効にしますが、対応行為は変わりません。</p>
        <details><summary>全{CHOICES.length}操作を試す（繰り返し・不適切な順番も含む）</summary><div className="coffee-choices">{CHOICES.map(x => <button className="secondary" key={x.act} onClick={() => apply(choiceInterpretation(x.act), x.label, false)}>検証：{x.label}</button>)}</div></details>
        {import.meta.env.DEV && !blind && <details className="coffee-debug"><summary>内部情報・判断理由（未開示の事実を含む）</summary><p>{scene.reason}</p><pre>{JSON.stringify(sceneSnapshot(scene), null, 2)}</pre>{last && <><h3>分岐・解釈・開示の根拠・変更前後</h3><pre>{JSON.stringify({ branch: last.branch, interpretation: last.interpretation, disclosures: last.disclosures, wishes: last.wishes, automatic: last.automatic, changes: last.changes, before: last.before, after: last.after }, null, 2)}</pre></>}</details>}
      </details>
    </div>
  </main>
}
