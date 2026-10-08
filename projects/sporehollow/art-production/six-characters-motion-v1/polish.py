# Native-stage corrections: preserve approved head pixels across locomotion cycles.
from pathlib import Path
from PIL import Image
import json
S=Path(__file__).parent;P=S.parents[1];N=S/'native';R=P/'art_delivery/two_direction_review_v1/native'
log=[]
for who,key,band in [('merchant','merchant_walk',17),('maid','maid_locomotion',28),('dancer','dancer_motion',29),('thief','thief_motion',31)]:
 head=Image.open(R/who/'idle_right.png').convert('RGBA')
 if who=='merchant':
  pad=Image.new('RGBA',(48,48));pad.alpha_composite(head,(8,0));head=pad
 for i in range(4):
  f=N/f'{key}_{i:02}.png';im=Image.open(f).convert('RGBA');im.paste(head.crop((0,0,head.width,band)),(0,0));im.save(f)
 log.append({'target':who,'source':str((R/who/'idle_right.png').relative_to(P)),'frames':list(range(4)),'replace_top_band_px':band,'reason':'Preserve adopted face/head silhouette, no new facial redesign during locomotion.'})
# Extra horizontal transparent margin for bull lunges/fall. Body pixels unchanged.
for f in N.glob('bull_motion_*.png'):
 im=Image.open(f).convert('RGBA')
 if im.size==(80,64):
  out=Image.new('RGBA',(96,64));out.alpha_composite(im,(8,0));out.save(f)
log.append({'target':'bull','canvas':[96,64],'anchor':[48,58],'pad_left_right_px':8,'reason':'Preserve full horns/hooves/tail at the largest attack and fall extent without shrinking.'})
(S/'native-corrections.json').write_text(json.dumps(log,ensure_ascii=False,indent=2),encoding='utf-8')
print('Head-lock corrections and transparent bull padding applied.')
