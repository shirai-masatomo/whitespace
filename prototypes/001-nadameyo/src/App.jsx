import { useRef, useState } from 'react'
import './App.css'
import Character from './Character.jsx'
import intentDictionary from './data/intent-dictionary.json'
import { createIntentEvaluator } from './lib/intentMatcher.js'
import { advanceGame, createInitialState, INITIAL_REPLY, LIMITS } from './lib/gameEngine.js'
import { describeChange, describeReply, getReflection, INTENT_LABELS } from './lib/responses.js'

const evaluate = createIntentEvaluator(intentDictionary)

function Meter({ label, value, max, tone, hint }) {
  return <div className="meter">
    <div className="meter-heading"><span>{label}</span><strong>{value} / {max}</strong></div>
    <div className="meter-track" role="meter" aria-label={label} aria-valuenow={value}
      aria-valuemin={0} aria-valuemax={max} style={{ gridTemplateColumns: `repeat(${max}, 1fr)` }}>
      {Array.from({ length: max }, (_, index) => <span key={index}
        className={index < value ? `meter-cell ${tone}` : 'meter-cell'} />)}
    </div>
    <small>{hint}</small>
  </div>
}

function App() {
  const [input, setInput] = useState('')
  const [game, setGame] = useState(createInitialState)
  const [round, setRound] = useState(0)
  const [reducedMotion, setReducedMotion] = useState(false)
  const inputRef = useRef(null)
  const characterRef = useRef(null)
  const composing = useRef(false)
  const last = game.history.at(-1)
  const ended = game.result !== 'playing'
  const reflection = getReflection(game)

  function submitLine(event) {
    event.preventDefault()
    if (composing.current || !input.trim() || ended) return
    setGame((current) => advanceGame(current, input, evaluate))
    setInput('')
    inputRef.current?.focus({ preventScroll: true })
    requestAnimationFrame(() => characterRef.current?.scrollIntoView({ block: 'start' }))
  }

  function restart() {
    setRound((value) => value + 1)
    setGame(createInitialState())
    setInput('')
    requestAnimationFrame(() => characterRef.current?.scrollIntoView({ block: 'start' }))
  }

  return <main className="game-shell">
    <header className="game-header">
      <div><p className="eyebrow">WHITESPACE / EXPERIMENT 001</p><h1>宥めよ<span>言葉で、距離を変える。</span></h1></div>
      <p className="turn-counter">残り発言数 <strong>{game.turnsLeft}</strong><span> / {LIMITS.turns}</span></p>
    </header>
    <p className="intro">閉じかけた会話を、もう一度。5回の言葉で、相手が話せるところまで近づこう。</p>
    <section className="status-panel" aria-label="現在の状態">
      <Meter label="信頼度" value={game.trust} max={LIMITS.trust} tone="trust" hint="4で、相手が心を開く" />
      <Meter label="緊張度" value={game.tension} max={LIMITS.tension} tone="danger" hint="5で、会話が閉じる" />
    </section>
    <Character key={round} game={game} stageRef={characterRef} manualReduced={reducedMotion} onReducedChange={setReducedMotion} />
    <div className="play-layout">
      <div className="dialogue-panel">
        <section className="conversation" aria-label="相手の反応" aria-live="polite" aria-atomic="true">
          <p className="speaker"><span className={`signal ${game.tension >= 4 ? 'tense' : ''}`} />相手
            <span className="mood">{ended ? '会話を終えて' : game.tension >= 4 ? '声がこわばっている' : game.trust >= 2 ? '少し、目が合う' : 'まだ、距離がある'}</span></p>
          <p className="reply">{last ? describeReply(last) : INITIAL_REPLY}</p>
          <p className="change">{last ? `${describeChange(last)} · 発言 −1` : 'まずは、あなたから一言。'}</p>
        </section>
        {!ended ? <form className="line-form" onSubmit={submitLine}>
          <div className="form-heading"><label htmlFor="line">あなたの言葉</label><span>{input.length} / 80</span></div>
          <div className="input-row">
            <input key="playing" ref={inputRef} autoComplete="off" id="line" maxLength={80}
              aria-describedby="input-help" value={input} onChange={(event) => setInput(event.target.value)}
              onCompositionStart={() => { composing.current = true }}
              onCompositionEnd={() => { composing.current = false }}
              onKeyDown={(event) => { if (event.key === 'Enter' && (event.nativeEvent.isComposing || event.keyCode === 229)) event.preventDefault() }}
              placeholder="今、相手に伝えたいこと" />
            <button type="submit" disabled={!input.trim()}>送る</button>
          </div>
          <p id="input-help">Enterで送信。聞き返しでも1回消費し、数値は変わりません。</p>
        </form> : <section className={`result ${game.result}`} aria-label="会話の結果" aria-live="polite">
          <p className="eyebrow">{game.result === 'succeeded' ? '成功 · 会話がひらいた' : game.endReason === 'tension' ? '失敗 · 緊張が限界に達した' : '失敗 · 発言数を使い切った'}</p>
          <h2>会話のふり返り</h2><p>{reflection.advice}</p>
          <p className="reflection-counts">届いた言葉 {reflection.heard} · 聞き返し {reflection.uncertain} · 繰り返し {reflection.repeated} · 歩み寄り {reflection.repairs}</p>
          <button autoFocus onClick={restart} type="button">もう一度</button>
        </section>}
      </div>
      <details className="guide" aria-label="遊び方">
        <summary>会話の手がかり・遊び方</summary>
        <h2>一言ずつ、<br />相手の反応を。</h2>
        <p>謝る、話を聞く、安心を伝える。違う言葉で、少しずつ信頼を重ねます。</p>
        <p>同じ文を繰り返しても信頼は増えません。強い言葉の直後に、まだ使っていない謝罪の言葉を送ると緊張を1戻します。</p>
        <details><summary>最初の言葉に迷ったら</summary><p>「ごめん」「話を聞くよ」「ここにいるよ」など。どれか一つから、相手の返答を読んでみよう。</p></details>
        <p className="prototype-note">言葉を理解しきれないときは聞き返す、小さな会話の試作です。</p>
      </details>
    </div>
    {game.history.length > 0 && <details className="history-panel" aria-label="会話履歴">
      <summary>ここまでの言葉 · {game.history.length}往復</summary>
      <ol className="history">{[...game.history].reverse().map((entry, index) => <li key={game.history.length - index}>
        <span className="history-number">{String(game.history.length - index).padStart(2, '0')}</span>
        <div><p className="your-line">{entry.line}</p><p className="history-reply">{describeReply(entry)}</p><small>{describeChange(entry)}</small></div>
      </li>)}</ol>
    </details>}
    {import.meta.env.DEV && <details className="debug"><summary>開発用：判定の内訳</summary>
      {last ? <dl><dt>評価器 / 意味</dt><dd>{last.evaluation.engine} / {INTENT_LABELS[last.evaluation.intent]} ({last.evaluation.disposition})</dd>
        <dt>正規化した入力</dt><dd>{last.evaluation.normalizedInput}</dd>
        <dt>一致した表現</dt><dd>{last.evaluation.matches.map((match) => `${match.text} [${match.status}]`).join('、') || 'なし'}</dd>
        <dt>判断理由</dt><dd>{last.evaluation.reason}</dd>
        <dt>会話の文脈</dt><dd>反復: {last.repeated ? 'あり' : 'なし'} / 歩み寄り: {last.repair ? 'あり' : 'なし'}</dd></dl>
        : <p>送信すると、一致した表現と判断理由がここに表示されます。</p>}
    </details>}
    <footer>WHITESPACE <span>ことばの実験室</span></footer>
  </main>
}

export default App
