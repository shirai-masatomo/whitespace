'use strict';
const data=JSON.parse(document.getElementById('review-data').textContent), assets=data.assets, $=id=>document.getElementById(id);
const KEY='heroine-expression-decisions-v1', statuses={unreviewed:'未確認',accepted:'採用',hold:'保留',rejected:'不採用',revise:'修正待ち'};
const byId=new Map(assets.map(a=>[a.id,a])), selections=new Set();let decisions={},storageOK=true;
function isLatest(a){return Array.isArray(data.latest_ids)?data.latest_ids.includes(a.id):a.new}
function message(s){$('message').textContent=s}
try{const cached=JSON.parse(localStorage.getItem(KEY)||'{}');if(cached&&typeof cached==='object'&&!Array.isArray(cached))decisions=cached}catch(e){storageOK=false;message('ブラウザー保存が使えません。採否はJSONへ書き出してください。')}
function current(a){const d=decisions[a.id];return d&&d.source_sha256===a.sha256&&Object.hasOwn(statuses,d.status)?d:{status:'unreviewed',note:'',source_sha256:a.sha256}}
function stash(){try{localStorage.setItem(KEY,JSON.stringify(decisions))}catch(e){storageOK=false;message('保存に失敗しました。JSONを書き出して保管してください。')}}
function escapeText(v){return String(v??'')}
function el(tag,text,cls){const n=document.createElement(tag);if(text!==undefined)n.textContent=escapeText(text);if(cls)n.className=cls;return n}
function option(value,label){const n=el('option',label);n.value=value;return n}
for(const [k,label] of [['gaze','視線'],['blush','赤み'],['brows','眉'],['mouth','口'],['kind','種類']]){
 const s=$(k);s.append(option('',label+'：すべて'));const values=[...new Set(assets.map(a=>String(a.factors[k]??'未分類')))];values.sort((a,b)=>a.localeCompare(b,'ja')).forEach(v=>s.append(option(v,v)));
}
$('status').append(option('','採否：すべて'));for(const [k,v] of Object.entries(statuses))$('status').append(option(k,v));
function stats(){const counts=Object.fromEntries(Object.keys(statuses).map(k=>[k,0]));for(const a of assets)counts[current(a).status]++;$('stats').textContent=assets.length+'候補 ｜ '+Object.entries(counts).map(([k,v])=>statuses[k]+' '+v).join(' ／ ')}
function setDecision(a,status,note){decisions[a.id]={status,note,source_sha256:a.sha256,updated_at:new Date().toISOString()};stash();stats()}
function card(a){
 const c=el('article',undefined,'card');c.dataset.status=current(a).status;c.dataset.id=a.id;
 const im=el('img');im.src=$('view').value==='full'?a.full_url:a.preview_url;im.alt=a.label;im.loading='lazy';c.append(im);
 const h=el('h3',a.label);c.append(h);c.append(el('span',isLatest(a)?'今回のアップ':'既存候補','tag'+(isLatest(a)?' new':'')));c.append(el('small',a.id));
 const f=el('div',undefined,'factors');for(const [k,t] of [['gaze','視線'],['blush','赤み'],['brows','眉'],['mouth','口']])f.append(el('p',t+'：'+a.factors[k]));c.append(f);
 c.append(el('p',a.annotation_note,'sub'));if(a.quality_note)c.append(el('p',a.quality_note,'sub'));
 const lab=el('label',undefined,'compare-label'),check=el('input');check.type='checkbox';check.checked=selections.has(a.id);lab.append(check,document.createTextNode(' 比較に並べる（最大4件）'));check.addEventListener('change',()=>{if(check.checked&&selections.size>=4){check.checked=false;message('比較は4件までです。先に1件外してください。');return}if(check.checked)selections.add(a.id);else selections.delete(a.id);comparison()});c.append(lab);
 const decision=el('select',undefined,'decision');decision.setAttribute('aria-label',a.label+'の採否');for(const [k,v] of Object.entries(statuses))decision.append(option(k,v));decision.value=current(a).status;
 const note=el('textarea');note.placeholder='採否の理由・直したい点';note.value=current(a).note;note.setAttribute('aria-label',a.label+'のメモ');
 decision.addEventListener('change',()=>{setDecision(a,decision.value,note.value);c.dataset.status=decision.value;comparison();render();message(a.label+'：'+statuses[decision.value]+'。'+(storageOK?'確定結果はJSONにも書き出してください。':'ブラウザー保存に失敗したためJSONを書き出してください。'))});
 note.addEventListener('change',()=>{setDecision(a,decision.value,note.value);message(storageOK?'メモをブラウザー保存しました。JSON書き出しでバックアップできます。':'ブラウザー保存に失敗しました。JSONを書き出して保管してください。')});c.append(decision,note);
 const links=el('div',undefined,'toolbar');for(const [name,url] of [[a.full_label||'全身PNG',a.full_url],['顔パッチ',a.overlay_url]])if(url){const link=el('a',name);link.href=url;link.target='_blank';link.rel='noopener';links.append(link)}c.append(links);
 const detail=el('details'),sum=el('summary','作成条件・既存コメント');detail.append(sum,el('p',a.requested_spec||'既存資料を参照'),el('p',a.previous_note||''),el('p','SHA256: '+a.sha256));c.append(detail);return c;
}
function filtered(){const q=$('query').value.trim().toLowerCase();return assets.filter(a=>['gaze','blush','brows','mouth','kind'].every(k=>!$(k).value||String(a.factors[k])===$(k).value)&&(!$('status').value||current(a).status===$('status').value)&&(!q||[a.id,a.label,...Object.values(a.factors),a.previous_note,current(a).note].join(' ').toLowerCase().includes(q))&&(!$('newOnly').checked||isLatest(a)))}
function render(){const list=filtered(),root=$('cards');root.replaceChildren(...list.map(card));$('count').textContent=list.length+' / '+assets.length+'候補';$('empty').hidden=list.length>0;stats()}
function comparison(){const root=$('comparison');root.replaceChildren();for(const id of selections){const a=byId.get(id),fig=el('figure'),im=el('img');im.src=a.preview_url;im.alt=a.label;fig.append(im,el('figcaption',a.label+' ｜ '+statuses[current(a).status]));for(const [k,v] of Object.entries(a.factors))if(k!=='kind')fig.append(el('p',k+': '+v,'sub'));const b=el('button','比較から外す');b.onclick=()=>{selections.delete(id);comparison();render()};fig.append(b);root.append(fig)}$('compareEmpty').hidden=selections.size>0;$('compareCount').textContent=selections.size+' / 4件'}
for(const id of ['gaze','blush','brows','mouth','kind','status','view','query','newOnly'])$(id).addEventListener('input',render);
$('clearFilters').onclick=()=>{for(const id of ['gaze','blush','brows','mouth','kind','status','query'])$(id).value='';$('newOnly').checked=false;render()};
$('compareNew').onclick=()=>{selections.clear();assets.filter(isLatest).slice(0,4).forEach(a=>selections.add(a.id));comparison();render();$('compareTitle').scrollIntoView({behavior:'smooth',block:'start'})};
function download(name,obj){const u=URL.createObjectURL(new Blob([JSON.stringify(obj,null,2)],{type:'application/json'})),a=document.createElement('a');a.href=u;a.download=name;a.click();setTimeout(()=>URL.revokeObjectURL(u),1000)}
$('export').onclick=()=>{download('heroine-expression-decisions.json',{schema:'heroine-expression-review-v1',exported_at:new Date().toISOString(),catalog_version:data.version,decisions:assets.map(a=>({id:a.id,label:a.label,...current(a)}))});message('採否JSONを書き出しました。ダウンロード先で保管してください。')};
$('import').addEventListener('change',async e=>{const file=e.target.files?.[0];if(!file)return;try{const obj=JSON.parse(await file.text());if(obj.schema!=='heroine-expression-review-v1'||!Array.isArray(obj.decisions))throw new Error('対応する採否JSONではありません');const additions={};let skipped=0;for(const d of obj.decisions){if(!d||typeof d!=='object'){skipped++;continue}const a=byId.get(d.id);if(!a||a.sha256!==d.source_sha256||!Object.hasOwn(statuses,d.status)||typeof d.note!=='string'){skipped++;continue}additions[d.id]={status:d.status,note:d.note,source_sha256:d.source_sha256,updated_at:typeof d.updated_at==='string'?d.updated_at:new Date().toISOString()}}decisions={...decisions,...additions};stash();render();comparison();message(Object.keys(additions).length+'件を取り込み。版違い等の除外 '+skipped+'件。'+(storageOK?'':'保存失敗：JSONを書き出してください。'))}catch(err){message('取り込み失敗：'+err.message)}e.target.value=''});
$('catalogExport').onclick=()=>download('heroine-expression-catalog.json',data);
stats();render();comparison();
