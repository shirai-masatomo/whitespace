/* Original deterministic ecosystem model. No DOM, timers, assets or network. */
(function(root) {
  'use strict';
  const W = 28, H = 18, STEP = 0.5;
  const DIRS = [[1,0],[-1,0],[0,1],[0,-1]];
  const RULES = Object.freeze({prepTicks:80, waveGap:22, raiders:3, energy:52, maxTicks:440, grazerCap:38, hunterCap:10, invaderHP:34, invaderAttack:4, hunterHP:15, hunterAttack:4});
  const idx = (x,y) => y*W+x;
  class World {
    constructor(seed=1) {
      this.seed=seed>>>0; this.rng=this.seed||1; this.tick=0; this.phase='prepare'; this.result=null;
      this.core=3; this.energy=RULES.energy; this.nextId=1; this.spawned=0; this.invaders=[]; this.animals=[];
      this.actions=[]; this.events=[]; this.samples=[]; this.effects=[]; this.revision=0; this.routeRevision=-1;
      this.stats={predation:0,grazing:0,births:{grazer:0,hunter:0},starvation:0,kills:0,breaches:0,maxReach:0,excavated:0,excavatedByRaiders:0};
      this.tiles=Array.from({length:W*H},(_,i)=>({solid:true,nutrient:10+Math.floor(this.random()*12),moss:0,spore:false,egg:false}));
      this.entry=idx(1,9); this.heart=idx(26,9);
      for(let x=1;x<27;x++) this.tiles[idx(x,9)].solid=false;
      for(const [x,y] of [[8,6],[15,12],[21,6]]) this.tiles[idx(x,y)].egg=true;
      for(const x of [3,7,12,18,23]) {this.tiles[idx(x,9)].moss=3;this.tiles[idx(x,9)].spore=true;}
      for(const x of [5,11,20]) this.addAnimal('grazer',idx(x,9),11);

      this.say('地表の採掘隊が近づいている。横道と餌場を育てよう。');
      this.sample();
    }
    random() { this.rng=(Math.imul(this.rng,1664525)+1013904223)>>>0; return this.rng/4294967296; }
    neighbors(i) { const x=i%W,y=Math.floor(i/W); return DIRS.map(([dx,dy])=>[x+dx,y+dy]).filter(([a,b])=>a>0&&a<W-1&&b>0&&b<H-1).map(([a,b])=>idx(a,b)); }
    say(text) { this.events.push({tick:this.tick,text}); if(this.events.length>12)this.events.shift(); }
    addAnimal(kind,pos,energy=12) { const a={id:this.nextId++,kind,pos,energy,hp:kind==='hunter'?RULES.hunterHP:4,age:0}; this.animals.push(a); return a; }
    act(type,x,y,record=true) {
      if(this.result || !Number.isInteger(x)||!Number.isInteger(y)||x<=0||x>=W-1||y<=0||y>=H-1) return false;
      const p=idx(x,y), t=this.tiles[p]; let ok=false;
      if(type==='dig' && t.solid && this.energy>=1 && this.neighbors(p).some(n=>!this.tiles[n].solid)) {
        this.energy--;t.solid=false;this.stats.excavated++;this.revision++;ok=true;
        if(t.egg) { t.egg=false;this.addAnimal('hunter',p,15);this.say('眠っていたツノイモリが目覚めた。胞虫を探して動き出す。'); }
      } else if(type==='seal'&&!t.solid&&p!==this.entry&&p!==this.heart&&this.energy>=3&&!this.animals.some(a=>a.pos===p)&&!this.invaders.some(a=>a.pos===p)) {
        this.energy-=3;t.solid=true;t.moss=0;t.spore=false;this.revision++;ok=true;
      } else if(type==='seed'&&!t.solid&&t.moss===0&&this.energy>=3) {
        this.energy-=3;t.moss=2;t.spore=true;t.nutrient+=8;ok=true;
      }
      if(record)this.actions.push({tick:this.tick,type,x,y,accepted:ok});
      return ok;
    }
    begin(record=true) { if(this.phase!=='prepare'||this.result)return false;this.phase='defend';this.waveStart=this.tick;this.say('採掘隊が侵入！ 生きものは命令を聞かない。餌と通り道で導こう。');if(record)this.actions.push({tick:this.tick,type:'begin',accepted:true});return true; }
    search(start,predicate,limit=12) {
      const queue=[start], dist=new Map([[start,0]]), first=new Map([[start,start]]);
      for(let k=0;k<queue.length;k++) {
        const p=queue[k]; if(predicate(p)&&p!==start)return first.get(p);
        if(dist.get(p)>=limit)continue;
        const offset=Math.floor(this.random()*4),ns=this.neighbors(p);
        for(let z=0;z<ns.length;z++) {const n=ns[(z+offset)%ns.length];if(this.tiles[n].solid||dist.has(n))continue;dist.set(n,dist.get(p)+1);first.set(n,p===start?n:first.get(p));queue.push(n);}
      }
      return start;
    }
    routeCosts() {
      if(this.routeRevision===this.revision)return this.costs;
      const costs=Array(W*H).fill(Infinity),open=new Set([this.heart]);costs[this.heart]=0;
      while(open.size){let best=-1;for(const p of open)if(best<0||costs[p]<costs[best])best=p;open.delete(best);for(const n of this.neighbors(best)){const cost=costs[best]+(this.tiles[best].solid?9:1);if(cost<costs[n]){costs[n]=cost;open.add(n);}}}
      this.routeRevision=this.revision;this.costs=costs;return costs;
    }
    ecology() {
      for(let p=0;p<this.tiles.length;p++){
        const t=this.tiles[p];if(t.solid)continue;
        const ns=this.neighbors(p),walls=ns.filter(n=>this.tiles[n].solid).length;
        if(!t.moss){if(t.spore&&t.nutrient>0&&this.random()<0.04+walls*0.015){t.moss=1;t.nutrient--;}continue;}
        if(t.nutrient>0&&t.moss<5&&this.random()<0.10+walls*0.07){t.moss++;t.nutrient--;}
        if(t.moss>=3&&this.tick%6===0&&this.random()<0.32){const n=ns[Math.floor(this.random()*ns.length)],b=this.tiles[n];if(!b.solid&&!b.moss&&b.nutrient>0){b.moss=1;b.spore=true;t.moss--;}}
      }
      for(const a of [...this.animals]) {
        if(a.hp<=0)continue;a.age++;a.energy-=a.kind==='hunter'?0.11:0.17;
        if(a.kind==='grazer') {
          if(this.tiles[a.pos].moss>0){this.tiles[a.pos].moss--;a.energy+=3.5;this.stats.grazing++;this.effects.push({pos:a.pos,color:"#99daa0",until:this.tick+2});}
          else if(this.tick%2===a.id%2)a.pos=this.search(a.pos,p=>this.tiles[p].moss>0,9);
          if(a.energy>16&&this.random()<0.18&&this.count('grazer')<RULES.grazerCap){a.energy*=0.5;this.addAnimal('grazer',a.pos,a.energy);this.stats.births.grazer++;this.effects.push({pos:a.pos,color:"#efcf89",until:this.tick+3});}
        } else {
          const enemy=this.invaders.find(v=>v.hp>0&&(v.pos===a.pos||this.neighbors(a.pos).includes(v.pos)));
          if(enemy && this.tick%2===0){enemy.hp-=a.energy>5?RULES.hunterAttack:2;a.energy-=0.2;}
          else {
            const prey=this.animals.find(v=>v.kind==='grazer'&&v.hp>0&&v.pos===a.pos);
            if(prey){prey.hp=0;a.energy+=10;this.stats.predation++;this.effects.push({pos:a.pos,color:"#bfa0df",until:this.tick+3});}
            else if(this.tick%2===a.id%2){
              const target=this.search(a.pos,p=>this.animals.some(v=>v.kind==='grazer'&&v.hp>0&&v.pos===p),8);
              const previous=a.pos;a.pos=target;
              if(target===previous&&this.random()<0.12){const choices=this.neighbors(a.pos).filter(p=>!this.tiles[p].solid);if(choices.length)a.pos=choices[Math.floor(this.random()*choices.length)];}
            }
            if(a.energy>26&&this.random()<0.16&&this.count('hunter')<RULES.hunterCap){a.energy*=0.5;this.addAnimal('hunter',a.pos,a.energy);this.stats.births.hunter++;this.effects.push({pos:a.pos,color:"#e4b9f1",until:this.tick+3});}
          }
        }
        if(a.energy<=0){a.hp=0;this.stats.starvation++;this.tiles[a.pos].nutrient+=8;}
      }
      this.animals=this.animals.filter(a=>a.hp>0);
    }
    count(kind){return this.animals.filter(a=>a.kind===kind&&a.hp>0).length;}
    raid() {
      if(this.spawned<RULES.raiders&&this.tick-this.waveStart>=this.spawned*RULES.waveGap){this.invaders.push({id:this.nextId++,pos:this.entry,hp:RULES.invaderHP,dig:0,path:[this.entry],born:this.tick});this.spawned++;}
      const costs=this.routeCosts();
      for(const v of this.invaders){
        if(v.hp<=0)continue;
        if(this.tick%2!==0)continue;
        const attacker=this.animals.find(a=>a.kind==='hunter'&&a.hp>0&&(a.pos===v.pos||this.neighbors(v.pos).includes(a.pos)));
        if(attacker){attacker.hp-=RULES.invaderAttack;this.effects.push({pos:attacker.pos,color:"#f3a083",until:this.tick+2});continue;}
        const ns=this.neighbors(v.pos);ns.sort((a,b)=>(costs[a]+(this.tiles[a].solid?9:1))-(costs[b]+(this.tiles[b].solid?9:1)));
        const next=ns[0];
        if(this.tiles[next].solid){v.dig++;if(v.dig>=4){this.tiles[next].solid=false;this.tiles[next].egg=false;v.dig=0;this.revision++;this.stats.excavatedByRaiders++;}continue;}
        v.pos=next;v.path.push(next);this.stats.maxReach=Math.max(this.stats.maxReach,v.pos%W-1);
        if(this.tiles[next].moss){this.tiles[next].moss=0;this.say('採掘隊が苔を踏み荒らした。餌場が減っていく。');}
        if(next===this.heart){this.core--;this.stats.breaches++;v.hp=0;v.escaped=true;}
      }
      for(const v of this.invaders){if(v.hp<=0&&!v.counted){v.counted=true;v.lifetime=(this.tick-v.born)*STEP;if(!v.escaped){this.stats.kills++;this.tiles[v.pos].nutrient+=18;this.say('採掘隊を撃退。残された養分から、また命が育つ。');}}}
      this.animals=this.animals.filter(a=>a.hp>0);
      if(this.core<=0)this.finish('loss');
      else if(this.spawned===RULES.raiders&&this.invaders.every(v=>v.hp<=0))this.finish('win');
    }
    step() {
      if(this.result)return;
      this.tick++;this.effects=this.effects.filter(e=>e.until>=this.tick);
      this.ecology();
      if(this.phase==='prepare'&&this.tick>=RULES.prepTicks)this.begin(false);
      if(this.phase==='defend')this.raid();
      if(this.tick%10===0)this.sample();
      if(this.tick>=RULES.maxTicks&&!this.result)this.finish('loss');
    }
    finish(result){this.result=result;this.phase='finished';this.sample();this.say(result==='win'?'地脈は守られた。あなたの庭が、採掘隊を退けた。':'地脈が奪われた。次はどこを掘り、何を育てる？');}
    sample(){this.samples.push({time:this.tick*STEP,moss:this.tiles.reduce((n,t)=>n+(t.moss>0?1:0),0),grazer:this.count('grazer'),hunter:this.count('hunter'),core:this.core});}
    snapshot(){return {version:1,seed:this.seed,tick:this.tick,seconds:this.tick*STEP,phase:this.phase,result:this.result,core:this.core,energy:this.energy,counts:{moss:this.tiles.reduce((n,t)=>n+(t.moss>0?1:0),0),grazer:this.count('grazer'),hunter:this.count('hunter')},stats:JSON.parse(JSON.stringify(this.stats)),terrain:this.tiles.map(t=>t.solid?1:0),tiles:this.tiles.map(t=>({...t})),animals:this.animals.map(a=>({...a})),invaders:this.invaders.map(v=>({...v,path:[...v.path]})),actions:this.actions.map(a=>({...a})),samples:this.samples.map(a=>({...a}))};}
  }
  function replay(snapshot) {
    const w=new World(snapshot.seed); let cursor=0;
    while(w.tick<=snapshot.tick){
      while(cursor<snapshot.actions.length&&snapshot.actions[cursor].tick===w.tick){const a=snapshot.actions[cursor++];if(a.type==='begin')w.begin();else w.act(a.type,a.x,a.y);}
      if(w.tick===snapshot.tick||w.result)break;
      w.step();
    }
    return w;
  }
  root.Spore={World,W,H,STEP,RULES,idx,replay};
  if(typeof module!=='undefined')module.exports=root.Spore;
})(globalThis);
