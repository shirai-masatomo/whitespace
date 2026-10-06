from pathlib import Path
from PIL import Image
import hashlib,json
SRC=Path(__file__).resolve().parent;ROOT=SRC.parents[1];OUT=ROOT/'art_delivery/enemy_animal_direction_v3'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
data=json.loads((OUT/'pose-data.json').read_text(encoding='utf-8'));chars=data['characters'];poses=data['poses']
labels={
'salaryman':['idle','phone_take_pocket','phone_take_draw','phone_take_check','phone_call','phone_put_end','phone_put_pocket'],
'destroyer':['idle_wrapped_chain','draw_back','overhead','slam','extend_chain','recover'],
'martial_artist':['face_target','stand_straight','bow','guard','punch','kick','depart'],
'ninja':['idle_relaxed','throw_draw','throw_release','throw_follow','recoil_alive','retreat'],
'tamer':['idle','notice','crouch','offer_hand','offer_treat','lead_away'],
'runner':['ready','run_extended','run_gathered','form_break','pant','recover'],
'doberman':['stand','run_extended','run_gathered','attack_guard'],
'bullfrog':['idle','mouth_open','brace_pull','hit_recoil','vocal_sac','croak'],
'hedgehog':['idle','flinch','compress','spines_up','defense_ball','relax']}
palettes={'salaryman':'青灰・生成りの曇り眼鏡・くすんだ赤','destroyer':'灰桃の肌・黒茶の革・真鍮・鋼','martial_artist':'墨色・生成り・白髪・黄土の帯','ninja':'藍・スレート・灰色。顔を完全に覆う','tamer':'白灰の髪・暗い青緑・黄土','runner':'灰の髪と上着・青緑・濃灰・白灰の靴','doberman':'黒・焦茶・青灰のハイライト','bullfrog':'灰白・生成り・灰褐色の皺','hedgehog':'焦茶・生成りの鋭い棘'}
accepted={'martial_artist','tamer','doberman','bullfrog'};posemap={}
for p in poses:
 n=p['character'];i=p['key_pose'];p['action']=labels[n][i];p['direction']='right';p['runtime_ready']=False
 p['design_status']='accepted_v2_preserved' if n in accepted or (n=='hedgehog' and i in [0,1,2,5]) else 'accepted_v3'
 p['foot_baseline_y']=p['anchor'][1];p['contains_cast_shadow']=False
 if n=='destroyer' and i==3:p['contact_note']='Boot soles y64; low fist extends to y66. Lowest opaque pixel is not the floor.'
 posemap[p['file']]=p
part_use={
'iron_ball':([5,0],'鎖リング上端。鉄球を本体から分離'),'chain_source':([7,7],'原画由来の鎖形状参考'),
'chain_link':([0,1],'鎖の連結案。正式な回転と接続は未確定'),'shuriken':([3,3],'独立した飛翔物'),
'dagger':([1,2],'握り位置。手裏剣と別形状'),'phone':([0,0],'端末寸法案。本体にも保持中端末を描画済み。二重に重ねない'),
'tongue_body':([0,1],'口元側。8×3を水平伸縮。端面の枠なし'),'tongue_tip':([2,2],'付着点中心'),
'tongue_wrap_back':([9,5],'対象より背面の巻き付き'),'tongue_wrap_front':([9,5],'対象より前面の巻き付き')}
assets=[];native_count=0
for path in sorted(OUT.rglob('*.png')):
 rel=path.relative_to(OUT).as_posix();im=Image.open(path)
 a={'file':rel,'canvas_size_px':list(im.size),'mode':im.mode,'sha256':sha(path),'status':'direction_review_only','runtime_ready':False,'frame_duration_ms':None,'loop':False}
 if rel in posemap:a.update(posemap[rel]);native_count+=1
 elif rel.startswith('pose_drafts/'):a.update({'character':'doberman','action':'stand','direction':'left','anchor':[32,44],'body_bbox':list(im.getbbox()),'design_status':'accepted_v2_preserved'});native_count+=1
 elif rel.startswith('concept_parts/'):
  an,use=part_use[path.stem];a.update({'anchor':an,'use':use});native_count+=1
 elif rel.startswith('equipment/'):a.update({'anchor':[16,16],'use':'UIアイコン案。装着表示ではない','design_status':'accepted_v2_preserved'});native_count+=1
 else:a.update({'use':'確認用合成。実装へ取り込まない','native_scale':1,'zoom_scale':4,'scale_filter':'nearest','anchor':None})
 if im.mode=='RGBA':
  vals=set(im.getchannel('A').getdata());assert vals<={0,255},(rel,vals)
  a['alpha_values']=sorted(vals);a['opaque_palette_count']=len({pix[:3] for pix in im.getdata() if pix[3]})
 assets.append(a)
