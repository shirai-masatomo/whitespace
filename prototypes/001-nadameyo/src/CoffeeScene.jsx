import { useEffect, useRef, useState } from 'react'
import Character from './Character.jsx'
import { CONDITIONS, CHOICES, createCoffeeScene, stepCoffeeScene, choiceInterpretation, visibleScene, sceneSnapshot } from './lib/coffeeScene.js'
import { coffeeCharacter } from './lib/coffeeCharacter.js'
import { coffeeLanguageRequest } from './lib/coffeeLanguage.js'
import './CoffeeScene.css'
export default function CoffeeScene() {
  const [scene, setScene] = useState(() => createCoffeeScene())
  const [round, setRound] = useState(0), [reduced, setReduced] = useState(false)
  const [input, setInput] = useState(''), [pending, setPending] = useState(false), [result, setResult] = useState(null), [error, setError] = useState('')
  const request = useRef(null), dialogue = useRef(null)
  useEffect(() => () => request.current?.abort(), [])
  const known = visibleScene(scene), last = scene.history.at(-1)
  function cancel() { request.current?.abort(); request.current = null; setPending(false) }
  function restart(condition) { cancel(); setScene(createCoffeeScene(condition)); setRound(x => x + 1); setInput(''); setResult(null); setError('') }
  function apply(interpretation, text) { cancel(); setScene(current => stepCoffeeScene(current, interpretation, text)); setResult(null); setInput(''); setError(''); requestAnimationFrame(() => dialogue.current?.scrollIntoView({ block: 'start' })) }
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
    <header className="coffee-header"><p className="coffee-eyebrow">CONTEXT STUDY / 01</p><h1>こぼれたコーヒー</h1><p>同じ言葉を、違う間柄で。知る・提案する・渡す、そのあいだを試す。</p>
      <div className="coffee-condition"><label>固定条件 <select value={scene.condition} onChange={e => restart(e.target.value)}>{Object.entries(CONDITIONS).map(([id, item]) => <option key={id} value={id}>{item.label}</option>)}</select></label><button className="secondary" onClick={() => restart(scene.condition)}>この条件で再開始</button></div>
      <p className="coffee-hint">切替・再開始で会話、知識、物を初期化します。得点・手数制限はありません。</p>
    </header>
    <div className="coffee-layout"><section className="coffee-observation" aria-label="主人公が知っている状況"><h2>あなたに見えていること</h2><details className="coffee-intro"><summary>開始時に見たこと</summary><p>{CONDITIONS[scene.condition].intro}</p></details>
      <ul className="coffee-facts">{Object.entries(known).filter(([key]) => key !== 'role').map(([key, value]) => <li key={key}>{value}</li>)}</ul>
      <div className={`coffee-table ${scene.environment.table}`} aria-hidden="true"><span className="coffee-cup">◯</span><span className="coffee-puddle" /><span className="coffee-paper">{scene.environment.tissue === 'used' ? '使用済み' : scene.environment.tissue === 'partner' ? '相手の手元' : 'あなたの手元'}</span></div>
      <p className="coffee-hint">「渡す」の後も机は濡れたまま。「様子を見る」で相手が拭くところまで進みます。</p>
    </section><div ref={dialogue} className="coffee-dialogue"><Character key={round} displayState={coffeeCharacter(scene)} manualReduced={reduced} onReducedChange={setReduced} />
      <section className="coffee-reply" aria-label="相手の返答" aria-live="polite"><span>相手 / {scene.relationship.type === 'friend' ? '友人' : '近くの席の人'}</span><p>{scene.reply}</p></section>
      <section className="coffee-controls" aria-label="発言と行動"><h2>言葉をかける</h2><div className="coffee-choices">{CHOICES.filter(x => x.kind === 'speech').map(x => <button key={x.act} onClick={() => apply(choiceInterpretation(x.act), x.label)}>{x.label}</button>)}</div>
        <h2>行動する</h2><div className="coffee-choices actions">{CHOICES.filter(x => x.kind === 'action').map(x => <button key={x.act} className="secondary" onClick={() => apply(choiceInterpretation(x.act), x.label)}>{x.label}</button>)}</div>
      </section></div></div>
    <details className="coffee-language"><summary>自分の言葉で試す · ローカルモデル実験</summary><p>現在の発言・あなたの既知情報・直近5往復をローカルモデルで解釈します。解釈を見てから実行できます。未起動・失敗時も上の選択肢を使えます。</p>
      <form onSubmit={interpret}><label htmlFor="coffee-input">あなたの発言・行動</label><textarea id="coffee-input" maxLength={280} rows={2} value={input} onChange={e => { setInput(e.target.value); setResult(null) }} disabled={pending} placeholder="例：ティッシュ、使いますか？" /><div className="coffee-choices"><button disabled={pending || !input.trim()}>{pending ? '解釈を待っています…' : '解釈を確認する'}</button>{pending && <button type="button" className="secondary" onClick={() => { cancel(); setError('解釈を中止しました。') }}>中止</button>}</div></form>
      {error && <p role="alert">{error}</p>}
      {result && <div className="coffee-interpretation" role="status"><p><strong>{result.interpretation.status === 'matched' ? CHOICES.find(x => x.act === result.interpretation.act)?.label : result.interpretation.status === 'unsupported' ? '未対応の行為' : '確認が必要'}</strong> / {result.interpretation.target}</p><p>{result.interpretation.reason}</p><p>入力内の根拠：「{result.interpretation.evidence || 'なし'}」 · {(result.elapsedMs / 1000).toFixed(2)}秒（読込 {(result.loadMs / 1000).toFixed(2)}秒）</p><button onClick={() => apply(result.interpretation, result.input)}>{result.interpretation.status === 'matched' ? 'この解釈で進める' : '聞き返しとして会話に残す'}</button><button className="secondary" onClick={() => setResult(null)}>採用しない</button></div>}
    </details>
    <details className="coffee-history"><summary>会話と行動の記録 · {scene.history.length}件</summary>{scene.history.length === 0 ? <p>まだやり取りはありません。</p> : <ol>{[...scene.history].reverse().map(x => <li key={x.id}><strong>{x.id}. {x.kind === 'action' ? '行動' : '発言'}：{x.input}</strong><p>{x.reply}</p><small>{x.interpretation.source === 'choice' ? '選択肢' : 'ローカルモデルの解釈を確認して採用'}</small></li>)}</ol>}</details>
    {import.meta.env.DEV && <details className="coffee-debug"><summary>開発用：世界の事実・判断理由（プレイヤーには未開示の情報を含む）</summary><h2>固定条件 {scene.condition}</h2><p>{scene.reason}</p><h3>世界と知識を分けた現在の状態</h3><pre>{JSON.stringify(sceneSnapshot(scene), null, 2)}</pre>{last && <><h3>今回の解釈</h3><pre>{JSON.stringify(last.interpretation, null, 2)}</pre><h3>更新した項目</h3><pre>{JSON.stringify(last.changes, null, 2)}</pre><details><summary>更新前 → 更新後</summary><pre>{JSON.stringify({ before: last.before, after: last.after }, null, 2)}</pre></details></>}</details>}
  </main>
}
