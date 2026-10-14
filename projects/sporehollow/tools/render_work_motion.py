"""Render production work-motion draw commands on CPU; never launches Godot/GPU.
Requires Pillow. Output is a pose comparison, not an in-game screenshot.
"""
import argparse,json,hashlib
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
def render(root,commands):
 canvas=Image.new("RGBA",(200,145),(65,81,61,255));d=ImageDraw.Draw(canvas)
 d.line((20,111,180,111),fill=(144,158,120),width=1)
 d.line((100,108,100,115),fill=(231,196,111),width=1)
 for c in commands:
  color=tuple(round(v*255) for v in c.get("color",[1,1,1,1]))
  if c["type"]=="sprite":
   path=root/c["path"].removeprefix("res://")
   with Image.open(path) as source:
    x,y,w,h=c["rect"];sprite=source.convert("RGBA").resize((round(w),round(h)),Image.Resampling.NEAREST)
    canvas.alpha_composite(sprite,(round(x),round(y)))
  elif c["type"]=="line":
   d.line([tuple(p) for p in c["points"]],fill=color,width=max(1,round(c["width"])))
  elif c["type"]=="polygon":d.polygon([tuple(p) for p in c["points"]],fill=color)
  elif c["type"]=="rect":
   x,y,w,h=c["rect"];d.rectangle((x,y,x+w-1,y+h-1),fill=color)
 return canvas.convert("RGB")
def main():
 ap=argparse.ArgumentParser();ap.add_argument("--project",type=Path,required=True);a=ap.parse_args();root=a.project
 out=root/"review/current/work-motion";data=json.loads((out/"motion-draw-commands.json").read_text(encoding="utf-8-sig"))
 manifest=json.loads((root/"art_delivery/colony_growth_assets_v1/manifest.json").read_text(encoding="utf-8"))
 def entries(obj):
  if isinstance(obj,dict):
   if str(obj.get("file","")).startswith("work_pose/"):yield obj
   for v in obj.values():yield from entries(v)
  elif isinstance(obj,list):
   for v in obj:yield from entries(v)
 checks=[]
 for row in entries(manifest):
  path=root/"art_delivery/colony_growth_assets_v1"/row["file"]
  with Image.open(path) as im:actual_size=list(im.size);mode=im.mode
  checks.append({"file":row["file"],"sha256":hashlib.sha256(path.read_bytes()).hexdigest(),"valid":hashlib.sha256(path.read_bytes()).hexdigest()==row["sha256"] and actual_size==row["size_px"] and mode=="RGBA"})
 assert len(checks)==4 and all(c["valid"] for c in checks)
 (out/"asset-checks.json").write_text(json.dumps({"source_commit":"adb33aa07da2ec57959e0315963f15003ddcd085","checks":checks},indent=2),encoding="utf-8")
 font=ImageFont.truetype("C:/Windows/Fonts/meiryo.ttc",14);small=ImageFont.truetype("C:/Windows/Fonts/meiryo.ttc",12)
 titles={"mine":"採掘","clear_tree":"伐採","build":"建築"}
 rows=[(k,di) for k in titles for di in [-1,1]]
 sheet=Image.new("RGB",(1024,1042),(236,230,210));draw=ImageDraw.Draw(sheet)
 draw.text((14,10),"作業モーション試作：共通描画命令のCPU再現（実ゲーム画面ではありません）",font=font,fill=(43,58,40))
 draw.text((14,33),"既存の接近 → 振りかぶり → 接触 → 戻り → 通常復帰 ／ 黄色の印は固定足元",font=small,fill=(43,58,40))
 for ri,(kind,di) in enumerate(rows):
  y=65+ri*162
  baseline=lambda action: next(b["commands"] for b in data["baselines"] if b["direction"]==di and b["action"]==action)
  frame=lambda n: next(b["commands"] for b in data["frames"] if b["kind"]==kind and b["direction"]==di and b["frame"]==n)
  for ci,(label,commands) in enumerate([("接近",baseline("walk")),("振りかぶり",frame(6)),("接触",frame(9)),("戻り",frame(12)),("中断・完了",baseline("idle"))]):
   tile=render(root,commands);sheet.paste(tile,(12+ci*200,y+17))
   draw.text((12+ci*200,y),titles[kind]+("左 " if di<0 else "右 ")+label,font=small,fill=(43,58,40))
 sheet.save(out/"work-motion-comparison.png",optimize=True)
 frames=[]
 for fi in range(36):
  pic=Image.new("RGB",(624,358),(236,230,210));d=ImageDraw.Draw(pic)
  d.text((12,8),"CPU動作見本 · 12fps · 足元固定 · ゲーム画面/GPU検証ではありません",font=small,fill=(43,58,40))
  for ci,kind in enumerate(titles):
   for ri,di in enumerate([-1,1]):
    frame=next(f for f in data["frames"] if f["kind"]==kind and f["direction"]==di and f["frame"]==fi)
    pic.paste(render(root,frame["commands"]),(12+ci*200,45+ri*156))
    d.text((12+ci*200,29+ri*156),titles[kind]+("左 " if di<0 else "右 ")+{"windup":"振りかぶり","contact":"接触","return":"戻り"}[frame["stage"]],font=small,fill=(43,58,40))
  frames.append(pic)
 frames[0].save(out/"work-motion.gif",save_all=True,append_images=frames[1:],duration=83,loop=0,optimize=False)
 print("Four official assets verified; CPU comparison PNG and 36-frame GIF saved.")
if __name__=="__main__":main()