refs=json.loads((SRC/'references/reference-hashes.json').read_text(encoding='utf-8-sig'))
for r in refs:assert sha(ROOT/'art_delivery'/r['file'])==r['sha256'],r['file']
for rel in ['ranch_assets_v1/cat/idle_left_00.png','ranch_assets_v1/scroll/idle_none_00.png','earth_stone_buildings_v1/soil/wall/normal/mask_10.png','earth_stone_buildings_v1/soil/wall/damaged/mask_10.png','effects_v1/sound_wave/02.png']:
 refs.append({'file':rel,'sha256':sha(ROOT/'art_delivery'/rel)})
frozen=[]
for p in (SRC/'references/frozen-v2').rglob('*.png'):
 rel=p.relative_to(SRC/'references/frozen-v2')
 if rel.parts[0]=='hedgehog' and rel.name in ['key_03.png','key_04.png']:continue
 q=OUT/'pose_drafts'/rel;assert sha(p)==sha(q),(str(rel),'accepted PNG changed')
 frozen.append({'file':q.relative_to(OUT).as_posix(),'sha256':sha(q)})
for n in ['collar','healing_berry']:
 old=ROOT/'art_delivery/enemy_animal_direction_v2/equipment'/f'{n}.png'
 if not old.exists():old=ROOT/'art-production/enemy-animal-direction-v2/review-before-last-feedback/equipment'/f'{n}.png'
 q=OUT/'equipment'/f'{n}.png';assert sha(old)==sha(q),n
 frozen.append({'file':q.relative_to(OUT).as_posix(),'sha256':sha(q)})
