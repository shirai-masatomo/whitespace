extends RefCounted
## Enemy/friendly Human skill catalogue. Presentation and tunable execution share these rows.
const ROWS={
 "abduct_keeper":["連れ去り","Passive",0.0,"牧場主が気絶し、隣接して拘束できる","拘束を経て牧場の外へ運ぶ","paw"],
 "iron_ball":["鉄球破壊","Active",1.6,"建物や相手に隣接","鉄球で攻撃。対物攻撃力4（Lv1）","iron_ball"],
 "bow":["礼","Passive",0.0,"新たな相手と勝負する前と勝負後","0.75秒の礼をする","paw"],
 "nonlethal":["不殺","Passive",0.0,"人・動物へ攻撃","相手のHPを1未満にしない","heart"],
 "phone":["応援要請","Active",0.0,"被弾時15%、一度だけ","電話2秒後に要請。3秒後に森の外から増援。1夜4回まで","phone"],
 "shuriken":["手裏剣","Active",4.0,"見通せる2〜5マスの敵","7ダメージ","paw"],
 "tame":["手懐け","Active",3.0,"3マス以内の動物を見通せる","忠誠を一時30低下。柴犬への効果は半分","whistle"],
 "lead":["連れ去り","Passive",0.0,"忠誠25以下の動物に隣接","動物を連れて退却。外へ出る前なら救出できる","paw"],
 "fatigue":["疲労","Passive",0.0,"8秒走り続ける","4秒間移動速度1.0。休んだ後は再び走る","moon"],
 "companion":["ドーベルマン同行","Passive",0.0,"襲来時20%","ドーベルマンが同じ外周入口から続く","paw"],
 "intercept":["迎撃特性","Passive",0.0,"敵を見つける","屋外の敵を追う。通常攻撃は噛みつき","paw"],
 "dance":["舞","Active",6.0,"3マス以内に活動中の味方","1秒舞い、味方の移動・攻撃速度を3秒間1.15倍","paw"],
 "resurrection":["復活の舞","Ultimate",0.0,"READY・3マス以内の復活可能な味方","死体が残る8秒以内、舞姫以外・個体1回。舞姫の現在HPまで回復。武闘家優先","resurrection"],
 "poison":["毒瓶","Active",8.0,"見通せる5マス以内の敵","着弾周囲1マスに毒。5秒間、毎秒1ダメージ・移動0.8倍","paw"],
 "steal":["盗む","Passive",0.0,"落とし物に隣接","盗品を持って退却。外へ出る前に倒せば取り戻せる","basket"],
 "coffee_support":["コーヒー配布","Active",1.0,"同じ陣営の仲間に隣接","HP3・スタミナ12回復。一巡後は自分も飲み10秒休息","cup"],
 "rage":["激ギレ","Ultimate",0.0,"READY・敵を見つける","6秒間、攻撃12・移動/攻撃速度2倍。乳牛は攻撃しない","rage"]}
const BY_ACTOR={"kidnapper":["abduct_keeper"],"destroyer":["iron_ball"],"martial_artist":["bow","nonlethal"],"salaryman":["phone"],"ninja":["shuriken"],"animal_tamer":["tame","lead"],"runner":["fatigue","companion"],"doberman":["intercept"],"dancer":["dance","resurrection"],"thief":["poison","steal"],"maid":["coffee_support","rage"]}
const TUNING={"dance_duration":1.0,"dance_buff":3.0,"maid_recruit_chance":0.05,"maid_recruit_range":2,"maid_first_day":11}
static func get_skill(id: String) -> Dictionary:
 var r=ROWS.get(id,[])
 if r.is_empty():return {}
 return {"SkillID":id,"Name":r[0],"Type":r[1],"UnlockLevel":1,"Cooldown":r[2],"Condition":r[3],"Effect":r[4],"IconID":r[5],"Rarity":2 if r[1]=="Ultimate" else 0,"AIHints":{"priority":100 if r[1]=="Ultimate" else 10}}
static func tooltip(s: Dictionary) -> String:
 return s.Name+"\n"+s.Type+" / Lv%d"%s.UnlockLevel+(" / CT %s秒"%str(s.Cooldown) if s.Type=="Active" and s.Cooldown>0 else "")+"\n条件："+s.Condition+"\n"+s.Effect
