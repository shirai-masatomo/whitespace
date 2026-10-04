from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageOps
import numpy as np,json,hashlib
R=Path(__file__).resolve().parents[2];B=R/"art_delivery/kidnapper_basic_v1";D=R/"art_delivery/kidnapper_reactions_v1";D.mkdir(exist_ok=True);(D/"review").mkdir(exist_ok=True)
idle=Image.open(B/"idle/right_00.png").convert("RGBA")
head=idle.copy();a=np.array(head);a[19:]=0;a[15:19,:13]=0;head=Image.fromarray(a)
def reflect(im):
 out=Image.new("RGBA",(32,48));out.alpha_composite(ImageOps.mirror(im),(1,0));return out
def compose(body,face,headshift=(0,0)):
 a=np.array(body);a[:19]=0;out=Image.fromarray(a);out.alpha_composite(face,headshift);return out
def lean(body,amount):
 # Keep the feet fixed; displace only upper rows in integer pixel steps.
 im=Image.new("RGBA",(32,48))
 for y in range(19,44):
  dx=round(amount*(1-(y-19)/24));im.alpha_composite(body.crop((0,y,32,y+1)),(dx,y))
 return im
frames={}
back=reflect(head)
frames["search"]=[compose(idle,head),compose(idle,back),compose(idle,head)]
guard=Image.open(B/"attack/right_02.png").convert("RGBA")
frames["discovery"]=[compose(guard,head,(0,-1)),compose(guard,head)]
frames["discovery"][0].putpixel((18,18),(80,61,80,255))
frames["hit"]=[compose(lean(idle,-2),head,(-2,0)),compose(lean(idle,-1),head,(-1,0))]
guard=Image.open(B/"attack/right_02.png").convert("RGBA")
frames["retreat"]=[]
for i in range(4):
 walk=Image.open(B/f"walk/right_{i:02}.png").convert("RGBA")
 body=walk.copy();body.paste((0,0,0,0),(0,19,32,31));body.alpha_composite(guard.crop((0,19,32,31)),(0,19))
 frames["retreat"].append(compose(body,back))
durations=dict(search=[300,450,250],discovery=[120,180],hit=[100,140],retreat=[90]*4)
assets=[];animations={};allims={}
for action,seq in frames.items():
 for direction in ["right","left"]:
  names=[]
  for i,f in enumerate(seq):
   im=f if direction=="right" else reflect(f);fn=f"{action}/{direction}_{i:02}.png";p=D/fn;p.parent.mkdir(exist_ok=True);im.save(p)
   assert im.size==(32,48) and im.getbbox()[3]==44 and set(np.array(im)[:,:,3].flat)<={0,255}
   assets.append(dict(file=fn,canvas_size_px=[32,48],foot_anchor_px=[16,44],action=action,direction=direction,frame_index=i,frame_duration_ms=durations[action][i],loop=action=="retreat",sha256=hashlib.sha256(p.read_bytes()).hexdigest()))
   names.append(fn);allims[fn]=im
  animations[f"{action}_{direction}"]=dict(frames=names,frame_order=list(range(len(seq))),frame_duration_ms=durations[action],loop=action=="retreat",after="return to existing state" if action!="retreat" else "hide/despawn according to existing retreat processing")
font=ImageFont.truetype(r"C:\Windows\Fonts\meiryo.ttc",16);proof=Image.new("RGB",(980,940),"#e7d9b5");d=ImageDraw.Draw(proof)
d.text((18,10),"誘拐者の補助動作：採用顔の再利用・固定足元（素材比較）",font=font,fill="#382519")
labels=dict(search="探索：左右を警戒",discovery="発見：小さく身構える",hit="被弾：後方へひるむ",retreat="退散：振り返りながら移動")
for j,(action,seq) in enumerate(frames.items()):
 y=55+j*215;d.text((18,y),labels[action],font=font,fill="#382519")
 for i,im in enumerate(seq):
  z=im.resize((128,192),Image.Resampling.NEAREST);proof.paste(z,(270+i*168,y-15),z)
 d.text((20,y+80),str(durations[action])+" ms",font=font,fill="#382519")
proof.save(D/"review/reactions.png")
bg=Image.open(R/"art-production/ranch-assets-v1/references/implementation-native-scale.png").convert("RGB").crop((350,70,1050,230))
gif=[];timings=[]
for t in range(12):
 im=bg.copy();d=ImageDraw.Draw(im)
 for j,(action,seq) in enumerate(frames.items()):
  f=seq[t%len(seq)];im.paste(f,(65+j*165,70),f);d.text((15+j*165,12),action,font=font,fill="#fff0ce")
 gif.append(im.resize((1050,240),Image.Resampling.NEAREST));timings.append(150)
gif[0].save(D/"review/reactions.gif",save_all=True,append_images=gif[1:],duration=timings,loop=0)
m=dict(delivery="kidnapper_reactions_v1",status="ready_for_implementation_integration",assets=assets,animations=animations,source="../kidnapper_basic_v1",face="same adopted v2 head pixel data, translations and horizontal reflection only",shadow="no ground shadow",review_only=["review/reactions.png","review/reactions.gif"],rules="Existing kidnapper only. HP0 retreat, no corpse/death. No damage/speed/detection changes. Discovery contains no baked punctuation or UI.",unfinished=["runtime integration and isolated rendering validation"])
(D/"manifest.json").write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding="utf8")
(D/"HANDOFF.md").write_text("""# 誘拐者：補助動作
採用v2／kidnapper_basic_v1の同じ頭・服・手足を使った補助動作。生成顔を追加していない。

完成：左右の探索3コマ、発見2コマ、被弾2コマ、退散4コマ、計22PNG。全32×48、足元(16,44)、二値alpha、通常RGBA・nearest。透明余白を維持。動作名・順序・時間・loop・SHA256はmanifest.json。

探索は頭を左右へ向ける。発見は小さく身構える。被弾は足元を保って上体を引く。退散は振り返りながら手を守りへ寄せる。静止・歩行・攻撃・壁ドア攻撃・運搬はkidnapper_basic_v1を併用。
退散だけループ。その他は一度再生後、既存状態へ戻す。HP0で死亡・死体表示にしない。退散PNGを描くだけで逃走や消去のゲーム処理が実装されたとは扱わない。

体の整数ピクセル変形と採用頭の平行移動・反転で調整。被弾画像の横移動は小さな身振りで、実際のノックバック判定・移動速度・索敵半径を規定しない。顔の変形、文字、HP、強い点滅はなし。地面影は焼き込んでいない。

reviewは保存済み実背景への合成比較。GIFは動き一覧のため150ms等間隔で並べた確認用であり、本番再生時間はmanifestを使う。ゲーム内検証ではない。残る作業は実装担当による取り込みと隔離描画検証。
出典と加工手順は../../art-production/kidnapper-v1/prepare_reactions.py、元の生成原画とプロンプトは同フォルダ。
""",encoding="utf8")
print("validated",len(assets),"reaction frames")


