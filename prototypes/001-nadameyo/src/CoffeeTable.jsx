export default function CoffeeTable({ scene, reduced }) {
  const wet = scene.environment.table === 'wet'
  const notebook = scene.environment.notebook, safe = scene.environment.notebookPosition === 'safe'
  const wiping = scene.events.some(e => e.type === 'wipe')
  return <div className={`coffee-tableau ${wet ? 'wet' : 'dry'} ${reduced ? 'reduced' : ''}`} role="img" aria-label={`${wet ? '机にこぼれたコーヒー' : 'コーヒーを拭き取った机'}。${notebook === 'absent' ? '' : notebook === 'wet' ? 'ノートの端が濡れている' : 'ノートに染みが残る'}`}>
    <svg viewBox="0 0 800 190" aria-hidden="true">
      <defs><linearGradient id="table-surface" x2="0" y2="1"><stop stopColor="#e5e4da" /><stop offset="1" stopColor="#afb7ac" /></linearGradient></defs>
      <path fill="url(#table-surface)" stroke="#7e8b81" d="M130 20H670L795 175H5Z" />
      <path className="table-spill" d="M325 64c-30-32 80-45 115-16s90 7 101 31-61 48-98 28-98 28-124 6-21-35 6-49Z" />
      <g transform="translate(274 42) rotate(-65)"><ellipse rx="26" ry="13" fill="#263d37" /><path d="M-26 0v39q26 19 52 0V0" fill="#4b6661" /><ellipse cy="39" rx="26" ry="13" fill="#545e58" /><path d="M26 6q29 0 22 26-5 8-22 4" fill="none" stroke="#344b48" strokeWidth="8" /></g>
      {notebook !== 'absent' && <g className={`table-notebook ${safe ? 'safe' : ''}`}><path d="M0 0h83v54H0Z" fill="#a3b39a" stroke="#324e40" strokeWidth="2" /><path d="M9 0v54M18 13h52M18 25h52M18 37h40" stroke="#5c6964" strokeWidth="2" /><path d="M53 37q26-18 30-2v19H50Z" fill={notebook === 'wet' ? '#8b5838' : '#b99b76'} opacity=".85" /></g>}
      {wiping && <path key={`${scene.history.length}`} className="wipe-trace" d="m340 65 130 30-115 14" fill="none" stroke="#d8dfd5" strokeWidth="12" strokeLinecap="round" />}
    </svg>
  </div>
}