actions={'phone_take':('salaryman',[1,2,3]),'phone_call':('salaryman',[4]),'phone_put':('salaryman',[5,6]),'destroyer_swing':('destroyer',[0,1,2,3,4,5]),'bow_start':('martial_artist',[0,1,2,3]),'bow_end':('martial_artist',[3,0,2,6]),'ninja_throw':('ninja',[0,1,2,3]),'tamer_lure':('tamer',[1,2,3,4,4,5]),'runner_fatigue':('runner',[1,2,3,4,5,1]),'bullfrog_tongue':('bullfrog',[0,1,1,2,2,0]),'bullfrog_alarm':('bullfrog',[3,4,5,0]),'hedgehog_defense':('hedgehog',[0,1,2,3,4,5])}
actions={k:{'character':n,'keys':idx,'frame_duration_ms':None,'loop':False,'status':'storyboard_order_only_not_animation'} for k,(n,idx) in actions.items()}
manifest={'schema_version':1,'delivery':'enemy_animal_direction_v3','date':'2026-10-06','branch':'codex/sporehollow-art-assets','status':'design_adopted_motion_production_authorized','base_art_commit':'5848c4f8aedde4acfa33586f82c3397d1b6d58a0','stop_condition':'採用済み。デザインを大きく変える場合だけユーザーへ確認する','coordinate_convention':'top-left origin; bbox right/bottom exclusive; foot anchor is ground contact, not lowest opaque pixel','characters':chars,'actions':actions,
'layers':{'destroyer':['actor_with_permanent_wrapped_chain','separate_extended_chain','separate_iron_ball'],'bullfrog':['tongue_wrap_back','target_actor','frog_actor','tongue_body','tongue_wrap_front','tongue_tip','optional_existing_sound_wave'],'ninja':['actor','independent_shuriken_or_dagger','existing_scroll_drop']},
'attachments_proposed':{'destroyer_grip_px':[[48,49],[14,38],[25,11],[57,64],[70,43],[46,51]],'destroyer_visual_contact_key':3,'ninja_visual_release_key':2,'bullfrog_mouth_px':{'key_01':[53,31],'key_02':[57,33]},'bullfrog_review_range':{'cell_width_px':48,'anchor_cell_distance':3,'anchor_distance_px':144,'note':'足元38→182。舌の見える長さは体幅を除く。射程ロジック未編集。'},'runner_doberman_review_anchor_distance_px':61},
'background':{'source':'review/current/story/06_ranch_idol_and_forest.png in implementation checkout','snapshot':'../../art-production/enemy-animal-direction-v3/references/farm-day.png','sha256':sha(SRC/'references/farm-day.png'),'game_launched':False,'in_game_verified':False},
'spec_snapshots':[{'file':n,'sha256':sha(SRC/'references'/n)} for n in ['ART_SPEC.md','ENEMIES.md','ANIMALS.md','ITEMS.md']],
'approved_existing_references':refs,'preserved_v2_files':frozen,'assets':assets,'unfinished':['正式な全方向の歩行・攻撃・被弾・退散等','フレーム時間・ループ・接触判定の確定','鎖と巻き付きの連続補間','ゲーム取り込みと隔離描画検証']}
manifest['adoption'] = {'date': '2026-10-06', 'user_message': '修正分採用で！', 'revised_characters': ['salaryman', 'destroyer', 'ninja', 'runner', 'hedgehog'], 'all_previous_acceptances_preserved': True, 'scope': 'design and special-motion direction; runtime animations delivered separately'}
(OUT/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
rows=[]
for n,v in chars.items():
 c=v['canvas'];a=v['anchor'];h=v['standing_body_height_px'];status='v2方向維持' if n in accepted else ('通常v2 / 迎撃v3採用済み' if n=='hedgehog' else 'v3採用済み')
 rows.append(f"| {v['name_ja']} | {c[0]}×{c[1]} | ({a[0]},{a[1]}) | {h}px | {palettes[n]} | {status} |")
previews=sorted([p for d in ['preview','motion_storyboards'] for p in (OUT/d).glob('*.png')],key=lambda p:p.name)
links='\n'.join(f"- [{p.name}]({p.relative_to(OUT).as_posix()})" for p in previews)
doc="""# 第一段階 v3 — 方向確認用 HANDOFF

**基本デザインと特殊モーションの方向性を採用済み。正式動作は別セットで順次納品します。**
2026-10-06、ユーザーの「修正分採用で！」により修正5体を採用。以前の採用分も維持し、この絵柄・寸法を正式動作制作の基準にします。ここに保存した絵コンテ自体は正式アニメーションではありません。

- ブランチ: codex/sporehollow-art-assets
- 納品: projects/sporehollow/art_delivery/enemy_animal_direction_v3/
- 原画・参照・加工スクリプト: projects/sporehollow/art-production/enemy-animal-direction-v3/
- preview / motion_storyboards は確認専用。pose_drafts / concept_parts / equipment も今回は方向確認用の加工PNG。本番へ自動取り込みしないこと。
- 通常RGBA・alpha 0/255・nearest。PNG単体には文字、背景、価格、HP、レアリティ、確認用足元線を焼き込んでいません。

## 最新の変更と維持

サラリーマンは添付の顔の面構成を参考に、曇り眼鏡・細い手足・前へ出る腹。デストロイマン（仕様ID destroyer）は革の継ぎ目、金具、暗いゴーグル、真鍮の鼻先のある覆面へ。忍者は目を完全に隠し、脱力した姿勢から素早く投げる案。
ランナーは小さい頭と長い首/手足。身体高54pxを採用。主人公42pxに対して高い頭身を維持します。
ハリネズミは通常18pxを残し、迎撃だけ変更。棘を立てたキー21px、丸い防御キー23pxです。

「他はいい」に基づき、武闘家、ムッツゴロウ、ドーベルマン、描き直したウシガエル、首輪、薄黄色一粒きのみ、ハリネズミ通常/被弾/縮む/戻るはv2加工済みPNGを維持。既存主人公v1・柴犬C・鶏・猫・誘拐者・商人も未変更。ハッシュ結果はQA.jsonとmanifest.jsonへ記録。

## レビュー画像

全シートは1×と同一画像のnearest4×。図鑑用の別人格は作っていません。アプリが画像を縮める場合は、ファイルを100%表示して確認してください。

LINKS

## 採用基準

身体高は通常キーの不透明bbox高。各キーの実bboxはmanifestへ記録。透明余白は切り詰めないこと。

| 素材 | キャンバス | 足元 | 通常身体高 | 基本色 | 状態 |
|---|---:|---:|---:|---|---|
ROWS

通常は右向き。ドーベルマンだけ左右立ち・走行2キー・攻撃構えを用意し、33px / 柴犬C28pxの相対サイズを維持。
デストロイマンの叩きつけキーは足裏y64、下がった拳がy66まで出ます。最低の不透明画素を足裏と誤認しないこと。
走行キーは空中姿勢も含む絵コンテです。接地タイミングを検証した正式歩行ループではありません。

## 動作・レイヤー案

- 鉄球: 下げる→引く→振りかぶる→壁へ叩きつける→伸びる→戻す。胴巻き鎖は常時本体、動く鎖/鉄球は独立。接触意図はキー3。土壁は既存通常/損傷素材。耐久値や判定は変更していません。
- 武闘家: 対面→直立→短い礼→構え。終了時は構え解除→対象確認→礼→離れる。突き/蹴りも確認。礼の時間は未確定。
- サラリーマン: phone_take=1,2,3 / phone_call=4 / phone_put=5,6 に分割可能。通話と短い発話は同じキーへ統合。端末案3×6px。保持中の端末は本体にも描画済みなのでphone.pngを二重に載せないこと。巨大な頭上アイコンはありません。
- 忍者: キー2で手裏剣を離す意図。shuriken / daggerは独立した別形状。煙玉なし。撃退時は生きて退散し、既存巻物を別レイヤーで落とす合成例。巻物の盤面サイズは既存実装の判断を維持。
- ムッツゴロウ: 発見→しゃがむ→手→おやつ/声→猫が近づく→同行。添付写真から白髪オールバック・眼鏡・華奢な老人を参照。煙草なし。猫は既存素材を左右向きで合成。懐柔判定や柴犬の抵抗仕様は未編集。
- ランナー: 大きな歩幅→脚を集める→フォーム崩れ→膝に手→回復→再走。同行犬とは足元61px離して別のマスに配置。
- ウシガエル: 灰白色でたるむ体を維持。tongue_body 8×3 / tongue_tip / tongue_wrap_back / tongue_wrap_frontを分離。巻き付き後半面→対象→前半面の順。3マス見本は横48pxの足元基準点間144px。見える舌の長さは体幅を除きます。射程ロジックは未編集。鳴き声は既存音波を別描画。
- ハリネズミ: 縮む→棘→顔を隠す防御→解除。中心の体を巨大化せず、迎撃時の輪郭を強めました。
- 装備: 首輪とごつごつした薄黄色一粒きのみは32×32のUI案。装着スプライトやレアリティ差分なし。
- 運搬が必要なら主人公は独立レイヤーで肩へ保持する構成を推奨。保持ソケットは正式動作時に確定。今回は新敵の運搬キーはなく、既存誘拐者の運搬を変更していません。

manifestの順番は絵コンテ順です。frame_duration_ms=null / loop=false は正式な時間・ループをまだ設定していない意味です。移動速度、発生率、ダメージ、当たり判定を推測で追加しないでください。

## 原画・加工・検査

内蔵画像生成を原案/修正に使用。外部有料APIは不使用。原画とプロンプトは制作領域のgeneration-records.json。v2採用原案はreferences/v2-generation-records.json。
共通縮尺、足元配置、共有減色、1px輪郭、角刈り/電話の画素補正、透過残片除去を行い、単純縮小だけで終えていません。
ART_SPEC / ENEMIES / ANIMALS / ITEMSは開始時の実装側内容を保存してハッシュ記録。保存済み実画面review/current/story/06_ranch_idol_and_forest.pngの草地へ合成しています。
**今回のゲーム内動作を検証した画像ではありません。ゲームは起動していません。**
本体に地面への落ち影なし。ゲーム側の影を使って二重影を避けてください。体・服・武器の内部陰影は絵の一部です。

## 未確定・次工程

修正5体を含むデザインは採用済み。通常の動作追加で再承認は求めません。大きなデザイン変更が必要な場合だけ確認します。
正式な全方向歩行/攻撃/被弾/退散、通話口パク、鎖の連続回転、巻き付きの距離/向き補間、時間とループは未完成。
正式制作へ進み、使える動作セットから独立した納品フォルダ・コミットで受け渡します。ゲームコード・本番シーン・UID・設定は未編集。取り込み、座標、描画順、隔離描画検証は実装担当へ引き継ぎます。
"""
(OUT/'HANDOFF.md').write_text(doc.replace('LINKS',links).replace('ROWS','\n'.join(rows)),encoding='utf-8')
qa={'status':'pass','png_count':len(assets),'native_rgba_draft_count':native_count,'review_sheet_count':len(previews),'preserved_v2_png_count':len(frozen),'existing_reference_hash_count':len(refs),'alpha':'native PNGs binary 0/255','prototype_only':True,'game_launched':False,'runtime_verification':False}
(OUT/'QA.json').write_text(json.dumps(qa,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(qa,ensure_ascii=False))

