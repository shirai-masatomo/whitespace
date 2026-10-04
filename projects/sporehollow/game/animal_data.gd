extends RefCounted
## Only playable species; future species stay in ANIMALS.md.
const SPECIES = {
	"shiba": {"title": "柴犬", "category": "dog", "hp": 40, "attack": 10, "object_attack": 0, "attack_seconds": 1.2, "move_speed": 2.0, "detection_range": 4, "attack_target_range": 4, "loyalty": 75, "can_enter_indoor": false, "orders": ["auto","stay","wander","rest","attack_target","guide"], "commands": true, "mortal": false, "affinity": false, "skills": ["bark", "rescue"]},
	"hen": {"title": "鶏", "category": "bird", "hp": 20, "attack": 0, "object_attack": 0, "attack_seconds": 0, "move_speed": 1.3, "detection_range": 3, "attack_target_range": 0, "loyalty": 0, "can_enter_indoor": true, "orders": ["guide"], "commands": false, "mortal": false, "affinity": false, "skills": ["lay", "feather"]},
	"cat": {"title": "猫", "category": "cat", "hp": 28, "attack": 0, "object_attack": 0, "attack_seconds": 0, "move_speed": 1.8, "detection_range": 3, "attack_target_range": 0, "loyalty": 0, "can_enter_indoor": true, "orders": [], "commands": false, "mortal": false, "affinity": true, "skills": ["charm", "meow"]}}
const SKILLS = {
	"bark": {"name": "吠える", "type": "active", "unlock_level": 1, "cooldown": 6.0, "condition": "敵を検知", "effect": "周囲4マスの敵を1秒足止め"},
	"rescue": {"name": "救出本能", "type": "passive", "unlock_level": 1, "condition": "主人公が連れ去られる", "effect": "運搬者を最優先 / 移動1.5倍"},
	"lay": {"name": "産卵", "type": "passive", "unlock_level": 1, "condition": "夜明け", "effect": "卵を1個産む"},
	"feather": {"name": "羽落とし", "type": "passive", "unlock_level": 2, "condition": "夜明け・低確率", "effect": "羽を落とす"},
	"charm": {"name": "懐柔", "type": "passive", "unlock_level": 1, "condition": "敵側動物が近い", "effect": "敵側動物と仲良くなる"},
	"meow": {"name": "鳴く", "type": "active", "unlock_level": 2, "cooldown": 12.0, "condition": "敵が3マス以内", "effect": "攻撃力15%低下 / 4秒", "range": 3, "duration": 4.0, "reduction": 0.15}}

static func has_skill(a: Dictionary, id: String) -> bool:
	return id in SPECIES[a.species].skills and a.lv >= SKILLS[id].unlock_level
