"""CPU layout evidence from actual headless Godot control bounds, not game screenshots."""
import json,argparse
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageColor

def main():
 ap=argparse.ArgumentParser();ap.add_argument('--project',type=Path,required=True);ap.add_argument('--output',type=Path);a=ap.parse_args();out=a.output or a.project/'review/current/work-ui'
 data=json.loads((out/'ui-layouts.json').read_text(encoding='utf-8-sig'))['layouts']
 def font(size):return ImageFont.truetype('C:/Windows/Fonts/meiryo.ttc',int(size))
 def draw_scene(row):
  image=Image.new('RGB',(1280,800),'#435344');d=ImageDraw.Draw(image)
  d.text((20,65),'UI座標のCPU確認図 / 地形・GPU描画は省略',font=font(16),fill='#f1e4b8')
  d.text((20,92),row['name']+'  '+str(row['window'])+' / 論理座標1280×800',font=font(13),fill='#ddd2aa')
  card=row['card']
  if card:
   x,y,w,h=card['rect'];d.rounded_rectangle((x,y,x+w,y+h),radius=4,fill='#536e52',outline='#afae88',width=2)
   for yy,text,size in [(10,card['name']+' Lv'+str(card['level']),17),(35,'満腹%d · スタミナ%d/%d'%(card['satiety'],card['stamina'],card['max_stamina']),13),(61,'HP %d / %d'%(card['hp'],card['max_hp']),13),(85,card['effects'],12)]:d.text((x+12,y+yy),text,font=font(size),fill='#f2ead5')
  for n in row['nodes']:
   x,y,w,h=n['rect'];t=n['type'];text=n.get('text','');color=n.get('color','e7d9b5ff');color='#'+color[:6]
   if w<=0 or h<=0 or y>800:continue
   if t=='Panel':d.rounded_rectangle((x,y,x+w,y+h),radius=4,fill='#e7d9b5',outline='#795b3e',width=2)
   elif t in ['Button','OptionButton','CheckButton']:
    d.rounded_rectangle((x,y,x+w,y+h),radius=3,fill=color,outline='#877f5a')
    ft=font(n.get('font',14));d.text((x+5,y+max(0,(h-ft.size-3)/2)),text,font=ft,fill='#384738')
   elif t=='Label':d.text((x,y),text,font=font(n.get('font',13)),fill='#384738')
   elif t=='LineEdit':
    d.rectangle((x,y,x+w,y+h),fill='#f5efdd',outline='#62795f');d.text((x+6,y+5),text,font=font(14),fill='#384738')
   elif t=='Tree':
    d.rectangle((x,y,x+w,y+h),fill='#f3ecd9',outline='#b9ad8b')
    for i,line in enumerate(n['rows']):
     if i*26>h-25:break
     d.text((x+8,y+5+i*26),'▸ □ '+line,font=font(14),fill='#384738')
   elif t in ['VScrollBar','HScrollBar']:
    d.rectangle((x,y,x+w,y+h),fill='#ccc4ae')
    if t=='VScrollBar':d.rounded_rectangle((x+2,y+2,x+max(3,w-2),y+max(8,h/2)),radius=2,fill='#718261')
   elif t=='ProgressBar':
    d.rectangle((x,y,x+w,y+h),fill='#d9d0b8');d.rectangle((x,y,x+w*n['value']/max(1,n['maximum']),y+h),fill='#7c9b65')
  return image
 for width in [1280,1600]:
  rows=[r for r in data if r['window'][0]==width]
  unique={r['name']:r for r in rows}
  sheet=Image.new('RGB',(1280,2000),'#eee7d2');d=ImageDraw.Draw(sheet)
  d.text((12,8),f'{width}幅の実Control座標を確認 / CPU再現・実画面ではありません',font=font(18),fill='#384738')
  for i,(name,row) in enumerate(unique.items()):
   # Crop lower-left UI at 1:1 logical pixels; keep content size and vertical location.
   scene=draw_scene(row);tile=scene.crop((0,240,460,800));tile=tile.resize((426,518),Image.Resampling.NEAREST)
   x=(i%3)*426;y=44+(i//3)*550
   sheet.paste(tile,(x,y+22));d.text((x+8,y),name,font=font(14),fill='#384738')
  sheet=sheet.crop((0,0,1280,min(2000,44+((len(unique)+2)//3)*550)))
  sheet.save(out/f'ui-layouts-{width}.png',optimize=True)
  chosen=unique['architect-設置'];scene=draw_scene(chosen).resize((width,int(width*800/1280)),Image.Resampling.NEAREST);scene.save(out/f'architect-{width}.png',optimize=True)
 print('CPU layout sheets and full-frame coordinate previews generated')
if __name__=='__main__':main()
