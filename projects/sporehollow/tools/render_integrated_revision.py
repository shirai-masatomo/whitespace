"""CPU evidence from tested terrain data and production sprite frame rectangles; no GPU."""
import json,argparse
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

def main():
 ap=argparse.ArgumentParser();ap.add_argument('--project',type=Path,required=True);a=ap.parse_args();out=a.project/'review/current/integrated-revision'
 font=lambda n:ImageFont.truetype('C:/Windows/Fonts/meiryo.ttc',n)
 data=json.loads((out/'integrated-revision.json').read_text(encoding='utf-8'))
 maps=data['maps'];sheet=Image.new('RGB',(1200,360*len(maps)+60),'#ede7d4');draw=ImageDraw.Draw(sheet)
 draw.text((16,12),'CPU分布確認図 — 実ゲーム画面ではありません / 緑:森林、灰:岩場、点:木・岩、白:中央',font=font(17),fill='#273b2c')
 palette={'woodland':'#476344','rocky':'#9a9483','open':'#b1aa86','lush':'#7e8c5a','dry':'#ad8966'}
 for i,m in enumerate(maps):
  y0=60+i*360;draw.text((16,y0),f"seed {m['seed']} / 森林29% / 左:バイオーム 右:木・採掘岩セル",font=font(16),fill='#273b2c')
  for offset in [16,620]:
   for j,kind in enumerate(m['regions']):
    x=offset+(j%100)*5;y=y0+30+(j//100)*4;draw.rectangle((x,y,x+4,y+3),fill=palette[kind])
  for x,y in m['trees']:draw.rectangle((620+x*5+1,y0+30+y*4,620+x*5+3,y0+30+y*4+2),fill='#1c3926')
  for x,y in m['rocks']:draw.rectangle((620+x*5,y0+30+y*4,620+x*5+4,y0+30+y*4+3),fill='#d0c8ad')
  for xoff in [16,620]:draw.ellipse((xoff+247,y0+163,xoff+253,y0+169),fill='white')
 sheet.save(out/'forest-distribution.png',optimize=True)
 frames=json.loads((out/'integrated-behaviors.json').read_text(encoding='utf-8'))['frames']
 sheet=Image.new('RGB',(1100,340),'#485b42');draw=ImageDraw.Draw(sheet)
 draw.text((12,8),'柴犬の正式素材＋共通描画矩形 / CPU確認図・足元と倍率は全コマ共通',font=font(17),fill='#f0e4c6')
 selected=[r for r in frames if r['action'] in ['idle','walk','hurt'] and (r['action']=='walk' or r['index']==0)]
 for k,row in enumerate(selected):
  col=k%6;line=k//6;x=col*180;y=45+line*145
  image=Image.open(a.project/row['path'].replace('res://','')).convert('RGBA');scale=2.4
  image=image.resize(tuple(round(v*scale) for v in image.size),Image.Resampling.NEAREST)
  foot=(x+85,y+116);anchor=(round(24*scale),round(44*scale));sheet.paste(image,(foot[0]-anchor[0],foot[1]-anchor[1]),image)
  draw.line((x+8,foot[1],x+165,foot[1]),fill='#cbbd80');draw.text((x+8,y+119),f"{row['action']} {row['index']} {'←' if row['facing']<0 else '→'}",font=font(13),fill='#f0e4c6')
 sheet.save(out/'shiba-scale.png',optimize=True)
 print('Wrote CPU distribution and frame-comparison images')
if __name__=='__main__':main()
