import { useEffect, useState } from 'react'
import App from './App.jsx'
import Comparison from './Comparison.jsx'
export default function Workspace() {
  const [comparison, setComparison] = useState(() => window.location.hash === '#compare')
  useEffect(() => {
    const update = () => setComparison(window.location.hash === '#compare')
    window.addEventListener('hashchange', update)
    return () => window.removeEventListener('hashchange', update)
  }, [])
  return <><nav className="workspace-nav" aria-label="試作の画面"><a href="#game" aria-current={!comparison ? 'page' : undefined}>宥めよ</a><a href="#compare" aria-current={comparison ? 'page' : undefined}>言語比較ラボ</a><span>切替時に入力・ゲームをリセット</span></nav>{comparison ? <Comparison /> : <App />}</>
}
