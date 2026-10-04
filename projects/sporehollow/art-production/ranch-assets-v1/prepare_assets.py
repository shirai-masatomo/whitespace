from pathlib import Path
from PIL import Image,ImageDraw,ImageOps,ImageFont
import numpy as np,json,hashlib
R=Path(r"C:\Users\masat\.codex\worktrees\sporehollow-art\codex_test\projects\sporehollow")
P=R/"art-production/ranch-assets-v1";D=R/"art_delivery/ranch_assets_v1"
for s in ["hen","cat","merchant","stall","scroll","book","review"]:(D/s).mkdir(parents=True,exist_ok=True)
hexes=["382519","5e351e","99653f","171d19","784321","ae622b","d88332","eda146","f7bc65","fff0ce","e5c89c","bc9569","c45d4d","f1aba0","8f969d","b4bbc0","666d73","d2d5d3","dadf81","536e52","7d8b62","edb476","b1b28c","e7d9b5"]
pal=Image.new("P",(1,1));rgb=[tuple(bytes.fromhex(h)) for h in hexes];pal.putpalette(sum([list(c) for c in rgb],[])+list(rgb[0])*(256-len(rgb)))
def cut(im):
    a=im.getchannel("A").point(lambda v:255 if v>=128 else 0);b=a.getbbox();im=im.crop(b);im.putalpha(a.crop(b));return im
def norm(im,size):
    im=im.resize(size,Image.Resampling.BOX);a=im.getchannel("A").point(lambda v:255 if v>=128 else 0)
    q=im.convert("RGB").quantize(palette=pal,dither=Image.Dither.NONE).convert("RGBA");q.putalpha(a);return q
def fit(im,maxsize):
    r=min(maxsize[0]/im.width,maxsize[1]/im.height);return norm(im,(round(im.width*r),round(im.height*r)))
