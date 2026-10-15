"""CPU rendering of production ghost draw commands. No game window or GPU.
The wall mesh uses the same source/destination grid as building_art.gd.
This artifact is a draw-command comparison, NOT an actual game screenshot.
"""
import argparse,json
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageChops

def render(root,commands):
    canvas=Image.new('RGBA',(144,114),(100,109,78,255))
    d=ImageDraw.Draw(canvas)
    for x in range(0,145,48): d.line((x,0,x,114), fill=(125,133,99,255))
    for y in range(0,115,42): d.line((0,y,144,y), fill=(125,133,99,255))
    for c in commands:
        color=tuple(round(v*255) for v in c.get('color',[1,1,1,1]))
        layer=Image.new('RGBA',canvas.size)
        draw=ImageDraw.Draw(layer)
        if c['type'] in ('sprite','mesh'):
            source=Image.open(root/c['path'].removeprefix('res://')).convert('RGBA')
            if c['type']=='mesh':
                # Exact piecewise wall UV deformation, no invented art.
                out=Image.new('RGBA',(48,68))
                sx=[0,18,30,48];dx=[0,8,40,48]
                sy=[0,2,16,28,44,68];dy=[0,2,8,36,44,68]
                for j in range(5):
                    for i in range(3):
                        tile=source.crop((sx[i],sy[j],sx[i+1],sy[j+1])).resize((dx[i+1]-dx[i],dy[j+1]-dy[j]),Image.Resampling.NEAREST)
                        out.paste(tile,(dx[i],dy[j]))
                source=out
            x,y,w,h=c['rect']
            source=source.resize((round(w),round(h)),Image.Resampling.NEAREST)
            source=ImageChops.multiply(source,Image.new('RGBA',source.size,color))
            layer.alpha_composite(source,(round(x),round(y)))
        elif c['type']=='rect':
            x,y,w,h=c['rect'];draw.rectangle((x,y,x+w-1,y+h-1),fill=color)
        elif c['type']=='arc':
            x,y=c['at'];r=c['radius'];draw.ellipse((x-r,y-r,x+r,y+r),outline=color,width=round(c['width']))
        elif c['type']=='line':draw.line([tuple(p) for p in c['points']],fill=color,width=round(c['width']))
        canvas.alpha_composite(layer)
    return canvas.convert('RGB')

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--project',type=Path,required=True);a=ap.parse_args()
    out=a.project/'review/current/building-preview'
    data=json.loads((out/'ghost-commands.json').read_text(encoding='utf-8-sig'))['pictures']
    font=ImageFont.truetype('C:/Windows/Fonts/meiryo.ttc',16)
    small=ImageFont.truetype('C:/Windows/Fonts/meiryo.ttc',13)
    labels=['土壁','木壁','石壁','ドア','施錠ドア','土床','木床','石床','調理台','木工作業台','裁縫台','木箱','木製棚','こけし','化石']
    sheet=Image.new('RGB',(1000,970),(233,223,194));d=ImageDraw.Draw(sheet)
    d.text((14,10),'建築ゴースト：本体描画命令のCPU再現（実ゲーム画面ではありません）',font=font,fill=(48,62,42))
    d.text((14,38),'左：設置可（45%）　右：設置不可（赤色48%＋禁止マーク）／新規素材なし',font=small,fill=(48,62,42))
    for i,title in enumerate(labels):
        x=12+(i%3)*330;y=72+(i//3)*178
        d.text((x,y),title,font=font,fill=(48,62,42))
        for j in range(2):
            im=render(a.project,data[i*2+j]['commands'])
            sheet.paste(im,(x+j*158,y+32))
    sheet.save(out/'ghosts-cpu.png')
    print(out/'ghosts-cpu.png')
if __name__=='__main__':main()
