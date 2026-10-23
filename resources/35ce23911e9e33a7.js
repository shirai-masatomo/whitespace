const data=JSON.parse(document.getElementById('data').textContent);const $=id=>document.getElementById(id);
function update(){const r=data.scenes.find(x=>x.case===$('case').value&&x.stage===+$('stage').value&&x.door===$('door').value);$('scene').src=r.url;$('scene').alt=r.stage_note;$('note').textContent=r.stage_note+'。男子3人・ヒロイン1人。';}
for(const id of ['case','stage','door'])$(id).addEventListener('input',update);update();
