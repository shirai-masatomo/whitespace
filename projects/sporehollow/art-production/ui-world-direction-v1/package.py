from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import hashlib,json,shutil
S=Path(__file__).parent;P=S.parents[1];D=P/'art_delivery/ui_world_direction_v1'
main=Path(r'C:/Users/masat/Documents/codex_test/projects/sporehollow')
for name in ['ART_SPEC.md','ANIMALS.md','ENEMIES.md','ITEMS.md','WORLD_SYSTEMS.md']:shutil.copy2(main/name,S/'specs'/name)
for name in ['07_forest_overview.png','09_combat_ready.png']:
 shutil.copy2(main/'review/current/revision-30207f2'/name,S/'references'/('latest_'+name))
shutil.copy2(main/'review/current/PACKET.md',S/'references/latest-PACKET.md')
def sha(f):return hashlib.sha256(f.read_bytes()).hexdigest()
# Fix a review caption only (3x is the actual render above).
p=S/'finalize.py';t=p.read_text(encoding='utf-8-sig').replace('原寸・4倍 / 影や効果範囲','原寸・3倍 / 影や効果範囲');p.write_text(t,encoding='utf-8')
im=Image.open(D/'preview/E_ready_native.png');dr=ImageDraw.Draw(im);dr.rectangle((0,0,999,48),fill='#242c29');dr.text((20,14),'E  READY：原寸・3倍 / 影や効果範囲とは別の表示',font=ImageFont.truetype('C:/Windows/Fonts/meiryo.ttc',23),fill='#e7dcc0');im.save(D/'preview/E_ready_native.png')
# Small disconnected remnants are explicitly visible in raw sources but not promoted to completed game assets.
cfg={}
for id in ['goldA','goldB']:cfg[id]={'anchor':[72,152],'world_or_ui':'world','occupancy_cells':[2,2],'logical_footprint_rect_px':[24,68,120,152],'layers':['body_and_plinth'],'unresolved':['Choose A or B','damaged/prayer/transport states not made','old ART_SPEC anchor must be reconciled by implementation']}
for id in ['tree_a','tree_b','tree_c']:
 cfg[id]={'anchor':[32,72],'world_or_ui':'world','recommended_trunk_collision_rect_px':[27,63,37,73],'canopy_rect_px':{'tree_a':[2,4,62,51],'tree_b':[5,6,59,52],'tree_c':[12,19,52,50]}[id],'layers':['trunk','canopy'],'unresolved':['Native canopy cleanup after adoption','collision rectangle is a suggestion, not game logic','cutting/falling states not made']}
 for layer in ['trunk','canopy']:cfg[id+'_'+layer]={**cfg[id],'layers':[layer],'action':'layer_candidate'}
