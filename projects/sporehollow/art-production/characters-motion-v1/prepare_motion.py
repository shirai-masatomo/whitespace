from pathlib import Path
from PIL import Image,ImageOps,ImageDraw,ImageFont
import numpy as np,json,shutil,hashlib
R=Path(r"C:\Users\masat\.codex\worktrees\sporehollow-art\codex_test\projects\sporehollow")
P=R/"art-production/characters-motion-v1";D=R/"art_delivery/characters_motion_v1"
D.mkdir(exist_ok=True);(D/"review").mkdir(exist_ok=True)
ref={k:Image.open(R/f"art_delivery/characters_v1/{k}_idle_right_00.png").convert("RGBA") for k in ["keeper","shiba"]}
def split(img):
    a=np.asarray(img)[:,:,3];xs=np.flatnonzero((a>127).sum(0)>8);gr=np.split(xs,np.flatnonzero(np.diff(xs)>1)+1)
    out=[]
    for g in gr:
        if len(g)<30:continue
        c=img.crop((int(g[0]),0,int(g[-1])+1,img.height));m=c.getchannel("A").point(lambda v:255 if v>127 else 0);b=m.getbbox();c=c.crop(b);c.putalpha(m.crop(b));out.append(c)
    assert len(out)==3
    return out
def resize(c,targetwidth,palette):
    h=round(c.height*targetwidth/c.width);c=c.resize((targetwidth,h),Image.Resampling.BOX)
    a=c.getchannel("A").point(lambda v:255 if v>=128 else 0);c=c.convert("RGB").quantize(palette=palette,dither=Image.Dither.NONE).convert("RGBA");c.putalpha(a);return c
def reflect(f):
    r=Image.new("RGBA",f.size);r.alpha_composite(ImageOps.mirror(f),(1,0));return r
