extends RefCounted
const Data = preload("res://game/progression_data.gd")
## Only playable species; future species stay in ANIMALS.md.
const SPECIES = {
	"cow":{"category":"bovine","hp":60,"attack":0,"object_attack":0,"attack_seconds":1.2,"move_speed":1.3,"detection_range":5,"attack_target_range":5,"loyalty":85,"can_enter_indoor":true,"orders":["guide"],"commands":true,"mortal":true,"affinity":false,"combat_response":2,"skills":["milk"],"title":"乳牛"},
	"bull":{"category":"bovine","hp":80,"attack":12,"object_attack":0,"attack_seconds":1.2,"move_speed":1.8,"detection_range":5,"attack_target_range":5,"loyalty":85,"can_enter_indoor":true,"orders":["auto","stay","wander","rest","guide","charge"],"commands":true,"mortal":true,"affinity":false,"combat_response":0,"skills":["charge","grit"],"title":"闘牛"},
	"maid":{"category":"human","hp":45,"attack":3,"object_attack":0,"attack_seconds":1.2,"move_speed":2.0,"detection_range":5,"attack_target_range":5,"loyalty":85,"can_enter_indoor":true,"orders":["auto","stay","rest","guide"],"commands":true,"mortal":true,"affinity":false,"combat_response":0,"skills":["coffee_support"],"title":"メイド","has_stamina":true,"ultimates":["rage"]},
	"shiba": {"title": "柴犬", "category": "dog", "hp": 40, "attack": 10, "object_attack": 0, "attack_seconds": 1.2, "move_speed": 2.0, "detection_range": 4, "attack_target_range": 4, "loyalty": 75, "can_enter_indoor": false, "orders": ["auto","stay","wander","rest","attack_target","guide"], "commands": true, "mortal": false, "affinity": false, "combat_response": Data.CombatResponse.AUTO, "skills": ["bark", "rescue"]},
	"hen": {"title": "鶏", "category": "bird", "hp": 20, "attack": 0, "object_attack": 0, "attack_seconds": 0, "move_speed": 1.3, "detection_range": 3, "attack_target_range": 0, "loyalty": 0, "can_enter_indoor": true, "orders": ["guide"], "commands": false, "mortal": true, "affinity": false, "combat_response": Data.CombatResponse.NONE, "skills": ["lay", "feather"]},
	"cat": {"title": "猫", "category": "cat", "hp": 28, "attack": 0, "object_attack": 0, "attack_seconds": 0, "move_speed": 1.8, "detection_range": 3, "attack_target_range": 0, "loyalty": 0, "can_enter_indoor": true, "orders": [], "commands": false, "mortal": true, "affinity": true, "combat_response": Data.CombatResponse.NONE, "skills": ["charm", "meow"]},
	"doberman":{"title":"ドーベルマン","category":"dog","hp":55,"attack":14,"object_attack":1,"attack_seconds":1.0,"move_speed":Data.FAST_SPEED,"detection_range":5,"attack_target_range":6,"loyalty":90,"can_enter_indoor":false,"orders":["auto","stay","wander","rest","attack_target","guide"],"commands":true,"mortal":true,"affinity":true,"combat_response":Data.CombatResponse.AUTO,"skills":["intercept"]},
	"bullfrog":{"title":"ウシガエル","category":"amphibian","hp":34,"attack":2,"object_attack":0,"attack_seconds":1.5,"move_speed":1.4,"detection_range":5,"attack_target_range":5,"loyalty":45,"can_enter_indoor":true,"orders":["auto","stay","wander","guide"],"commands":true,"mortal":true,"affinity":false,"combat_response":Data.CombatResponse.AUTO,"skills":["tongue","croak"]},
	"hedgehog":{"title":"ハリネズミ","category":"small","hp":38,"attack":0,"object_attack":0,"attack_seconds":1.5,"move_speed":1.2,"detection_range":2,"attack_target_range":2,"loyalty":40,"can_enter_indoor":true,"orders":["stay","guide"],"commands":true,"mortal":true,"affinity":false,"combat_response":Data.CombatResponse.REACTIVE,"skills":["spines"]}}
