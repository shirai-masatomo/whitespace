from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageOps
import json,hashlib,shutil,numpy as np
S=Path(__file__).parent;P=S.parents[1];D=P/'art_delivery/two_direction_review_v1';Q=D/'qa';Q.mkdir(exist_ok=True)
m=json.loads((D/'manifest.json').read_text(encoding='utf-8'))
def sha(f):return hashlib.sha256(f.read_bytes()).hexdigest()
def font(n):return ImageFont.truetype('C:/Windows/Fonts/meiryo.ttc',n)
def txt(im,xy,s,n=16,c='#e9deca'):ImageDraw.Draw(im).text(xy,s,font=font(n),fill=c)
main=Path(r'C:\Users\masat\Documents\codex_test\projects\sporehollow')
ref=main/'review/current/revision-f6a60ee/01_residents_forest_placeables.png'
shutil.copy2(ref,S/'references/current-farm.png')
# Source screenshot grass only, to avoid an apparent in-game integration claim.
ground=Image.open(ref).convert('RGBA').crop((80,65,1200,225))
out=Image.new('RGBA',(1120,570),'#252d29')
txt(out,(18,12),'原寸比較 — 保存済みゲーム画面の草地へオフライン合成',24)
txt(out,(18,48),'実装 f6a60ee の背景部分を使用。今回の画像をゲームへ取り込んだ実行画面ではありません。',15)
items=[('主人公','characters_v1/keeper_idle_right_00.png',[16,44]),('柴犬C','characters_v1/shiba_idle_right_00.png',[24,44]),('鶏','ranch_assets_v1/hen/idle_right_00.png',[16,29]),('猫','ranch_assets_v1/cat/idle_right_00.png',[24,36])]
items+=[(n,'two_direction_review_v1/native/'+w+'/idle_right.png',an) for w,n,an in [('merchant','商人',[16,44]),('maid','メイド',[32,58]),('dancer','舞姫',[32,58]),('thief','盗賊',[32,58]),('cow','乳牛',[40,58]),('bull','闘牛',[40,58])]]
items.append(('荷車','two_direction_review_v1/native/merchant/cart_move_right.png',[64,88]))
for row in range(2):
 strip=ground.copy()
 for i,(name,file,an) in enumerate(items):
  im=Image.open(P/'art_delivery'/file).convert('RGBA')
  if row and i>=4:im=ImageOps.mirror(im)
  x=45+i*95
  strip.alpha_composite(im,(x-an[0],125-an[1]));txt(strip,(x-30,136),name,12,'#f7eed8')
 out.alpha_composite(strip,(0,100+row*205));txt(out,(18,78+row*205),['右向き 原寸','左向き 原寸（主人公・柴犬・鶏・猫はサイズ参照用の右向きを維持）'][row],14)
txt(out,(18,528),'影は追加していません。主人公v1・柴犬C・鶏・猫の元PNGは無改変。',16)
out.save(Q/'native_ground.png')
# Binary alpha checks and mirrored-pair/foot checks.
errors=[];checked=0
for a in m['review_assets']:
 f=D/a['file'];im=Image.open(f);ar=np.array(im)
 if im.mode!='RGBA' or list(im.size)!=a['canvas']:errors.append('mode/size:'+a['asset_id'])
 if not set(np.unique(ar[:,:,3])).issubset({0,255}):errors.append('body alpha:'+a['asset_id'])
 if sha(f)!=a['sha256'] or sha(D/a['pose_file'])!=a['pose_sha256']:errors.append('hash:'+a['asset_id'])
 if a['direction'] not in ['left','right'] or a['runtime_ready']:errors.append('direction/status:'+a['asset_id'])
 if im.getbbox()[3]!=a['anchor'][1]:errors.append('baseline:'+a['asset_id'])
 if a['method']=='exact_existing_png' and sha(P/a['source'])!=sha(f):errors.append('adopted PNG differs:'+a['asset_id'])
 if a['method']=='horizontal_mirror_of_right':
  right=Image.open(D/a['source']);expected=ImageOps.mirror(right)
  if np.any(np.array(expected)!=ar):errors.append('mirror:'+a['asset_id'])
 checked+=1
for a in m['sheets']:
 if sha(D/a['file'])!=a['sha256']:errors.append('sheet hash:'+a['target'])
prior=json.loads((S/'existing-png-hashes.json').read_text())
for f,h in prior.items():
 if sha(P/f)!=h:errors.append('existing asset changed:'+f)
# Light/dark strips with visible anchors; review-only.
aa=m['review_assets'];cols=6;cw=180;ch=160
out=Image.new('RGBA',(cols*cw,70+((len(aa)+cols-1)//cols)*ch),'#252d29');txt(out,(18,12),'透過検査：白い毛・服・髪・扇を保持 / 明色・暗色',22)
for j,a in enumerate(aa):
 x=j%cols*cw;y=70+j//cols*ch;txt(out,(x+2,y),a['asset_id'],10)
 for k,bg in enumerate(['#eadebc','#101c18']):
  tile=Image.new('RGBA',(cw//2-2,130),bg);im=Image.open(D/a['file']).convert('RGBA')
  if im.width>84:im=im.resize((round(im.width*.6),round(im.height*.6)),Image.Resampling.NEAREST)
  tile.alpha_composite(im,((tile.width-im.width)//2,90-im.height));out.alpha_composite(tile,(x+k*cw//2,y+20))
out.save(Q/'alpha.png')
qa={'date':'2026-10-08','direction_sheets':6,'representative_poses':checked,'prior_pngs_unchanged':len(prior),'errors':errors,'checks':['All bodies RGBA alpha0/255','Exact adopted right PNGs unchanged','Mirrored left PNGs same size and baseline','Foot bottom equals anchor y','All direction values right or left','All PNG hashes match','Source screenshot grass comparison and native/light/dark visual inspection'],'not_claimed':['Motion completeness','In-game integration','Runtime render verification','User adoption of these sheets']}
(D/'QA.json').write_text(json.dumps(qa,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
m['qa_previews']=[{'file':f.relative_to(D).as_posix(),'sha256':sha(f),'runtime_ready':False} for f in sorted(Q.glob('*.png'))]
m['reference_specs']={f.name:sha(f) for f in (S/'references').glob('*.md')}
(D/'manifest.json').write_text(json.dumps(m,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
assert not errors,errors
print('PASS',checked,'poses /6 sheets /',len(prior),'existing PNGs unchanged')
