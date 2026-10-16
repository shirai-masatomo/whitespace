from pathlib import Path
import json
from PIL import Image, ImageDraw, ImageFont, ImageChops
p=Path(__file__).resolve().parents[1]
d=p/'review/current/interaction-revision'
data=json.loads((d/'construction-visual.json').read_text(encoding='utf-8-sig'))
font=ImageFont.truetype(r'C:\Windows\Fonts\meiryo.ttc',14)
cache={}
def color(s):return tuple(bytes.fromhex(s))
def render(calls,size):
 image=Image.new('RGBA',size,'#798b51')
 for c in calls:
  if 'path' not in c:
   overlay=Image.new('RGBA',size);pen=ImageDraw.Draw(overlay);ink=color(c['color'])
   if 'rect' in c:
    x,y,w,h=c['rect'];pen.rectangle((x,y,x+w-1,y+h-1),fill=ink)
   if 'line' in c:pen.line([tuple(q) for q in c['line']],fill=ink,width=round(c['width']))
   if 'arc' in c:
    x,y=c['arc'];r=c['radius'];pen.ellipse((x-r,y-r,x+r,y+r),outline=ink,width=round(c['width']))
   image.alpha_composite(overlay);continue
  key=c['path']
  if key not in cache:cache[key]=Image.open(p/key.removeprefix('res://')).convert('RGBA')
  source=cache[key]
  if 'mesh' in c:
   dest=Image.new('RGBA',(48,68))
   for yi in range(len(data['sy'])-1):
    for xi in range(len(data['sx'])-1):
     x0,x1=map(int,data['sx'][xi:xi+2]);y0,y1=map(int,data['sy'][yi:yi+2]);dx0,dx1=map(int,data['dx'][xi:xi+2]);dy0,dy1=map(int,data['dy'][yi:yi+2])
     patch=source.crop((x0,y0,x1,y1)).resize((dx1-dx0,dy1-dy0),Image.Resampling.NEAREST);dest.alpha_composite(patch,(dx0,dy0))
   source=dest
  if 'src' in c:
   x,y,w,h=map(int,c['src']);source=source.crop((x,y,x+w,y+h))
  if 'size' in c:source=source.resize(tuple(map(int,c['size'])),Image.Resampling.NEAREST)
  if 'tint' in c:source=ImageChops.multiply(source,Image.new('RGBA',source.size,color(c['tint'])))
  image.alpha_composite(source,tuple(map(int,c['at'])))
 return image
names={'wall':'土壁','wood_wall':'木壁','stone_wall':'石壁','soil_tile':'土床','wood_tile':'木床','stone_tile':'石床','door':'扉','cooking_bench':'調理台'}
sheet=Image.new('RGB',(1032,9*326+56),'#f1e8ce');pen=ImageDraw.Draw(sheet)
pen.text((12,5),'本番描画命令＋正式PNGのCPU合成比較（実ゲームのスクリーンショットではありません）',font=font,fill='#273f32')
for i,row in enumerate(data['rooms']):
 col=i%3;line=i//3;x=col*344+8;y=56+line*326
 label={'half':'変更前：半マス延長','none':'比較：延長なし','contact':'採用：接地8px・1マス敷居'}[row['mode']]
 pen.text((x,y),label+' / '+names[row['wall']]+'＋'+names[row['floor']],font=font,fill='#273f32')
 sheet.paste(render(row['calls'],(328,296)).convert('RGB'),(x,y+25))
sheet.save(d/'construction-floor-comparison.png')
# Representative wood/wood row, plus both unlike floor materials.
sheet.crop((0,56+3*326,1032,56+6*326)).save(d/'construction-floor-detail.png')
sheet=Image.new('RGB',(880,4*194+68),'#f1e8ce');pen=ImageDraw.Draw(sheet)
pen.text((12,5),'建築ゴーストのCPU合成：資材待ちは砂時計、設置不可だけ禁止マーク',font=font,fill='#273f32')
for i,row in enumerate(data['ghosts']):
 x=(i%4)*220+10;y=(i//4)*194+64
 label={'before':'変更前（不足時も白）','normal':'資材あり','wait':'資材待ち・予約可能','invalid':'設置不可・予約不可'}[row['state']]
 pen.text((x,y-25),label,font=font,fill='#273f32');pen.text((x,y+139),names[row['kind']],font=font,fill='#273f32')
 sheet.paste(render(row['calls'],(200,136)).convert('RGB'),(x,y))
sheet.save(d/'construction-ghost-comparison.png')
print('CPU comparisons: floor, detail, ghost')

sheet=Image.new('RGB',(1032,350),'#f1e8ce');pen=ImageDraw.Draw(sheet)
pen.text((12,5),'壁の完成・施工中・破壊：本番描画命令のCPU合成',font=font,fill='#273f32')
for i,row in enumerate(data['wall_states']):
 x=i*344+8;pen.text((x,30),{'ready':'完成','building':'施工中','destroyed':'破壊後'}[row['state']],font=font,fill='#273f32')
 sheet.paste(render(row['calls'],(328,296)).convert('RGB'),(x,54))
sheet.save(d/'construction-wall-states.png')
