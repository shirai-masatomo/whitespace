from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageOps
import json,hashlib,math,numpy as np
R=Path(__file__).resolve().parents[2];D=R/"art_delivery/ranch_assets_v1";B=D/"book"
M=json.loads((D/"manifest.json").read_text(encoding="utf8"))
font=ImageFont.truetype(r"C:\Windows\Fonts\meiryo.ttc",14)
base=Image.open(B/"open_00.png").convert("RGBA").resize((256,160),Image.Resampling.NEAREST)
closed=Image.open(B/"closed_00.png").convert("RGBA").resize((64,80),Image.Resampling.NEAREST)
# Single hinge. Cover is a uniform2x source crop with only perspective width changing.
front=closed.crop((5,3,61,69)).resize((112,132),Image.Resampling.NEAREST)
frontcanvas=Image.new("RGBA",(256,160));frontcanvas.alpha_composite(front,(128,9))
frontcanvas.resize((1024,640),Image.Resampling.NEAREST).save(B/"front_cover_hinge_layer.png")
right=base.copy();right.paste((0,0,0,0),(0,0,128,160))
inside=base.crop((18,9,128,141))
def large(im):return im.resize((1024,640),Image.Resampling.NEAREST)
def output(seq,name,durations):
    paths=[]
    for i,f in enumerate(seq):
        p=f"book/{name}_{i:02}.png";large(f).save(D/p);paths.append(p)
    return {"files":paths,"frame_size":[1024,640],"hinge":[512,36],"frame_order":list(range(len(seq))),"duration_ms":durations,"loop":False,"status":"art_complete_integration_unverified"}
opening=[]
for i,(side,fac) in enumerate([("front",1),("front",.75),("front",.25),("back",.25),("back",.75),("back",1)]):
    if i==5:f=base.copy()
    else:
        f=right.copy()
        if side=="front":
            w=max(1,round(112*fac));f.alpha_composite(front.resize((w,132),Image.Resampling.NEAREST),(128,9))
        else:
            w=max(1,round(110*fac));f.alpha_composite(inside.resize((w,132),Image.Resampling.NEAREST),(128-w,9))
        # Binding stays under the pivot throughout; no shadow/light side inversion.
        f.alpha_composite(base.crop((126,9,130,141)),(126,9))
    opening.append(f)
anims={"open":output(opening,"opening",[110]*6),"close":output(list(reversed(opening)),"closing",[110]*6)}
# Page turning overlays use the same blank paper for recto/verso and a fixed vertical hinge.
# Give content quads to the game so text stays separately rendered and can follow the turn.
quads={}
for direction in ["next","previous"]:
    seq=[];quad=[]
    for i in range(6):
        f=base.copy();dr=ImageDraw.Draw(f)
        if i in [0,5]:quad.append(None)
        else:
            signed=math.cos(math.pi*i/5)*(1 if direction=="next" else -1)
            w=max(2,round(98*abs(signed)));x0,x1=(128,128+w) if signed>=0 else (128-w,128)
            # Page edge and receiving shadow stay below/right from upper-left illumination.
            dr.rectangle((x0+1,15,x1+1,137),fill="#bc9569")
            dr.rectangle((x0,13,x1,134),fill="#fff0ce",outline="#e5c89c",width=1)
            dr.line((128,13,128,134),fill="#bc9569")
            quad.append([[x0*4,52],[x1*4,52],[x1*4,536],[x0*4,536]])
        seq.append(f)
    anims["page_"+direction]=output(seq,"page_"+direction,[100]*6);quads[direction]=quad
M["book"].update({"open_close_page_turn":"complete_blank_page_art","animations":anims,"hinge":[512,36],"front_cover_hinge_layer":"book/front_cover_hinge_layer.png","page_content_quads":quads,"render_rule":"opening/closing canvas stays1024x640. Use closed_00 only for independent compact icon, not directly interpolated. Text and prices rendered separately. Perspective narrows width only during hinge rotation.","page_text_safe_rects":[[152,112,440,484],[584,112,872,484]]})
for state in ["closed","open"]:
    M["book"][state].update({"action":"idle","frame_order":[0],"duration_ms":[None],"duration_mode":"hold_until_state_change","loop":False})
