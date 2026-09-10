import { characterState } from './characterState.js'
// Presentation-only mapping: no score or turn limit is introduced into the scene.
export function coffeeCharacter(state) {
  const base = characterState({ trust: state.relationship.type === 'friend' ? 3 : 1, tension: state.partner.agitation, result: 'playing', history: [] })
  const notebook = state.environment.notebook !== 'absent'
  const distant = state.partner.circumstance === 'bad_day' && !state.memory.listened
  if (notebook) { base.pose.yaw = .24; base.pose.pitch = .13 }
  else if (distant) { base.pose.yaw = -.3; base.pose.pitch = .11 }
  return { ...base, caption: state.environment.table === 'wet' ? '机はまだ濡れている' : '相手が机を拭いた',
    description: notebook ? 'ノートのある側に顔を向けている。' : distant ? '視線が机から離れ、うつむいている。' : state.partner.agitation >= 3 ? '肩に力が入り、机へ注意を向けている。' : '肩の力が少し抜けている。',
    event: state.history.length ? { id: `coffee:${state.history.length}`, kind: state.reaction } : null }
}