states={};records=[];face_qa=[]
for key in ["keeper","shiba"]:
    (D/key).mkdir(exist_ok=True)
    idle=ref[key];w=idle.width;rgb=sorted(set(p[:3] for p in idle.getdata() if p[3]))
    pal=Image.new("P",(1,1));pal.putpalette(sum([list(c) for c in rgb],[])+list(rgb[0])*(256-len(rgb)))
    source=split(Image.open(P/"originals"/f"{key}-rest-body.png").convert("RGBA"))
    phases=[]
    for i,c in enumerate(source):
        body=resize(c,(19 if i==0 else 22) if key=="keeper" else (25 if i==0 else 28),pal)
        f=Image.new("RGBA",idle.size)
        if key=="keeper":
            f.alpha_composite(body,(16-body.width//2,44-body.height))
            offset=4 if i==0 else 8
            head=idle.crop((0,0,32,22));f.alpha_composite(head,(0,offset))
            # Exact source head pixel comparison on opaque head mask.
            arr=np.asarray(f.crop((0,offset,32,offset+22)));aa=np.asarray(head);assert np.array_equal(arr[aa[:,:,3]>0],aa[aa[:,:,3]>0])
        else:
            f.alpha_composite(body,(24-body.width//2,44-body.height))
            offset=5 if i==0 else 10
            head=idle.crop((22,16,38,31));f.alpha_composite(head,(22,16+offset))
            arr=np.asarray(f.crop((22,16+offset,38,31+offset)));aa=np.asarray(head);assert np.array_equal(arr[aa[:,:,3]>0],aa[aa[:,:,3]>0])
        phases.append(f)
        face_qa.append({"character":key,"pose":i,"head_opaque_pixels_match_approved_source":True})
    # Native-pixel breathing motion in torso only. Keep head, silhouette and ground stable.
    rest0=phases[1];rest1=phases[2]
    if key=="keeper":
        sleep=[]
        for r in [rest0,rest1]:
            s=r.copy()
            # Same hat and face pixels; lower the original brim over the unchanged face to signal sleep.
            s.paste((0,0,0,0),(0,0,32,22))
            s.alpha_composite(idle.crop((0,0,32,15)),(0,14))
            sleep.append(s)
        states[key]={"settle":[phases[0],rest0],"rest":[rest0,rest1],"sleep":sleep,"wake":[rest0,phases[0]]}
    else:states[key]={"settle":[phases[0],rest0],"rest":[rest0,rest1],"wake":[rest0,phases[0]]}
    # Finish walk from existing fixed-head preview; add tiny forearm swing for the keeper.
    for direction in ["right","left"]:
        walks=[]
        for i in range(4):
            src=R/f"art-production/walk-preview-c/processed/{key}/walk_{direction}_{i:02}.png"
            f=Image.open(src).convert("RGBA")
            if key=="keeper":
                # Use the existing approved hand pixels; keep face/hat entirely untouched.
                right=Image.open(R/f"art-production/walk-preview-c/processed/keeper/walk_right_{i:02}.png").convert("RGBA")
                for box,delta in [((8,29,14,35),[-1,0,1,0][i]),((21,29,25,35),[1,0,-1,0][i])]:
                    arm=idle.crop(box)
                    # Preserve trouser/torso cells; move only skin + its immediate dark outline.
                    a=np.asarray(arm).copy();keep=np.zeros(a.shape[:2],bool)
                    for yy in range(a.shape[0]):
                        for xx in range(a.shape[1]):
                            r,g,b,al=map(int,a[yy,xx])
                            keep[yy,xx]=al>0 and (r>170 or (r<65 and g<40))
                    a[~keep]=0;arm=Image.fromarray(a)
                    for yy in range(a.shape[0]):
                        for xx in range(a.shape[1]):
                            if keep[yy,xx]:right.putpixel((box[0]+xx,box[1]+yy),(0,0,0,0))
                    right.alpha_composite(arm,(box[0]+delta,box[1]))
                f=right if direction=="right" else reflect(right)
            walks.append(f)
        states[key]["walk_"+direction]=walks
    for action,frames in list(states[key].items()):
        directions=["right","left"] if not action.startswith("walk_") else [action.split("_")[1]]
        for direction in directions:
            final=frames if direction=="right" or action.startswith("walk_") else [reflect(f) for f in frames]
            name=action if not action.startswith("walk_") else "walk"
            times=[100]*4 if name=="walk" else ([650,650] if name in ["rest","sleep"] else [180,180])
            sheet=Image.new("RGBA",(w*len(final),48))
            for i,f in enumerate(final):
                fp=D/key/f"{name}_{direction}_{i:02}.png";f.save(fp);sheet.alpha_composite(f,(w*i,0))
                assert f.getbbox()[3]==44 and set(f.getchannel("A").getdata())=={0,255}
                if name=="walk":assert f.getbbox()[1]==(2 if key=="keeper" else 16)
            sheet.save(D/key/f"{name}_{direction}_sheet.png")
            records.append({"character":key,"action":name,"direction":direction,"canvas":[w,48],"foot_anchor":[w//2,44],"frame_order":list(range(len(final))),"frame_duration_ms":times,
                            "loop":name in ["walk","rest","sleep"],"files":[f"{key}/{name}_{direction}_{i:02}.png" for i in range(len(final))],
                            "sheet":f"{key}/{name}_{direction}_sheet.png","status":"art_complete_game_integration_unverified"})
# Detailed proof includes static source next to generated body composites.
font=ImageFont.truetype(r"C:\Windows\Fonts\meiryo.ttc",14)
proof=Image.new("RGB",(1080,760),"#e7d9b5");draw=ImageDraw.Draw(proof)
for row,key in enumerate(["keeper","shiba"]):
    draws=[("採用静止",ref[key]),("移行",states[key]["settle"][0]),("休息0",states[key]["rest"][0]),("休息1",states[key]["rest"][1])]
    draws += [("睡眠",states[key]["sleep"][0])] if key=="keeper" else [("起床",states[key]["wake"][1])]
    for col,(name,f) in enumerate(draws):
        x=col*212+10;y=row*320+50;draw.text((x,y-26),key+" "+name,font=font,fill="#384738")
        z=f.resize((f.width*4,192),Image.Resampling.NEAREST);proof.paste(z,(x,y),z);draw.line((x,y+176,x+190,y+176),fill="#a78851")
draw.text((16,700),"顔・頭部は既存PNGの画素。睡眠は同じ帽子で顔を覆う。静止納品は無変更。",font=font,fill="#384738")
proof.save(D/"review/rest-proof.png")
man={"delivery":"characters_motion_v1","requires_static_delivery":"../characters_v1","assets":records,"head_reuse_checks":face_qa,
"notes":["Faces are not regenerated; existing opaque head pixels composited unchanged for rest","Keeper sleep lowers the same hat over existing face; no new facial design","Existing static delivery untouched","All frames preserve canvas and foot y44; pose heights naturally change during sitting/lying","Game runtime visual verification pending"],
"source_art":"../../art-production/characters-motion-v1","generator":"image_gen.imagegen","prompts":"../../art-production/characters-motion-v1/prompts.json"}
(D/"manifest.json").write_text(json.dumps(man,ensure_ascii=False,indent=2),encoding="utf8")
print(json.dumps({"animation_count":len(records),"frame_files":sum(len(r["files"]) for r in records),"head_checks":face_qa}))

