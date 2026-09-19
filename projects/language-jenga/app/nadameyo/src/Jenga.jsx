import { useState } from 'react'
import App from './App.jsx'
import { LAYERS, labels, createGame, changeLayer, interpret, renderReply, removedCount, accomplished, undo, finish } from './lib/layers.js'
import './Jenga.css'

function Scene({ result, layers }) {
  const shared = result.scene === 'shared'
  const lent = result.scene === 'lent'
  const wet = layers.rain === 0
  const two = layers.umbrellas === 1
  return <svg className={`j-scene ${result.scene}`} viewBox="0 0 560 210" role="img" aria-label={`${result.title}。${wet ? '雨の駅前' : layers.rain === 1 ? '雨上がりの駅前' : '天気の層は未指定'}`}>
    <path d="M20 185H540 M410 55h100v130 M424 65h70v24" fill="none" stroke="#485864" strokeWidth="2" />
    <text x="436" y="82" fill="#aab9bf" fontSize="13">駅入口</text>
    {wet && Array.from({ length: 22 }, (_, i) => <path key={i} d={`M${25 + i * 24} ${8 + i % 4 * 22}l-8 18`} stroke="#647885" opacity=".5" />)}
    <g transform={`translate(${shared ? 245 : 185},115)`}><circle cy="-10" r="12" fill="#e5c8a7" /><path d="M0 4v42m0-28l-16 18m16-18l16 18m-16 10l-15 25m15-25l15 25" stroke="#e5c8a7" strokeWidth="7" fill="none" strokeLinecap="round" /></g>
    <g transform={`translate(${shared ? 285 : 330},115)`}><circle cy="-10" r="12" fill="#86b8b1" /><path d="M0 4v42m0-28l-16 18m16-18l16 18m-16 10l-15 25m15-25l15 25" stroke="#86b8b1" strokeWidth="7" fill="none" strokeLinecap="round" /></g>
    {(layers.umbrellas !== null || lent) && layers.rain !== 1 && <g transform={`translate(${shared ? 265 : lent ? 330 : 185},78)`}><path d="M-66 0Q0-76 66 0Z" fill="#dfb36a" /><path d="M0-38v82q0 14 12 10" stroke="#dfb36a" strokeWidth="4" fill="none" /></g>}
    {two && layers.rain !== 1 && !lent && <g transform="translate(330,78)"><path d="M-57 0Q0-67 57 0Z" fill="#80b4b0" /><path d="M0-33v77" stroke="#80b4b0" strokeWidth="4" /></g>}
    {layers.rain === 1 && (layers.umbrellas !== null || lent) && <path d={`M${lent ? 350 : 205} 138l-6 38h12Zm0 0v-12`} fill="#dfb36a" stroke="#dfb36a" strokeWidth="3" />}
    {layers.rain === 1 && two && <path d="M350 138l-6 38h12Zm0 0v-12" fill="#80b4b0" stroke="#80b4b0" strokeWidth="3" />}
    <text x={shared ? 237 : 175} y="205" fill="#e5c8a7" fontSize="12">自分</text><text x={shared ? 282 : 320} y="205" fill="#86b8b1" fontSize="12">相手</text>
  </svg>
}

