import { useState } from 'react'
import './App.css'

const MAX_TENSION = 5
const SUCCESS_TRUST = 4
const MAX_TURNS = 5

const openingLine = '……もういい。全部、わかってるんだろ。'

const trustWords = [
  { word: 'ごめん', reply: '……謝れば済むと思ってるわけじゃ、ないよな。' },
  { word: '大丈夫', reply: '大丈夫って……どうして、そう言える。' },
  { word: '聞かせて', reply: '……聞いて、どうするつもりだ。' },
]

const tensionWords = [
  { word: '落ち着いて', amount: 1, reply: '落ち着け？　簡単に言うなよ。' },
  { word: 'お前', amount: 2, reply: '……その呼び方、やめろ。' },
  { word: '知らない', amount: 2, reply: '知らない？　じゃあ、どうしてここにいる。' },
]

function clamp(value, min, max) {
  return Math.min(Math.max(value, min), max)
}

function evaluateLine(line) {
  const trustMatch = trustWords.find(({ word }) => line.includes(word))
  const tensionMatch = tensionWords.find(({ word }) => line.includes(word))

  if (tensionMatch) {
    return {
      trustChange: 0,
      tensionChange: tensionMatch.amount,
      reply: tensionMatch.reply,
    }
  }

  if (trustMatch) {
    return {
      trustChange: 1,
      tensionChange: 0,
      reply: trustMatch.reply,
    }
  }

  return {
    trustChange: 0,
    tensionChange: 1,
    reply: '……それで、何が言いたい。',
  }
}

function Meter({ label, value, max, tone }) {
  return (
    <div className="meter">
      <div className="meter-heading">
        <span>{label}</span>
        <strong>
          {value} / {max}
        </strong>
      </div>
      <div className="meter-track" aria-label={`${label}: ${value} / ${max}`}>
        {Array.from({ length: max }, (_, index) => (
          <span
            className={index < value ? `meter-cell active ${tone}` : 'meter-cell'}
            key={index}
          />
        ))}
      </div>
    </div>
  )
}

function App() {
  const [input, setInput] = useState('')
  const [tension, setTension] = useState(2)
  const [trust, setTrust] = useState(0)
  const [turnsLeft, setTurnsLeft] = useState(MAX_TURNS)
  const [reply, setReply] = useState(openingLine)
  const [history, setHistory] = useState([])
  const [result, setResult] = useState('playing')

  function submitLine(event) {
    event.preventDefault()

    const line = input.trim()
    if (!line || result !== 'playing') return

    const evaluation = evaluateLine(line)
    const nextTension = clamp(tension + evaluation.tensionChange, 0, MAX_TENSION)
    const nextTrust = clamp(trust + evaluation.trustChange, 0, SUCCESS_TRUST)
    const nextTurnsLeft = turnsLeft - 1

    let nextResult = 'playing'
    let nextReply = evaluation.reply

    if (nextTension >= MAX_TENSION) {
      nextResult = 'failed'
      nextReply = '……もう、話すことはない。'
    } else if (nextTrust >= SUCCESS_TRUST) {
      nextResult = 'succeeded'
      nextReply = '……少しだけなら。話してもいい。'
    } else if (nextTurnsLeft === 0) {
      nextResult = 'failed'
      nextReply = '……遅すぎた。'
    }

    setTension(nextTension)
    setTrust(nextTrust)
    setTurnsLeft(nextTurnsLeft)
    setReply(nextReply)
    setResult(nextResult)
    setHistory((current) => [...current, { line, reply: nextReply }])
    setInput('')
  }

  function restart() {
    setInput('')
    setTension(2)
    setTrust(0)
    setTurnsLeft(MAX_TURNS)
    setReply(openingLine)
    setHistory([])
    setResult('playing')
  }

  return (
    <main className="game-shell">
      <header className="game-header">
        <p className="eyebrow">DIRECTIVE 001</p>
        <h1>宥めよ</h1>
        <p className="turn-counter">残り発言数 {turnsLeft}</p>
      </header>

      <section className="status-panel" aria-label="現在の状態">
        <Meter label="緊張度" value={tension} max={MAX_TENSION} tone="danger" />
        <Meter label="信頼度" value={trust} max={SUCCESS_TRUST} tone="trust" />
      </section>

      <section className="conversation" aria-live="polite">
        <p className="speaker">相手</p>
        <p className="reply">「{reply}」</p>
      </section>

      {history.length > 0 && (
        <ol className="history" aria-label="会話履歴">
          {history.map((entry, index) => (
            <li key={`${entry.line}-${index}`}>
              <span>あなた: {entry.line}</span>
              <small>相手: {entry.reply}</small>
            </li>
          ))}
        </ol>
      )}

      {result === 'playing' ? (
        <form className="line-form" onSubmit={submitLine}>
          <label htmlFor="line">あなたの言葉</label>
          <div className="input-row">
            <input
              autoComplete="off"
              autoFocus
              id="line"
              maxLength="80"
              onChange={(event) => setInput(event.target.value)}
              placeholder="一文だけ入力する"
              value={input}
            />
            <button disabled={!input.trim()} type="submit">
              送る
            </button>
          </div>
        </form>
      ) : (
        <section className={`result ${result}`}>
          <p>{result === 'succeeded' ? '成功' : '失敗'}</p>
          <button onClick={restart} type="button">
            もう一度
          </button>
        </section>
      )}
    </main>
  )
}

export default App
