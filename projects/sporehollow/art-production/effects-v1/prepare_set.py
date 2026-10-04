from pathlib import Path
from PIL import Image,ImageOps,ImageDraw,ImageFont
import numpy as np,json,hashlib
R=Path(__file__).resolve().parents[2];P=R/"art-production/effects-v1";D=R/"art_delivery/effects_v1"
D.mkdir(exist_ok=True);(D/"review").mkdir(exist_ok=True)
raw=Image.open(P/"originals/effects-kit.png").convert("RGBA")
specs=[
("soil_dust",(0,0),(20,18),["ad8b62","c6aa7e","e0c99c"],[16,26],"ground work/contact", [70,80,90,100]),
("wood_chips",(1,0),(22,18),["784321","a87945","cf9f67"],[16,26],"wood work/contact",[60,70,90,100]),
("stone_powder",(2,0),(20,18),["858675","b2b09a","d1ccb6"],[16,26],"stone work/contact",[70,80,90,100]),
("build_complete",(0,1),(14,14),["ad9557","d4b774","fff0ce"],[16,16],"completed construction, near active work point",[80,110,100,110]),
("attack_hit",(1,1),(16,16),["b18d56","e0c99c","fff0ce"],[16,16],"physical attack visual contact",[50,60,70,80]),
("hurt",(2,1),(14,14),["795038","ae7048","c89465"],[16,16],"received hit at contact point, not face",[60,70,80,90]),
("item_collect",(0,2),(12,12),["ad9557","d4b774","fff0ce"],[16,16],"collected item previous position",[70,90,90,90]),
("sound_wave",(1,2),(22,22),["ad956e","dfcba7","fff0ce"],[4,16],"mouth/whistle source; points right",[70,90,100,100]),
("lock_break",(2,2),(16,18),["6c5433","ad9557","d6ba77"],[16,16],"existing lock center",[70,80,90,110])]
assets=[];animations={};sequences={}
def palette(im,colors):
 rgb=[tuple(bytes.fromhex(c)) for c in colors];p=Image.new("P",(1,1));p.putpalette(sum([list(c) for c in rgb],[])+list(rgb[0])*(256-len(rgb)))
 a=im.getchannel("A").point(lambda z:255 if z>=128 else 0);f=im.convert("RGB").quantize(palette=p,dither=Image.Dither.NONE).convert("RGBA");f.putalpha(a);return f
def save(im,fn,anchor,name,index,ms,use):
 path=D/fn;path.parent.mkdir(exist_ok=True);im.save(path)
 assert im.size==(32,32) and set(np.array(im)[:,:,3].flat)<={0,255}
 assets.append(dict(file=fn,canvas_size_px=[32,32],anchor_px=anchor,action=name,frame_index=index,frame_duration_ms=ms,loop=False,visible_bbox_exclusive_px=list(im.getbbox()) if im.getbbox() else None,use=use,sha256=hashlib.sha256(path.read_bytes()).hexdigest()))
