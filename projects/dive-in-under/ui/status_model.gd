extends RefCounted
## Read-only adapter; no mutation, action, RNG or save calls.
const E=preload("res://core/expedition.gd")
const Items=preload("res://ui/warehouse_catalog.gd")
const STAT_NAMES={"max_hp":"HP","max_sp":"SP","atk":"攻撃力","def":"防御力","spd":"素早さ"}
const STAT_TEXT={
"max_hp":"生命力の上限。HPが0になると探索を終えて町へ戻る。レベルと装備で変化する。",
"max_sp":"スキルに使うSPの上限。戦闘では条件を満たすスキルを自動使用する。最大SPが0の間、ゲージは空のまま表示される。",
"atk":"通常攻撃の威力に関わる。表示値にはレベル成長と装備の補正が含まれる。装備の補正は残りの耐久によって低下する。",
"def":"受ける通常攻撃のダメージを抑える。装備とその耐久を反映した現在の値。防御態勢の効果は別に確認できる。",
"spd":"戦闘の行動順を決める。同じ素早さのときは戦闘の乱数で順番が決まる。装備による補正も含まれる。"}
const EFFECT_NAMES={"poison":"毒","blind":"暗闇","paralysis":"麻痺","defense":"防御態勢"}
static func actor(s: Dictionary, cfg: Dictionary, data: Dictionary) -> Dictionary:
	return E.battle_state(s,data).hero if s.phase=="battle" else E.hero(s,cfg)
static func equipment(s: Dictionary, cfg: Dictionary, slot: String) -> Dictionary:
	var uid: String=s.equipment[slot]
	if uid=="": return {"empty":true,"slot":slot,"name":"装備なし"}
	var item: Dictionary=cfg.items[s.items[uid]]
	return {"empty":false,"slot":slot,"uid":uid,"name":Items.name_of(item),"description":item.get("description",Items.DESCRIPTIONS.get(s.items[uid],"")),"condition":s.item_condition[uid].duplicate(true),"item":item.duplicate(true)}
static func base_value(s: Dictionary, cfg: Dictionary, key: String) -> int:
	return int(cfg.initial[key])+(int(E.level_info(s,cfg).level)-1)*int(cfg.growth[key])
static func effects(unit: Dictionary, rules: Dictionary) -> Array:
	var rows: Array=[]
	for id in unit.get("statuses",{}):
		var effect: Dictionary=unit.statuses[id]
		var text: String={"poison":"自身の行動機会の開始時にHPを%d失う。"%int(effect.potency),"blind":"命中率が%dポイント低下する。"%roundi(float(effect.potency)*100),"paralysis":"自身の行動機会を失う。"}.get(id,"付与中の状態。")
		rows.append({"id":id,"name":EFFECT_NAMES.get(id,id),"remaining":int(effect.remaining),"text":text,"skill":effect.skill})
	if unit.get("defense_until",-1)>=0:
		rows.append({"id":"defense","name":"防御態勢","remaining":maxi(0,int(unit.defense_until)-int(unit.action_count)),"text":"防御力が%d%%上昇する。"%roundi(float(rules.skills.S105.def_bonus)*100),"skill":"S105"})
	return rows
static func effect_detail(effect: Dictionary, data: Dictionary) -> String:
	return "%s\n\n残り %d 回の自身の行動機会。\n発生元：%s\n\n残り期間はラウンド数ではなく、このキャラクターの行動機会を基準に数える。"%[effect.text,effect.remaining,data.rules.skills.get(effect.skill,{}).get("name",effect.skill)]
static func profile() -> Dictionary:
	var value=JSON.parse_string(FileAccess.get_file_as_string("res://data/v1/hero-profile.json"))
	return value.facts if value is Dictionary and value.get("schema_version")==1 else {}
