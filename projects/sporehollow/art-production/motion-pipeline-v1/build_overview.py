from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import json,subprocess
ROOT=Path(__file__).resolve().parents[2];DEST=ROOT/'art_delivery/enemy_animal_direction_v3';ids=['destroyer','martial_artist','ninja','animal_tamer','runner','doberman','bullfrog','hedgehog']
font=lambda sz:ImageFont.truetype('C:/Windows/Fonts/meiryo.ttc',sz)
meta={cid:json.loads((ROOT/'art_delivery'/f'{cid}_motion_v1/manifest.json').read_text(encoding='utf-8')) for cid in ids}
labels={'destroyer':'デストロイマン','martial_artist':'武闘家','ninja':'忍者','animal_tamer':'ムッツゴロウ','runner':'ランナー','doberman':'ドーベルマン','bullfrog':'ウシガエル','hedgehog':'ハリネズミ'}
seq={}
for cid in ids:
 actions={'destroyer':['walk','iron_ball_windup','iron_ball_hit','hurt','retreat'],'martial_artist':['walk','bow','attack','kick','bow_end'],'ninja':['walk','shuriken','dagger','retreat'],'animal_tamer':['walk','tame','lead','tame_end'],'runner':['run','tired_enter','tired','tired_exit','attack'],'doberman':['walk','run','attack','hurt'],'bullfrog':['move','tongue_extend','tongue','tongue_retract','croak'],'hedgehog':['move','defense_enter','defense','defense_exit','hurt']}[cid]
 seq[cid]=[(a,i) for a in actions for i in range(len(meta[cid]['actions'][a+'_right']['frames']))]
farm=Image.open(ROOT/'art-production/enemy-animal-direction-v3/references/farm-day.png').convert('RGB');bg=farm.crop((270,224,750,320));frames=[]
for t in range(24):
 page=Image.new('RGB',(1920,1120),'#eee5ca');d=ImageDraw.Draw(page);d.text((16,10),'採用後の正式動作8セット / 1x と nearest 4x / オフライン合成・ゲーム内検証ではありません',font=font(21),fill='#39251a')
 for row,members in enumerate([ids[:5],ids[5:]]):
  b=bg.copy().convert('RGBA');ann=[];y=55+row*530
  if row==0:positions=[100,185,265,340,430];ref='characters_v1/keeper_idle_right_00.png';anchor=[16,44];x0=20
  else:positions=[120,265,400];ref='characters_v1/shiba_idle_right_00.png';anchor=[24,44];x0=35
  im=Image.open(ROOT/'art_delivery'/ref).convert('RGBA');b.alpha_composite(im,(x0-anchor[0],86-anchor[1]))
  for cid,x in zip(members,positions):
   a,i=seq[cid][t%len(seq[cid])];m=meta[cid];clip=m['actions'][a+'_right'];o=ROOT/'art_delivery'/f'{cid}_motion_v1';im=Image.open(o/clip['frames'][i]).convert('RGBA');an=m['foot_anchor_px']['right'];b.alpha_composite(im,(x-an[0],86-an[1]))
   if 'weapon_frames' in clip:
    rel=clip['weapon_frames'][i];r=next(r for r in m['assets'] if r['file']==rel);wi=Image.open(o/rel).convert('RGBA');an=r['foot_anchor_px'];b.alpha_composite(wi,(x-an[0],86-an[1]))
   ann.append(labels[cid]+' : '+a)
  d.text((16,y),' / '.join(ann),font=font(15),fill='#39251a');page.paste(b.convert('RGB'),(16,y+28));page.paste(b.convert('RGB').resize((1920,384),Image.Resampling.NEAREST),(0,y+132))
 frames.append(page)
frames[5].save(DEST/'preview/formal_motion_overview.png')
strip=Image.new('RGB',(1920,1120*len(frames)))
for i,im in enumerate(frames):strip.paste(im,(0,i*1120))
pal=strip.quantize(colors=256,dither=Image.Dither.NONE);gf=[im.quantize(palette=pal,dither=Image.Dither.NONE) for im in frames];gf[0].save(DEST/'preview/formal_motion_overview.gif',save_all=True,append_images=gf[1:],duration=140,loop=0,disposal=2,optimize=False)
commits={cid:subprocess.check_output(['git','log','-1','--format=%H','--',str(ROOT/'art_delivery'/f'{cid}_motion_v1')],text=True).strip() for cid in ids}
entries=[];rows=[]
for cid in ids:
 m=meta[cid];actions=list(dict.fromkeys(a['action_id'] for a in m['actions'].values()));entries.append({'id':cid,'path':'../'+cid+'_motion_v1/','commit':commits[cid],'runtime_png_count':len(m['assets']),'action_count':len(actions),'complete_actions':actions,'in_game_verified':False});rows.append(f"| {labels[cid]} | [{cid}_motion_v1](../{cid}_motion_v1/HANDOFF.md) | `{commits[cid]}` | {len(m['assets'])} |")
