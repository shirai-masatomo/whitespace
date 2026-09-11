// Entry copy only. The scene's facts and transition rules remain in coffeeScene.
export const COFFEE_ENTRIES = {
  A: { label: '後から来た友人', intro: '友人の席へ、あなたは今来たところだ。' },
  B: { label: '近くの客', intro: 'あなたは近くの席の客。この人とは面識がない。' },
  C: { label: '居合わせた友人', intro: 'あなたが友人のカップにぶつかった。' },
}

// Randomness selects only an authored setup; it never changes a response.
export function pickBlindCircumstance(random = Math.random) {
  return ['cleanup', 'notebook', 'bad_day'][Math.min(2, Math.max(0, Math.floor(random() * 3)))]
}
export function presentedEvents(scene) {
  return scene.events.filter(event => event.type !== 'offer-paper' || !scene.events.some(e => e.type === 'receive'))
}
