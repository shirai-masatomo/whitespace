extends RefCounted
## Shared, versioned Lv1 tuning. No scene or simulation mutation.
const EnemySkills=preload("res://game/enemy_skills.gd")
const Levels=preload("res://game/level_stats.gd")
const ENEMY_LEVEL_OVERRIDES={} # No unapproved Lv2 combat tuning.
const ENEMY_GROWTH={}
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }
enum CombatResponse { AUTO, REACTIVE, NONE }
const FAST_SPEED = 3.0
const RARITY_NAMES = ["Common", "Uncommon", "Rare", "Epic", "Legendary"]
const RARITY_COLORS = ["8d917f", "74916c", "668b9d", "967fa0", "bfa260"]
const ROLL_WEIGHTS = {"shop":[90,8,2,0,0], "idol":[55,28,12,4,1]}
const BONUS_CHANCE = {"shop":0.05,"idol":0.25}
const BONUS_SKILLS = {
	"hardy":{"id":"hardy","name":"丈夫","rarity":Rarity.UNCOMMON,"type":"passive","unlock_level":1,"cooldown":0.0,"eligible_species":[],"eligible_tags":["animal"],"rollable":true,"source":"individual","condition":"常時","effect":"最大HP +4","max_hp":4}}
const ITEMS = {
	"collar":{"id":"collar","name":"首輪","rarity":Rarity.COMMON,"type":"equipment","equip_targets":["dog"],"durability":-1,"consumable":false,"trigger":"equipped","effects":{"loyalty":25,"defense":2},"buy":20,"sell":6},
	"berry":{"id":"berry","name":"きのみ","rarity":Rarity.COMMON,"type":"conditional_equipment","equip_targets":["animal"],"durability":1,"consumable":true,"trigger":"alive_hp_half","effects":{"heal_fraction":0.25},"buy":8,"sell":2}}
const ENEMY_ROWS = {
 "maid":["メイド",45,2.0,5,0,0,0,1.2,75,[50,45,0,5],Rarity.RARE,"仲間にコーヒーを届ける"],
 "dancer":["舞姫",38,1.6,6,2,2,0,1.5,75,[50,50,0,0],Rarity.RARE,"舞で味方を支え、倒れた仲間を復活させる"],
 "thief":["盗賊",32,2.0,7,4,4,0,1.2,70,[50,50,0,0],Rarity.UNCOMMON,"毒を投げ、落とし物を盗んで逃げる"],
	"kidnapper":["誘拐者",50,1.333333,6,5,5,2,1.4,40,[70,10,10,10],Rarity.COMMON,"主人公を連れ去る"],
	"destroyer":["デストロイヤー",80,1.1,5,7,7,4,1.6,20,[10,10,70,10],Rarity.UNCOMMON,"建築物を優先する"],
	"martial_artist":["武闘家",60,1.8,6,8,8,0,1.1,75,[50,50,0,0],Rarity.UNCOMMON,"人と動物に礼をして挑む"],
	"salaryman":["サラリーマン",28,1.4,5,3,3,1,1.5,35,[35,25,20,20],Rarity.COMMON,"弱いが応援を呼ぶ"],
	"ninja":["忍者",42,2.2,7,4,4,1,1.0,80,[45,30,10,15],Rarity.RARE,"見通せる相手に手裏剣を投げる"],
	"animal_tamer":["ムッツゴロウ",45,1.5,7,2,1,0,1.5,70,[5,85,0,0],Rarity.RARE,"動物を手懐けて連れ帰る"],
	"runner":["ランナー",35,FAST_SPEED,6,3,2,1,1.2,50,[45,20,5,30],Rarity.UNCOMMON,"速いが走り続けると疲れる"]}