export default function Jenga() {
  const [legacy, setLegacy] = useState(false)
  const [game, setGame] = useState(createGame)
  const [selected, setSelected] = useState('soft')
  const result = interpret(game.layers)
  const layer = LAYERS.find(l => l.id === selected)
  const value = game.layers[selected]
  const speech = LAYERS.filter(l => l.kind === 'speech' && game.layers[l.id] !== null)
  const change = next => setGame(s => changeLayer(s, selected, next))
  function reset() { setGame(createGame()); setSelected('soft') }
  return <>
    <nav className="j-nav" aria-label="試作の切替"><button onClick={() => setLegacy(false)} aria-pressed={!legacy}>言語ジェンガ</button><button onClick={() => setLegacy(true)} aria-pressed={legacy}>旧試作：宥めよ</button></nav>
    {legacy ? <App /> : <main className="jenga">
      <header className="j-header"><div><p className="j-eyebrow">LANGUAGE JENGA · 01</p><h1>雨の駅前</h1></div><p>言葉を抜く。<br />残った意味を、見届ける。</p></header>
      <div className="j-mission"><strong>挑戦：3層以上抜いて、相合傘を残す</strong><span>{removedCount(game.layers)} / 3 層を抜いた</span></div>
      <div className="j-layout">
        <section className="j-tower" aria-label="意味の層">
          <h2>何を、なくしてみる？</h2><p className="j-muted">層を選んで、抜く・差し替える。</p>
          {LAYERS.map((l, index) => <button key={l.id} className={`j-block ${game.layers[l.id] === null ? 'removed' : ''} ${selected === l.id ? 'selected' : ''}`} aria-pressed={selected === l.id} disabled={game.ended} onClick={() => setSelected(l.id)}>
            <span className="j-block-number">0{index + 1} · {l.name}</span>
            <strong>{game.layers[l.id] === null ? '抜けた層' : `${l.kind === 'speech' ? '「' : ''}${l.options[game.layers[l.id]]}${l.kind === 'speech' ? '」' : ''}`}</strong>
          </button>)}
          {!game.ended && <div className="j-edit"><span>{layer.name}を操作</span><div className="j-edit-buttons"><button disabled={value === null} onClick={() => change(null)}>この層を抜く</button><button onClick={() => change(value === 1 ? 0 : 1)}>{value === 1 ? '元の内容に変える' : `「${layer.options[1]}」に変える`}</button>{value === null && <button onClick={() => change(0)}>元の層を戻す</button>}</div><p className="j-mobile-response" aria-live="polite">{labels[result.kind]} — {result.title}<br />「{renderReply(game.layers, result)}」</p></div>}
        </section>
        <section className={`j-result ${result.kind}`} aria-label="残った場面">
          <div className="j-result-top"><span className="j-status">{labels[result.kind]}</span><span>駅前に残った、ひと場面</span></div>
          <Scene result={result} layers={game.layers} />
          <div className="j-speech"><span className="j-muted">残した言葉</span><p>{speech.length ? speech.map(l => `「${l.options[game.layers[l.id]]}」`).join(' ') : '言葉は、何も残っていない。'}</p></div>
          <div aria-live="polite" aria-atomic="true"><h2>{result.title}</h2><blockquote>「{renderReply(game.layers, result)}」</blockquote><p className="j-reason">{result.reason}</p></div>
          <details className="j-evidence"><summary>何が、この受け取り方を支えた？</summary><ul>{result.evidence.map(id => { const l = LAYERS.find(item => item.id === id); return <li key={id}>{l.name}：{game.layers[id] === null ? '抜けている' : l.options[game.layers[id]]}</li> })}</ul><p>この一場面に書いた解釈です。誰もが同じ受け取り方をするとは限りません。</p></details>
        </section>
      </div>
      <section className="j-footer" aria-label="区切りとやり直し">
        {game.ended ? <div role="status"><h2>{accomplished(game.layers) ? '細くなっても、約束は残った。' : result.kind === 'changed' ? '別の場面が、生まれた。' : result.kind === 'broken' ? '言葉の間で、足が止まった。' : '約束は残った。まだ抜ける層がある。'}</h2><p>{accomplished(game.layers) ? '挑戦達成。' : '今回は挑戦未達。'} {removedCount(game.layers)}層を抜いて、{labels[result.kind]}。別の抜き方も試せます。</p><button onClick={reset}>もう一度組み直す</button></div> : <><button disabled={!game.history.length} onClick={() => setGame(undo)}>一手戻す</button><button disabled={!game.history.length} onClick={reset}>最初から</button><button className="j-primary" disabled={!game.history.length} onClick={() => setGame(finish)}>この場面を確定</button><p>変わっても、崩れても戻せます。確定するまで自由に試してください。</p></>}
      </section>
      <details className="j-log"><summary>抜き方の記録（{game.history.length}手）</summary><ol>{game.history.map((h, i) => <li key={i}><strong>{LAYERS.find(l => l.id === h.id).name}：{h.value === null ? '抜く' : LAYERS.find(l => l.id === h.id).options[h.value]}</strong><span>{labels[h.result.kind]} — {h.result.title}</span></li>)}</ol></details>
    </main>}
  </>
}
