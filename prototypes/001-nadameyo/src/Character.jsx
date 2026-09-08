import { useEffect, useRef, useState, useSyncExternalStore } from 'react'
import { characterState, REACTION_LABELS } from './lib/characterState.js'
import './Character.css'

const motionQuery = () => window.matchMedia('(prefers-reduced-motion: reduce)')
const subscribeMotion = (notify) => { const query = motionQuery(); query.addEventListener('change', notify); return () => query.removeEventListener('change', notify) }

export default function Character({ game, stageRef, manualReduced, onReducedChange }) {
  const host = useRef(null)
  const renderer = useRef(null)
  const latest = useRef(null)
  const [failure, setFailure] = useState('')
  const [preview, setPreview] = useState(null)
  const [resumeAt, setResumeAt] = useState(0)
  const [fallback, setFallback] = useState(false)
  const [attempt, setAttempt] = useState(0)
  const systemReduced = useSyncExternalStore(subscribeMotion, () => motionQuery().matches, () => true)
  const reduced = systemReduced || manualReduced
  const visual = characterState(preview ? { ...preview, history: [] } : game)
  const event = preview ? { id: `preview:${preview.sequence}`, kind: preview.kind }
    : game.history.length > resumeAt ? visual.event : null
  const eventId = event?.id
  const eventKind = event?.kind

  useEffect(() => {
    const state = { ...characterState(preview ? { ...preview, history: [] } : game),
      event: eventId ? { id: eventId, kind: eventKind } : null, reduced }
    latest.current = state
    renderer.current?.update(state)
  }, [game, preview, eventId, eventKind, reduced])

  useEffect(() => {
    if (fallback) return
    let cancelled = false
    let instance
    import('./character/createCharacterRenderer.js').then(({ createCharacterRenderer }) => {
      if (cancelled) return
      try {
        instance = createCharacterRenderer(host.current, latest.current, setFailure)
        renderer.current = instance
      } catch { setFailure('この環境では3Dを利用できません。会話は続けられます。') }
    }).catch(() => { if (!cancelled) setFailure('3Dの読み込みに失敗しました。会話は続けられます。') })
    return () => { cancelled = true; instance?.dispose(); renderer.current = null }
  }, [fallback, attempt])

  function changePreview(fields) {
    setPreview((current) => ({ trust: current?.trust ?? game.trust, tension: current?.tension ?? game.tension,
      result: 'playing', kind: null, ...fields, sequence: (current?.sequence ?? 0) + 1 }))
  }
  function followGame() { setResumeAt(game.history.length); setPreview(null) }
  const displayFallback = fallback || Boolean(failure)
  return <section className="character-section" aria-label="対話相手">
    <div ref={stageRef} className="character-stage" data-display={displayFallback ? 'fallback' : '3d'}>
      <div className="stage-halo" />
      <div ref={host} className="character-canvas" aria-hidden="true" />
      {displayFallback && <div className="character-fallback" role="img" aria-label={visual.description}>
        <svg viewBox="0 0 240 300" aria-hidden="true">
          <path fill="#adb7b3" d="M91 139 76 74 91 31 127 17 157 49 164 95 144 139 132 154 105 153Z" />
          <path fill="#d3d8cd" d="M91 31 127 17 122 78 76 74Z M122 78 157 49 164 95 144 139Z" />
          <path fill="#71817c" d="M105 153 132 154 137 180 101 180Z" />
          <path fill="#8e9c95" d="M101 176 57 184 21 228 47 281 192 281 219 228 176 184 137 176Z" />
          <path fill="#b9c3b7" d="M101 176 119 229 57 184Z M119 229 137 176 176 184 192 281Z" />
          <path fill="#e5eed2" opacity={visual.pose.light} d="m119 204 9 18-9 31-9-31Z" />
        </svg>
        <span>{failure || '静止画で表示しています。'}</span>
      </div>}
      <div className="stage-caption"><span>SUBJECT / 001</span><span>{preview ? '表示プレビュー · 得点は変わりません' : `信頼 ${game.trust}/4 · 緊張 ${game.tension}/5 · 残り ${game.turnsLeft}回`}</span></div>
    </div>
    <div className="character-description"><p role="status">{visual.description}{eventKind && <span> {REACTION_LABELS[eventKind]}</span>}</p>
      <label className="motion-control"><input type="checkbox" checked={reduced} disabled={systemReduced} onChange={(e) => onReducedChange(e.target.checked)} />動きを減らす{systemReduced && '（OS設定）'}</label>
      {failure && <button className="secondary" onClick={() => { setFailure(''); setAttempt((value) => value + 1) }}>3Dを再試行</button>}
    </div>
    {import.meta.env.DEV && <details className="debug character-debug"><summary>開発用：人物の表示確認</summary>
      <p>{preview ? '表示のみ操作中' : '実ゲームに追従中'}。このパネルは実際の得点・履歴を変更しません。</p>
      <div className="visual-sliders"><label>表示の信頼 <output>{preview?.trust ?? game.trust}</output><input aria-label="表示の信頼" type="range" min="0" max="4" step="1" value={preview?.trust ?? game.trust} onChange={(e) => changePreview({ trust: Number(e.target.value) })} /></label>
        <label>表示の緊張 <output>{preview?.tension ?? game.tension}</output><input aria-label="表示の緊張" type="range" min="0" max="5" step="1" value={preview?.tension ?? game.tension} onChange={(e) => changePreview({ tension: Number(e.target.value) })} /></label></div>
      <div className="visual-buttons">{Object.entries(REACTION_LABELS).map(([kind, label]) => <button className="secondary" key={kind} onClick={() => changePreview({ kind, result: kind === 'success' ? 'succeeded' : kind === 'failure' ? 'failed' : 'playing' })}>{label}</button>)}
        <button className="secondary" onClick={followGame}>実ゲームに追従する</button></div>
      <label className="motion-control"><input type="checkbox" checked={fallback} onChange={(e) => { setFailure(''); setFallback(e.target.checked) }} />3Dなしの代替表示を確認</label>
      <button className="secondary context-test" disabled={displayFallback} onClick={() => renderer.current?.loseContext()}>3D接続切れを試す</button>
    </details>}
  </section>
}
