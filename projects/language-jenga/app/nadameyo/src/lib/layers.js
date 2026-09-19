// A finite authored scene, not a general-purpose Japanese understanding model.
export const LAYERS = [
  { id: 'rain', name: '場面', options: ['雨が降っている', '雨は上がった'], kind: 'context' },
  { id: 'bond', name: '関係', options: ['気心の知れた友人', '初対面の人'], kind: 'context' },
  { id: 'umbrellas', name: '持ち物', options: ['傘は一本だけ', 'それぞれ傘を持っている'], kind: 'context' },
  { id: 'offer', name: '申し出', options: ['この傘、使って', 'この傘は使わないで'], kind: 'speech' },
  { id: 'walk', name: '次の行動', options: ['駅まで一緒に行こう', '私はここで待つよ'], kind: 'speech' },
  { id: 'soft', name: '添える言葉', options: ['急がなくていいよ', '急いでね'], kind: 'speech' },
]
export const original = () => Object.fromEntries(LAYERS.map(l => [l.id, 0]))
export const labels = { kept: '維持', changed: '変容', broken: '崩壊' }
export function interpret(layers) {
  const { rain, bond, umbrellas, offer, walk } = layers
  const out = (kind, scene, title, reply, reason, evidence) => ({ kind, scene, title, reply, reason, evidence })
  if (walk === 0) {
    if (rain === 1) return out('changed', 'parallel', '傘を差さず、駅まで一緒に', '雨、止んだね。そのまま行こう。', '雨が上がったので、同行の約束は残っても相合傘の理由は消えた。', ['rain', 'walk'])
    if (umbrellas === 1) return out('changed', 'parallel', '二本の傘で、並んで歩く', 'うん、自分の傘で行くね。', 'それぞれ傘があるので、同じ傘に入らなくても同行できる。', ['umbrellas', 'walk'])
    if (offer === 1 && umbrellas === 0 && rain === 0) return out('broken', 'apart', '一緒に行きたい。でも傘には入れない', 'この雨で、傘に入らずどうやって行くの？', '一本しかない傘の使用を断りながら、雨の中で同行を求めている。', ['rain', 'umbrellas', 'offer', 'walk'])
    if (umbrellas === 0 && offer === 0) return out('kept', 'shared', '一本の傘で、駅へ', 'ありがとう。隣に入るね。', '一本の傘を使う申し出と同行の言葉が、相合傘を支えている。', ['umbrellas', 'offer', 'walk'])
    if (umbrellas === 0 && offer === null && rain === 0 && bond === 0) return out('kept', 'shared', '言わなくても、隣へ', 'じゃあ、隣に入るね。', '雨・一本の傘・親しい関係が残り、同行の誘いを傘への招きとして補っている。この場面での一解釈。', ['rain', 'bond', 'umbrellas', 'walk'])
    return out('broken', 'uncertain', '一緒に行く。その先が決まらない', '一緒に行くのはいいけど、傘はどうする？', '同行だけでは、同じ傘に入ってよいか確定できない。抜いた前提を都合よく補わない。', ['umbrellas', 'offer', 'bond', 'walk'])
  }
  if (offer === 0 && umbrellas === 1) return out('changed', 'apart', '傘は借りずに、別々の道へ', 'ありがとう。でも自分の傘があるから、これで行くね。', '申し出は届いたが、相手にも傘がある。一緒に行く約束はなく、貸し借りをせず別れる。', ['umbrellas', 'offer', 'walk'])
  if (offer === 0) return out('changed', 'lent', '傘を渡し、別々に過ごす', walk === 1 ? '借りて先に行くね。ここで待っていて。' : 'ありがとう。借りていくね。', '使ってという申し出は残ったが、一緒に歩く約束はない。貸し借りとして受け取られた。', ['offer', 'walk'])
  if (walk === 1 && rain === 0 && umbrellas === 0) return out('changed', 'apart', '別々に、雨が弱まるのを待つ', '分かった。私は駅の入口で雨宿りするね。', '傘を使う許可がないので受け渡しは起きない。同行せず、それぞれ雨を待つ。', ['rain', 'umbrellas', 'offer', 'walk'])
  if (walk === 1) return out('changed', 'apart', 'ここに残る人と、先へ進む人', '分かった。私は先に行くね。', '待つ意思は伝わる。傘を使う許可がないので、受け渡しは起きない。', ['offer', 'walk'])
  return out('broken', 'uncertain', '次の一歩が、決まらない', '……それで、どうしようか。', '場面や口調だけが残り、何をする申し出なのかがなくなった。', ['offer', 'walk'])
}
export function renderReply(layers, result) {
  if (layers.soft !== 1) return result.reply
  if (result.kind === 'broken') return result.reply + ' ……急ぐ前に、そこを確かめたい。'
  if (result.scene === 'apart' && layers.walk === 1 && layers.rain === 0 && layers.umbrellas === 0) return result.reply + ' ……雨が弱まるまでは待つよ。'
  return result.reply + ' ……急ぐね。'
}
export function createGame() { return { layers: original(), history: [], ended: false } }
export function removedCount(layers) { return Object.values(layers).filter(v => v === null).length }
export function accomplished(layers) { return removedCount(layers) >= 3 && interpret(layers).kind === 'kept' }
export function changeLayer(state, id, value) {
  const definition = LAYERS.find(l => l.id === id)
  if (state.ended || !definition || ![null, 0, 1].includes(value) || state.layers[id] === value) return state
  const layers = { ...state.layers, [id]: value }
  return { layers, ended: false, history: [...state.history, { id, value, before: state.layers, result: interpret(layers) }] }
}
export function undo(state) {
  if (state.ended || !state.history.length) return state
  return { layers: state.history.at(-1).before, history: state.history.slice(0, -1), ended: false }
}
export function finish(state) { return state.ended ? state : { ...state, ended: true } }