# Quality proofs of direction, cadence and final-size readability.
frames=[]
for index in range(8):
    canvas=Image.new("RGB",(700,380),"#e7d9b5");dr=ImageDraw.Draw(canvas)
    dr.text((12,8),"追加動作：上1倍／下4倍。基準線は足元。",font=font,fill="#382519")
    for j,key in enumerate(["hen","cat"]):
        direction="right" if index<4 else "left";k=index%4
        im=Image.open(D/key/f"walk_{direction}_{k:02}.png").convert("RGBA");foot=29 if key=="hen" else 36
        x=100+j*300
        dr.line((x-15,82,x+170,82),fill="#986544")
        canvas.paste(im,(x,82-foot),im)
        z=im.resize((im.width*4,im.height*4),Image.Resampling.NEAREST)
        canvas.paste(z,(x,285-foot*4),z);dr.line((x-15,285,x+180,285),fill="#986544")
        dr.text((x,315),f"{key} {direction} {k}",font=font,fill="#382519")
    frames.append(canvas)
frames[0].save(D/"review/animals-walk.gif",save_all=True,append_images=frames[1:],duration=180,loop=0,disposal=2)
contact=Image.new("RGB",(1120,480),"#e7d9b5");dr=ImageDraw.Draw(contact)
for row,(key,act) in enumerate([("hen","peck"),("cat","stretch")]):
    for i in range(4):
        direction="right" if i<2 else "left";f=Image.open(D/key/f"{act}_{direction}_{i%2:02}.png").convert("RGBA")
        z=f.resize((f.width*4,f.height*4),Image.Resampling.NEAREST);contact.paste(z,(20+i*270,25+row*220),z)
        dr.text((20+i*270,185+row*220),f"{key} {act} {direction} {i%2}",font=font,fill="#382519")
contact.save(D/"review/animal-actions.png")
bookproof=Image.new("RGB",(1050,620),"#536e52");dr=ImageDraw.Draw(bookproof)
for i,f in enumerate(opening):
    z=f.resize((336,210),Image.Resampling.NEAREST);xy=(10+(i%3)*345,20+(i//3)*280)
    bookproof.paste(z,xy,z);dr.text((xy[0],xy[1]+216),f"open {i}: hinge fixed",font=font,fill="#fff0ce")
bookproof.save(D/"review/book-opening.png")
gif=[];dur=[]
for name in ["open","page_next","page_previous","close"]:
    for i,path in enumerate(anims[name]["files"]):
        frame=Image.new("RGB",(640,420),"#536e52");im=Image.open(D/path).convert("RGBA").resize((640,400),Image.Resampling.NEAREST);frame.paste(im,(0,0),im)
        ImageDraw.Draw(frame).text((12,397),name,font=font,fill="#fff0ce")
        gif.append(frame);dur.append(500 if i in [0,5] else 110)
gif[0].save(D/"review/book-sequence.gif",save_all=True,append_images=gif[1:],duration=dur,loop=0,disposal=2)
# File dimensions, bounding boxes and hashes provide reproducible import checks.
files=[]
for p in sorted(D.rglob("*.png")):
    if "review" in p.parts:continue
    im=Image.open(p);a=im.getchannel("A")
    files.append({"file":p.relative_to(D).as_posix(),"size":list(im.size),"visible_bbox":list(a.getbbox()),"sha256":hashlib.sha256(p.read_bytes()).hexdigest(),"alpha":"binary" if set(a.getdata())<={0,255} else "graded"})
M["files"]=files;M["review_only"]=[p.relative_to(D).as_posix() for p in sorted((D/"review").iterdir())]
(D/"manifest.json").write_text(json.dumps(M,ensure_ascii=False,indent=2),encoding="utf8")
print("Production PNGs:",len(files))

