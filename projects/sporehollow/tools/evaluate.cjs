'use strict';
const {World,idx}=require('../src/sim.js');
const strategies={
 idle(w){},
 nests(w){for(const [x,y] of [[8,8],[8,7],[8,6],[15,10],[15,11],[15,12],[21,8],[21,7],[21,6]])w.act('dig',x,y);for(const [x,y] of [[8,7],[15,11],[21,7]])w.act('seed',x,y);},
 cavern(w){for(let y=8;y>=5;y--)for(let x=5;x<14;x++)w.act('dig',x,y);},
 detour(w){for(let x=5;x<=12;x++)w.act('dig',x,8);for(let x=5;x<=12;x++)w.act('dig',x,7);for(const x of [6,8,10])w.act('seal',x,9);w.act('dig',8,6);w.act('seed',8,7);},
 seal(w){for(const x of [6,9,14,19,24])w.act('seal',x,9);},
};
function run(strategy,seed){const w=new World(seed);strategies[strategy](w);while(!w.result)w.step();return w.snapshot();}
if(require.main===module){const n=Number(process.argv[2]||20);const out={};for(const name of Object.keys(strategies)){const runs=Array.from({length:n},(_,i)=>run(name,i+1));const avg=f=>+(runs.reduce((s,r)=>s+f(r),0)/n).toFixed(2);out[name]={runs:n,wins:runs.filter(r=>r.result==='win').length,kills:avg(r=>r.stats.kills),predation:avg(r=>r.stats.predation),births:avg(r=>r.stats.births.grazer+r.stats.births.hunter),seconds:avg(r=>r.seconds),core:avg(r=>r.core),survivors:avg(r=>r.counts.grazer+r.counts.hunter),starvation:avg(r=>r.stats.starvation)};}console.log(JSON.stringify(out,null,2));}
module.exports={strategies,run};
