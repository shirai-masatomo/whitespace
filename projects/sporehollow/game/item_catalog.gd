extends RefCounted
## Physical taxonomy is independent of recipe ingredients and usage tags.
const CATEGORIES={"resource":["資源・素材",{"earth":"土砂石材","wood":"木材","metal":"金属","fiber":"繊維・皮革","component":"加工部材"}],"food":["食料",{"raw":"生食材","cooked":"調理済み食品","feed":"飼料"}],"equipment":["装備・道具",{"clothing":"衣服","armor":"防具","weapon":"武器","tool":"道具"}],"medical":["医療・消耗品",{"medicine":"医療品","consumable":"消耗品"}],"furniture":["設備・家具",{"furniture":"家具","installation":"設置物"}],"special":["その他・特殊",{"trade":"交易品","blueprint":"設計図","special":"特殊品"}]}
# name, main category, subcategory, usage tags, existing placeholder icon
const FOOD_TIERS=["簡素","普通","上等","豪華"]
# Optional sixth field is tier; all existing foods default to simple.
const ROWS={
	"soil":["土","resource","earth",["building"],"soil"],"stone":["石材","resource","earth",["building"],"stone"],"wood":["木材","resource","wood",["building","carpentry"],"wood"],"fiber":["植物繊維","resource","fiber",["tailoring"],"feather"],
	"mushroom":["キノコ","food","raw",["cooking","meal"],"mushroom"],"egg":["卵","food","raw",["cooking","meal"],"egg"],"meat":["肉","food","raw",["cooking","meal"],"meat"],"milk":["ミルク","food","raw",["cooking","meal"],"milk"],
	"roast_mushroom":["焼きキノコ","food","cooked",["meal"],"mushroom"],"egg_meal":["卵料理","food","cooked",["meal"],"egg"],"roast_meat":["焼き肉","food","cooked",["meal"],"meat"],"stew":["肉とキノコの煮込み","food","cooked",["meal"],"mushroom"],
	"dog_food":["犬の餌","food","feed",["animal_feed"],"basket"],"hen_food":["鶏の餌","food","feed",["animal_feed"],"basket"],"cat_food":["猫の餌","food","feed",["animal_feed"],"basket"],
	"wood_staff":["木の長柄","equipment","weapon",["combat"],"hammer"],"fiber_clothes":["草繊維の服","equipment","clothing",["wear"],"collar"],"collar":["首輪","equipment","tool",["animal"],"collar"],"whistle":["ホイッスル","equipment","tool",["animal"],"whistle"],
	"berry":["きのみ","medical","medicine",["heal"],"berry"],"coffee":["コーヒー","medical","consumable",["recover"],"coffee"],"energy_drink":["活力ドリンク","medical","consumable",["recover"],"energy_drink"],
	"wood_crate":["木箱","furniture","furniture",["place"],"wood"],"wood_shelf":["木製棚","furniture","furniture",["place"],"wood"],"kokeshi":["こけし","furniture","installation",["place"],"wood"],"fossil":["化石","special","trade",["trade","place"],"stone"],"feather":["羽","special","trade",["trade"],"feather"],"skill_scroll":["技の巻物","special","special",["learn"],"book"],"chick":["ひよこ","special","special",["animal"],"egg"],
	"kennel_plan":["犬小屋の設計図","special","blueprint",["learn"],"book"],"coop_plan":["鶏小屋の設計図","special","blueprint",["learn"],"book"]}
static func item(id:String)->Dictionary:
	var r=ROWS.get(id,[id,"special","blueprint" if id.ends_with("_plan") else "special",[],"basket"])
	return {"id":id,"name":r[0],"category":r[1],"subcategory":r[2],"tags":r[3],"icon":r[4],"tier":int(r[5]) if r.size()>5 else 0}
static func title(id:String)->String:return item(id).name
static func accepted(z:Dictionary,id:String)->bool:
	var f=z.get("filter",{});var data=item(id)
	return f.get("items",{}).get(id,f.get("subs",{}).get(data.subcategory,f.get("categories",{}).get(data.category,f.get("all",true))))
static func configure(z:Dictionary,scope:String,id:String,value:bool):
	if not z.has("filter"):z.filter={"all":true,"categories":{},"subs":{},"items":{}}
	if scope=="all":z.filter={"all":value,"categories":{},"subs":{},"items":{}};return
	z.filter[scope][id]=value
	if scope=="categories":
		for sub in CATEGORIES[id][1]:z.filter.subs.erase(sub)
	if scope in ["categories","subs"]:
		for kind in z.filter.items.keys():
			var data=item(kind)
			if (scope=="categories" and data.category==id) or (scope=="subs" and data.subcategory==id):z.filter.items.erase(kind)
