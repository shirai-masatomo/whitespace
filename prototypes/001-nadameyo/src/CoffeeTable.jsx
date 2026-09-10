export default function CoffeeTable({ scene, reduced }) {
  const tissue = scene.environment.tissue, wet = scene.environment.table === 'wet'
  const wiping = scene.events.some(e => e.type === 'wipe')
  return <div className={`coffee-tableau ${tissue} ${wet ? 'wet' : 'dry'} ${reduced ? 'reduced' : ''}`} role="img" aria-label={`${wet ? '机にこぼれたコーヒー' : 'コーヒーを拭き取った机'}。${tissue === 'player' ? 'ティッシュはあなたの手元' : tissue === 'partner' ? '相手の手にティッシュ' : '相手側に使用済みティッシュ'}`}>
    <svg viewBox="0 0 800 190" aria-hidden="true">
      <defs><linearGradient id="table-surface" x2="0" y2="1"><stop stopColor="#423c36" /><stop offset="1" stopColor="#242927" /></linearGradient></defs>
      <path fill="url(#table-surface)" stroke="#71665a" d="M130 20H670L795 175H5Z" />
      <path className="table-spill" d="M325 64c-30-32 80-45 115-16s90 7 101 31-61 48-98 28-98 28-124 6-21-35 6-49Z" />
      <g transform="translate(274 42) rotate(-65)"><ellipse rx="26" ry="13" fill="#77827c" /><path d="M-26 0v39q26 19 52 0V0" fill="#c7cdc3" /><ellipse cy="39" rx="26" ry="13" fill="#545e58" /><path d="M26 6q29 0 22 26-5 8-22 4" fill="none" stroke="#b9c3b9" strokeWidth="8" /></g>
      <g className="table-tissue"><path d="m-28-10 53-6 10 36-60 8Z" fill={tissue === 'used' ? '#a99578' : '#e7e5d8'} /><path d="m-19-8 20 24 22-27" fill="none" stroke="#a8b4ac" strokeWidth="2" /></g>
      {wiping && <path key={`${scene.history.length}`} className="wipe-trace" d="m340 65 130 30-115 14" fill="none" stroke="#d8dfd5" strokeWidth="12" strokeLinecap="round" />}
    </svg><span className="coffee-object-caption">{tissue === 'player' ? '手元に、ティッシュ。' : tissue === 'partner' ? 'ティッシュは相手の手へ。' : '机から、コーヒーの溜まりが消えた。'}</span>
  </div>
}
