const data=JSON.parse(document.getElementById('viewer-data').textContent);
const select=document.getElementById('variant'),door=document.getElementById('door'),debug=document.getElementById('debug'),pic=document.getElementById('scene'),svg=document.getElementById('guide'),line=document.getElementById('line'),dot=document.getElementById('dot');
function update(){const item=data[Number(select.value)];pic.src=item.files[door.value];pic.alt=item.label;line.setAttribute('x1',item.from[0]);line.setAttribute('y1',item.from[1]);line.setAttribute('x2',item.to[0]);line.setAttribute('y2',item.to[1]);dot.setAttribute('cx',item.to[0]);dot.setAttribute('cy',item.to[1]);svg.hidden=!debug.checked;}
for(const el of [select,door,debug])el.addEventListener('change',update);update();