for id in ['maid','dancer','thief']:cfg[id]={'anchor':[32,58],'world_or_ui':'world','layers':['body_with_held_props'],'unresolved':['design adoption','native face/costume pixel finish','hand sockets and separate held props','all formal motion frames and directions']}
for id in ['cow','bull']:cfg[id]={'anchor':[40,58],'world_or_ui':'world','layers':['body'],'unresolved':['design adoption','body size provisional','formal motion not made']}
cfg['kokeshi']={'anchor':[16,36],'world_or_ui':'world','occupancy_cells':[1,1],'layers':['body'],'unresolved':['pickup UI variant','selection-only range feedback belongs to implementation']}
cfg['fossil']={'anchor':[24,36],'world_or_ui':'world','layers':['body'],'unresolved':['pickup UI variant','activation FX deferred','no dinosaur made']}
for id,an in [('poison_projectile',[16,12]),('poison_splash',[24,28]),('poison_cloud',[32,36])]:cfg[id]={'anchor':an,'world_or_ui':'world','layers':[id],'unresolved':['direction prototype only','timing and gameplay radius not specified']}
assets=[];checks=[]
for f in sorted((D/'candidates').rglob('*.png')):
 im=Image.open(f);id=f.stem;group=f.parent.name;c=cfg.get(id,{});anchor=c.get('anchor',[im.width//2,im.height//2])
 if group=='portraits':c={'world_or_ui':'UI','anchor':[96,96],'layers':['portrait'],'unresolved':['portrait direction approval; do not use on board']}
 if id=='ready_aura':anchor=[24,12]
 if id=='ready_stars':anchor=[12,12]
 if id=='ready_corners':anchor=[96,96]
 a={'asset_id':group+'.'+id,'file':f.relative_to(D).as_posix(),'canvas':list(im.size),'anchor':c.get('anchor',anchor),'anchor_kind':'foot' if group in ['world','new'] and not id.startswith('poison_') else 'UI_center_or_effect_origin','world_or_ui':c.get('world_or_ui','UI'),'status':'direction_review','runtime_ready':False,'action':c.get('action','static_concept'),'frame_index':0,'frame_order':[0],'frame_duration_ms':None,'loop':False,'layers':c.get('layers',['icon']),'baked_ground_shadow':False,'visible_bbox_exclusive':im.getbbox(),'sha256':sha(f),'unresolved':c.get('unresolved',['direction approval','not automatically connected to skills or rarity logic'])}
 for key in ['occupancy_cells','logical_footprint_rect_px','recommended_trunk_collision_rect_px','canopy_rect_px']:
  if key in c:a[key]=c[key]
 assets.append(a)
 alpha=set(im.getchannel('A').getdata());assert im.mode=='RGBA' and 0 in alpha
 assert alpha<={0,96,255},(id,alpha)
 assert im.getbbox() and 0<=a['anchor'][0]<=im.width and 0<=a['anchor'][1]<=im.height
 checks.append({'file':a['file'],'RGBA':True,'alpha_values':sorted(alpha),'sha256':a['sha256']})
for id in ['tree_a','tree_b','tree_c']:
 full=Image.open(D/f'candidates/world/{id}.png').convert('RGBA')
 merged=Image.alpha_composite(Image.open(D/f'candidates/world/{id}_trunk.png'),Image.open(D/f'candidates/world/{id}_canopy.png'))
 assert full.tobytes()==merged.tobytes()
review=[]
for folder in ['preview','storyboards']:
 for f in sorted((D/folder).glob('*.png')):
  im=Image.open(f);review.append({'asset_id':'review.'+f.stem,'file':f.relative_to(D).as_posix(),'canvas':list(im.size),'anchor':None,'world_or_ui':'review_only','runtime_ready':False,'action':'comparison' if folder=='preview' else f.stem,'layers':['review_composite'],'sha256':sha(f),'frame_duration_ms':None,'loop':False})
manifest={'schema_version':1,'delivery':'ui_world_direction_v1','date':'2026-10-07','branch':'codex/sporehollow-art-assets','status':'awaiting_direction_review','runtime_ready':False,'assets':[],'review_assets':assets+review,'storyboards':json.loads((D/'storyboards/index.json').read_text(encoding='utf-8')),'rendering':{'format':'RGBA','filter':'nearest','color_key':False,'preserve_padding':True},'source_directory':'../../art-production/ui-world-direction-v1','reference_game_revision':'30207f2fa1ca73991e48473907cbd7315aaebe52','source_spec_sha256':{f.name:sha(f) for f in sorted((S/'specs').glob('*.md'))},'source_pngs':{f.name:sha(f) for f in sorted((S/'originals').glob('*.png'))},'implementation_notes':['Nothing in this review set is approved for automatic runtime ingestion. assets is intentionally empty.','New user idol canvas/anchor proposal supersedes older96x128 spec only as a candidate, not an integration contract.','No existing delivered sprites or motion files changed.','No gameplay, scenes, UID, stats, or damage rules edited.','Offline compositions are not game-rendering evidence.']}
(D/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
qa={'date':'2026-10-07','candidate_count':len(assets),'review_image_count':len(review),'storyboard_count':7,'checks':checks,'tree_layer_recomposition':'exact pixel equality','visual_checks':['native and nearest magnification','six portraits192/96/48','dark/light alpha backgrounds','seven narrative storyboards','forest modular composition'],'not_verified':['game integration','runtime rendering order/collision','formal motion timing','approval of new design'],'limitations':['Concepts still need native pixel polish and action-ready layer separation after adoption.','Forest ground/deep-forest full repeatable asset set not produced before direction review.']}
(D/'QA.json').write_text(json.dumps(qa,ensure_ascii=False,indent=2),encoding='utf-8')
# A simple file-based review gallery has no game code and no remote calls.
cards=[('A 黄金像','preview/A_idols.png'),('B 森の全景','preview/B_forest_composition.png'),('B 木3種','preview/B_trees.png'),('C Portrait','preview/C_portraits.png'),('D/E UI','preview/DE_ui.png'),('E READY原寸','preview/E_ready_native.png'),('F 基本原画','preview/F_concept_art.png'),('F 盤面サイズ','preview/F_concepts.png')]
cards += [(x['action'],x['file']) for x in manifest['storyboards']]
html='<!doctype html><html lang="ja"><meta charset="utf-8"><title>ホイッスル牧場 方向確認 v1</title><style>body{background:#202a26;color:#ecdfbd;font:17px sans-serif;margin:32px}nav{position:sticky;top:0;background:#202a26;padding:12px}a{color:#dfc98c;margin-right:18px}img{max-width:100%;height:auto}section{margin:50px 0}p{line-height:1.8}</style><h1>ホイッスル牧場 — 第一段階レビュー</h1><p>未採用の原案・絵コンテです。本番素材やゲーム内検証画像ではありません。黄金像A/B、木・Portrait・UI、新規7種と特殊動作を確認してください。</p><nav>'
html+=''.join(f'<a href="#s{i}">{name}</a>' for i,(name,_) in enumerate(cards[:8]))+'</nav>'
html+=''.join(f'<section id="s{i}"><h2>{name}</h2><a href="{file}"><img src="{file}"></a></section>' for i,(name,file) in enumerate(cards))
html+='<p><a href="HANDOFF.md">HANDOFF</a><a href="manifest.json">manifest</a></p></html>'
(D/'index.html').write_text(html,encoding='utf-8')
print(json.dumps({'candidates':len(assets),'reviews':len(review),'storyboards':7},ensure_ascii=False))

