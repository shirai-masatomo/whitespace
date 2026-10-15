from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import json,random
root=Path(__file__).resolve().parents[1]
out=root/'review/current/interaction-revision'
font=lambda n:ImageFont.truetype(r'C:\Windows\Fonts\meiryo.ttc',n)
im=Image.new('RGB',(960,430),'#f1eddf');d=ImageDraw.Draw(im)
d.text((24,16),'禁止マーク：赤いバツを太く、明暗の縁で見やすく',font=font(22),fill='#253d32')
d.text((24,51),'実装の描画命令をCPUで再現した確認図（実ゲームのスクリーンショットではありません）',font=font(12),fill='#556354')
proof=json.loads((out/'forbidden-commands.json').read_text(encoding='utf-8'))
wood=Image.open(root/'art_delivery/resource_icons_v1/ui48/wood.png').convert('RGBA')
for col,(name,color,z) in enumerate([('草地 / 100%',(105,123,77),1),('土 / 50%',(128,113,87),.5),('岩 / 25%',(146,146,128),.25),('一部だけ禁止',(92,108,91),1)]):
 x=24+col*234
 d.text((x,86),name,font=font(16),fill='#253d32')
 for row in [0,1]:
  y=120+row*142;d.rectangle((x,y,x+210,y+118),fill=color)
  rng=random.Random(73)
  for k in range(450):
   px=x+rng.randrange(210);py=y+rng.randrange(118);offset=rng.randrange(-15,16)
   d.rectangle((px,py,px+1,py+1),fill=tuple(max(0,min(255,v+offset)) for v in color))
  sprite=wood.resize((max(12,round(48*z)),max(12,round(48*z))),Image.Resampling.NEAREST)
  anchor=(x+98,y+60);im.paste(sprite,(anchor[0]-sprite.width//2,anchor[1]-sprite.height//2),sprite)
  d.text((anchor[0]-8,anchor[1]+17),'8',font=font(12),fill='#fff0dc',stroke_width=1,stroke_fill='#252a22')
  d.text((x+8,y+6),'変更前' if row==0 else '変更後',font=font(14),fill='#fff6dd',stroke_width=1,stroke_fill='#263829')
  if row==0:
   d.text((anchor[0]+7,anchor[1]-26),'×',font=font(max(6,int(18*z))),fill='#9c5748')
  else:
   item=next(r for r in proof if r['zoom']==z and r['partial']==(col==3))
   def pt(a):return (anchor[0]+a[0]*z-60,anchor[1]+a[1]*z-60)
   for c in item['calls']:
    if c['type']=='line':d.line([pt(c['a']),pt(c['b'])],fill='#'+c['color'][:6],width=round(c['width']*z))
    else:
     p=pt(c['p']);r=c['radius']*z;d.ellipse((p[0]-r,p[1]-r,p[0]+r,p[1]+r),fill='#'+c['color'][:6])
d.text((24,407),'禁止解除で消灯。一部禁止のみ黄色の補助点。新規素材は使用していません。',font=font(12),fill='#253d32')
im.save(out/'forbidden-comparison.png')
# Exact existing artwork, same cell anchors. No synthetic replacement asset.
im=Image.new('RGB',(760,390),'#eee8d7');d=ImageDraw.Draw(im)
d.text((20,12),'既存正式画像の組み合わせ：ドアと2×2作業台',font=font(19),fill='#253d32')
d.text((20,42),'CPU素材・アンカー確認（ゲーム撮影ではありません）',font=font(12),fill='#546352')
for i,(orientation,opened,locked) in enumerate([('horizontal',False,False),('horizontal',True,False),('horizontal',False,True),('vertical',False,False),('vertical',True,True)]):
 canvas=Image.new('RGBA',(48,68));stem=root/'art_delivery/wood_buildings_v1/door';state='open' if opened else 'closed'
 for part in ['frame_rear','leaf_'+state+'_normal']+(['lock_'+state+'_normal'] if locked else [])+['frame_front']:
  canvas.alpha_composite(Image.open(stem/(orientation+'_'+part+'.png')).convert('RGBA'))
 x=30+i*145;y=78;im.paste(canvas.resize((96,136),Image.Resampling.NEAREST),(x,y),canvas.resize((96,136),Image.Resampling.NEAREST))
 d.text((x,216),('縦' if orientation=='vertical' else '横')+(' 開' if opened else ' 閉')+(' 施錠' if locked else ''),font=font(13),fill='#253d32')
for i,kind in enumerate(['cooking_bench','carpentry_bench','sewing_bench']):
 x=45+i*235;y=260
 for dx in [0,48,96]:d.line((x+dx,y,x+dx,y+84),fill='#98a184')
 for dy in [0,42,84]:d.line((x,y+dy,x+96,y+dy),fill='#98a184')
 a=Image.open(root/f'art_delivery/crafting_assets_v1/benches/{kind}.png').convert('RGBA').resize((96,88),Image.Resampling.NEAREST)
 im.paste(a,(x,y-4),a);d.text((x,354),['調理台','木工作業台','裁縫台'][i]+'：4マス',font=font(14),fill='#253d32')
im.save(out/'equipment-art-check.png')

