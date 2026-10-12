from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageChops,ImageSequence
import json,numpy as np,hashlib
S=Path(__file__).resolve().parent;P=S.parents[1];D=P/'art_delivery/biome_environment_v1'
def im(f):return Image.open(f).convert('RGBA')
font=ImageFont.truetype('C:/Windows/Fonts/meiryo.ttc',12)
m=json.loads((D/'manifest.json').read_text(encoding='utf-8'));assets=m['assets'];out=Image.new('RGBA',(1024,40+((len(assets)+7)//8)*155),'#334635');dr=ImageDraw.Draw(out)
dr.text((10,10),'ASSET INVENTORY / 2x nearest / offline / reference aliases not duplicated',font=font,fill='white')
for i,a in enumerate(assets):
 x=i%8*128;y=40+i//8*155;ob=im(D/a['file']);dr.text((x+3,y),a['file'].split('/')[-1],font=font,fill='white');dr.text((x+3,y+15),'/'.join(a['file'].split('/')[:-1])[:19],font=font,fill='#d6d3b5');z=1 if ob.height>64 else 2;out.alpha_composite(ob.resize((ob.width*z,ob.height*z),Image.Resampling.NEAREST),(x+(128-ob.width*z)//2,y+35))
out.save(D/'review/inventory.png')
# Mining transition is visual timing only, not a work-progress rule.
frames=[];rock=im(D/'rock/normal/mask_00.png')
for k in range(20):
 o=Image.new('RGBA',(360,180),'#839955');dd=ImageDraw.Draw(o);dd.text((8,6),'OFFLINE: normal -> cracks -> mined',font=font,fill='white');base=Image.new('RGBA',(48,54));base.alpha_composite(im(D/'rock/ground/exposed.png'),(0,12))
 if k<10:
  base.alpha_composite(rock)
  if k>=4:
   crack=im(D/('rock/damage/light.png' if k<7 else 'rock/damage/heavy.png'));crack.putalpha(ImageChops.multiply(crack.getchannel('A'),rock.getchannel('A')));base.alpha_composite(crack)
 elif k<15:
  base.alpha_composite(im(D/'rock/ground/rubble.png'),(0,12));f=min(k-10,3);base.alpha_composite(im(D/f'rock/fx/chips_{f:02}.png'),(8,20))
  base.alpha_composite(im(P/f'art_delivery/effects_v1/stone_powder/{f:02}.png'),(8,20))
 o.alpha_composite(base,(30,80));o.alpha_composite(base.resize((96,108),Image.Resampling.NEAREST),(180,50));frames.append(o.convert('RGB'))
frames[0].save(D/'review/mining.gif',save_all=True,append_images=frames[1:],duration=120,loop=0,disposal=2)
# Single tree fall concept; native resources unchanged, angle is code-driven.
frames=[];tree=im(P/'art_delivery/ui_world_direction_v1/candidates/world/tree_a.png');upper=tree.copy();ImageDraw.Draw(upper).rectangle((0,65,63,79),fill=(0,0,0,0));stump=im(D/'forest/stump_a.png')
for k in range(24):
 o=Image.new('RGBA',(300,200),'#839955');dd=ImageDraw.Draw(o);dd.text((5,5),'OFFLINE: code rotation / not runtime',font=font,fill='white');layer=Image.new('RGBA',(160,160))
 if k<7:
  layer.alpha_composite(tree,(48,68))
  if k>=3:layer.alpha_composite(im(D/'forest/notch_a_deep.png'),(48,68))
 else:
  layer.alpha_composite(stump,(48,68))
  if k<17:
   top=Image.new('RGBA',(160,160));top.alpha_composite(upper,(48,68));top=top.rotate(-min(85,(k-7)*10),Image.Resampling.NEAREST,center=(80,133));layer.alpha_composite(top)
 o.alpha_composite(layer,(70,25));frames.append(o.convert('RGB'))
frames[0].save(D/'review/felling.gif',save_all=True,append_images=frames[1:],duration=100,loop=0,disposal=2)
# Separate exact-native comparison and current runtime scale indication.
scale=Image.new('RGBA',(780,270),'#839955');dr=ImageDraw.Draw(scale)
for col,factor in enumerate([1.0,1.25]):
 x=col*390;dr.text((x+12,12),'48x42 tiles / animal '+str(factor)+'x',font=font,fill='white')
 scale.alpha_composite(rock,(x+40,120));keeper=im(P/'art_delivery/characters_v1/keeper_idle_right_00.png');dog=im(P/'art_delivery/characters_v1/shiba_idle_right_00.png');dog=dog.resize((round(48*factor),round(48*factor)),Image.Resampling.NEAREST);scale.alpha_composite(keeper,(x+130-16,159-44));scale.alpha_composite(dog,(x+205-round(24*factor),159-round(44*factor)))
 stone=im(P/'art_delivery/resource_icons_v1/hud24/stone.png');scale.alpha_composite(stone,(x+260,145));dr.text((x+12,225),'OFFLINE / PNGs unchanged / no new scale rule',font=font,fill='white')
scale.save(D/'review/scale_current.png')
# Human-readable filename table mirrors manifests; aliases include source timing.
lines=['# ファイルと用途','', '| ファイル | 寸法 | 基準点 | 占有 | 用途 |','|---|---|---|---|---|']
for a in assets:lines.append('| '+a['file']+' | '+str(a['size_px'])+' | '+str(a['anchor_px'])+' | '+str(a['occupied_cells'])+' | '+a['usage']+' |')
lines+=['','## 既存参照（PNGをコピーしない）','']
for a in m['reuse']:lines.append('- `'+a['file']+'` — '+a['role'])
(D/'FILES.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
html='''<!doctype html><html lang="ja"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>バイオーム正式素材 v1</title><style>body{max-width:1080px;margin:28px auto;padding:0 18px;background:#293d30;color:#eee4cd;font:17px/1.6 sans-serif}img{max-width:100%;height:auto;image-rendering:pixelated}a{color:#ecd29a}section{margin:36px 0}summary{cursor:pointer}</style><h1>バイオーム正式素材 v1</h1><p>岩場・採掘、乾燥地・草地、伐採差分。80枚の用途別PNG＋岩場シート1枚。既存素材23ファイルは参照利用。</p><p><strong>このページの見本はすべてオフライン合成です。実ゲーム内の動作確認済み画像ではありません。</strong></p><p><a href="HANDOFF.md">実装担当向け納品書</a> / <a href="FILES.md">ファイル用途一覧</a> / <a href="manifest.json">manifest</a> / <a href="QA.json">検査結果</a></p>'''
for title,file in [('岩場：単独・連結・部分採掘・採掘後','rock_mining.png'),('主人公・柴犬C・石材との縮尺','scale_current.png'),('採掘の表示切替','mining.gif'),('乾燥地・草地の控えめな差分','ground_comparison.png'),('既存3種の木と伐採差分','forest_differences.png'),('既存素材を使う倒木の構成例','felling.gif')]:html+=f'<section><h2>{title}</h2><img src="review/{file}" alt="{title}"></section>'
html+='<details><summary>全素材の一覧</summary><img src="review/inventory.png" alt="素材一覧"></details><details><summary>岩場16接続</summary><img src="review/rock_masks_2x.png" alt="16接続"></details></html>';(D/'index.html').write_text(html,encoding='utf-8');print('Reviews and filename table complete')
