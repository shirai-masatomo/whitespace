"""CPU layout preview from headless production Control bounds; not a GPU screenshot."""
import json, argparse
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

def main():
    ap=argparse.ArgumentParser(); ap.add_argument('--project',type=Path,required=True); args=ap.parse_args()
    out=args.project/'review/current/interaction-revision'
    rows=json.loads((out/'life-layouts.json').read_text(encoding='utf-8-sig'))['layouts']
    font=lambda size:ImageFont.truetype('C:/Windows/Fonts/meiryo.ttc',int(size))
    for width in (1280,1600):
        pages=[]
        for row in [r for r in rows if r['window'][0]==width]:
            im=Image.new('RGB',(1280,800),'#485b43');d=ImageDraw.Draw(im)
            d.text((16,355),f"{row['name']} / {width}px / CPU layout, not game screenshot",font=font(16),fill='#fff4d1')
            for n in row['nodes']:
                x,y,w,h=n['rect']; typ=n['type'];text=n.get('text','')
                if w<=0 or h<=0:continue
                box=(round(x),round(y),round(x+w),round(y+h))
                if typ=='Panel':d.rounded_rectangle(box,4,fill='#eee4c7',outline='#8c714b',width=2)
                elif typ in ('Button','OptionButton'):
                    d.rounded_rectangle(box,3,fill='#'+n.get('color','e8d8afff')[:6],outline='#897247')
                    d.text((x+7,y+max(0,(h-n.get('font',14))/2-3)),text,font=font(n.get('font',14)),fill='#283f32')
                    if typ=='OptionButton':d.polygon([(x+w-16,y+h/2-2),(x+w-7,y+h/2-2),(x+w-12,y+h/2+4)],fill='#6f674e')
                elif typ=='Label':d.text((x,y-2),text,font=font(n.get('font',14)),fill='#283f32',spacing=4)
                elif typ=='VScrollBar':
                    d.rectangle(box,fill='#cfc5aa');d.rounded_rectangle((x+1,y+2,x+w-1,y+h-2),3,fill='#718261')
                elif typ in ('VSeparator','HSeparator'):d.line((x,y,x+w,y+h),fill='#b2a685',width=1)
                if 'hours' in n:
                    colors={'sleep':'#7d96b7','work':'#91a28a','free':'#b6aa82'}
                    for hour,kind in enumerate(n['hours']):
                        d.rectangle((x+24*hour,y,x+24*hour+23,y+38),fill=colors[kind]);d.text((x+24*hour+4,y+8),str(hour),font=font(11),fill='#162c25')
            pages.append(im.crop((8,390,820,800)))
        sheet=Image.new('RGB',(824,44+len(pages)*422),'#f5efdf');d=ImageDraw.Draw(sheet)
        d.text((12,8),f'{width}×{width*800//1280} — 実UI座標のCPU確認図（実ゲーム画面ではありません）',font=font(15),fill='#283f32')
        for i,page in enumerate(pages):sheet.paste(page,(6,44+i*422))
        sheet.save(out/f'life-ui-{width}.png',optimize=True)
    print('CPU life layout previews written')
if __name__=='__main__':main()