const SKILLS = {
 "milk":{"name":"搾乳","type":"passive","unlock_level":1,"condition":"牧場主が隣接して搾乳・1日1回","effect":"ミルクを1個受け取る"},
 "charge":{"name":"突撃","type":"active","unlock_level":1,"cooldown":8.0,"condition":"指示後、指定地点へ直進","effect":"最初の敵に20ダメージ。壁・仲間で停止"},
 "grit":{"name":"根性","type":"passive","unlock_level":1,"condition":"HP50%以下","effect":"移動・攻撃速度1.5倍"},
 "coffee_support":{"name":"コーヒー配り","type":"active","unlock_level":1,"cooldown":1.0,"condition":"味方へ近づいて配る","effect":"HP3・スタミナ12回復。一巡後は自分も飲んで休む"},
	"intercept":{"name":"迎撃態勢","type":"passive","unlock_level":1,"condition":"検知済みの敵が攻撃対象範囲内","effect":"迷いを抑え迎撃"},
	"tongue":{"name":"舌拘束","type":"active","unlock_level":1,"cooldown":8.0,"condition":"敵を見通せる","effect":"4マス以内の1体を2秒足止め。人間のスタミナを20低下"},
	"croak":{"name":"警戒鳴き","type":"passive","unlock_level":1,"condition":"被弾","effect":"周囲6マスへ攻撃者の情報を共有"},
	"spines":{"name":"防御モード","type":"passive","unlock_level":1,"condition":"被弾","effect":"4秒間 防御+4・接触反射4"},
	"bark": {"name": "吠える", "type": "active", "unlock_level": 1, "cooldown": 6.0, "condition": "敵を検知", "effect": "周囲4マスの敵を1秒足止め"},
	"rescue": {"name": "救出本能", "type": "passive", "unlock_level": 1, "condition": "主人公が連れ去られる", "effect": "運搬者を最優先 / 移動1.5倍"},
	"lay": {"name": "産卵", "type": "passive", "unlock_level": 1, "condition": "夜明け", "effect": "卵を1個産む"},
	"feather": {"name": "羽落とし", "type": "passive", "unlock_level": 2, "condition": "夜明け・低確率", "effect": "羽を落とす"},
	"charm": {"name": "懐柔", "type": "passive", "unlock_level": 1, "condition": "敵側動物が近い", "effect": "敵側動物と仲良くなる"},
	"meow": {"name": "鳴く", "type": "active", "unlock_level": 2, "cooldown": 12.0, "condition": "敵が3マス以内", "effect": "攻撃力15%低下 / 4秒", "range": 3, "duration": 4.0, "reduction": 0.15}}

static func has_skill(a: Dictionary, id: String) -> bool:
	return (id in stats(a.species,a.lv).skills or id in a.get("bonus_skills",[])) and a.lv >= skill(id).get("unlock_level",1)

static func skill(id: String) -> Dictionary:
	var row=SKILLS.get(id,Data.BONUS_SKILLS.get(id,{})).duplicate(true)
	if row.is_empty(): return row
	row.id=id; row.rarity=Data.rarity(row.get("rarity",0))
	row.cooldown=row.get("cooldown",0.0)
	row.eligible_species=row.get("eligible_species",SPECIES.keys().filter(func(s):return id in SPECIES[s].skills))
	row.eligible_tags=row.get("eligible_tags",[])
	row.rollable=row.get("rollable",false); row.source=row.get("source","species")
	return row

const CHARACTER_TEXT={
 "cow":["穏やかなミルクの届け手。","牧場主がそばへ行くと、1日1回ミルクを受け取れる仲間。戦闘は苦手。"],
 "bull":["まっすぐ突進する頼もしい仲間。","指定地点へ直進する。障害物を迂回しないため、通路を確かめて指示しよう。"],
 "maid":["コーヒーで仲間を支える。","仲間へコーヒーを配り、一巡したら自分もひと休み。激ギレ中は敵へ立ち向かう。"],
 "shiba":["危険に立ち向かう、大切な相棒。","牧場主のかけがえのない相棒。高い忠誠心で危険に立ち向かい、屋外から主人を救う機会を待つ。"],
 "hen":["穏やかな卵の届け手。","毎朝卵を届ける穏やかな仲間。移動の誘導には応じるが、戦いは苦手。"],
 "cat":["気ままに歩く、自由な仲間。","気ままに牧場を歩く自由な仲間。指示には従わず、自分のペースで過ごす。"],
 "doberman":["鋭い目で守る、頼もしい番犬。","鋭い目で屋外を守る番犬。敵へ果敢に向かうが、柴犬の救出本能は持たない。"],
 "bullfrog":["のんびり構え、舌で足止め。","大きな体でのんびり構える仲間。舌で敵を足止めし、危険を周囲へ知らせる。"],
 "hedgehog":["控えめでも、棘は頼もしい。","ふだんは控えめな仲間。危険に反応して棘を立て、身を守りながら立ち向かう。"]}

static func character_text(species: String,short: bool=false) -> String:
	return CHARACTER_TEXT.get(species,["",""])[0 if short else 1]

const LEVEL_OVERRIDES={}
const GROWTH={"shiba":{"hp":4,"attack":2},"hen":{"hp":4},"cat":{"hp":4},"doberman":{"hp":4},"bullfrog":{"hp":4},"hedgehog":{"hp":4}}
static func stats(species: String,level: int=1) -> Dictionary:
	return Data.Levels.resolve(SPECIES[species],level,GROWTH.get(species,{}),LEVEL_OVERRIDES.get(species,{}))

static func short_description(species: String) -> String:
	return character_text(species,true)
