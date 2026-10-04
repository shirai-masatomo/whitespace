from PIL import Image,ImageOps,ImageDraw,ImageFont
from pathlib import Path
import numpy as np,json
R=Path(r"C:\Users\masat\.codex\worktrees\sporehollow-art\codex_test\projects\sporehollow")
O=R/"art-production/walk-preview-c"
refs={"keeper":R/"art-production/stage-1/processed/keeper_idle_right_00.png","shiba":R/"art-production/stage-1-v2/processed/c65/idle_right_00.png"}
cfg={"keeper":(32,42,31),"shiba":(48,28,36)}
def parts(im):
    a=np.asarray(im)[:,:,3];cols=np.flatnonzero((a>=128).sum(0)>10);gs=np.split(cols,np.flatnonzero(np.diff(cols)>1)+1)
    out=[]
    for g in gs:
        if len(g)<20:continue
        c=im.crop((int(g[0]),0,int(g[-1])+1,im.height));alpha=c.getchannel("A").point(lambda v:255 if v>=128 else 0)
        b=alpha.getbbox();c=c.crop(b);c.putalpha(alpha.crop(b));out.append(c)
    assert len(out)==4,len(out)
    return out
allframes={}
font=ImageFont.truetype(r"C:\Windows\Fonts\meiryo.ttc",16)
sheet=Image.new("RGB",(1200,680),"#e7d9b5");d=ImageDraw.Draw(sheet)
for row,key in enumerate(["keeper","shiba"]):
    idle=Image.open(refs[key]).convert("RGBA");w,h,cut=cfg[key]
    col=sorted({p[:3] for p in idle.getdata() if p[3]})
    p=Image.new("P",(1,1));p.putpalette(sum([list(c) for c in col],[])+list(col[0])*(256-len(col)))
    cropped=parts(Image.open(O/"originals"/(key+"-walk-guide.png")).convert("RGBA"))
    walks=[]
    for i,c in enumerate(cropped):
        target=(round(c.width*h/c.height),h);c=c.resize(target,Image.Resampling.BOX)
        alpha=c.getchannel("A").point(lambda v:255 if v>=128 else 0)
        c=c.convert("RGB").quantize(palette=p,dither=Image.Dither.NONE).convert("RGBA");c.putalpha(alpha)
        f=Image.new("RGBA",idle.size);f.alpha_composite(c,(w//2-c.width//2,44-h))
        # Raw output is motion source only. Preserve approved upper sprite pixel for pixel.
        f.paste(idle.crop((0,0,w,cut)),(0,0))
        f.save(O/"review"/f"{key}-grafted-{i}.png");walks.append(f)
    allframes[key]=walks
    for i,f in enumerate(walks+[idle]):
        zoom=f.resize((f.width*5,240),Image.Resampling.NEAREST)
        x=i*240;y=row*320+35
        d.text((x+10,y-25),f"{key} {i if i<4 else 'idle'}",font=font,fill="#384738")
        sheet.paste(zoom,(x,y),zoom);d.line((x,y+220,x+235,y+220),fill="#a78e61")
sheet.save(O/"review/graft-draft.png")

import hashlib,shutil,math
def hashfile(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def reflected_about_anchor(im):
    # Reflect around the integer anchor column, preserving odd-width body centering.
    z=Image.new("RGBA",im.size);z.alpha_composite(ImageOps.mirror(im),(1,0));return z
def components(alpha):
    a=np.asarray(alpha)>0;seen=set();parts=[]
    for y,x in zip(*np.where(a)):
        if (x,y) in seen:continue
        todo=[(x,y)];seen.add((x,y));piece=[]
        while todo:
            xx,yy=todo.pop();piece.append((xx,yy))
            for dx in [-1,0,1]:
                for dy in [-1,0,1]:
                    nx,ny=xx+dx,yy+dy
                    if 0<=nx<a.shape[1] and 0<=ny<a.shape[0] and a[ny,nx] and (nx,ny) not in seen:
                        seen.add((nx,ny));todo.append((nx,ny))
        parts.append(piece)
    return sorted(parts,key=len,reverse=True)
output={};qa_records=[];repair_counts={}
for key in ["keeper","shiba"]:
    idle=Image.open(refs[key]).convert("RGBA");w,h,oldcut=cfg[key]
    cutoff=35 if key=="keeper" else 36
    idle_left=reflected_about_anchor(idle) if key=="keeper" else Image.open(R/"art-production/stage-1-v2/processed/c65/idle_left_00.png").convert("RGBA")
    right=[]
    for i,raw in enumerate(allframes[key]):
        f=raw.copy();f.paste(idle.crop((0,0,w,cutoff)),(0,0))
        before=np.asarray(f).copy()
        # Correct limb depth between the two contact poses; raw generation nearly repeated them.
        arr=np.asarray(f).copy()
        if key=="keeper":
            # Rear boot in phase0; opposite boot recedes in phase2.
            lo,hi=(7,16) if i==0 else (18,27)
            if i in (0,2):
                for y in range(38,44):
                    for x in range(lo,min(hi,w)):
                        if tuple(arr[y,x,:3])==(108,71,44) and arr[y,x,3]:
                            arr[y,x,:3]=(78,46,24)
            if i==2:
                for x,y in [(16,35),(15,36),(14,37),(13,38)]:
                    if arr[y,x,3]:arr[y,x,:3]=(46,21,6)
        else:
            # White near paws and shaded far paws differentiate the alternating contact.
            lo,hi=(19,25) if i==0 else (28,36)
            if i in (0,2):
                for y in range(38,44):
                    for x in range(lo,hi):
                        if not arr[y,x,3]:continue
                        rgb=tuple(arr[y,x,:3])
                        if rgb==(255,240,206):arr[y,x,:3]=(229,200,156)
                        elif rgb==(237,161,70):arr[y,x,:3]=(216,131,50)
            # Remove soft generated edge mixtures only on leg silhouette, keeping opaque cream interiors.
            alpha=arr[:,:,3]>0
            for y in range(38,44):
                for x in range(w):
                    if not alpha[y,x]:continue
                    if any(nx<0 or nx>=w or ny>=48 or not alpha[ny,nx] for nx,ny in [(x-1,y),(x+1,y),(x,y+1)]):
                        arr[y,x,:3]=(56,37,25)
        f=Image.fromarray(arr)
        # Tiny isolated generation fragments aren't paws. Preserve every connected limb.
        pieces=components(f.getchannel("A"))
        for piece in pieces[1:]:
            if len(piece)<=2:
                for xy in piece:f.putpixel(xy,(0,0,0,0))
        repair_counts[f"{key}_{i}"]=int(np.any(np.asarray(f)!=before,axis=2).sum())
        right.append(f)
    left=[]
    for f in right:
        l=reflected_about_anchor(f)
        l.paste(idle_left.crop((0,0,w,cutoff)),(0,0))
        left.append(l)
    output[key]={"right":right,"left":left,"idle_right":idle,"idle_left":idle_left}
    # Idle files copied byte-for-byte whenever approved originals exist.
    shutil.copy2(refs[key],O/"processed"/key/"idle_right_00.png")
    if key=="shiba":
        shutil.copy2(R/"art-production/stage-1-v2/processed/c65/idle_left_00.png",O/"processed"/key/"idle_left_00.png")
        shutil.copy2(R/"art-production/stage-1-v2/processed/c65/idle_front_00.png",O/"processed"/key/"idle_front_00.png")
    else:idle_left.save(O/"processed"/key/"idle_left_00.png")
    for direction in ["right","left"]:
        sheet=Image.new("RGBA",(w*4,48))
        hashes=[]
        for i,f in enumerate(output[key][direction]):
            filename=f"walk_{direction}_{i:02}.png"
            f.save(O/"processed"/key/filename);sheet.alpha_composite(f,(w*i,0))
            a=f.getchannel("A");bb=a.getbbox()
            assert set(a.getdata())=={0,255}
            assert bb[3]==44 and bb[1]==44-h,(key,direction,i,bb)
            assert 0<bb[0] and bb[2]<w,(key,direction,i,bb)
            frozen=idle if direction=="right" else idle_left
            assert np.array_equal(np.asarray(f.crop((0,0,w,cutoff))),np.asarray(frozen.crop((0,0,w,cutoff))))
            conn=components(a);assert len(conn)==1,(key,direction,i,[len(c) for c in conn])
            hh=hashlib.sha256(f.tobytes()).hexdigest();hashes.append(hh)
            qa_records.append({"character":key,"direction":direction,"frame":i,"size":[w,48],"anchor":[w//2,44],"visible_bounds":list(bb),"alpha":[0,255],"connected_components":len(conn),"upper_body_matches_approved_idle":True,"pixel_sha256":hh})
        assert len(set(hashes))==4,(key,direction,"duplicate poses")
        sheet.save(O/"processed"/key/f"walk_{direction}_sheet.png")
    assert hashfile(refs[key])==hashfile(O/"processed"/key/"idle_right_00.png")
# Frame review: each orientation has 4 walks + the exact stop frame.
font=ImageFont.truetype(r"C:\Windows\Fonts\meiryo.ttc",16)
small=ImageFont.truetype(r"C:\Windows\Fonts\meiryo.ttc",13)
contact=Image.new("RGB",(1080,1020),"#e7d9b5");cd=ImageDraw.Draw(contact)
cd.text((16,12),"C案採用：歩行4コマ＋停止（4倍）／線は共通の足元 y44",font=font,fill="#384738")
for row,(key,direction) in enumerate([("keeper","right"),("keeper","left"),("shiba","right"),("shiba","left")]):
    y=48+row*238
    cd.text((16,y),("主人公" if key=="keeper" else "柴犬C")+" "+("右向き" if direction=="right" else "左向き"),font=font,fill="#384738")
    cd.rectangle((16,y+28,1064,y+222),fill="#798d51")
    for i,f in enumerate(output[key][direction]+[output[key]["idle_"+direction]]):
        x=35+i*208
        scaled=f.resize((f.width*4,192),Image.Resampling.NEAREST)
        contact.paste(scaled,(x,y+30),scaled)
        cd.line((x,y+206,x+192,y+206),fill="#e7d9b5")
        cd.text((x,y+208),f"{i:02} / 100ms" if i<4 else "停止 / 保持",font=small,fill="#fff0ce")
contact.save(O/"review/contact-sheet.png")
farm=Image.open(R/"review/current/indoors.png").convert("RGB")
tile=farm.crop((285,160,525,220))
sequence=[
{"start_ms":0,"end_ms":2000,"action":"walk","direction":"right","label":"右へ歩く","x_start":32,"x_end":92},
{"start_ms":2000,"end_ms":3000,"action":"idle","direction":"right","label":"停止（右向き）","x_start":92,"x_end":92},
{"start_ms":3000,"end_ms":5000,"action":"walk","direction":"left","label":"左へ歩く","x_start":92,"x_end":32},
{"start_ms":5000,"end_ms":6500,"action":"idle","direction":"left","label":"停止（左向きを保持）","x_start":32,"x_end":32}]
frames=[];trace=[]
for t in range(0,6500,50):
    phase=next(p for p in sequence if p["start_ms"]<=t<p["end_ms"])
    elapsed=t-phase["start_ms"]
    ratio=elapsed/(phase["end_ms"]-phase["start_ms"])
    pos=round(phase["x_start"]+(phase["x_end"]-phase["x_start"])*ratio)
    fi=(elapsed//100)%4 if phase["action"]=="walk" else None
    chosen={k:(output[k][phase["direction"]][fi] if fi is not None else output[k]["idle_"+phase["direction"]]) for k in output}
    world=tile.copy()
    for k,dx in [("keeper",0),("shiba",65)]:
        f=chosen[k];world.paste(f,(pos+dx,52-44),f)
    canvas=Image.new("RGB",(1000,460),"#e7d9b5");d=ImageDraw.Draw(canvas)
    d.text((20,12),"C案：主人公＋柴犬の歩行・停止見本",font=font,fill="#384738")
    d.text((20,38),f"{phase['label']}   {t/1000:.2f}s / 6.50s",font=font,fill="#384738")
    d.text((20,68),"1倍（実表示サイズ）",font=small,fill="#384738")
    # Native-size row: use source at 1 pixel per pixel, never resized.
    native_bg=farm.crop((280,150,1240,218));canvas.paste(native_bg,(20,91))
    for k,dx in [("keeper",0),("shiba",65)]:
        f=chosen[k];canvas.paste(f,(140+pos+dx,99),f)
    d.text((20,170),"4倍（nearest）：上半身固定／左右それぞれ4コマ・100ms／移動30px毎秒",font=small,fill="#384738")
    canvas.paste(world.resize((960,240),Image.Resampling.NEAREST),(20,194))
    d.text((20,439),"背景は保存済み823f876画面。素材の合成確認であり、ゲーム内検証ではありません。",font=small,fill="#384738")
    frames.append(canvas)
    trace.append({"time_ms":t,"phase":phase["label"],"direction":phase["direction"],"action":phase["action"],"frame":fi,"x":pos})
# Unified GIF palette prevents palette flicker. Pauses may be stored as consolidated frames.
pal=Image.new("RGB",(1000,460*4))
for i,ix in enumerate([0,40,60,100]):pal.paste(frames[ix],(0,460*i))
pal=pal.quantize(colors=128,method=Image.Quantize.MEDIANCUT)
indexed=[f.quantize(palette=pal,dither=Image.Dither.NONE) for f in frames]
indexed[0].save(O/"review/walk-right-stop-left-stop.gif",save_all=True,append_images=indexed[1:],duration=50,loop=0,optimize=False,disposal=2)
# Also lossless animation for browsers supporting APNG.
frames[0].save(O/"review/walk-right-stop-left-stop.png",save_all=True,append_images=frames[1:],duration=50,loop=0,disposal=0,blend=0)
frames[40].save(O/"review/stop-right.png");frames[100].save(O/"review/stop-left.png")
# Verify stop facing and position for entire holding ranges.
for p in sequence:
    rows=[r for r in trace if p["start_ms"]<=r["time_ms"]<p["end_ms"]]
    assert all(r["direction"]==p["direction"] for r in rows)
    if p["action"]=="idle":assert len({r["x"] for r in rows})==1 and all(r["frame"] is None for r in rows)
assert trace[-1]["direction"]=="left" and trace[-1]["action"]=="idle"
gif=Image.open(O/"review/walk-right-stop-left-stop.gif");duration=0
for i in range(gif.n_frames):gif.seek(i);duration+=gif.info["duration"]
assert duration==6500,duration
manifest={"status":"C_size_adopted_walk_stop_preview_ready","selected_variant":"stage-1-v2/c65","body_heights":{"keeper":42,"shiba":28},
"frames":{"keeper":{"size":[32,48],"anchor":[16,44]},"shiba":{"size":[48,48],"anchor":[24,44]}},
"walk":{"frame_order":[0,1,2,3],"duration_ms_per_frame":100,"cycle_ms":400,"loop":True,"directions":["right","left"],"frames_per_direction":4},
"idle":{"duration_ms":None,"behavior":"hold until new state; maintain last facing","right_source":"approved originals copied byte-for-byte","shiba_left_source":"approved C left copied byte-for-byte","keeper_left_source":"mirrored approved keeper around anchor"},
"preview_sequence":sequence,"preview_duration_ms":6500,"preview_speed_px_per_second":30,"preview_rate_fps":20,
"source_capture":"review/current/indoors.png (823f876, old captured frame)","game_launched":False,"production_scenes_or_logic_modified":False,
"generation":{"tool":"image_gen.imagegen","prompts":"prompts.json","originals":["originals/keeper-walk-guide.png","originals/shiba-walk-guide.png"],"external_paid_api":False},
"processing":["Generated lower-limb motion shapes normalized proportionally to approved frame","Approved head/torso preserved pixel for pixel; keeper hands preserved through y34","Native-pixel correction of limb depth and contour; nearly repeated contact frames differentiated","Left motion mirrored about fixed anchor, with approved left upper-body pixels restored","No per-frame resizing in preview; stops switch to approved idle"],
"native_pixel_repairs":repair_counts,"qa":qa_records,"limitations":["Short walk prototype; arms/head remain fixed to prevent appearance drift","Preview speed is for comparison; implementation should synchronize step cycle to movement","No rest/sleep/wake or tool-use frames in this preview","No current gameplay integration or GUI verification","No hen/cat/UI mass production"],"state_trace":"review/sequence-trace.json"}
(O/"manifest.json").write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding="utf-8")
(O/"review/sequence-trace.json").write_text(json.dumps(trace,ensure_ascii=False,indent=2),encoding="utf-8")
print(json.dumps({"walk_frames":len(qa_records),"unique_walk_frames_per_direction":4,"gif_duration_ms":duration,"gif_stored_frames":gif.n_frames,"right_idle_hashes_preserved":True,"last_direction":"left","native_pixel_repairs":repair_counts},ensure_ascii=False))

