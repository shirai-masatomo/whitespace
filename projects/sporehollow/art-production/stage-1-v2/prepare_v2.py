from PIL import Image,ImageOps,ImageDraw,ImageFont
from pathlib import Path
import json,shutil,numpy as np
R=Path(r"C:\Users\masat\.codex\worktrees\sporehollow-art\codex_test\projects\sporehollow")
O=R/"art-production/stage-1-v2"
palette_hex=["382519","171d19","784321","ae622b","d88332","eda146","f7bc65","fff0ce","e5c89c","bc9569","d46e6b","f1aba0"]
palette=[tuple(bytes.fromhex(h)) for h in palette_hex]
P=Image.new("P",(1,1));P.putpalette(sum([list(c) for c in palette],[])+[0]*(768-len(palette)*3))
params=[("a50",22),("b58",25),("c65",28)]
def split(im):
    aa=np.asarray(im.getchannel("A"));cols=np.flatnonzero((aa>=128).sum(0)>8)
    groups=np.split(cols,np.flatnonzero(np.diff(cols)>1)+1)
    out=[]
    for g in groups:
        c=im.crop((max(0,int(g[0])-2),0,min(im.width,int(g[-1])+3),im.height))
        a=c.getchannel("A").point(lambda v:255 if v>=128 else 0)
        b=a.getbbox();c=c.crop(b);c.putalpha(a.crop(b));out.append(c)
    assert len(out)==3
    return out
def native(c,h):
    # Single uniform scale factor, one raster rounding in width. Alpha-weighted box averaging.
    w=round(c.width*h/c.height)
    c=c.resize((w,h),Image.Resampling.BOX)
    a=c.getchannel("A").point(lambda v:255 if v>=128 else 0)
    q=c.convert("RGB").quantize(palette=P,dither=Image.Dither.NONE).convert("RGBA");q.putalpha(a)
    return q
