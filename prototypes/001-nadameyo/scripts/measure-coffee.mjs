import fs from 'node:fs/promises'
import { evaluateCoffeeModel } from '../server/coffeeModel.js'
import { createCoffeeScene, stepCoffeeScene, choiceInterpretation } from '../src/lib/coffeeScene.js'
import { coffeeLanguageRequest } from '../src/lib/coffeeLanguage.js'
const queried = stepCoffeeScene(createCoffeeScene('A'), choiceInterpretation('ask_event'))
const cases = [
 ['A-apology','A','ごめん','apologize'], ['C-apology','C','ごめん','apologize'],
 ['A-tissue','A','ティッシュ、使いますか？','offer_tissue'], ['B-tissue','B','ティッシュだけ、そっと渡しましょうか？','offer_tissue'],
 ['give','A','ティッシュを渡す','give_tissue'], ['negative','A','ティッシュは渡さない','clarify'],
 ['ambiguous','A','それでお願い','clarify'], ['unsupported','A','店員を呼んで','clarify'],
 ['repeat','A','さっき何があったって？','ask_event',queried], ['mixed','C','ごめん、ティッシュいる？','clarify'],
]
const rows=[]
for (const [id, condition, input, expected, state] of cases) {
 const payload=coffeeLanguageRequest(state ?? createCoffeeScene(condition), input)
 try { const result=await evaluateCoffeeModel(payload); rows.push({id, origin:'generated-evaluation-case',condition,input,expected,payload,result}); console.log(id,result.interpretation.act,Math.round(result.elapsedMs)+'ms') }
 catch(error){ rows.push({id,origin:'generated-evaluation-case',condition,input,expected,payload,error:error.message,diagnostic:error.diagnostic});console.log(id,error.message) }
}
await fs.writeFile(process.argv[2] ?? '../../docs/experiments/coffee-language-v2-2026-09-10.json', JSON.stringify({date:new Date().toISOString(), note:'Generated cases, not real player input. Expected acts are provisional; model is not ground truth. Existing Ollama/model only; no download. v1 first request timed out; v2 is already loaded.',rows},null,2)+'\n')
