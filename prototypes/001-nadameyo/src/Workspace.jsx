import { useEffect, useState } from 'react'
import App from './App.jsx'
import Comparison from './Comparison.jsx'
import CoffeeScene from './CoffeeScene.jsx'
const current = () => ['#compare', '#coffee'].includes(window.location.hash) ? window.location.hash : '#game'
export default function Workspace() {
  const [screen, setScreen] = useState(current)
  useEffect(() => {
    const update = () => setScreen(current())
    window.addEventListener('hashchange', update)
    return () => window.removeEventListener('hashchange', update)
  }, [])
  return <><nav className="workspace-nav" aria-label="試作の画面">{[['#game', '宥めよ'], ['#compare', '言語比較ラボ'], ['#coffee', '場面実験']].map(([hash, label]) => <a key={hash} href={hash} aria-current={screen === hash ? 'page' : undefined}>{label}</a>)}<span>切替時に入力・場面をリセット</span></nav>{screen === '#compare' ? <Comparison /> : screen === '#coffee' ? <CoffeeScene /> : <App />}</>
}
