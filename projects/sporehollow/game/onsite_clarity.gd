extends RefCounted
## Read-only explanations. Never sample AI, advance time, or change orders.
const SAVE_BOUNDARY="終了時に途中保存。時計・物資・仕事・敵を保ったまま再開します。"
const CARRIED_EGG="卵は食料・売却用の現物です。1個5G。\n禁止中の卵は食事・運搬・売却に使いません。"

static func eggs(_w,items: Array,reserved: bool) -> Array:
	if items.is_empty():return []
	var count=0
	for item in items:count+=item.get("amount",1)
	return ["卵 %d個 · 食料 / 売却：1個5G"%count,"回収指定あり → 保管域へ運搬" if reserved else "命令タブから回収・禁止・禁止解除", "禁止中の卵は食事・運搬・売却に使いません"]

static func dog(w,a: Dictionary) -> Array:
	if a.get("dead",false):return ["亡くなっています","この仲間には指示できません"]
	if a.get("lost",false):return ["牧場から連れ去られました","この仲間には指示できません"]
	if a.get("abductor",-1)>=0:return ["連れ去られているところ","運搬している敵を止めて救出"]
	if not a.get("placed",false):return ["入口からの入場待ち","入口の通路を空けてください"]
	if w.last_daily_day<=a.get("unavailable_through_day",0):return ["気絶・療養中：今は指示できません","復帰は%d日目から"%(int(a.unavailable_through_day)+1)]
	if a.hp<=0:return ["気絶しています","今は指示できません"]
	var state=str(a.get("state",""))
	var hint="「連れてく」で居場所を変えられます"
	var title=state
	if a.has("guide_job"):
		hint="誘導中 · 変えるなら作業予定を取消"
	elif state=="外で待つ" and a.get("rescuing",false):
		title="救出対象が屋内 · 出口を目指す"
		hint="柴犬は屋内不可。出口の配置を確認"
	elif state=="救出本能" and a.get("rescuing",false):
		title="牧場主の救出を優先中"
		hint="「待て」でその場の待機を優先"
	elif a.get("mode","")=="rest":
		title="休息中 · 無理しない指示" if state=="休む" else state
		hint="「無理するな」中 · 解除は「おまかせ」"
	elif state=="自主休養":
		title="傷を休める · 自主休養"
		hint="「連れてく」で休む場所を変えられます"
	elif state=="ひと休み":
		title="スタミナを回復中"
		hint="回復待ち · 居場所変更は「連れてく」"
	elif a.get("mode","")=="stay":
		title=("指示位置で待つ" if a.pos==a.home else "指示位置を目指す") if state=="待機" else state
		hint="「待て」中 · 救出も任せるなら「おまかせ」"
	elif state in ["追跡","様子見","吠える","位置調整"]:
		title={"追跡":"敵を追跡・迎撃中","様子見":"敵の様子を見ています","吠える":"敵に吠えています","位置調整":"敵との位置を調整中"}[state]
		hint="「狙え」で敵を指定／「待て」でその場待機"
	elif state in ["徘徊","見張り","警戒巡回"]:
		title="周囲を見回る · "+("警戒指示" if state=="警戒巡回" else "おまかせ" if a.get("mode","")=="auto" else "見張り")
	if not a.get("pending",{}).is_empty():hint="新しい指示に反応待ち · 現在は上の行動"
	elif w.jobs.any(func(j):return j.kind=="animal_order" and j.get("targets",[]).any(func(t):return t.id==a.id and not t.get("done",false))):hint="指示を届ける作業を予約中"
	return [title if title!="" else "行動の更新待ち",hint]
