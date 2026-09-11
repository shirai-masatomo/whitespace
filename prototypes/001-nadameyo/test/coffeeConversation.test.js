import test from 'node:test'
import assert from 'node:assert/strict'
import { createCoffeeScene, stepCoffeeScene, choiceInterpretation, coffeeCandidates } from '../src/lib/coffeeScene.js'
const act=(s,a)=>stepCoffeeScene(s,choiceInterpretation(a))
const run=(kind,acts)=>acts.reduce(act,createCoffeeScene('A',kind))
test('paper rechecks escalate across interleaving, and a concrete offer repairs the warning',()=>{
 let s=run('cleanup',['offer_tissue','offer_tissue'])
 assert.match(s.reply,/さっきお願いした紙/); assert.equal(s.conversation.closing,null)
 s=act(act(s,'check_wellbeing'),'offer_tissue');assert.match(s.reply,/確認はもう大丈夫/)
 s=act(s,'offer_tissue');assert.equal(s.conversation.closing,'repetition')
 const saved=act(s,'give_tissue');assert.equal(saved.environment.table,'dry');assert.equal(saved.conversation.closing,null)
 assert.equal(act(saved,'acknowledge').conversation.ending.kind,'complete')
 const cut=act(act(s,'ask_event'),'offer_help');assert.equal(cut.conversation.ending.kind,'refused')
})
test('alternating already answered topics also reach a boundary; silence does not',()=>{
 let s=run('cleanup',['give_tissue']);for(let i=0;i<12&&!s.conversation.ending;i++)s=act(s,i%2?'offer_help':'ask_event')
 assert.equal(s.conversation.ending.kind,'refused')
 s=createCoffeeScene();for(let i=0;i<20;i++)s=act(s,'observe')
 assert.equal(s.conversation.pressure,0);assert.equal(s.conversation.ending,null)
})
test('progress starts a new context for rechecking, but one unrelated button does not erase repetition',()=>{
 const s=run('notebook',['offer_tissue','offer_tissue','give_tissue','offer_tissue'])
 assert.equal(s.conversation.pressure,0);assert.doesNotMatch(s.reply,/同じ話が続いて/)
 const repeated=run('cleanup',['ask_event','ask_event','observe','ask_event','ask_event'])
 assert.equal(repeated.conversation.closing,'repetition')
})
test('acknowledged notebook requests persist and can be executed or delegated after reminders',()=>{
 const s=run('notebook',['offer_help','acknowledge','ask_event'])
 assert.match(s.reply,/さっきお願いしたノート/);assert.equal(s.environment.notebookPosition,'spill')
 assert.equal(act(s,'entrust').environment.notebookPosition,'safe')
 assert.equal(act(s,'move_notebook').events[0].actor,'player')
 const stalled=act(act(s,'offer_help'),'acknowledge');assert.equal(stalled.conversation.closing,'repetition')
})
test('rest permits a last word, ignores no repeated questioning, and keeps the unresolved concern',()=>{
 const s=run('bad_day',['listen','acknowledge']);assert.equal(s.conversation.closing,'rest')
 assert.equal(s.environment.table,'wet')
 const rest=act(s,'leave');assert.equal(rest.conversation.ending.kind,'rest');assert.match(rest.reply,/少し休む/);assert.equal(rest.partner.concern,'argument_unresolved')
 assert.equal(act(act(s,'listen'),'ask_event').conversation.ending.kind,'refused')
 assert.equal(run('bad_day',['give_tissue']).conversation.ending,null)
 assert.equal(run('notebook',['give_tissue','acknowledge']).conversation.ending,null)
})
test('leaving differs from temporary distance; every update path is sealed after ending',()=>{
 const fresh=createCoffeeScene(), away=act(fresh,'give_space');assert.equal(away.conversation.ending,null)
 const done=act(away,'leave');assert.equal(done.conversation.ending.kind,'left');assert.equal(done.environment.table,'wet')
 for(const a of ['give_tissue','ask_event','leave','acknowledge'])assert.equal(act(done,a),done)
 assert.equal(stepCoffeeScene(done,{status:'uncertain',act:'clarify',target:'unknown'}),done)
 assert.deepEqual(coffeeCandidates(done),[])
 assert.equal(createCoffeeScene().conversation.ending,null)
})
test('an apology softens repetition once; it neither moves objects nor erases responsibility',()=>{
 const s=run('cleanup',['offer_tissue','offer_tissue','offer_tissue','apologize'])
 assert.equal(s.conversation.pressure,0);assert.equal(s.environment.tissue,'player');assert.equal(s.relationship.apologized,false)
 assert.equal(s.conversation.repairUsed,true)
})

test('declining a request is not acknowledgment, delegation or physical execution',()=>{
 const s=run('notebook',['offer_help','acknowledge','decline_help'])
 assert.equal(s.relationship.notebookConsent,false)
 assert.equal(s.environment.notebookPosition,'spill')
 assert.equal(s.conversation.closing,'rest')
 assert.equal(act(s,'acknowledge').conversation.ending.kind,'rest')
})

test('late local interpretations cannot reopen an ended scene; repair preserves a first responsible apology',()=>{
 const done=run('cleanup',['leave'])
 const late={...choiceInterpretation('give_tissue'),source:'local-model'}
 assert.equal(stepCoffeeScene(done,late,'紙を渡す'),done)
 let c=createCoffeeScene('C'); for(const a of ['offer_tissue','offer_tissue','offer_tissue','apologize'])c=act(c,a)
 assert.equal(c.relationship.apologized,true);assert.equal(c.conversation.pressure,0)
})
