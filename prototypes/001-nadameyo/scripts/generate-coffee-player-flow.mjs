import { mkdirSync, writeFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { COFFEE_ENTRIES } from '../src/lib/coffeePresentation.js'
import { createCoffeeScene, coffeeCandidates, stepCoffeeScene, choiceInterpretation, sceneSnapshot, visibleScene } from '../src/lib/coffeeScene.js'

const directory = fileURLToPath(new URL('../../../docs/coffee-player-flow/', import.meta.url))
mkdirSync(directory, { recursive: true })
const actors = { player: 'あなたの動作', partner: '相手の動作', scene: '情景' }
const escape = value => value.replaceAll('&', '&amp;').replaceAll('"', '&quot;').replaceAll('<', '&lt;').replaceAll('>', '&gt;')
const reaction = state => [...state.events.map(e => `【${actors[e.actor]}】${e.text}`), state.reply ? `相手「${state.reply}」` : '相手の発話なし', !state.events.length && '新たな動作・情景の記録なし'].filter(Boolean).map(escape).join('<br/>')
const play = (state, choice) => stepCoffeeScene(state, choiceInterpretation(choice.act), choice.label)
const same = (a, b) => JSON.stringify(sceneSnapshot(a)) === JSON.stringify(sceneSnapshot(b))
const sameOutput = (a, b) => a.reply === b.reply && JSON.stringify(a.events) === JSON.stringify(b.events)
const menu = state => coffeeCandidates(state).map(c => c.disabled ? `~~${c.label}~~（無効：${c.note}）` : `「${c.label}」`).join(' ／ ')
const diagram = lines => '\n```mermaid\nflowchart TB\n' + lines.join('\n') + '\n```\n'
const option = c => `${c.kind === 'speech' ? '発言' : '行動'}：${c.label}`
function memory(state) {
  const known = visibleScene(state), r = state.relationship
  return [known.table, known.tissue, known.cause, known.injury, known.preference, known.consent,
    r.apologized ? '事故への謝罪済み' : '事故への謝罪はまだ成立していない',
    r.helpRefused ? '手伝いを断られた記憶あり' : '手伝いを断られた記憶なし',
    r.confirmationRequested ? '渡す前の確認を求められた記憶あり' : '渡す前の確認を求められた記憶なし',
    r.distance === 'away' ? '今は少し離れている' : '今は近くにいる',
    state.memory.spaceCalmed ? '距離を取って一度落ち着いた' : '距離取りによる落ち着きはまだない',
    `表示に影響する落ち着かなさ：${state.partner.agitation}`].join('。') + '。'
}
let firstCount = 0, secondCount = 0
for (const condition of Object.keys(COFFEE_ENTRIES)) {
  const entry = COFFEE_ENTRIES[condition], initial = createCoffeeScene(condition)
  let overview = `# ${condition}：${entry.label} — 初期状態から選ぶ\n\n[プレイヤー視点の入口へ](../COFFEE_PLAYER_FLOW.md)\n\n${entry.intro}\n\n【情景】${initial.events[0].text} 相手の発話はまだない。\n\n以下が通常画面の初手の全9候補。図ごとに同じ初期状態から始まる。細かい文字に縮めないため、選択ごとに分割した。2手目は各詳細リンクへ。\n`
  for (const first of coffeeCandidates(initial)) {
    firstCount++
    const afterFirst = play(initial, first), filename = `${condition}-${first.act}.md`
    overview += `\n## ${option(first)}\n` + diagram([
      '  start["場面の始まり"]', `  start --> pick["${escape(option(first))}"]`, `  pick --> reply["${reaction(afterFirst)}"]`,
    ]) + `\n[この初手から、2手目の全選択と反応を見る](${filename})\n`
    let detail = `# ${condition}：初手「${first.label}」から\n\n[${entry.label}の初手一覧](${condition}.md) / [入口](../COFFEE_PLAYER_FLOW.md)\n\n${entry.intro}\n\n## 初手と、その直後\n` + diagram([
      '  start["場面の始まり"]', `  start --> pick["${escape(option(first))}"]`, `  pick --> reply["${reaction(afterFirst)}"]`,
    ]) + `\nここから下は、同じ初手の直後から選べる**別々の2手目**。上から順に押す手順ではない。発言も行動も選べる。\n`
    for (const second of coffeeCandidates(afterFirst)) {
      secondCount++
      const afterSecond = second.disabled ? afterFirst : play(afterFirst, second)
      const repeatChoice = coffeeCandidates(afterSecond).find(c => c.act === second.act)
      const repeated = !repeatChoice.disabled && play(afterSecond, repeatChoice)
      const loop = repeated && same(afterSecond, repeated) && sameOutput(afterSecond, repeated)
      detail += `\n## 2手目：${second.label}${second.disabled ? '（無効）' : ''}\n`
      const lines = [`  from["初手『${escape(first.label)}』の反応の後"]`, `  from --> pick["${escape(option(second))}${second.disabled ? '（無効）' : ''}"]`]
      if (second.disabled) lines.push(`  pick -.-> disabled["実行できない：${escape(second.note)}<br/>相手の反応・状態更新なし"]`)
      else {
        lines.push(`  pick --> reply["${reaction(afterSecond)}"]`)
        if (loop) lines.push(`  reply -->|"同じ選択を繰り返すと、同じ反応"| pick`)
      }
      detail += diagram(lines)
      detail += `\n**この後の通常候補**：${menu(afterSecond)}\n`
      detail += `\n<details>\n<summary>この地点で引き継ぐこと（他の枝とは合流しない）</summary>\n\n${memory(afterSecond)}\n\n</details>\n`
      if (afterSecond.environment.tissue === 'partner') detail += '\n→ [受け取った直後からの共通の続き](CONTINUE.md#受け取った直後)。上の知識・記憶を引き継ぐ。\n'
      else detail += '\n3手目以降の返答の全面展開はこの図では省略。上の候補から続行できる。[続きの読み方](CONTINUE.md)を参照。\n'
    }
    detail += `\n[初手一覧へ戻る](${condition}.md) / [内部状態の詳細検証資料](../COFFEE_STATES_${condition}.md)\n`
    writeFileSync(directory + filename, detail)
  }
  writeFileSync(directory + `${condition}.md`, overview)
}
// A concrete existing path illustrates cleanup, without treating all histories as equal.
let received = createCoffeeScene('A')
for (const act of ['offer_tissue', 'give_tissue']) received = play(received, coffeeCandidates(received).find(c => c.act === act))
const watch = coffeeCandidates(received).find(c => c.act === 'observe'), cleaned = play(received, watch)
writeFileSync(directory + 'CONTINUE.md', `# 2手目の後を読む\n\n[入口](../COFFEE_PLAYER_FLOW.md)\n\n2手目までの各枝は、台詞が同じでも合流していない。各地点の「この後の通常候補」と「引き継ぐこと」が続行時の前提。ループ矢印は、同じ操作をもう一度した結果の発話・動作・全更新状態が一致する場合だけ付けている。別の操作へ変えるときは、その記憶を保持する。\n\n3手目以降の全返答は未展開。全履歴を図へ膨らませず、議論したい初手・2手目を入口にする。詳しい条件差は[内部図と全状態表](../COFFEE_TRANSITIONS.md)に残した。\n\n## 受け取った直後\n\n以下は現在の実装にある、Aで「ティッシュいる？」→「ティッシュを渡す」の続き。受取直後は全条件でこの「拭くのを見守る」に同じ台詞と動作が返るが、他の発言への反応や知識・謝罪・拒否の記憶まで同じにはしない。自動進行ではない。\n` + diagram([
  `  received["${reaction(received)}"]`, `  received --> watch["行動：${watch.label}"]`, `  watch --> done["${reaction(cleaned)}"]`,
]) + `\n**受取直後の全候補**：${menu(received)}\n\n**拭いた後の全候補**：${menu(cleaned)}\n\n「ティッシュを渡す」は無効なので、通常画面で再度押して相手の台詞を得る経路はない。検証パネルだけの操作をこの図に混ぜない。拭いた後も場面は終了せず、会話・距離取り・観察を続けられる。\n`)
if (firstCount !== 27 || secondCount !== 243) throw new Error('初手・2手目の列挙数が変わったため、入口の説明を更新してください。')
console.log({ firstChoices: firstCount, secondChoices: secondCount, conditionPages: 3, detailPages: 27 })
