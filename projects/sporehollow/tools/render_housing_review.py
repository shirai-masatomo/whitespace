from pathlib import Path
import json
from PIL import Image, ImageDraw, ImageFont
p=Path(__file__).resolve().parents[1]
d=p/'review/current/interaction-revision'
data=json.loads((d/'housing-draw.json').read_text(encoding='utf-8-sig'))
sheet=Image.new('RGB',(760,375),'#f1e8ce');draw=ImageDraw.Draw(sheet)
font=ImageFont.truetype(r'C:\Windows\Fonts\meiryo.ttc',15)
draw.text((12,6),'床と壁：本番描画命令のCPU合成（実ゲームの撮影ではありません）',font=font,fill='#273f32')
for i,calls in enumerate(data['pages']):
 image=Image.new('RGBA',(336,300),'#798b51')
 for c in calls:
  if 'rect' in c:
   x,y,w,h=map(int,c['rect']);ImageDraw.Draw(image).rectangle((x,y,x+w-1,y+h-1),fill='#'+c['color']);continue
  source=Image.open(p/c['path'].removeprefix('res://')).convert('RGBA')
  if 'mesh' in c:
   dest=Image.new('RGBA',(48,68))
   for yi in range(len(data['sy'])-1):
    for xi in range(len(data['sx'])-1):
     x0,x1=map(int,data['sx'][xi:xi+2]);y0,y1=map(int,data['sy'][yi:yi+2]);dx0,dx1=map(int,data['dx'][xi:xi+2]);dy0,dy1=map(int,data['dy'][yi:yi+2])
     patch=source.crop((x0,y0,x1,y1)).resize((dx1-dx0,dy1-dy0),Image.Resampling.NEAREST);dest.alpha_composite(patch,(dx0,dy0))
   source=dest
  if 'src' in c:
   x,y,w,h=map(int,c['src']);source=source.crop((x,y,x+w,y+h))
  image.alpha_composite(source,tuple(map(int,c['at'])))
 sheet.paste(image.convert('RGB'),(20+i*380,64))
 draw.text((20+i*380,38),'変更前' if i==0 else '変更後：壁の下へ床を切り出して延長',font=font,fill='#273f32')
sheet.save(d/'housing-floor-comparison.png')
print(d/'housing-floor-comparison.png')
