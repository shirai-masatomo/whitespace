extends RefCounted
const Data=preload("res://game/progression_data.gd")
const Animals=preload("res://game/animal_data.gd")
## Temporary Stage1 assortment. Prices, weights and stock are tuning, not final balance.
const CATEGORIES = {"animals": "仲間", "materials": "素材", "facilities": "施設", "items": "アイテム"}
const FOOD = {"dog_food": {"category": "dog", "hp": 10}, "hen_food": {"category": "bird", "hp": 8}, "cat_food": {"category": "cat", "hp": 8}}

static func table() -> Dictionary:
	var rows = [
 ["maid","メイド Lv1","animals",120,0,1,0.0,true,1],
 ["cow","乳牛 Lv1","animals",80,26,1,0.0,true,1],
 ["bull","闘牛 Lv1","animals",100,32,1,0.0,true,1],
 ["kokeshi","こけし","items",30,10,1,0.0,true,1],
 ["fossil","化石","items",20,6,1,0.0,true,1],
 ["milk","ミルク","items",12,6,1,0.0,false,0],
		["collar","首輪","items",20,6,1,0.0,true,2],
		["berry","きのみ","items",8,2,1,0.0,true,3],
		["doberman","ドーベルマン Lv1","animals",70,24,1,1.0,true,1],
		["bullfrog","ウシガエル Lv1","animals",36,12,1,1.0,true,1],
		["hedgehog","ハリネズミ Lv1","animals",32,10,1,1.0,true,1],
		["whistle", "ホイッスル", "items", 18, 6, 1, 0.0, true, 1],
		["coffee", "コーヒー", "items", 8, 2, 1, 0.0, true, 1],
		["energy_drink", "活力ドリンク", "items", 15, 4, 1, 0.0, true, 1],
		["shiba", "柴犬 Lv1", "animals", 42, 15, 1, 0.0, false, 0],
		["hen", "鶏 Lv1", "animals", 30, 10, 1, 1.0, true, 1],
		["cat", "猫 Lv1", "animals", 38, 12, 1, 1.0, true, 1],
		["soil", "土 50", "materials", 15, 5, 50, 0.0, true, 4],
		["wood", "木材 20", "materials", 12, 4, 20, 0.0, true, 3],
		["stone", "石 10", "materials", 10, 3, 10, 0.0, true, 3],
		["dog_food", "犬用餌 HP+10", "items", 8, 2, 1, 0.0, true, 4],
		["hen_food", "鶏用餌 HP+8", "items", 6, 1, 1, 0.0, true, 4],
		["cat_food", "猫用餌 HP+8", "items", 6, 1, 1, 0.0, true, 4],
		["feather", "鶏の羽", "items", 8, 2, 1, 0.0, false, 0],
		["egg", "卵", "items", 12, 5, 1, 0.0, false, 0],
		["mushroom", "キノコ", "items", 10, 3, 1, 0.0, false, 0],
		["kennel_plan", "犬小屋の設計図", "items", 30, 5, 1, 0.0, false, 0]]
	var products = {}
	for r in rows:
		products[r[0]] = {"ProductID": r[0], "Name": r[1], "Category": r[2], "BuyPrice": r[3], "SellPrice": r[4], "Amount": r[5],
			"Rarity": Data.Rarity.COMMON if r[7] else Data.Rarity.UNCOMMON, "Weight": r[6], "UnlockCondition": "", "StageMin": 1, "Enabled": r[0] not in ["shiba","kennel_plan","maid"] and not FOOD.has(r[0]), "Guaranteed": r[7], "Stock": r[8]}
	return products

static func generate(stage: int, seed_value: int, blueprints: Array, day: int=1) -> Array:
	var random = RandomNumberGenerator.new()
	random.seed = seed_value * 313 + stage * 733 + day*79
	var stock = []
	var candidates = []
	var total = 0.0
	for product in table().values():
		if day<({"doberman":3,"bullfrog":2,"hedgehog":2,"cow":4,"maid":5,"bull":6,"kokeshi":4,"fossil":4}.get(product.ProductID,1)): continue
		if not product.Enabled or stage < product.StageMin or (product.UnlockCondition != "" and product.UnlockCondition not in blueprints): continue
		if product.Guaranteed: stock.append({"product": product.ProductID, "remaining": product.Stock, "individual": {"loyalty": 0}})
		elif product.Category == "animals" and product.Weight > 0:
			candidates.append(product)
			total += product.Weight
	var roll = random.randf() * total
	for p in candidates:
		roll -= p.Weight
		if roll <= 0:
			stock.push_front({"product": p.ProductID, "remaining": 1, "individual": {"loyalty": 75 if p.ProductID == "shiba" else 0}})
			break
	for i in range(stock.size()):
		var row=stock[i]
		if Animals.SPECIES.has(row.product):
			row.individual=Data.individual(row.product,seed_value*313+day*65537+i*73,"shop")
			row.individual.loyalty=Animals.SPECIES[row.product].loyalty
	return stock