const SPECIAL = {"phone_chance":0.15,"phone_delay":2.0,"reinforcement_delay":3.0,"night_reinforcement_cap":4,
	"shuriken_range":5,"shuriken_ct":4.0,"shuriken_damage":7,"bow_seconds":0.75,
	"tame_range":3,"tame_loss":30.0,"tame_ct":3.0,"tame_recovery":2.0,"tame_threshold":25,"shiba_resistance":0.5,
	"runner_run":8.0,"runner_tired":4.0,"runner_tired_speed":1.0,"companion_chance":0.2,
	"tongue_range":4,"tongue_ct":8.0,"tongue_stop":2.0,"croak_range":6,
	"spines_defense":4,"spines_duration":4.0,"spines_reflect":4}

static func rarity(value) -> int:
	if value is String: return maxi(0,RARITY_NAMES.map(func(v):return v.to_lower()).find(value.to_lower()))
	return clampi(int(value),0,Rarity.LEGENDARY) if value!=null else Rarity.COMMON

static func enemy(id: String,level: int=1) -> Dictionary:
	var r=ENEMY_ROWS.get(id,ENEMY_ROWS.kidnapper)
	var base={"archetype":id,"species":id,"name":r[0],"lv":1,"rarity":r[10],"type_tag":"Human","max_hp":r[1],"defense":0,
		"move_speed":r[2],"sight_range":r[3],"attack_range":1,"human_attack":r[4],"animal_attack":r[5],"object_attack_power":r[6],
		"attack_interval":r[7],"ai_accuracy":r[8],"target_weights":{"keeper":r[9][0],"animal":r[9][1],"structure":r[9][2],"idol":r[9][3]},
		"karma_min":0,"karma_max":-1,"spawn_weight":1.0,"recruitable":id in ["martial_artist","ninja","maid"],"recruit_condition_id":"cow_encounter" if id=="maid" else "unconfigured",
		"loot_table":"scroll" if id=="ninja" else ("small_gold" if id=="salaryman" else "none"),"skills":EnemySkills.BY_ACTOR.get(id,[]).duplicate(),"role_text":r[11],"max_stamina":100.0,"stamina_regen":2.0,"ultimates":["resurrection"] if id=="dancer" else (["rage"] if id=="maid" else []),"level_overrides":ENEMY_LEVEL_OVERRIDES.get(id,{})}
	return Levels.resolve(base,level,ENEMY_GROWTH.get(id,{}),base.level_overrides)

static func weighted(rng: RandomNumberGenerator, weights: Array) -> int:
	var total=0.0
	for weight in weights: total+=weight
	var roll=rng.randf()*total
	for i in range(weights.size()):
		roll-=weights[i]
		if roll<0: return i
	return weights.size()-1

static func individual(species: String, seed_value: int, source: String="shop", karma: int=0) -> Dictionary:
	var rng=RandomNumberGenerator.new(); rng.seed=seed_value
	var weights=ROLL_WEIGHTS.get(source,ROLL_WEIGHTS.shop).duplicate()
	if source=="idol":
		for i in range(1,weights.size()): weights[i]*=1.0+minf(karma,100)*0.01*i
	var tier=weighted(rng,weights)
	var bonus=[]
	if rng.randf()<BONUS_CHANCE.get(source,0.0): bonus.append("hardy")
	return {"species":species,"lv":1,"rarity":tier,"bonus_skills":bonus,"equipment":{},"source":source}

static func idol_reward(category: String, karma: int, seed_value: int, day: int) -> Dictionary:
	var rng=RandomNumberGenerator.new(); rng.seed=seed_value*1009+day*313
	var record={"category":category,"seed":seed_value,"day":day}
	if category=="animal":
		var pool=["hen","cat","doberman","bullfrog","hedgehog"] # Unique starting Shiba is never a reward.
		record.merge(individual(pool[rng.randi_range(0,pool.size()-1)],rng.randi(),"idol",karma))
	elif category=="item":
		record.item_id=["collar","berry"][rng.randi_range(0,1)]; record.rarity=Rarity.COMMON
	elif category=="gold": record.gold_amount=[40,60,90][rng.randi_range(0,2)]
	else: return {}
	return record