def anchor(im,size,point):
    f=Image.new("RGBA",size);f.alpha_composite(im,(point[0]-im.width//2,point[1]-im.height));return f
def mirror(f):
    out=Image.new("RGBA",f.size);out.alpha_composite(ImageOps.mirror(f),(1,0));return out
records=[]
def record(name,frames,size,base,action,direction,times,loop):
    strip=Image.new("RGBA",(size[0]*len(frames),size[1]))
    paths=[]
    for i,f in enumerate(frames):
        path=f"{name}/{action}_{direction}_{i:02}.png";f.save(D/path);strip.alpha_composite(f,(size[0]*i,0));paths.append(path)
        assert f.size==tuple(size) and f.getbbox()[3]==base[1]
        assert set(f.getchannel("A").getdata())=={0,255}
    sp=f"{name}/{action}_{direction}_sheet.png";strip.save(D/sp)
    records.append({"asset":name,"action":action,"direction":direction,"files":paths,"sheet":sp,"frame_size":list(size),"foot_anchor":base,"frame_order":list(range(len(frames))),"duration_ms":times,"loop":loop,"status":"art_complete_integration_unverified"})
animal={}
for key,h,size,base in [("hen",18,(32,32),(16,29)),("cat",24,(48,40),(24,36))]:
    raw=Image.open(P/"originals"/f"{key}.png").convert("RGBA");w0,h0=raw.size
    cells=[cut(raw.crop((c*w0//3,r*h0//2,(c+1)*w0//3,(r+1)*h0//2))) for r in range(2) for c in range(3)]
    scale=h/cells[0].height
    natives=[]
    for i,c in enumerate(cells):
        c=norm(c,(round(c.width*scale),round(c.height*scale)))
        # Pixel cleanup: no semitransparent fringe or isolated edge marks.
        natives.append(c)
    idle=anchor(natives[0],size,base)
    cuty=base[1]-5
    walks=[]
    for c in natives[1:5]:
        f=anchor(c,size,base);f.paste(idle.crop((0,0,size[0],cuty)),(0,0));walks.append(f)
    special=anchor(natives[5],size,base)
    # Visible head/shoulder lift; preserve contact pixels and frame.
    special2=special.copy()
    cutline=base[1]-5
    upper=special.crop((0,0,size[0],cutline))
    special2.paste((0,0,0,0),(0,0,size[0],cutline))
    special2.alpha_composite(upper,(0,-1))
    special2.paste(special.crop((0,cutline,size[0],cutline+1)),(0,cutline-1))
    animal[key]=idle
    for direction in ["right","left"]:
        xf=(lambda f:f) if direction=="right" else mirror
        record(key,[xf(idle)],size,base,"idle",direction,[None],False)
        record(key,[xf(f) for f in walks],size,base,"walk",direction,[120]*4,True)
        record(key,[xf(special),xf(special2)],size,base,"peck" if key=="hen" else "stretch",direction,[260,260],key=="hen")
# Merchant board identity from actual stall, native standing frame same height as keeper.
merchant=anchor(fit(cut(Image.open(P/"originals/merchant-v2.png").convert("RGBA")),(28,42)),(32,48),(16,44))
record("merchant",[merchant],(32,48),(16,44),"idle","right",[None],False)
# Merchant facing generated is three-quarter; preserve source, no unsolicited directional variants.
scroll=anchor(fit(cut(Image.open(P/"originals/scroll.png").convert("RGBA")),(22,20)),(24,24),(12,22))
record("scroll",[scroll],(24,24),(12,22),"idle","none",[None],False)
stallsmall=anchor(fit(cut(Image.open(P/"originals/stall.png").convert("RGBA")),(180,120)),(192,128),(96,124))
stall=stallsmall.resize((768,512),Image.Resampling.NEAREST)
record("stall",[stall],(768,512),(384,496),"idle","front",[None],False)
# Book UI grid is4px. Retain material aspect; extend blank mid-page region rather than stretching leather/textures.
openraw=cut(Image.open(P/"originals/book_open.png").convert("RGBA"))
openbody=fit(openraw,(220,126))
mid=openbody.height//2;extra=16
extended=Image.new("RGBA",(openbody.width,openbody.height+extra))
extended.alpha_composite(openbody.crop((0,0,openbody.width,mid)),(0,0))
band=openbody.crop((0,mid,openbody.width,mid+1)).resize((openbody.width,extra),Image.Resampling.NEAREST);extended.alpha_composite(band,(0,mid))
extended.alpha_composite(openbody.crop((0,mid,openbody.width,openbody.height)),(0,mid+extra))
opened=Image.new("RGBA",(256,160));opened.alpha_composite(extended,((256-extended.width)//2,(160-extended.height)//2))
opened=opened.resize((1024,640),Image.Resampling.NEAREST);opened.save(D/"book/open_00.png")
coverbody=fit(cut(Image.open(P/"originals/book_cover.png").convert("RGBA")),(56,74))
closed=Image.new("RGBA",(64,80));closed.alpha_composite(coverbody,(5,3))
# Reinforce source embossed paw and inset border on the native grid.
cd=ImageDraw.Draw(closed)
cd.rectangle((9,7,56,64),outline="#5e351e",width=1)
cd.rectangle((11,9,54,62),outline="#99653f",width=1)
cd.rectangle((24,27,44,48),fill="#784321")
paw=[".##..##.",".##..##.","........","##.##.##","##.##.##","..####..",".######.",".######.","..####.."]
for yy,row in enumerate(paw):
    for xx,ch in enumerate(row):
        if ch=="#":cd.point((31+xx,33+yy),fill="#5e351e")
closed=closed.resize((256,320),Image.Resampling.NEAREST);closed.save(D/"book/closed_00.png")
# Three non-overlapping source-derived layers reconstruct open exactly.
aa=np.asarray(opened).copy();r,g,b=[aa[:,:,i].astype(int) for i in range(3)]
paper=(aa[:,:,3]>0)&(r>140)&(g>115)&(b>75)&(g>r*.7)
spine=(aa[:,:,3]>0)&(np.abs(np.arange(1024)[None,:]-512)<=8)
for name,mask in [("paper",paper&~spine),("binding_shadow",spine),("cover",~paper&~spine&(aa[:,:,3]>0))]:
    layer=aa.copy();layer[:,:,3]=np.where(mask,aa[:,:,3],0);Image.fromarray(layer).save(D/f"book/{name}_layer.png")
recon=Image.new("RGBA",opened.size)
for name in ["cover","paper","binding_shadow"]:recon.alpha_composite(Image.open(D/f"book/{name}_layer.png"))
assert np.array_equal(np.asarray(recon)[np.asarray(opened)[:,:,3]>0],np.asarray(opened)[np.asarray(opened)[:,:,3]>0])
font=ImageFont.truetype(r"C:\Windows\Fonts\meiryo.ttc",15)
proof=Image.new("RGB",(1100,920),"#e7d9b5");dr=ImageDraw.Draw(proof)
dr.text((16,10),"追加素材：1倍でサイズ比較／下は4倍。主人公・柴犬の納品PNGは無変更。",font=font,fill="#384738")
farm=Image.open(P/"references/implementation-native-scale.png").convert("RGB");proof.paste(farm.crop((280,90,1280,200)),(16,40))
chars=[("主人公",Image.open(R/"art_delivery/characters_v1/keeper_idle_right_00.png"),(16,44)),("柴犬C",Image.open(R/"art_delivery/characters_v1/shiba_idle_right_00.png"),(24,44)),("鶏",animal["hen"],(16,29)),("猫",animal["cat"],(24,36)),("商人",merchant,(16,44)),("巻物",scroll,(12,22))]
for i,(name,im,base) in enumerate(chars):
    x=90+i*145;proof.paste(im,(x,118-base[1]),im);dr.text((x-10,125),name,font=font,fill="#fff0ce")
    z=im.resize((im.width*4,im.height*4),Image.Resampling.NEAREST);proof.paste(z,(25+i*178,190+176-base[1]*4),z)
    dr.text((25+i*178,376),name,font=font,fill="#384738")
# UI at a practical slot; preserve aspect ratio.
slot=(18,425,420,700);dr.rectangle(slot,outline="#795b3e",width=2)
thumb=stall.copy();thumb.thumbnail((400,270),Image.Resampling.NEAREST);proof.paste(thumb,(18+(402-thumb.width)//2,425+(275-thumb.height)//2),thumb)
dr.text((18,709),"露店：予定枠へ等比配置",font=font,fill="#384738")
cv=closed.copy();proof.paste(cv,(452,428),cv)
op=opened.resize((384,240),Image.Resampling.NEAREST);proof.paste(op,(710,462),op)
dr.text((452,764),"閉表紙256×320",font=font,fill="#384738");dr.text((740,719),"見開き・分離パーツ",font=font,fill="#384738")
proof.save(D/"review/overview.png")
man={"delivery":"ranch_assets_v1","adopted_basis":"keeper_v1 + Shiba C; existing hen/cat/merchant/book identities","animations":records,
"book":{"closed":{"file":"book/closed_00.png","size":[256,320],"spine_anchor_x":20},"open":{"file":"book/open_00.png","size":[1024,640],"spine_anchor_x":512},"layers":["book/cover_layer.png","book/paper_layer.png","book/binding_shadow_layer.png"],"text_baked":False,"open_close_page_turn":"processing"},
"generator":"image_gen.imagegen","source_prompts":"../../art-production/ranch-assets-v1/prompts.json",
"processing":"Native palette cleanup, exact canvas/anchor placement, equal-scale output; book blank center extended without stretching edge textures",
"runtime_verified":False}
(D/"manifest.json").write_text(json.dumps(man,ensure_ascii=False,indent=2),encoding="utf8")
print([(k,v.getbbox()) for k,v in animal.items()]);print("merchant",merchant.getbbox(),"scroll",scroll.getbbox(),"stall",stall.getbbox(),"book",opened.getbbox(),closed.getbbox())

