import fs from 'node:fs/promises'
import { exploreCoffee, phase } from './coffeeGraph.mjs'
import { COFFEE_RULES } from '../src/lib/coffeeRules.js'
import { CHOICES } from '../src/lib/coffeeScene.js'
const dir = new URL('../../../docs/', import.meta.url)
const names = { U: '濡れた机・未同意', H: '濡れた机・援助を辞退', G: '濡れた机・受取同意', W: '濡れた机・同意解除', R: '濡れた机・相手がティッシュ所持', D: '拭き取り済み・使用済みティッシュ' }
const graphs = ['A','B','C'].map(id => exploreCoffee(id))
const esc = value => String(value ?? '（発話なし）').replaceAll('|','／').replaceAll('\n',' ')
const label = act => CHOICES.find(c => c.act === act).label
let md = `# コーヒー場面・全選択肢の遷移図

これはプレイ履歴の図ではなく、固定条件A/B/Cの**実装全体**の設計図。生成元は coffeeRules.js / coffeeScene.js、再生成はアプリで \`node scripts/generate-coffee-map.mjs\`。既存の個別プレイ履歴の出力機能は追加しない。

## 数え方

- 完全状態：四つの外殻＋将来の挙動に影響する記憶。最新の台詞、履歴の長さ、経路そのものは数えない。状態は \`sceneSnapshot\` の値の組合せ。
- 分岐数：その条件で到達可能な**返答規則IDの数**。同じIDでも出発状態が違えば別の遷移辺。if文や分岐点の数ではない。
- 遷移辺数：到達可能な完全状態×9操作。通常画面で無効の操作も検証パネルから実行できるため含める。自己ループも1辺。
- 主要ルート数：開始→拭き取り完了の**最短操作列**と、開始→濡れたまま距離を取る最短操作列（1本）を合算。代表経路に限定した数で、全ルート数ではない。どちらも終了/勝敗ではなく、その後も操作可能。
- ループがあるので、全操作列は無限。有限の主要ルート数と混同しない。

| 条件 | 完全な到達状態数 | 規則分岐数 | 全遷移辺 | 自己ループ | 主要ルート数 | 片付け最短 |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
`
for(const g of graphs) md += `| ${g.condition} | ${g.states} | ${g.branches.size} | ${g.transitions} | ${g.selfLoops} | ${g.dryWays+1} | ${g.minDry}操作・${g.dryWays}通り |\n`
md += `
自由入力の保留/未対応は \`clarify\` の1規則で、事実を変えず同じ完全状態へ戻る。上の9操作の分岐数/辺数には含めない。モデルの全出力列を網羅したとは扱わない。

## 図の読み方と履歴の因子

下の条件別図は物と同意の流れをまとめた**射影図**。同じ箱の中の履歴差を同一状態とみなしてはいない。完全な状態と9操作の行き先は [Aの全状態表](COFFEE_STATES_A.md)、[Bの全状態表](COFFEE_STATES_B.md)、[Cの全状態表](COFFEE_STATES_C.md) に記載。

状態表の因子：P=物/同意の箱、d=near/away（距離）、a=落ち着かなさ0〜5、k=既知情報（c原因、iけがなし、w拭きたい、tティッシュ希望、q静かに、s自分で拭く）、h=履歴（h援助辞退、r事前確認要求、p謝罪済み、s距離取りで一度落ち着いた）。0は該当なし。

原因の値はA/Bならpartner、Cならplayer。共有済み情報は既知項目から一意に決まり重複して数えない。環境のcoffeeは過去のこぼれた出来事、現在の溜まりはtableで表す。未解決で距離を取る状態はP=Wかつd=away、またはP=Rかつd=away。完了後にもd=awayがある。

\`\`\`mermaid
flowchart LR
  H0[援助辞退なし] -->|Bで手伝おうか| H1[援助辞退の記憶 h]
  R0[確認要求なし] -->|無同意で渡そうとする| R1[確認要求の記憶 r]
  R1 -->|再び無同意で渡す・hなし| R1
  H1 -->|無同意で渡す・hを優先して返答| H1
  N[近くにいる] -->|そっとしておく| A[離れている]
  A -->|そっとしておく・観察| A
  A -->|発言または渡そうとする| N
  K0[未開示の知識] -->|根拠のある台詞だけを開示| K1[既知の項目を保持]
  K1 -->|再質問で補足・消去しない| K1
  C0[C 未謝罪] -->|ごめん・落ち着かなさを1下げる| C1[C 謝罪済み]
  C1 -->|ごめん・再加点なし| C1
\`\`\`

距離を取る初回だけ落ち着く記憶s、知識（けがなし）による再質問、原因既知による再説明、謝罪済みによる再返答は全状態表で別の列/行。落ち着かなさは表示にも影響し、別状態として残す。履歴フラグを消さずとも、新しい同意を得れば受け渡しできる。
`
md += '\n図の矢印の番号：' + CHOICES.map((c,i)=>(i+1)+'='+c.label).join('、') + '。\n'
for(const g of graphs) {
 md += `\n## 条件${g.condition}：物と同意の流れ\n\n\`\`\`mermaid\nflowchart LR\n  START((開始)) --> U\n`
 for(const p of g.phases) md += `  ${p}["${names[p]}"]\n`
 const grouped = new Map()
 for(const edge of g.phaseEdges.keys()) { const [from,to,act] = edge.split(':'); const k = from+':'+to; const a = grouped.get(k) ?? []; if(!a.includes(act))a.push(act);grouped.set(k,a) }
 for(const [edge,acts] of grouped) { const [from,to]=edge.split(':');md+=`  ${from} -->|"${acts.map(act=>CHOICES.findIndex(c=>c.act===act)+1).join(', ')}"| ${to}\n` }
 md += `\`\`\`\n\n### 条件${g.condition}の全操作・返答分岐\n\n同一操作は上から最初に成立した規則を適用。各行の台詞と開示根拠は実装から取得。状態表の各セルから規則IDを引ける。距離awayから発言/受け渡しを選ぶ場合は、どの行にも「近くへ戻る」が追加される。\n\n| 操作 | 規則ID | 優先順付き条件 | 台詞 | 実際の動作 | 開示する情報（台詞内の根拠） | 変わり得る項目 | Pの行き先 |\n| --- | --- | --- | --- | --- | --- | --- | --- |\n`
 for(const r of COFFEE_RULES.filter(r=>g.branches.has(r.id))) {const b=g.branches.get(r.id),e=b.example;md+=`| ${label(r.act)} | ${r.id} | ${r.guard} | ${esc(r.speech)} | ${e.events.filter(x=>x.type!=='return').map(x=>esc(x.actor+': '+x.text)).join(' / ')||'なし'} | ${e.disclosures.map(f=>esc(f.key+'='+f.value+'「'+f.quote+'」')).join(' / ')||'なし'} | ${[...b.changes].join(', ')||'なし'} | ${[...b.phases].join(', ')} |\n`}
 const nodes=g.nodes
 let table=`# 条件${g.condition}：完全な状態と全9操作\n\n[図と読み方へ](COFFEE_TRANSITIONS.md)。自動生成。各セルは **次の状態ID / 返答規則ID**。全規則の台詞・動作・開示は親文書の条件別表にある。同じ状態IDへの遷移はループ。Pだけ同じでもk/h/d/aが異なる行は合流させていない。\n\n| ID | P | d | a | k | h | ${CHOICES.map(c=>c.label).join(' | ')} |\n| --- | --- | --- | ---: | --- | --- | ${CHOICES.map(()=> '---').join(' | ')} |\n`
 for(let i=0;i<nodes.length;i++) { const n=nodes[i],k=n.player.knowledge,r=n.relationship;const kb=[k.cause&&'c',k.injury&&'i',k.wipe&&'w',k.tissue&&'t',k.quiet&&'q',k.selfWipe&&'s'].filter(Boolean).join('')||'0';const hb=[r.helpRefused&&'h',r.confirmationRequested&&'r',r.apologized&&'p',n.memory.spaceCalmed&&'s'].filter(Boolean).join('')||'0';table+=`| ${i} | ${phase(n)} | ${r.distance} | ${n.partner.agitation} | ${kb} | ${hb} | ${g.edges.slice(i*9,i*9+9).map(e=>e.to+' / '+e.branch).join(' | ')} |\n` }
 await fs.writeFile(new URL(`COFFEE_STATES_${g.condition}.md`,dir),table)
}
md+=`\n## 通常の候補と対応行為\n\n全状態で発言6候補は残す（ごめん、味方だ等も隠さない）。行動3候補も表示するが、相手所持/使用済みでは「渡す」を無効にして理由を添える。「観察」は相手所持時だけ「拭くのを見守る」、「そっとしておく」は距離awayで「離れたままにする」に表示名を変える。処理するactは同じ。検証パネルは全9操作を常に実行できる。\n\n## 実装と検証の区別\n\n- 上記分岐と状態数は実装を幅優先探索して取得した到達可能性。最新のテスト実行結果を自動的に意味するものではない。\n- coffeeGraph.test.jsは同じ全状態×9操作を実行し、知識の単調性と開示根拠、物の所有/同意、受取/拭くイベントの事実対応、架空の辞退履歴がないことを検証する。全到達規則IDがカバーされたかも確認する。\n- 台詞の自然さ、視覚表現、画面操作を全状態でテストしたわけではない。実ブラウザで確認した具体的経路と実行結果は [今回の作業記録](COFFEE_PRESENCE_REVIEW.md) に別記する。\n- 実装にない終了判定は設けていない。再開始/条件切替は各条件の状態0へ戻り、会話と記憶を消す。\n`
await fs.writeFile(new URL('COFFEE_TRANSITIONS.md',dir),md)
console.log(graphs.map(g=>({condition:g.condition,states:g.states,branches:g.branches.size,edges:g.transitions,shortestCleanupRoutes:g.dryWays})))