for name,(cx,cy),size,colors,anchor,use,duration in specs:
 f=raw.crop((cx*512,cy*341,(cx+1)*512,(cy+1)*341));a=f.getchannel("A").point(lambda z:255 if z>=180 else 0);b=a.getbbox();f=f.crop(b);f.putalpha(a.crop(b))
 scale=min(size[0]/f.width,size[1]/f.height);f=palette(f.resize((round(f.width*scale),round(f.height*scale)),Image.Resampling.BOX),colors)
 center=(16,19) if anchor==[16,26] else (16,16)
 if name=="sound_wave":origin=(5,16-f.height//2)
 else:origin=(center[0]-f.width//2,center[1]-f.height//2)
 base=Image.new("RGBA",(32,32));base.alpha_composite(f,origin);seq=[]
 for i in range(4):
  im=Image.new("RGBA",(32,32))
  if name=="sound_wave":
   a=np.array(base);solid=a[:,:,3]>0;seen=np.zeros((32,32),bool);parts=[]
   for yy,xx in zip(*np.where(solid)):
    if seen[yy,xx]:continue
    stack=[(yy,xx)];seen[yy,xx]=True;points=[]
    while stack:
     y,x=stack.pop();points.append((y,x))
     for dy in [-1,0,1]:
      for dx in [-1,0,1]:
       ny,nx=y+dy,x+dx
       if 0<=ny<32 and 0<=nx<32 and solid[ny,nx] and not seen[ny,nx]:seen[ny,nx]=True;stack.append((ny,nx))
    parts.append(points)
   parts.sort(key=lambda q:sum(x for y,x in q)/len(q));selection=parts[:1] if i==0 else parts[:2] if i==1 else parts if i==2 else parts[-1:]
   keep=np.zeros((32,32),bool)
   for part in selection:
    for y,x in part:keep[y,x]=True
   a[~keep]=0;im=Image.fromarray(a)
  elif i==0:
   small=f.resize((max(1,round(f.width*.55)),max(1,round(f.height*.55))),Image.Resampling.NEAREST);im.alpha_composite(small,(center[0]-small.width//2,center[1]-small.height//2))
  elif i==1:im=base.copy()
  else:
   # Dissolve into sparse moving pixel clusters; not a scaled copy of the source.
   for y in range(0,32,2):
    for x in range(0,32,2):
     tile=base.crop((x,y,x+2,y+2))
     if not tile.getbbox():continue
     if i==3 and (x//2+y//2)%3!=0:continue
     dx=-2 if x<center[0] else 2;dy=(-2 if y<center[1] else 1)
     if name in ["wood_chips","stone_powder","lock_break"]:dy+=i
     nx=x+dx*(i-1);ny=y+dy
     if 1<=nx<=29 and 1<=ny<=29:im.alpha_composite(tile,(nx,ny))
   if i==3:
    # Let remaining fragments thin out while keeping alpha binary.
    a=np.array(im);ys,xs=np.indices((32,32));a[(xs+ys)%2==1]=0;im=Image.fromarray(a)
  seq.append(im);save(im,f"{name}/{i:02}.png",anchor,name,i,duration[i],use)
 sequences[name]=seq;animations[name]=dict(frames=[f"{name}/{i:02}.png" for i in range(4)],frame_order=[0,1,2,3],frame_duration_ms=duration,loop=False,after="hide effect; do not hold final fragment frame",origin=use)
 if name=="sound_wave":
  left=[ImageOps.mirror(f) for f in seq];sequences["sound_wave_left"]=left
  for i,im in enumerate(left):save(im,f"sound_wave_left/{i:02}.png",[28,16],"sound_wave_left",i,duration[i],"mouth/whistle source; points left")
  animations["sound_wave_left"]=dict(animations["sound_wave"],frames=[f"sound_wave_left/{i:02}.png" for i in range(4)])
font=ImageFont.truetype(r"C:\Windows\Fonts\meiryo.ttc",14)
proof=Image.new("RGB",(1180,940),"#e7d9b5");d=ImageDraw.Draw(proof)
d.text((16,12),"小さな演出素材：各32×32・短い4コマ・終端で非表示（2×拡大／1×比較）",font=font,fill="#382519")
for j,(name,seq) in enumerate(sequences.items()):
 y=50+j*84;d.text((12,y+14),name,font=font,fill="#382519")
 for i,im in enumerate(seq):
  z=im.resize((64,64),Image.Resampling.NEAREST);proof.paste(z,(175+i*80,y),z)
 # Dark/light alpha view and actual-scale placement.
 for x,col in [(520,"#25352e"),(600,"#fff3dc")]:
  d.rectangle((x,y,x+70,y+70),fill=col);z=seq[1].resize((64,64),Image.Resampling.NEAREST);proof.paste(z,(x+3,y+3),z)
 for i,im in enumerate(seq):proof.paste(im,(730+i*90,y+20),im)
 d.text((1090,y+20),"1×",font=font,fill="#382519")
proof.save(D/"review/effect-frames.png")
# Actual-size actor+effect context on saved farm background; does not claim in-game execution.
bg=Image.open(R/"art-production/ranch-assets-v1/references/implementation-native-scale.png").convert("RGB").crop((200,70,1100,390))
keeper=Image.open(R/"art_delivery/characters_v1/keeper_idle_right_00.png").convert("RGBA");dog=Image.open(R/"art_delivery/characters_v1/shiba_idle_right_00.png").convert("RGBA")
gif=[]
for frame in range(4):
 im=bg.copy();dr=ImageDraw.Draw(im)
 for j,(name,seq) in enumerate(list(sequences.items())):
  x=40+(j%5)*175;y=110+(j//5)*150
  actor=dog if name=="sound_wave" else keeper;foot=(24,44) if actor==dog else (16,44)
  im.paste(actor,(x-foot[0],y-foot[1]),actor)
  # Effects at work point or mouth, offset so faces remain legible.
  f=seq[frame];anc=next(a["anchor_px"] for a in assets if a["action"]==name);origin=(x+22,y-20) if name=="sound_wave" else (x+22,y-6)
  im.paste(f,(origin[0]-anc[0],origin[1]-anc[1]),f)
  dr.text((x-20,y+13),name,font=font,fill="#fff0ce")
 gif.append(im)
gif[1].save(D/"review/farm-native.png")
gif[0].save(D/"review/effects.gif",save_all=True,append_images=gif[1:],duration=[100,100,100,100],loop=0)
m=dict(delivery="effects_v1",status="ready_for_implementation_integration",assets=assets,animations=animations,bindings=dict(whistle="sound_wave / sound_wave_left",bark="sound_wave / sound_wave_left"),shadow="none; no external ground shadow",placement="anchors are visual origins, not gameplay effect radii; keep behind work labels/items/UI",review_only=["review/effect-frames.png","review/farm-native.png","review/effects.gif"],unfinished=["runtime hookup to existing events and isolated rendering validation"],rules="No numbers, text, HP, selection range, new abilities or gameplay timing. All effects non-looping, auto-hide after last frame. Use native-size unless implementation agrees.")
(D/"manifest.json").write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding="utf8")
(D/"HANDOFF.md").write_text("""# 小さな演出素材
完成：土ぼこり、木くず、石粉、建築完了、攻撃命中、被弾、アイテム回収、音の波（左右）、ロック破損。ホイッスルと吠える音には同じ控えめな波を使う。各4コマ、計40PNG。

全32×32、通常RGBA、二値alpha、nearest。表示される図形は概ね12〜26pxに抑え、原画の発光・ぼかしを取り除いた。影なし。数字・文字・HPバー・選択範囲・別の動物を焼き込んでいない。

## 取り込み
土／木／石はアンカー(16,26)を作業・接触点の地面へ。その他は(16,16)を局所の接触点・建築完了点・回収前のアイテム位置・ロック中心へ。
音の波は右(4,16)、左(28,16)を口元／ホイッスル位置へ。画像を持つ方向は左右で逆なので、左用を右のアンカーで描かない。半径や効果範囲をこの画像の寸法から決めない。

すべてloop=false。最後のコマの表示時間が終わったら非表示とし、破片を画面へ残さない。時間はmanifest記載（約260〜400ms）。既存イベントの発生に接続し、イベント時刻・ダメージ・索敵・移動・回収ルールを変えない。顔・仕事札・落とし物・UIを覆う位置へ大きく拡大しない。

## 出典・検査
内蔵画像生成による原案を../../art-production/effects-v1/originals/に保存。等比縮小の後に限定色、輪郭・白い部分を保持する二値透過、発生・広がり・破片化・消散を整数ピクセルで整形。単に縮小した静止画を完成扱いにしていない。
PNG寸法・RGBA・alpha・ハッシュを検査。reviewは実寸で保存済み牧場背景へ合成し、明暗背景でも確認。GIFは一覧比較用の等間隔再生で、本番時間はmanifestを参照。ゲーム内確認済みの証拠ではない。
残る作業は実装担当による既存処理への接続と隔離描画検証。
""",encoding="utf8")
print("validated",len(assets),"FX PNGs")

