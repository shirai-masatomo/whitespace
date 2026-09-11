import { useEffect, useRef, useState } from 'react'
import Character from './Character.jsx'
import CoffeeTable from './CoffeeTable.jsx'
import { CONDITIONS, CHOICES, createCoffeeScene, stepCoffeeScene, choiceInterpretation, visibleScene, sceneSnapshot, coffeeCandidates } from './lib/coffeeScene.js'
import { coffeeCharacter } from './lib/coffeeCharacter.js'
import { coffeeLanguageRequest } from './lib/coffeeLanguage.js'
import './CoffeeScene.css'
import { CIRCUMSTANCES } from './lib/coffeeCircumstances.js'
import { COFFEE_ENTRIES } from './lib/coffeePresentation.js'
const actorName = actor => ({ player: 'あなた', partner: '相手', scene: '情景' })[actor]
export default function CoffeeScene() {
  const [scene, setScene] = useState(() => createCoffeeScene())
  const [round, setRound] = useState(0), [reduced, setReduced] = useState(false)
  const [input, setInput] = useState(''), [pending, setPending] = useState(false), [result, setResult] = useState(null), [error, setError] = useState('')
  const request = useRef(null), dialogue = useRef(null)
  useEffect(() => () => request.current?.abort(), [])
  const known = visibleScene(scene), last = scene.history.at(-1), candidates = coffeeCandidates(scene)
  function cancel() { request.current?.abort(); request.current = null; setPending(false) }
  function restart(condition, circumstance = condition === scene.condition ? scene.partner.circumstance : 'cleanup') { cancel(); setScene(createCoffeeScene(condition, circumstance)); setRound(x => x + 1); setInput(''); setResult(null); setError('') }
  function apply(interpretation, text, focusScene = true) { cancel(); setScene(current => stepCoffeeScene(current, interpretation, text)); setResult(null); setInput(''); setError(''); if (focusScene) requestAnimationFrame(() => { if (dialogue.current?.getBoundingClientRect().top < -60) dialogue.current.scrollIntoView({ block: 'start' }) }) }
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
    <fieldset className="coffee-entry"><legend>あなたは、この場にどう居合わせた？</legend><div className="coffee-entry-options">{Object.entries(COFFEE_ENTRIES).map(([id, entry]) => <label key={id}><input type="radio" name="coffee-entry" value={id} checked={scene.condition === id} onChange={() => restart(id)} /><span>{entry.label}</span></label>)}</div><small>選び直すと、場面を最初から。</small></fieldset>
    <details className="coffee-circumstances"><summary>同じ場面で、事情を変えてみる</summary><label htmlFor="circumstance">相手が気にしていること</label><select id="circumstance" value={scene.partner.circumstance} onChange={e => restart('A', e.target.value)}>{Object.entries(CIRCUMSTANCES).map(([id, label]) => <option key={id} value={id}>{label}</option>)}</select><p>比較は「後から来た友人」に揃えます。選び直すと会話と物の状態を初期化します。ここで選ぶ事情を、主人公が最初から知っているわけではありません。</p></details>
    <div ref={dialogue} className="coffee-focus">
      <p className="coffee-setting">{COFFEE_ENTRIES[scene.condition].intro}</p>
      <div className={`coffee-set ${scene.relationship.distance} ${reduced ? 'reduced' : ''}`}><Character key={round} displayState={coffeeCharacter(scene)} manualReduced={reduced} onReducedChange={setReduced} /><CoffeeTable scene={scene} reduced={reduced} /></div>
      <section className="coffee-response" aria-label="最新のやり取り" aria-live="polite">
        {last && <p className="coffee-your-line">あなた{last.kind === 'speech' ? '：「' + last.input + '」' : ' · ' + last.input}</p>}
        <div className="coffee-stage-directions">{scene.events.filter(event => event.type !== 'offer-paper' || !scene.events.some(e => e.type === 'receive')).map((event, index) => <p key={index}><span>{actorName(event.actor)}</span>{event.text}</p>)}</div>
        {scene.reply && <blockquote><span>{scene.relationship.type === 'friend' ? '友人' : '近くの席の人'}</span><p>「{scene.reply}」</p></blockquote>}
      </section>
      <section className="coffee-controls" aria-label="発言と行動"><div><h2>声をかける</h2><div className="coffee-choices">{candidates.filter(x => x.kind === 'speech' && !x.secondary).map(x => <button key={x.act} data-act={x.act} onClick={() => apply(choiceInterpretation(x.act), x.label)}>{x.label}</button>)}</div><details className="coffee-other-lines"><summary>ほかの言い方</summary><div className="coffee-choices">{candidates.filter(x => x.secondary).map(x => <button key={x.act} onClick={() => apply(choiceInterpretation(x.act), x.label)}>{x.label}</button>)}</div></details></div>
        <div><h2>動く</h2><div className="coffee-choices actions">{candidates.filter(x => x.kind === 'action').map(x => <button key={x.act} data-act={x.act} className="secondary" disabled={x.disabled} title={x.note || undefined} onClick={() => apply(choiceInterpretation(x.act), x.label)}>{x.label}{x.note && <small>{x.note}</small>}</button>)}</div></div>
      </section>
    </div>
    <div className="coffee-drawers">
      <details className="coffee-notes"><summary>見聞きしたこと</summary><h3>場面の始まり</h3><p>{CONDITIONS[scene.condition].intro}</p><ul>{Object.entries(known).filter(([key]) => key !== 'role').map(([key,value]) => <li key={key}>{value}</li>)}</ul></details>
      <details className="coffee-history"><summary>やり取りを振り返る · {scene.history.length}件</summary>{!last ? <p>まだやり取りはありません。</p> : <ol>{scene.history.map(x => <li key={x.id}><strong>{x.id}. あなた / {x.kind === 'action' ? '行動の選択' : '発言'}：{x.input}</strong>{x.events.map((e,i) => <p className="coffee-history-event" key={i}>{actorName(e.actor)} / {e.text}</p>)}{x.reply && <p>相手：「{x.reply}」</p>}<small>{x.interpretation.source === 'choice' ? '選択肢' : 'モデル解釈を確認して採用'}</small></li>)}</ol>}</details>
      <details className="coffee-language"><summary>自分の言葉で話す · 実験中</summary><p>ローカルモデルで解釈し、確認してから会話へ進めます。未起動・失敗時も選択肢を使えます。</p>
        <form onSubmit={interpret}><label htmlFor="coffee-input">あなたの発言・行動</label><textarea id="coffee-input" maxLength={280} rows={2} value={input} onChange={e => { setInput(e.target.value); setResult(null) }} disabled={pending} placeholder="例：ティッシュ、使いますか？" /><div className="coffee-choices"><button disabled={pending || !input.trim()}>{pending ? '解釈を待っています…' : '解釈を確認する'}</button>{pending && <button type="button" className="secondary" onClick={() => { cancel(); setError('解釈を中止しました。') }}>中止</button>}</div></form>
        {error && <p role="alert">{error}</p>}
        {result && <div className="coffee-interpretation" role="status"><p><strong>{result.interpretation.status === 'matched' ? CHOICES.find(x => x.act === result.interpretation.act)?.label : result.interpretation.status === 'unsupported' ? '未対応の行為' : '確認が必要'}</strong> / {result.interpretation.target}</p><p>{result.interpretation.reason}</p><p>根拠：「{result.interpretation.evidence || 'なし'}」 · {(result.elapsedMs / 1000).toFixed(2)}秒</p><button onClick={() => apply(result.interpretation, result.input)}>{result.interpretation.status === 'matched' ? 'この解釈で進める' : '聞き返しとして会話に残す'}</button><button className="secondary" onClick={() => setResult(null)}>採用しない</button></div>}
      </details>
      <details className="coffee-lab"><summary>操作と内部情報を検証する</summary><p>現在の条件：{CONDITIONS[scene.condition].label}。通常画面は手元にない物の操作を無効にしますが、対応行為は変わりません。</p>
        <details><summary>全{CHOICES.length}操作を試す（繰り返し・不適切な順番も含む）</summary><div className="coffee-choices">{CHOICES.map(x => <button className="secondary" key={x.act} onClick={() => apply(choiceInterpretation(x.act), x.label, false)}>検証：{x.label}</button>)}</div></details>
        {import.meta.env.DEV && <details className="coffee-debug"><summary>内部情報・判断理由（未開示の事実を含む）</summary><p>{scene.reason}</p><pre>{JSON.stringify(sceneSnapshot(scene), null, 2)}</pre>{last && <><h3>分岐・解釈・開示の根拠・変更前後</h3><pre>{JSON.stringify({ branch: last.branch, interpretation: last.interpretation, disclosures: last.disclosures, wishes: last.wishes, automatic: last.automatic, changes: last.changes, before: last.before, after: last.after }, null, 2)}</pre></>}</details>}
      </details>
    </div>
  </main>
}
