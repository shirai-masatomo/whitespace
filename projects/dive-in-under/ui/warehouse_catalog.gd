extends RefCounted
const Storage=preload("res://core/storage.gd")
const DESCRIPTIONS={
"I01":"使い込まれた皮の帽子。地下の岩肌から頭を守る。",
"I02":"丈夫な粗布で仕立てた上着。軽く、動きやすい。",
"I03":"厚手の革のズボン。探索に必要な身軽さを保つ。",
"I04":"幾度も地下を歩いた古いブーツ。まだ旅を支えてくれる。",
"I05":"飾り気のない鉄の指輪。身につけると力が増す。",
"I06":"静かな光をたたえる腕輪。装備すると守りを補う。",
"I07":"煤に覆われた小さな首飾り。持ち主の生命力を支える。",
"I08":"ランタンの火を映す耳飾り。身のこなしを助ける。",
"I09":"青く澄んだ探索用のレンズ。装備すると攻撃力を補う。",
"I10":"道中で見つかる補修用の石。大切に保管しておこう。",
"I11":"深層から持ち帰った指輪。強い力を秘めている。"}
const CATEGORIES={"all":"すべて","consumable":"消耗品","material":"素材","weapon":"武器","armor":"防具","key":"大事なもの"}
static func name_of(item: Dictionary) -> String:
	return item.name.replace("（使用は後工程）","")
static func details(s: Dictionary, uid: String, cfg: Dictionary) -> Dictionary:
	var id: String=s.items[uid]; var item: Dictionary=cfg.items[id]
	var carried:=0; var stored:=0
	for source in ["inventory","cloth"]:
		for key in s[source]:
			if s.items[key]==id: carried+=1
	for key in s.equipment.values():
		if key!="" and s.items[key]==id: carried+=1
	for key in s.warehouse:
		if s.items[key]==id: stored+=1
	return {"name":name_of(item),"type":CATEGORIES.get(Storage.category(item),"その他"),
	"carried":carried,"stored":stored,"description":item.get("description",DESCRIPTIONS.get(id,"")),
	"uses":str(item.get("uses","—")),"special":str(item.get("special_effects","—")),"marks":str(item.get("marks","—"))}
