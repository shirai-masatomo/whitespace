from PIL import Image, ImageDraw, ImageFont
from pathlib import Path
import json, shutil, hashlib
root=Path(r"C:\Users\masat\.codex\worktrees\sporehollow-art\codex_test\projects\sporehollow")
out=root/"art-production"/"stage-1"
source=Path(r"C:\Users\masat\.codex\generated_images\01a1062f-6339-7812-baec-d517611755ca\exec-6a5b9882-62c9-4046-a71a-c7b0633607b0.png")
shutil.copy2(source,out/"originals"/"generated-pair-v1.png")
im=Image.open(source).convert("RGBA")
def sprite(box, size, max_size, anchor):
    crop=im.crop(box)
    mask=crop.getchannel("A").point(lambda v:255 if v>=128 else 0)
    bounds=mask.getbbox()
    crop=crop.crop(bounds)
    crop.putalpha(mask.crop(bounds))
    ratio=min(max_size[0]/crop.width,max_size[1]/crop.height)
    target=(round(crop.width*ratio),round(crop.height*ratio))
    crop=crop.resize(target,Image.Resampling.NEAREST)
    return crop,target
keeper,ks=sprite((0,0,790,926),(32,48),(28,42),(16,44))
dog,ds=sprite((790,0,1698,926),(48,48),(44,44),(24,44))
# Shared finite palette, no dithering: readable solid pixel clusters instead of noisy gradients.
pixels=[p[:3] for s in (keeper,dog) for p in s.getdata() if p[3]]
strip=Image.new("RGB",(len(pixels),1)); strip.putdata(pixels)
palette=strip.quantize(colors=24,method=Image.Quantize.MEDIANCUT)
def finish(s,size,anchor):
    a=s.getchannel("A")
    s=s.convert("RGB").quantize(palette=palette,dither=Image.Dither.NONE).convert("RGBA"); s.putalpha(a)
    canvas=Image.new("RGBA",size,(0,0,0,0))
    xy=(anchor[0]-s.width//2,anchor[1]-s.height)
    canvas.alpha_composite(s,xy)
    return canvas
keeper=finish(keeper,(32,48),(16,44)); dog=finish(dog,(48,48),(24,44))
keeper.save(out/"processed"/"keeper_idle_right_00.png")
dog.save(out/"processed"/"shiba_idle_right_00.png")
pair=Image.new("RGBA",(96,48)); pair.alpha_composite(keeper,(0,0)); pair.alpha_composite(dog,(48,0))
pair.save(out/"processed"/"pair_actual_size.png")
fontpath=r"C:\Windows\Fonts\meiryo.ttc"
font=ImageFont.truetype(fontpath,16); small=ImageFont.truetype(fontpath,13)
sheet=Image.new("RGB",(880,720),"#e7d9b5"); d=ImageDraw.Draw(sheet)
d.text((20,12),"第一段階 v1：主人公＋柴犬 ／ 採用前の比較見本",font=font,fill="#384738")
d.text((20,38),"原画から整形・共通24色・1px輪郭・nearest。足元は両方 y=44。",font=small,fill="#384738")
farm=Image.open(root/"review/current/indoors.png").convert("RGBA")
grass=farm.crop((280,85,1120,225))
sheet.paste(grass.convert("RGB"),(20,88))
d.text((20,64),"1倍：1280×800画面での素材寸法（既存の鶏・猫は画面の切り出し）",font=small,fill="#384738")
for s,pos in [(keeper,(110,142)),(dog,(220,142))]: sheet.paste(s,pos,s)
hen=farm.crop((1005,506,1044,547))
cat=farm.crop((1040,624,1090,673))
sheet.paste(hen.convert("RGB"),(390,149)); sheet.paste(cat.convert("RGB"),(530,141))
for x,label in [(92,"主人公 32×48"),(196,"柴犬 48×48"),(365,"現行の鶏"),(508,"現行の猫")]: d.text((x,204),label,font=small,fill="#f8efda")
d.text((20,242),"4倍：色・目・足・輪郭と共通の接地位置",font=small,fill="#384738")
bg=farm.crop((300,150,510,206)).resize((840,224),Image.Resampling.NEAREST)
sheet.paste(bg.convert("RGB"),(20,266))
for s,pos in [(keeper,(188,282)),(dog,(432,282))]:
    zoom=s.resize((s.width*4,s.height*4),Image.Resampling.NEAREST); sheet.paste(zoom,pos,zoom)
d.line((110,458,732,458),fill="#e7d9b5",width=1)
d.text((20,502),"透過確認（4倍）／右端：採用原画の同寸法参考",font=small,fill="#384738")
for box,col in [((20,530,300,706),"#22352d"),((310,530,590,706),"#fbf5e8"),((600,530,860,706),"#ffffff")]:d.rectangle(box,fill=col)
zoom=dog.resize((192,192),Image.Resampling.NEAREST)
# Full frame is shown at 3x in alpha panels to fit; labels state actual magnification.
d.rectangle((20,502,870,527),fill="#e7d9b5")
d.text((20,502),"透過確認（3倍）／右端：採用原画の同寸法参考（白背景のまま）",font=small,fill="#384738")
zoom=dog.resize((144,144),Image.Resampling.NEAREST)
sheet.paste(zoom,(88,548),zoom); sheet.paste(zoom,(378,548),zoom)
original=Image.open(root/"assets/ui/shiba-source.png").crop((1498,58,1980,566))
original.thumbnail((42,44),Image.Resampling.NEAREST)
original=original.resize((original.width*3,original.height*3),Image.Resampling.NEAREST)
sheet.paste(original.convert("RGB"),(658,550))
sheet.save(out/"review"/"comparison-v1.png")
# Explicitly labelled compositing evidence, never represented as a new gameplay capture.
scene=Image.new("RGB",(1280,850),"#e7d9b5");scene.paste(farm.convert("RGB"),(0,50))
sd=ImageDraw.Draw(scene);sd.text((16,10),"素材配置見本：前回 823f876 の実画面へ合成 ／ 最新ゲーム内検証ではありません",font=font,fill="#384738")
scene.paste(keeper,(340,480),keeper);scene.paste(dog,(404,480),dog)
sd.text((312,454),"新規見本 1倍",font=small,fill="#fbf5e8")
scene.save(out/"review"/"ranch-composite-v1.png")
assets=[]
for name,s,anchor in [("keeper_idle_right_00.png",keeper,[16,44]),("shiba_idle_right_00.png",dog,[24,44])]:
    opaque=[p for p in s.getdata() if p[3]]
    qa={"rgba":s.mode=="RGBA","alpha_values":sorted(set(s.getchannel("A").getdata())),"visible_bounds":list(s.getbbox()),"opaque_colors":len(set(p[:3] for p in opaque)),"bottom_visible_row":s.getbbox()[3]-1,"horizontal_and_bottom_margins_clear":s.getbbox()[0]>0 and s.getbbox()[2]<s.width and s.getbbox()[3]<s.height}
    assert qa["alpha_values"]==[0,255] and qa["bottom_visible_row"]==43 and qa["horizontal_and_bottom_margins_clear"]
    assets.append({"file":"processed/"+name,"size":list(s.size),"foot_anchor":anchor,"state":"idle_right","frame_order":[0],"frame_duration_ms":None,"playback":"hold until state changes; single static candidate","status":"candidate_not_adopted","qa":qa})
manifest={"stage":1,"status":"awaiting_initial_style_and_size_selection","implementation_base":"1d637354d55c20675f5594e36befd307ca954af6","spec":"../ART_SPEC.md (relative to art-production)","generation":{"tool":"image_gen.imagegen","prompt":"prompt.txt","source":"originals/generated-pair-v1.png","paid_external_api":False},"assets":assets,"processing":["Separate generated characters by transparent gutter","Alpha threshold 128 removes faint fringe; preserve opaque cream fur","Uniform aspect-fit then nearest-neighbor sampling, no anisotropic stretch","Shared 24-color palette without dithering","Align soles at y43, foot anchor y44; transparent frame margins","Inspect at native size and enlarged on source ranch, light and dark backgrounds"],"limitations":["ImageGen output did not follow requested canvas or exact pixel grid; normalized output is a candidate","Source ranch capture is old 823f876; no game was launched","Hen/cat are unmodified old screenshot crops for context, not delivered assets","Only one right-facing static candidate each; no walk, front or rest frames yet","Keeper tool readability awaits later working-pose sample","Dog visible height 44 vs keeper 42 follows provisional ART_SPEC; user should judge relative size","Final in-game integration and visual acceptance remain implementation-owner work"]}
(out/"manifest.json").write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding="utf-8")
auditpath=root/"art-production/reference-audit.json";audit=json.loads(auditpath.read_text(encoding="utf-8-sig"))
audit["status"]="stage_1_candidate_ready_for_selection";audit["implementation_head"]=manifest["implementation_base"];audit["remote_head_verified"]=False
audit["image_tool"]["generation_executed"]=True;audit["image_tool"]["reason"]="ART_SPEC received; initial candidate generated"
audit["missing"]=[entry for entry in audit["missing"] if entry["reference"]!="ART_SPEC.md"]
audit["next_stage"]="User selects initial style and relative size; then stage 2 cleanup/directions/animation against the same standard"
audit["delivered_assets"]=["stage-1/manifest.json"];audit["current_spec"]="projects/sporehollow/ART_SPEC.md"
auditpath.write_text(json.dumps(audit,ensure_ascii=False,indent=2),encoding="utf-8")
print(json.dumps({"keeper_content":ks,"shiba_content":ds,"assets":assets},ensure_ascii=False,indent=2))


