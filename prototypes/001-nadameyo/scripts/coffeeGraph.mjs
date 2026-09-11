import { CHOICES, createCoffeeScene, stepCoffeeScene, choiceInterpretation, sceneSnapshot } from '../src/lib/coffeeScene.js'
export function stateKey(state) { return JSON.stringify(sceneSnapshot(state)) }
export function phase(state) { const e = state.environment; return e.tissue === 'used' ? 'D' : e.tissue === 'partner' ? 'R' : ({ none: 'U', declined: 'H', accepted: 'G', withdrawn: 'W' })[state.relationship.consent] }
// All future-sensitive memory lives in the snapshot. Display text / history length
// do not determine any subsequent guard and are deliberately not graph states.
export function exploreCoffee(condition, inspect = () => {}, maxStates = 500) {
  const initial = createCoffeeScene(condition), queue = [initial], seen = new Map([[stateKey(initial), 0]])
  const branches = new Map(), phases = new Set(), phaseEdges = new Map()
  let truncated = false, expandedStates = 0, transitions = 0, selfLoops = 0, minDry = Infinity, dryWays = 0
  const depths = [0], ways = [1], edges = []
  for (let i = 0; i < queue.length; i++) {
    const before = queue[i]; phases.add(phase(before))
    if (before.conversation.ending) continue
    expandedStates++
    for (const choice of CHOICES) {
      const after = stepCoffeeScene(before, choiceInterpretation(choice.act)), last = after.history.at(-1)
      inspect(before, choice, after)
      const key = stateKey(after), previousIndex = seen.get(key)
      if (key === stateKey(before)) selfLoops++
      if (after.environment.table === 'dry' && before.environment.table !== 'dry') {
        const length = depths[i] + 1
        if (length < minDry) { minDry = length; dryWays = ways[i] }
        else if (length === minDry) dryWays += ways[i]
      }
      const branch = branches.get(last.branch) ?? { count: 0, example: last, phases: new Set(), changes: new Set() }
      branch.count++; branch.phases.add(`${phase(before)}→${phase(after)}`)
      last.changes.forEach(c => branch.changes.add(c.field)); branches.set(last.branch, branch)
      const edge = `${phase(before)}:${phase(after)}:${choice.act}`; phaseEdges.set(edge, (phaseEdges.get(edge) ?? 0) + 1)
      transitions++
      if (previousIndex === undefined) {
        if (queue.length >= maxStates) { truncated = true; continue }
        seen.set(key, queue.length); queue.push({ ...after, history: [] }); depths.push(depths[i] + 1); ways.push(ways[i])
      } else if (depths[previousIndex] === depths[i] + 1) ways[previousIndex] += ways[i]
      edges.push({ from: i, to: seen.get(key), act: choice.act, branch: last.branch })
    }
  }
  return { condition, truncated, expandedStates, states: queue.length, transitions, selfLoops, minDry, dryWays, phases: [...phases], branches, phaseEdges, nodes: queue.map(sceneSnapshot), edges }
}
