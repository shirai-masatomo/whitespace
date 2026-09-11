import { mkdir, writeFile } from 'node:fs/promises'
import { exploreCoffee } from './coffeeGraph.mjs'
const directory = new URL('../../../.tmp-docs/', import.meta.url)
await mkdir(directory, { recursive: true })
const graphs = ['A', 'B', 'C'].map(condition => {
  const graph = exploreCoffee(condition)
  return { condition, truncated: graph.truncated, expandedStates: graph.expandedStates, states: graph.nodes, transitions: graph.edges }
})
await writeFile(new URL('coffee-states.json', directory), JSON.stringify(graphs, null, 2))
console.log('最大500状態/条件の範囲を .tmp-docs/coffee-states.json へ出力しました。人向け文書は変更していません。')