text='''# 採用後の正式動作・納品一覧

ブランチ: `codex/sporehollow-art-assets`。2026-10-06。
修正5体の採用と、サラリーマン確認後の「他もお願い」に基づく追加納品です。
残り8体、左右55動作セット（左右を同じ動作として数える）、本番RGBA PNG396枚。静止は採用元と完全同一です。

| 素材 | 納品フォルダ・説明 | 納品コミットSHA（最新補正含む） | PNG数 |
|---|---|---|---:|
'''+ '\n'.join(rows)+'''

サラリーマンは `../salaryman_motion_v1/`（ea06d76c9a6f6e5505dc013ad0ae9f5a9699d83f）、首輪・きのみは `../equipment_icons_v1/`（ef12e658aa7279900adf3d9deb3e0282b78c4aaf）を維持。

## 完成範囲と取り込み

各セットのmanifest.assetsだけが本番一覧。actionsがフレーム順・時間・ループ、sockets/partsが握り・口元と独立部品。正面・背面の専用動作やレベル差分は今回の横向き契約外です。

デストロイマン: 歩行・鉄球振りかぶり/接触・被弾・退散。武器レイヤーを別アンカーで重ねる。握り接続の補正コミット13674fbを含める。
武闘家: 礼の開始/終了・構え・突き・蹴り。忍者: 手裏剣と短剣を独立、煙なし、生存退散。
ムッツゴロウ: 実装ID animal_tamer、懐柔/先導時の動物は別レイヤー。
ランナー: 走行・息切れ・回復・攻撃。同行犬は別マス。
ドーベルマン: 歩行/走行・噛み付き・被弾・既存仕様の流血なし死亡。
ウシガエル: 移動・舌の伸び/保持/戻し・鳴き・被弾。背面巻き付き→対象→前面巻き付き。見本3マスは既存4マス射程の変更指示ではない。
ハリネズミ: 移動・棘を立てる/保持/解除・被弾。採用した迎撃シルエットを維持。

## 確認画像と限界

[8セット動作GIF](preview/formal_motion_overview.gif)、[比較画像](preview/formal_motion_overview.png)。個別セットのpreviewには全コマ・暗明背景・実寸比較・動作GIF。複数部品の例にはspecial_motion.gifも用意。
いずれも保存済み牧場背景へのオフライン合成であり、ゲームの動作検証ではありません。overviewは同期比較用の固定140ms、正式時間は各manifestに従う。

全396PNGのハッシュ・RGBA・二値透過・寸法・左右反転・必要ActionID・武器握り接続・GIF復号を検査済み。監査記録: `../../art-production/motion-pipeline-v1/audit-results.json`。

ゲームへの取り込み・描画順・座標・隔離描画検証は実装担当。ゲームコード・本番シーン・UID・能力ルールは未編集。ユーザーのゲームは起動していません。原画・プロンプト・加工履歴は各art-productionの*-motion-v1に保存。
'''
(DEST/'FORMAL_DELIVERIES.md').write_text(text,encoding='utf-8')
p=DEST/'manifest.json';m=json.loads(p.read_text(encoding='utf-8'));m['formal_deliveries']=[e for e in m.get('formal_deliveries',[]) if e.get('id') not in ids]+entries;m['formal_delivery_index']='FORMAL_DELIVERIES.md';m['unfinished']=['本フォルダの絵コンテは正式動作ではない。FORMAL_DELIVERIESの個別納品を使用','正面・背面の専用動作、レベル差分は今回の横向き契約外','ゲーム取り込みと隔離描画検証'];p.write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf-8')
p=DEST/'HANDOFF.md';s=p.read_text(encoding='utf-8');s=s.replace('他キャラクターの正式動作は引き続き未納品です。','残り8体の正式動作も先行納品済みです。完成範囲・フォルダ・コミットSHAは [FORMAL_DELIVERIES.md](FORMAL_DELIVERIES.md) を参照。');p.write_text(s,encoding='utf-8')
print(json.dumps(entries,ensure_ascii=False))
