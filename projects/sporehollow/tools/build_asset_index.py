"""Generate a portable, reference-only browser for runtime assets; never copy images."""
from pathlib import Path
from html import escape
from urllib.parse import quote
import re, json
ROOT=Path(__file__).resolve().parents[1]
selected=set((ROOT/'game').glob('*.gd'))|{ROOT/'game/main.tscn',ROOT/'project.godot'}
pending=list(selected)
while pending:
    src=pending.pop()
    for rel in re.findall(r'res://([^"\n]+)',src.read_text(encoding='utf-8-sig')):
        target=ROOT/rel
        if rel=='game/build_stamp.json':continue
        if not target.exists():
            if rel=='assets/audio/Porch_Swing_Serenade.mp3':continue
            raise RuntimeError(f'Missing runtime resource: {rel}')
        if target.is_dir():
            selected.update(f for f in target.rglob('*') if f.suffix.lower() in ('.png','.svg','.jpg','.webp'))
        elif target not in selected:
            selected.add(target)
            if target.suffix in ('.gd','.tscn','.tres'):pending.append(target)
animals=('shiba','cat','hen','cow','bull','doberman','bullfrog','hedgehog')
people=('keeper','merchant','maid','dancer','thief','destroyer','martial_artist','salaryman','ninja','animal_tamer','runner','kidnapper')
def category(rel):
    s=rel.lower()
    if s.endswith(('.mp3','.ogg','.wav')):return '音'
    if '/fonts/' in s:return 'フォント・出典'
    if any(x in s for x in ('book/','scroll/','/assets/ui/','assets/ui/','cart_ui','resource_icons','adopted_ui')):return 'UI・図鑑'
    if any(x in s for x in ('effects','projectile','aura')):return '効果'
    parts=re.split(r'[/_.]',s)
    if any(re.search(r'(^|/|_)'+x+r'(_|/|\.)',s) for x in animals):return '動物'
    if any(x in s for x in people):return '人物'
    return '建物・世界'
unused_book_layers={'binding_shadow_layer.png','closed_00.png','cover_layer.png','front_cover_hinge_layer.png','paper_layer.png'}
selected={f for f in selected if not (f.parent.name=='book' and f.name in unused_book_layers)}
files=sorted(f for f in selected if f.suffix.lower() in ('.png','.svg','.jpg','.webp','.mp3','.ogg','.wav','.ttf'))
groups={k:[] for k in ('人物','動物','建物・世界','UI・図鑑','効果','音','フォント・出典')}
for f in files:groups[category(f.relative_to(ROOT).as_posix())].append(f)
out=ROOT/'素材';out.mkdir(exist_ok=True)
css='body{margin:0;background:#f3f1e9;color:#25352b;font:16px system-ui}header{background:#253e32;color:white;padding:24px 32px;position:sticky;top:0;z-index:2}h1{margin:0 0 8px;font-size:26px}nav{display:flex;gap:18px;margin:12px 0}nav a{color:#f7e8b1}input{padding:10px;width:min(500px,80%)}main{padding:16px 32px}h2{scroll-margin-top:185px}.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(190px,1fr));gap:12px}.card{background:white;border:1px solid #c6cbbb;border-radius:7px;padding:12px;overflow:hidden}.card img{width:100%;height:140px;object-fit:contain;image-rendering:pixelated;background:repeating-conic-gradient(#e6e9e3 0% 25%,#f9faf7 0% 50%) 50%/20px 20px}.card a{color:#244d35}small{display:block;overflow-wrap:anywhere;color:#59665c}audio{width:100%}footer{padding:32px}.hidden{display:none}'
parts=['<!doctype html><html lang="ja"><meta charset="utf-8"><title>ホイッスル牧場・使用素材</title><style>'+css+'</style><header><h1>ホイッスル牧場・使用素材</h1><div>ゲームが参照する実ファイルだけを表示。画像を押すと原寸を開きます。</div><nav>'+''.join(f'<a href="#{i}">{k}</a>' for i,k in enumerate(groups))+'</nav><input id="find" placeholder="名前・動作を検索（例：shiba、walk、book）"></header><main>']
for i,(name,items) in enumerate(groups.items()):
    parts.append(f'<section><h2 id="{i}">{name} <small>{len(items)}ファイル</small></h2><div class="grid">')
    for f in items:
        rel=f.relative_to(ROOT).as_posix();url=quote('../'+rel,safe='/');label=f.stem
        if f.suffix.lower() in ('.png','.svg','.jpg','.webp'):media=f'<img loading="lazy" src="{url}" alt="{escape(label)}">'
        elif f.suffix.lower() in ('.mp3','.ogg','.wav'):media=f'<audio controls preload="none" src="{url}"></audio>'
        else:media='<div style="height:70px;font-size:34px">あいうえお Aa</div>'
        parts.append(f'<article class="card" data-name="{escape(rel)}"><a href="{url}">{media}<b>{escape(label)}</b></a><small>{escape(rel)}</small></article>')
    if name=='音':parts.append('<p>効果音・環境音の一部は game/farm_audio.gd が生成します。音源ファイルがない公開版でも動作します。</p>')
    parts.append('</div></section>')
parts.append('</main><footer>図鑑：ゲーム内で牧場主を左クリック → 画面下「図鑑」 → 上部「動物／敵」。<br>この一覧は実体への参照です。画像の複製や旧候補・プレビューは含めません。</footer><script>document.querySelector("#find").addEventListener("input",e=>{const q=e.target.value.toLowerCase();document.querySelectorAll(".card").forEach(c=>c.classList.toggle("hidden",!c.dataset.name.toLowerCase().includes(q)));});</script></html>')
(out/'index.html').write_text(''.join(parts),encoding='utf-8')
print(json.dumps({'files':len(files),'categories':{k:len(v) for k,v in groups.items()}},ensure_ascii=False))
