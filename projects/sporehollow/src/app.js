/* Canvas presentation and input only; simulation is shared with Node evaluation. */
(() => {
 'use strict';
 const {World,W,H,STEP,RULES}=Spore, canvas=document.querySelector('#board'),ctx=canvas.getContext('2d'),T=32;
 const $=id=>document.getElementById(id);let world=new World(17),started=false,paused=false,speed=1,tool='dig',hover=-1,drag=false,lastPaint=-1,acc=0,last=0,endingShown=false;
 const colors={moss:'#9ddaa4',grazer:'#edbd67',hunter:'#bea1e2'};
 function reset(seed){world=new World(seed);started=false;paused=false;endingShown=false;acc=0;speed=1;lastPaint=-1;$('intro').classList.remove('hidden');$('ending').classList.add('hidden');$('pause').textContent='一時停止';$('speed').textContent='速度 ×1';render();}
 function select(value){tool=value;for(const b of document.querySelectorAll('[data-tool]'))b.classList.toggle('selected',b.dataset.tool===tool);}
 function paint(p){if(!started||world.result||p<0||lastPaint===p)return;lastPaint=p;if(!world.act(tool,p%W,Math.floor(p/W)))$('hover').textContent='そこには使えません。隣接・地脈力・生物を確認。';render();}
 function pointer(event){const r=canvas.getBoundingClientRect();const x=Math.floor((event.clientX-r.left)/r.width*W),y=Math.floor((event.clientY-r.top)/r.height*H);return x>=0&&x<W&&y>=0&&y<H?y*W+x:-1;}
 canvas.addEventListener('pointerdown',e=>{if(e.button!==0)return;drag=true;lastPaint=-1;canvas.setPointerCapture(e.pointerId);hover=pointer(e);paint(hover);});
 canvas.addEventListener('pointermove',e=>{hover=pointer(e);if(drag)paint(hover);else render();});
 canvas.addEventListener('pointerup',()=>{drag=false;lastPaint=-1;});canvas.addEventListener('pointercancel',()=>{drag=false;});canvas.addEventListener('pointerleave',()=>{if(!drag)hover=-1;});
 document.addEventListener('keydown',e=>{if(e.repeat||['INPUT','TEXTAREA','SELECT'].includes(e.target.tagName))return;if(['1','2','3'].includes(e.key))select(['dig','seal','seed'][+e.key-1]);if(e.code==='Space'&&e.target.tagName!=='BUTTON'&&started&&!world.result){e.preventDefault();togglePause();}});
 for(const b of document.querySelectorAll('[data-tool]'))b.addEventListener('click',()=>select(b.dataset.tool));
 $('start').onclick=()=>{started=true;acc=0;$('intro').classList.add('hidden');};
 function togglePause(){paused=!paused;$('pause').textContent=paused?'再開':'一時停止';acc=0;render();}
 $('pause').onclick=togglePause;$('speed').onclick=()=>{speed=speed===1?2:1;$('speed').textContent=`速度 ×${speed}`;};
 $('invade').onclick=()=>{world.begin();render();};$('restart').onclick=()=>reset(world.seed);$('retry').onclick=()=>{const seed=world.seed;reset(seed);started=true;$('intro').classList.add('hidden');};
 $('new-seed').onclick=()=>reset((world.seed+1)>>>0);$('observe').onclick=()=>$('ending').classList.add('hidden');
 $('export').onclick=()=>{const url=URL.createObjectURL(new Blob([JSON.stringify(world.snapshot(),null,2)],{type:'application/json'}));const a=document.createElement('a');a.href=url;a.download=`sporehollow-${world.seed}-${world.tick}.json`;a.click();setTimeout(()=>URL.revokeObjectURL(url),500);};
 document.addEventListener('visibilitychange',()=>{acc=0;last=performance.now();});
 function box(x,y,w,h,c){ctx.fillStyle=c;ctx.fillRect(Math.round(x),Math.round(y),w,h);}
 function circle(x,y,r,c){ctx.fillStyle=c;ctx.beginPath();ctx.arc(x,y,r,0,Math.PI*2);ctx.fill();}
 function drawCreature(a){const x=a.pos%W*T+T/2+((a.id*7)%9-4),y=Math.floor(a.pos/W)*T+T/2+((a.id*3)%7-3);if(a.kind==='grazer'){circle(x,y,7,'#9c7343');circle(x-1,y-2,6,colors.grazer);box(x-5,y-7,2,3,'#fff1c0');box(x+2,y-3,2,2,'#213031');box(x-5,y+5,3,3,'#805b42');box(x+3,y+5,3,3,'#805b42');}else{box(x-11,y+1,6,4,'#7c659b');box(x-7,y-5,16,10,colors.hunter);box(x+5,y-9,3,5,'#e6cae1');box(x-4,y-10,3,6,'#e6cae1');box(x+5,y-3,2,2,'#19262a');box(x-6,y+5,4,3,'#806898');box(x+5,y+5,4,3,'#806898');if(a.hp<RULES.hunterHP){box(x-9,y+11,18,2,'#293936');box(x-9,y+11,Math.max(0,a.hp/RULES.hunterHP*18),2,'#d9a38c');}}}
 function render(){ctx.clearRect(0,0,canvas.width,canvas.height);box(0,0,canvas.width,canvas.height,'#101c23');
   for(let p=0;p<world.tiles.length;p++){const t=world.tiles[p],x=p%W*T,y=Math.floor(p/W)*T,border=p%W===0||p%W===W-1||p<W||p>=W*(H-1);if(t.solid){box(x,y,T,T,border?'#182728':((p*13)%5===0?'#3b4541':'#34413e'));box(x+2,y+2,T-4,2,'#4d5850');if(p%3===0){box(x+8,y+15,12,2,'#253531');box(x+18,y+16,2,8,'#253531');}if(t.nutrient>18)box(x+5,y+22,3,2,'#727455');if(t.egg){circle(x+16,y+16,10,'#533e54');circle(x+16,y+16,6,'#ce9bb8');box(x+14,y+10,3,4,'#f0d5cc');}}else{box(x,y,T,T,(p%3===0?'#16292b':'#17262b'));for(const n of world.neighbors(p))if(world.tiles[n].solid){const dx=n%W-p%W,dy=Math.floor(n/W)-Math.floor(p/W);if(dx)box(x+(dx>0?T-3:0),y,3,T,'#536151');else box(x,y+(dy>0?T-3:0),T,3,'#536151');}
     if(t.moss){for(let k=0;k<t.moss;k++){const px=x+4+(k*7+p*3)%24,py=y+6+(k*11+p)%21;box(px,py,5,5,k%2?'#6daf87':colors.moss);box(px+1,py-2,2,3,'#d2f0bd');}}}
   }
   const ex=world.entry%W*T,ey=Math.floor(world.entry/W)*T;box(ex,ey,4,T,'#ed997b');ctx.fillStyle='#f2ac8c';ctx.font='bold 12px sans-serif';ctx.fillText('入口',ex-1,ey-9);
   const cx=world.heart%W*T+16,cy=Math.floor(world.heart/W)*T+16;const glow=ctx.createRadialGradient(cx,cy,2,cx,cy,35);glow.addColorStop(0,'#f9d88a66');glow.addColorStop(1,'#f9d88a00');ctx.fillStyle=glow;ctx.fillRect(cx-35,cy-35,70,70);ctx.fillStyle='#edd28b';ctx.beginPath();ctx.moveTo(cx,cy-13);ctx.lineTo(cx+10,cy);ctx.lineTo(cx,cy+13);ctx.lineTo(cx-10,cy);ctx.fill();ctx.font='12px sans-serif';ctx.fillText('地脈',cx-12,cy-25);
   for(const a of world.animals)drawCreature(a);
   for(const v of world.invaders){if(v.hp<=0)continue;const x=v.pos%W*T+16,y=Math.floor(v.pos/W)*T+16;box(x-6,y-5,12,14,'#e88e72');box(x-9,y-10,18,6,'#c4cbc4');box(x+2,y-9,4,3,'#ffe5a6');box(x-5,y+9,4,5,'#576665');box(x+2,y+9,4,5,'#576665');box(x+9,y-1,6,3,'#e3b58d');box(x-12,y+17,24,2,'#413f3b');box(x-12,y+17,24*v.hp/RULES.invaderHP,2,'#efb993');}
   for(const effect of world.effects){const x=effect.pos%W*T+16,y=Math.floor(effect.pos/W)*T+16;ctx.strokeStyle=effect.color;ctx.lineWidth=2;ctx.beginPath();ctx.arc(x,y,10+(effect.until-world.tick)*2,0,Math.PI*2);ctx.stroke();}
   if(hover>=0){const x=hover%W*T,y=Math.floor(hover/W)*T;ctx.strokeStyle=tool==='seal'?'#ffbb83':tool==='seed'?'#b0e9b1':'#e6ead5';ctx.lineWidth=2;ctx.strokeRect(x+1,y+1,T-2,T-2);const t=world.tiles[hover];const creatures=world.animals.filter(a=>a.pos===hover);$('hover').textContent=t.egg?'眠り卵：掘るとツノイモリが目覚める':t.solid?'岩：開いた通路からつなげて掘れる':`養分 ${t.nutrient} / 苔 ${t.moss}${creatures.length?' / 生物 '+creatures.length+'匹':''}`;}
   const moss=world.tiles.filter(t=>t.moss>0).length;$('moss-count').textContent=moss;$('grazer-count').textContent=world.count('grazer');$('hunter-count').textContent=world.count('hunter');
   $('phase').textContent=world.result?'観察終了':paused?'一時停止':world.phase==='prepare'?'庭づくり':'侵入中';$('wave').textContent=world.phase==='prepare'?`侵入まで ${Math.max(0,(RULES.prepTicks-world.tick)*STEP).toFixed(0)}秒`:`採掘隊 ${world.spawned} / 3 ・ 撃退 ${world.stats.kills}`;$('core').textContent='地脈 '+ '● '.repeat(world.core)+'○ '.repeat(3-world.core);$('energy').textContent='地脈力 '+world.energy;$('ecology').textContent=`捕食 ${world.stats.predation} / 繁殖 ${world.stats.births.grazer+world.stats.births.hunter} / 餓死 ${world.stats.starvation}`;
   $('events').replaceChildren(...world.events.slice(-3).map(e=>{const div=document.createElement('div');div.textContent=`${(e.tick*STEP).toFixed(0).padStart(2,'0')}s　${e.text}`;return div;}));$('seed-label').textContent=`SEED ${world.seed} · ${(world.tick*STEP).toFixed(0)}秒`;$('invade').disabled=!started||world.phase!=='prepare';$('pause').disabled=!started||!!world.result;
   if(world.result&&!endingShown){endingShown=true;$('ending').classList.remove('hidden');$('ending-title').textContent=world.result==='win'?'地脈は、守られた。':'地脈が、奪われた。';$('ending-copy').textContent=world.result==='win'?'生きものたちが採掘隊を退けました。別の掘り方では、どんな庭になるでしょう。':'採掘隊は地脈へ到達しました。餌場と巣をつなぐか、進路を曲げるか。次の仮説を試そう。';$('ending-stats').textContent=`撃退 ${world.stats.kills}/3　捕食 ${world.stats.predation}　繁殖 ${world.stats.births.grazer+world.stats.births.hunter}　餓死 ${world.stats.starvation}`;}
 }
 function frame(now){if(last&&started&&!paused&&!world.result&&!document.hidden){acc+=Math.min((now-last)/1000,0.2)*speed;while(acc>=STEP){world.step();acc-=STEP;}render();}last=now;requestAnimationFrame(frame);}render();requestAnimationFrame(frame);
 // Read-only snapshot for browser diagnostics; gameplay and input remain authoritative.
 window.sporeSnapshot=()=>world.snapshot();
})();
