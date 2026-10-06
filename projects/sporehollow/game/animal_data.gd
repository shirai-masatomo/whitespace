extends RefCounted
const Data = preload("res://game/progression_data.gd")
## Only playable species; future species stay in ANIMALS.md.
const SPECIES = {
	"shiba": {"title": "柴犬", "category": "dog", "hp": 40, "attack": 10, "object_attack": 0, "attack_seconds": 1.2, "move_speed": 2.0, "detection_range": 4, "attack_target_range": 4, "loyalty": 75, "can_enter_indoor": false, "orders": ["auto","stay","wander","rest","attack_target","guide"], "commands": true, "mortal": false, "affinity": false, "combat_response": Data.CombatResponse.AUTO, "skills": ["bark", "rescue"]},
	"hen": {"title": "鶏", "category": "bird", "hp": 20, "attack": 0, "object_attack": 0, "attack_seconds": 0, "move_speed": 1.3, "detection_range": 3, "attack_target_range": 0, "loyalty": 0, "can_enter_indoor": true, "orders": ["guide"], "commands": false, "mortal": true, "affinity": false, "combat_response": Data.CombatResponse.NONE, "skills": ["lay", "feather"]},
	"cat": {"title": "猫", "category": "cat", "hp": 28, "attack": 0, "object_attack": 0, "attack_seconds": 0, "move_speed": 1.8, "detection_range": 3, "attack_target_range": 0, "loyalty": 0, "can_enter_indoor": true, "orders": [], "commands": false, "mortal": true, "affinity": true, "combat_response": Data.CombatResponse.NONE, "skills": ["charm", "meow"]},
	"doberman":{"title":"ドーベルマン","category":"dog","hp":55,"attack":14,"object_attack":1,"attack_seconds":1.0,"move_speed":Data.FAST_SPEED,"detection_range":5,"attack_target_range":6,"loyalty":90,"can_enter_indoor":false,"orders":["auto","stay","wander","rest","attack_target","guide"],"commands":true,"mortal":true,"affinity":true,"combat_response":Data.CombatResponse.AUTO,"skills":["intercept"]},
	"bullfrog":{"title":"ウシガエル","category":"amphibian","hp":34,"attack":2,"object_attack":0,"attack_seconds":1.5,"move_speed":1.4,"detection_range":5,"attack_target_range":5,"loyalty":45,"can_enter_indoor":true,"orders":["auto","stay","wander","guide"],"commands":true,"mortal":true,"affinity":false,"combat_response":Data.CombatResponse.AUTO,"skills":["tongue","croak"]},
	"hedgehog":{"title":"ハリネズミ","category":"small","hp":38,"attack":0,"object_attack":0,"attack_seconds":1.5,"move_speed":1.2,"detection_range":2,"attack_target_range":2,"loyalty":40,"can_enter_indoor":true,"orders":["stay","guide"],"commands":true,"mortal":true,"affinity":false,"combat_response":Data.CombatResponse.REACTIVE,"skills":["spines"]}}
const SKILLS = {
	"intercept":{"name":"迎撃態勢","type":"passive","unlock_level":1,"condition":"検知済みの敵が攻撃対象範囲内","effect":"迷いを抑え迎撃"},
	"tongue":{"name":"舌拘束","type":"active","unlock_level":1,"cooldown":8.0,"condition":"敵を見通せる","effect":"4マス以内の1体を2秒足止め"},
	"croak":{"name":"警戒鳴き","type":"passive","unlock_level":1,"condition":"被弾","effect":"周囲6マスへ攻撃者の情報を共有"},
	"spines":{"name":"防御モード","type":"passive","unlock_level":1,"condition":"被弾","effect":"4秒間 防御+4・接触反射4"},
	"bark": {"name": "吠える", "type": "active", "unlock_level": 1, "cooldown": 6.0, "condition": "敵を検知", "effect": "周囲4マスの敵を1秒足止め"},
	"rescue": {"name": "救出本能", "type": "passive", "unlock_level": 1, "condition": "主人公が連れ去られる", "effect": "運搬者を最優先 / 移動1.5倍"},
	"lay": {"name": "産卵", "type": "passive", "unlock_level": 1, "condition": "夜明け", "effect": "卵を1個産む"},
	"feather": {"name": "羽落とし", "type": "passive", "unlock_level": 2, "condition": "夜明け・低確率", "effect": "羽を落とす"},
	"charm": {"name": "懐柔", "type": "passive", "unlock_level": 1, "condition": "敵側動物が近い", "effect": "敵側動物と仲良くなる"},
	"meow": {"name": "鳴く", "type": "active", "unlock_level": 2, "cooldown": 12.0, "condition": "敵が3マス以内", "effect": "攻撃力15%低下 / 4秒", "range": 3, "duration": 4.0, "reduction": 0.15}}

static func has_skill(a: Dictionary, id: String) -> bool:
	return (id in SPECIES[a.species].skills or id in a.get("bonus_skills",[])) and a.lv >= skill(id).get("unlock_level",1)

static func skill(id: String) -> Dictionary:
	var row=SKILLS.get(id,Data.BONUS_SKILLS.get(id,{})).duplicate(true)
	if row.is_empty(): return row
	row.id=id; row.rarity=Data.rarity(row.get("rarity",0))
	row.cooldown=row.get("cooldown",0.0)
	row.eligible_species=row.get("eligible_species",SPECIES.keys().filter(func(s):return id in SPECIES[s].skills))
	row.eligible_tags=row.get("eligible_tags",[])
	row.rollable=row.get("rollable",false); row.source=row.get("source","species")
	return row
