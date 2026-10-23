
const config={"canvas": [1671, 941], "default_scene": {"id": "E3_heart_flutter", "title": "E3 隣の男子を意識して胸に手を添える", "story": "相手のほうを見て胸元に手を重ねる。会話に参加する男子と、同席の男子が見える距離。", "substitute": false, "background": "../../projects/local-ai-image-lab/assets/locations/heroine-home/living-night-sofa-bedroom-slide-open.png", "background_closed": "../../projects/local-ai-image-lab/assets/locations/heroine-home/living-night-sofa-bedroom-slide-closed.png", "layers": [{"asset": "contact_shadow", "source": "../media/cfd394d2eae5a6daefa0.png", "crop": [0, 0, 1671, 941], "original_size": [1671, 941], "x": 0, "y": 0, "w": 1671, "h": 941, "group": "接地影", "mirror": false}, {"asset": "male_a", "source": "../media/eeba6ab352228d377b79.png", "crop": [210, 9, 873, 1488], "original_size": [1037, 1516], "w": 280, "h": 625, "group": "相手男子A", "mirror": false, "x": 674, "y": 139, "anchor": {"source": [520, 875], "target": [805, 505], "purpose": "座面の支持点またはキスの口元"}}, {"asset": "heroine_heart_flutter", "source": "../media/0061783d6f3c1200a549.png", "crop": [310, 12, 805, 1500], "original_size": [1037, 1516], "w": 178, "h": 535, "group": "ヒロイン", "mirror": false, "x": 947, "y": 186, "anchor": {"source": [555, 900], "target": [1035, 505], "purpose": "座面の支持点またはキスの口元"}}, {"asset": "table", "source": "../../projects/local-ai-image-lab/assets/locations/heroine-home/living-night-sofa-bedroom-table-foreground.png", "crop": [0, 0, 1671, 941], "original_size": [1671, 941], "w": 1671, "h": 941, "group": "家具前景", "mirror": false, "x": 0, "y": 0}, {"asset": "can", "source": "../media/640a19a8c2139855653c.png", "crop": [219, 178, 823, 1378], "original_size": [1024, 1536], "w": 27, "h": 54, "group": "お酒", "mirror": false, "x": 948, "y": 514}, {"asset": "bottle", "source": "../media/85cc1e2ded086fe6a8f5.png", "crop": [297, 73, 722, 1455], "original_size": [1024, 1536], "w": 28, "h": 92, "group": "お酒", "mirror": false, "x": 1007, "y": 460}, {"asset": "glass", "source": "../media/8faa0b85a06c48b55446.png", "crop": [330, 203, 964, 987], "original_size": [1295, 1214], "w": 35, "h": 43, "group": "お酒", "mirror": false, "x": 1064, "y": 532}, {"asset": "mob_b_teasing", "source": "../media/3a4ddaba26eefd768047.png", "crop": [27, 16, 1035, 1435], "original_size": [1038, 1515], "w": 376, "h": 530, "group": "同席男子B", "mirror": false, "x": 72, "y": 396}, {"asset": "male_c", "source": "../media/84b8276301b806bcc0ba.png", "crop": [24, 87, 1005, 1460], "original_size": [1037, 1516], "w": 379, "h": 530, "group": "同席男子C", "mirror": false, "x": 1260, "y": 396}, {"asset": "can", "source": "../media/640a19a8c2139855653c.png", "crop": [219, 178, 823, 1378], "original_size": [1024, 1536], "w": 31, "h": 61, "group": "お酒", "mirror": false, "x": 444, "y": 836}, {"asset": "glass", "source": "../media/8faa0b85a06c48b55446.png", "crop": [330, 203, 964, 987], "original_size": [1295, 1214], "w": 36, "h": 45, "group": "お酒", "mirror": false, "x": 1172, "y": 865}, {"asset": "bottle", "source": "../media/85cc1e2ded086fe6a8f5.png", "crop": [297, 73, 722, 1455], "original_size": [1024, 1536], "w": 30, "h": 99, "group": "お酒", "mirror": false, "x": 1225, "y": 797}], "male_count": 3, "female_count": 1, "heroine_asset": "heroine_heart_flutter", "contact_review": "座面・床支持、人物の大小、机の原寸・重なりを目視調整。手指・腕の回り込み・複雑な脚絡みは仕上げ余地あり。", "files": {"open": "../media/63663886c57c173b1741.png", "closed": "../media/e754790c4cd1ab4e6372.png"}}, "pairs": [{"id": "01_sweet_hug_v2", "label": "甘えて抱きつく", "action": "cuddle_arm", "representation": "paired", "participants": ["heroine", "male_a"], "layer": {"asset": "01_sweet_hug_v2", "source": "../media/5368c2fd90d168c0159c.png", "shadow": "../media/711799e937c2e26b3206.png", "crop": [71, 10, 1011, 1486], "original_size": [1037, 1516], "x": 704, "y": 149, "w": 398, "h": 625, "mirror": false, "group": "接触ペア", "source_anchor": [580, 850], "target_anchor": [920, 505]}, "files": {"open": "../media/31f47b3905083c56a6f1.png", "closed": "../media/4ea2c9fc64821f61802f.png"}}, {"id": "02_wont_let_go_v2", "label": "抱きついて離れたくない", "action": "cling", "representation": "paired", "participants": ["heroine", "male_a"], "layer": {"asset": "02_wont_let_go_v2", "source": "../media/76a90bc194f79fb3fd66.png", "shadow": "../media/132991388cdb72d3586e.png", "crop": [64, 2, 1001, 1490], "original_size": [1037, 1516], "x": 703, "y": 149, "w": 394, "h": 625, "mirror": false, "group": "接触ペア", "source_anchor": [580, 850], "target_anchor": [920, 505]}, "files": {"open": "../media/c876b919e91690ea6096.png", "closed": "../media/2ffa5d2a2173e772494c.png"}}, {"id": "03_lean_in", "label": "身を寄せる", "action": "lean", "representation": "paired", "participants": ["heroine", "male_a"], "layer": {"asset": "03_lean_in", "source": "../media/237dc8598cc29e2ac9ce.png", "shadow": "../media/df2de87887f169f69968.png", "crop": [77, 6, 985, 1486], "original_size": [1037, 1516], "x": 708, "y": 149, "w": 383, "h": 625, "mirror": false, "group": "接触ペア", "source_anchor": [580, 850], "target_anchor": [920, 505]}, "files": {"open": "../media/51505a9fe99f6848196e.png", "closed": "../media/ee12897fe5452efb7f9c.png"}}, {"id": "04_mutual_lean", "label": "身を寄せ合う", "action": "mutual_lean", "representation": "paired", "participants": ["heroine", "male_a"], "layer": {"asset": "04_mutual_lean", "source": "../media/21efd9e3c92ccd7a989d.png", "shadow": "../media/8a8642b67fbcc527b01e.png", "crop": [75, 7, 1002, 1489], "original_size": [1037, 1516], "x": 707, "y": 149, "w": 391, "h": 625, "mirror": false, "group": "接触ペア", "source_anchor": [580, 850], "target_anchor": [920, 505]}, "files": {"open": "../media/aaaec4ce8af451924eae.png", "closed": "../media/4819deafd600bdf3cf23.png"}}, {"id": "05_hold_hands", "label": "手をつなぐ", "action": "hold_hands", "representation": "paired", "participants": ["heroine", "male_a"], "layer": {"asset": "05_hold_hands", "source": "../media/db7615ba0b6f450185f0.png", "shadow": "../media/01a8bfa8d3bb794ac7ed.png", "crop": [71, 12, 1000, 1499], "original_size": [1037, 1516], "x": 666, "y": 153, "w": 390, "h": 625, "mirror": false, "group": "接触ペア", "source_anchor": [580, 850], "target_anchor": [880, 505]}, "files": {"open": "../media/0c12e8e20c36115f5221.png", "closed": "../media/3e7c0fe4f438e85530b8.png"}}, {"id": "06_gaze", "label": "見つめ合う", "action": "gaze", "representation": "paired", "participants": ["heroine", "male_a"], "layer": {"asset": "06_gaze", "source": "../media/d3d96253747902427ac2.png", "shadow": "../media/8d9796958b753b3995b5.png", "crop": [62, 9, 1010, 1475], "original_size": [1037, 1516], "x": 699, "y": 146, "w": 404, "h": 625, "mirror": false, "group": "接触ペア", "source_anchor": [580, 850], "target_anchor": [920, 505]}, "files": {"open": "../media/c7cdef4e6585e5f31965.png", "closed": "../media/815bfb8f1deb272c6e5c.png"}}], "individual_lean": {"asset": "09_independent_lean", "source": "../media/74d4249a231f7b5c3390.png", "shadow": "../media/b3275dca2b7813d8f9d7.png", "crop": [211, 13, 821, 1505], "original_size": [1037, 1516], "x": 857, "y": 209, "w": 227, "h": 555, "mirror": false, "group": "ヒロイン", "source_anchor": [285, 230], "target_anchor": [885, 290]}, "participants": ["heroine", "male_a"], "spectators": ["male_b", "male_c"], "interaction_state": {"action": "none", "target_id": "male_a", "representation": "individual", "pair_asset_id": null}, "on_enter_contact": ["validate asset before changing visibility", "snapshot independent transforms", "hide only heroine and male_a", "show a single pair group at shared root", "keep male_b and male_c visible"], "on_exit_contact": ["remove pair group", "restore heroine and male_a from snapshot", "keep spectators untouched"], "root_operations": ["translate group", "uniform scale group"], "not_implemented": ["independent limb rigging", "front-back arm overlay switching", "expression replacement inside paired face", "game-engine integration"], "heart_effect": "../media/455813e2539163061a9d.png"},canvasWidth=config.canvas[0],canvasHeight=config.canvas[1];
const stage=document.getElementById('stage'),viewport=document.getElementById('viewport'),pose=document.getElementById('pose');
for(const p of config.pairs){const o=new Option(p.label,p.id);pose.add(o)}
for(const label of ['首に腕を回す：未生成','首への甘噛み：未生成']){const o=new Option(label,'unavailable');o.disabled=true;pose.add(o)}
const zero=()=>({dx:0,dy:0,scale:1});
const state={mode:'paired',pairId:config.pairs[0].id,closed:false,heart:false,pairMotion:zero(),individualMotion:zero()};
let snapshot={mode:'none',individualMotion:zero()},root=null,rootLayer=null,viewScale=1;
const clone=v=>JSON.parse(JSON.stringify(v));
function pairById(id){return config.pairs.find(p=>p.id===id)}
function enterPair(){
 const candidate=pairById(pose.value);
 if(!candidate){document.getElementById('status').textContent='素材がないため表示は変更していません。';return}
 if(state.mode!=='paired')snapshot={mode:state.mode,individualMotion:clone(state.individualMotion)};
 state.pairId=candidate.id;state.mode='paired';state.pairMotion=zero();render();
}
function exitPair(){
 state.mode=snapshot.mode;state.individualMotion=clone(snapshot.individualMotion);
 render();
}
function element(l){
 const wrap=document.createElement('div');wrap.className='layer';
 Object.assign(wrap.style,{left:l.x+'px',top:l.y+'px',width:l.w+'px',height:l.h+'px'});
 const im=document.createElement('img'),b=l.crop,z=l.h/(b[3]-b[1]);im.src=l.source;im.alt='';
 Object.assign(im.style,{position:'absolute',left:(-b[0]*z)+'px',top:(-b[1]*z)+'px',width:(l.original_size[0]*z)+'px',height:(l.original_size[1]*z)+'px',maxWidth:'none'});
 if(l.mirror){im.style.transform='scaleX(-1)';im.style.transformOrigin=((b[0]+b[2])*z/2)+'px center'}
 wrap.append(im);return wrap;
}
function actorsFor(group){return group==='相手男子A'?['male_a']:group==='ヒロイン'?['heroine']:group==='同席男子B'?['male_b']:group==='同席男子C'?['male_c']:[]}
function rootFor(l,ids){
 root=document.createElement('div');root.className='contactRoot';root.dataset.actors=ids.join(',');
 root.setAttribute('aria-label',state.mode==='paired'?'二人をまとめて左右に動かす':'女性単独を動かす');
 Object.assign(root.style,{left:l.x+'px',top:l.y+'px',width:l.w+'px',height:l.h+'px'});
 const fx=document.createElement('img');fx.className='hearts';fx.src=config.heart_effect;fx.alt='ハート演出';fx.hidden=!state.heart;root.append(fx);
 root.append(element({...l,x:0,y:0,source:l.shadow}));
 root.append(element({...l,x:0,y:0}));
 rootLayer=l;
 let drag=null;
 root.onpointerdown=ev=>{if(ev.button!==0)return;drag={x:ev.clientX,y:ev.clientY,start:clone(motion())};root.setPointerCapture(ev.pointerId);ev.preventDefault()};
 root.onpointermove=ev=>{if(!drag)return;const m=motion();m.dx=Math.max(-70,Math.min(70,Math.round(drag.start.dx+(ev.clientX-drag.x)/viewScale)));m.dy=state.mode==='individual'?Math.max(-25,Math.min(25,Math.round(drag.start.dy+(ev.clientY-drag.y)/viewScale))):0;refresh()};
 root.onpointerup=ev=>{drag=null;if(root.hasPointerCapture(ev.pointerId))root.releasePointerCapture(ev.pointerId)};
 root.onpointercancel=()=>{drag=null};return root;
}
function motion(){return state.mode==='paired'?state.pairMotion:state.individualMotion}
function flags(){
 const p=pairById(state.pairId),active=state.mode!=='none';
 return {contact_active:active,action:state.mode==='paired'?p.action:state.mode==='individual'?'lean':'none',target_id:active?'male_a':null,render_mode:state.mode,pair_asset:state.mode==='paired'?p.layer.source:null,hidden_individuals:state.mode==='paired'?['heroine','male_a']:[],spectators_kept:['male_b','male_c'],transform:active?clone(motion()):null,heart:state.heart};
}
function refresh(){
 const enabled=state.mode!=='none',m=motion(),dx=document.getElementById('dx'),dy=document.getElementById('dy'),size=document.getElementById('size');
 dx.disabled=size.disabled=!enabled;dy.disabled=state.mode!=='individual';
 if(root&&rootLayer){
  const l=rootLayer,b=l.crop,z=l.h/(b[3]-b[1]);root.style.transformOrigin=((l.source_anchor[0]-b[0])*z)+'px '+((l.source_anchor[1]-b[1])*z)+'px';
  root.style.transform='translate('+m.dx+'px,'+(state.mode==='paired'?0:m.dy)+'px) scale('+m.scale+')';
  root.querySelector('.hearts').hidden=!state.heart;
 }
 dx.value=m.dx;dy.value=m.dy;size.value=Math.round(m.scale*100);
 document.getElementById('dxValue').textContent=m.dx+'px';document.getElementById('dyValue').textContent=state.mode==='paired'?'座面の高さを固定':m.dy+'px';document.getElementById('sizeValue').textContent=Math.round(m.scale*100)+'%';
 document.getElementById('flags').textContent=JSON.stringify(flags(),null,2);
 const ids=[...stage.querySelectorAll('[data-actors]')].flatMap(n=>n.dataset.actors.split(',')).filter(Boolean);
 const unique=new Set(ids),ok=unique.size===ids.length&&['heroine','male_a','male_b','male_c'].every(id=>unique.has(id));
 document.getElementById('status').textContent=(ok?'ヒロイン1人／男子3人。':'表示人数に不整合があります。')+(state.mode==='paired'?'接触中の二人は1グループ。':state.mode==='individual'?'女性単独の接点を調整。':'接触前の個別表示。');
 document.getElementById('representation').value=state.mode;document.getElementById('exit').disabled=state.mode!=='paired';
}
function render(){
 stage.replaceChildren();root=null;rootLayer=null;
 const bg=document.createElement('img');bg.className='background';bg.src=config.default_scene[state.closed?'background_closed':'background'];bg.alt='夜リビング';stage.append(bg);
 let inserted=false;
 for(const l of config.default_scene.layers){
  if(l.group==='接地影')continue;
  if(state.mode==='paired'&&['相手男子A','ヒロイン'].includes(l.group))continue;
  if(state.mode==='individual'&&l.group==='ヒロイン')continue;
  if(l.group==='家具前景'&&!inserted){
   if(state.mode==='paired'){const p=pairById(state.pairId);stage.append(rootFor(p.layer,['heroine','male_a']))}
   else if(state.mode==='individual')stage.append(rootFor(config.individual_lean,['heroine']));
   inserted=true;
  }
  const node=element(l),ids=actorsFor(l.group);if(ids.length)node.dataset.actors=ids.join(',');stage.append(node);
 }
 document.getElementById('door').textContent=state.closed?'引き戸を開ける':'引き戸を閉める';refresh();
}
document.getElementById('enter').onclick=enterPair;document.getElementById('exit').onclick=exitPair;
pose.onchange=()=>{if(state.mode==='paired')enterPair()};
document.getElementById('representation').onchange=ev=>{
 if(ev.target.value==='paired'){enterPair();return}
 state.mode=ev.target.value;render();
};
for(const id of ['dx','dy','size'])document.getElementById(id).oninput=ev=>{const m=motion();if(id==='dx')m.dx=+ev.target.value;else if(id==='dy')m.dy=+ev.target.value;else m.scale=+ev.target.value/100;refresh()};
document.getElementById('reset').onclick=()=>{if(state.mode==='paired')state.pairMotion=zero();else state.individualMotion=zero();refresh()};
document.getElementById('door').onclick=()=>{state.closed=!state.closed;render()};
document.getElementById('heart').onchange=ev=>{state.heart=ev.target.checked;refresh()};
document.getElementById('export').onclick=()=>{const u=URL.createObjectURL(new Blob([JSON.stringify(flags(),null,2)],{type:'application/json'})),a=document.createElement('a');a.href=u;a.download='contact-placement.json';a.click();setTimeout(()=>URL.revokeObjectURL(u),1000)};
const resize=()=>{viewScale=viewport.clientWidth/canvasWidth;stage.style.transform='scale('+viewScale+')'};
new ResizeObserver(resize).observe(viewport);render();resize();
