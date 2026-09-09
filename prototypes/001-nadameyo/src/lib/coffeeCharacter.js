import { characterState } from './characterState.js'
// Presentation-only mapping: no score or turn limit is introduced into the scene.
export function coffeeCharacter(state) {
  const base = characterState({ trust: state.relationship.type === 'friend' ? 3 : 1, tension: state.partner.agitation, result: 'playing', history: [] })
  return { ...base, caption: state.environment.table === 'wet' ? '机はまだ濡れている' : '相手が机を拭いた',
    description: state.partner.agitation >= 3 ? '肩に力が入り、机へ注意を向けている。' : '肩の力が少し抜けている。',
    event: state.history.length ? { id: `coffee:${state.history.length}`, kind: state.reaction } : null }
}