def frame(c):
    f=Image.new("RGBA",(48,48));f.alpha_composite(c,(24-c.width//2,44-c.height));return f
font=ImageFont.truetype(r"C:\Windows\Fonts\meiryo.ttc",15)
contact=Image.new("RGB",(1000,800),"#e7d9b5");draw=ImageDraw.Draw(contact)
meta={}
for row,(key,h) in enumerate(params):
    raw=Image.open(O/"originals"/(key+"-generated.png")).convert("RGBA")
    parts=split(raw)
    right=native(parts[0],h)
    if key=="a50":right=ImageOps.mirror(right)
    left=ImageOps.mirror(right)
    front=native(parts[2],h)
    meta[key]={"height":h,"side_size":list(right.size),"front_size":list(front.size)}
    for col,(name,s) in enumerate([("right",right),("left",left),("front",front)]):
        (O/"processed"/key).mkdir(exist_ok=True)
        frame(s).save(O/"processed"/key/("idle_"+name+"_00.png"))
        s.save(O/"review"/(key+"-"+name+"-body.png"))
        zoom=s.resize((s.width*8,s.height*8),Image.Resampling.NEAREST)
        x=30+col*325;y=35+row*260
        draw.text((x,y),key+" "+name+" "+str(s.size),font=font,fill="#382519")
        contact.paste(zoom,(x,y+26),zoom)
contact.save(O/"review/draft-detail.png")
(O/"draft-metadata.json").write_text(json.dumps(meta,indent=2))
print(json.dumps(meta))

# Native-size repairs after inspecting draft-detail.png. Coordinates relative to visible body.
# Each case has its own pixel decisions; these are not merely resized final images.
fixes={
"a50":{"right":{"K":[(15,7),(19,7)],"O":[(17,10),(18,10)],"c":[(15,6),(16,8),(17,8),(12,19),(13,19)],"h":[(14,2)],"p":[(14,3)]},
       "front":{"K":[(3,6),(3,7),(9,6),(9,7),(6,8),(6,9)],"O":[(5,10),(7,10),(6,11)],"p":[(6,10)],"c":[(4,8),(8,8),(3,19),(9,19)],"r":[(2,2),(10,2)]}},
"b58":{"right":{"K":[(18,7),(18,8),(23,8),(23,9)],"O":[(20,11),(21,11)],"c":[(18,6),(19,9),(20,9),(20,10),(13,22),(14,22)],"p":[(15,4)]},
       "front":{"K":[(4,7),(4,8),(9,7),(9,8),(6,9),(7,9)],"O":[(5,11),(8,11),(6,13),(7,13)],"p":[(6,11),(7,11),(6,12),(7,12)],"c":[(4,6),(9,6),(3,9),(10,9),(3,22),(10,22)]}},
"c65":{"right":{"K":[(19,8),(19,9),(24,9),(24,10)],"O":[(21,13),(22,13)],"c":[(19,7),(20,10),(21,11),(22,11),(14,24),(15,24)],"p":[(15,4)]},
       "front":{"K":[(4,8),(5,8),(4,9),(5,9),(11,8),(12,8),(11,9),(12,9),(7,10),(8,10),(9,10),(8,11)],
                "O":[(6,12),(7,13),(9,13),(10,12),(8,15)],"p":[(8,13),(8,14)],"c":[(5,7),(11,7),(5,10),(11,10),(4,25),(12,25)]}}
}
colors={symbol:tuple(bytes.fromhex(h))+(255,) for symbol,h in zip("OKBSothcCPpr",palette_hex)}
# Remove accidental black padding entries from palette without changing transparency.
def repair(c, edits):
    c=c.copy(); a=np.asarray(c)[:,:,3]>0
    for y in range(c.height):
        for x in range(c.width):
            if not a[y,x]:continue
            if c.getpixel((x,y))[:3]==(0,0,0):c.putpixel((x,y),colors["K"])
            # Single-pixel silhouette contour, never white-key extraction.
            if any(nx<0 or ny<0 or nx>=c.width or ny>=c.height or not a[ny,nx] for nx,ny in [(x-1,y),(x+1,y),(x,y-1),(x,y+1)]):
                c.putpixel((x,y),colors["O"])
    for code,points in edits.items():
        for xy in points:
            if c.getpixel(xy)[3]:c.putpixel(xy,colors[code])
    return c
assets=[];frames={};repair_stats={}
keeper_path=R/"art-production/stage-1/processed/keeper_idle_right_00.png"
shutil.copy2(keeper_path,O/"processed/keeper_idle_right_00.png")
keeper=Image.open(keeper_path).convert("RGBA")
for key,h in params:
    right0=Image.open(O/"review"/(key+"-right-body.png"))
    front0=Image.open(O/"review"/(key+"-front-body.png"))
    right=repair(right0,fixes[key]["right"]);front=repair(front0,fixes[key]["front"])
    left=ImageOps.mirror(right)
    # Body highlight stays toward screen upper-left after mirroring, rather than reversing illumination.
    ly={"a50":12,"b58":14,"c65":16}[key]
    candidates=[x for x in range(2,left.width-2) if left.getpixel((x,ly))==colors["o"] and left.getpixel((x,ly-1))[3]]
    for x in candidates[:2]:left.putpixel((x,ly),colors["t"])
    repair_stats[key]={"right_changed_pixels":int(np.any(np.asarray(right)!=np.asarray(right0),axis=2).sum()),
                      "front_changed_pixels":int(np.any(np.asarray(front)!=np.asarray(front0),axis=2).sum()),
                      "left_derived_from_right":"mirrored geometry plus screen-upper-left body highlight"}
    frames[key]={}
    strip=Image.new("RGBA",(144,48))
    for col,(name,s) in enumerate([("right",right),("left",left),("front",front)]):
        f=frame(s);frames[key][name]=f
        f.save(O/"processed"/key/("idle_"+name+"_00.png"));strip.alpha_composite(f,(48*col,0))
        bbox=f.getbbox(); alpha=set(f.getchannel("A").getdata())
        assert f.size==(48,48) and alpha=={0,255} and bbox[3]==44 and bbox[3]-bbox[1]==h
        assert 0<bbox[0]<bbox[2]<48 and bbox[1]>0
        assets.append({"variant":key,"pose":name,"file":f"processed/{key}/idle_{name}_00.png","canvas":[48,48],"anchor":[24,44],
                       "visible_bounds":list(bbox),"body_size":[bbox[2]-bbox[0],bbox[3]-bbox[1]],"height_ratio_to_v1":h/44,
                       "frame_order":[0],"duration_ms":None,"playback":"static hold; no animation yet","status":"size_candidate",
                       "alpha_values":[0,255],"rgba":True})
    strip.save(O/"processed"/key/"idle_right_left_front.png")
    # Mirrored silhouette check: compare tight crops, not padding around an odd-width body.
    aa=right.getchannel("A"); bb=ImageOps.mirror(left.getchannel("A"));assert np.array_equal(np.asarray(aa),np.asarray(bb))
farm=Image.open(R/"review/current/indoors.png").convert("RGBA")
def existing_reference(box,kind):
    s=farm.crop(box);a=np.asarray(s).copy();r,g,b=[a[:,:,i].astype(int) for i in range(3)]
    if kind=="hen":
        keep=((r-g>22)&(r>90))|((r>180)&(g>160)&(b>110))|((r<65)&(g<85)&(b<75))
    else:
        keep=((abs(r-g)<23)&(abs(g-b)<23)&(r>75)&(b>75))|((r>180)&(g>185)&(b<160))
    # Exclude vegetation/shadows by color; reference pixels themselves are unchanged.
    a[:,:,3]=np.where(keep,255,0)
    s=Image.fromarray(a);return s.crop(s.getbbox())
hen=existing_reference((1005,506,1044,547),"hen");cat=existing_reference((1040,624,1090,673),"cat")
hen.save(O/"review/existing-hen-crop.png");cat.save(O/"review/existing-cat-crop.png")
font=ImageFont.truetype(r"C:\Windows\Fonts\meiryo.ttc",16)
small=ImageFont.truetype(r"C:\Windows\Fonts\meiryo.ttc",13)
big=ImageFont.truetype(r"C:\Windows\Fonts\meiryo.ttc",20)
labels={"a50":"A  50%  /  身体高22px","b58":"B  約57%  /  身体高25px","c65":"C  約64%  /  身体高28px"}
sheet=Image.new("RGB",(1040,920),"#e7d9b5");d=ImageDraw.Draw(sheet)
d.text((20,12),"第一段階 v2 ｜ 柴犬のサイズ比較（主人公はv1のまま）",font=big,fill="#384738")
d.text((20,45),"上3段＝実寸1倍。柴犬は右・左・正面。48×48フレーム／足元(24,44)を共通化。",font=small,fill="#384738")
for row,(key,h) in enumerate(params):
    y=76+row*130
    d.text((20,y),labels[key],font=font,fill="#384738")
    bg=farm.crop((280,90,1280,188)).convert("RGB")
    sheet.paste(bg,(20,y+26))
    baseline=y+94
    for s,x,label in [(keeper,170,"主人公"),(frames[key]["right"],310,"柴犬 右"),(frames[key]["left"],400,"左"),(frames[key]["front"],490,"正面")]:
        sheet.paste(s,(x,baseline-44),s);d.text((x-4,baseline+6),label,font=small,fill="#fff0ce")
    for s,x,label in [(hen,680,"既存の鶏"),(cat,810,"既存の猫")]:
        sheet.paste(s,(x,baseline-s.height),s);d.text((x-9,baseline+6),label,font=small,fill="#fff0ce")
d.text((20,474),"4倍：同じ足元に配置。大きさと顔・足の読みやすさを比較",font=font,fill="#384738")
for col,(key,h) in enumerate(params):
    x=20+col*340
    d.rectangle((x,504,x+324,737),fill="#798d51")
    d.text((x+12,512),labels[key],font=small,fill="#fff0ce")
    # Tight native bodies only for enlarged panel; baseline remains common.
    base=716
    for pose,px in [("right",x+10),("left",x+117),("front",x+232)]:
        s=frames[key][pose];b=s.getbbox();s=s.crop(b).resize(((b[2]-b[0])*4,h*4),Image.Resampling.NEAREST)
        sheet.paste(s,(px,base-s.height),s)
    d.line((x+8,base,x+316,base),fill="#e7d9b5")
d.text((20,755),"透過検査（3倍）：暗色／明色。白毛を保持し、輪郭を濃茶のドットで修正。",font=small,fill="#384738")
for col,(key,h) in enumerate(params):
    x=20+col*340
    d.rectangle((x,782,x+161,905),fill="#22352d");d.rectangle((x+162,782,x+324,905),fill="#fbf5e8")
    for pose,px in [("right",x+20),("front",x+211)]:
        s=frames[key][pose];b=s.getbbox();s=s.crop(b).resize(((b[2]-b[0])*3,h*3),Image.Resampling.NEAREST)
        sheet.paste(s,(px,894-s.height),s)
sheet.save(O/"review/comparison-v2.png")
# Native transparent lineup; source dimensions are fixed and declared, not CSS-inferred.
native_sheet=Image.new("RGBA",(560,168))
for row,(key,h) in enumerate(params):
    baseline=row*56+44
    for s,x in [(keeper,10),(frames[key]["right"],90),(frames[key]["left"],155),(frames[key]["front"],220)]:
        native_sheet.alpha_composite(s,(x,baseline-44))
    native_sheet.alpha_composite(hen,(330,baseline-hen.height));native_sheet.alpha_composite(cat,(430,baseline-cat.height))
native_sheet.save(O/"review/lineup-native.png")
# Dedicated direction/alpha check at 6x.
qa=Image.new("RGB",(960,770),"#e7d9b5");qd=ImageDraw.Draw(qa)
qd.text((18,10),"三方向・足元・透過の検査（6倍）",font=big,fill="#384738")
for row,(key,h) in enumerate(params):
    y=56+row*232
    qd.text((18,y),labels[key],font=small,fill="#384738")
    for col,pose in enumerate(["right","left","front"]):
        x=20+col*310
        qd.rectangle((x,y+24,x+294,y+215),fill=["#22352d","#fbf5e8","#798d51"][col])
        s=frames[key][pose];b=s.getbbox();body=s.crop(b).resize(((b[2]-b[0])*6,h*6),Image.Resampling.NEAREST)
        qa.paste(body,(x+147-body.width//2,y+204-body.height),body)
        qd.line((x+12,y+204,x+282,y+204),fill="#b59c68")
qa.save(O/"review/directions-alpha-v2.png")
import hashlib
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
assert sha(keeper_path)==sha(O/"processed/keeper_idle_right_00.png")
manifest={"revision":"stage-1-v2","status":"style_approved_size_awaiting_selection","keeper":{"source":str(keeper_path),"file":"processed/keeper_idle_right_00.png","sha256":sha(keeper_path),"unchanged":True,"canvas":[32,48],"anchor":[16,44]},
"variants":[{"id":k,"target_prompt_percent":v,"actual_body_height":h,"actual_height_percent":round(100*h/44,2),"note":"Whole-pixel size, tentative comparison only"} for (k,h),v in zip(params,[50,58,65])],
"assets":assets,"palette":palette_hex,"pixel_repairs":repair_stats,"generator":"image_gen.imagegen","prompt_set":"prompts.json","external_paid_api":False,
"reference_capture":{"path":"../review/current/indoors.png (relative to project)","implementation":"823f876","current_game_verification":False,"hen_cat":"Existing rendered pixels extracted for review only; no animal redesign"},
"limitations":["Side geometry mirrored for exact size consistency; small upper-left highlight corrected afterward","ImageGen did not honor native resolution or requested first pose in A; normalized and repaired at native size","50% option intentionally has minimal eye/mouth marks; choose based on 1x appearance","Latest game was not launched; screenshot composite only","Walk/stop sample begins after user selects size","No mass production or UI/hen/cat redesign"],
"next_sequence":["walk right","stop facing right","walk left","stop facing left"]}
(O/"manifest.json").write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding="utf-8")
print(json.dumps({"keeper_unchanged":True,"repairs":repair_stats,"assets":assets},ensure_ascii=False))

