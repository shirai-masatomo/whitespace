extends RefCounted
## All equipment gestures commit this transaction on the caller's copied state.
const Party=preload("res://core/party_ui.gd")
const Storage=preload("res://core/storage.gd")
static func reason(s: Dictionary, args: Dictionary, cfg: Dictionary, removing: bool=false) -> String:
	var actor: String=args.get("actor","hero");var source: String=args.get("source","inventory");var destination: String=args.get("destination",source)
	if s.phase not in ["town","explore","reward","event","event_result","treasure","portal","portal_done"]:return "戦闘中は装備を変更できません。"
	if not Party.exists(s,actor):return "対象キャラが見つかりません。"
	if source not in ["inventory","warehouse"] or destination not in ["inventory","warehouse"]:return "収納先を選んでください。"
	if s.phase!="town" and (source=="warehouse" or destination=="warehouse"):return "ダンジョンでは倉庫を利用できません。"
	var equipment: Dictionary=Party.gear(s,actor);var slot: String=args.get("slot","");var uid: String=args.get("uid","")
	if removing:
		if not equipment.has(slot) or equipment[slot]=="":return "外す装備を選んでください。"
		if destination=="inventory" and s.inventory.size()>=15:return "バックパックに空きがありません。"
	else:
		if uid not in s[source] or not s.items.has(uid):return "選択した収納にその品がありません。"
		var actual_slot: String=cfg.items[s.items[uid]].slot
		if actual_slot=="" or (slot!="" and slot!=actual_slot):return "この部位には装備できません。"
		slot=actual_slot
		if equipment[slot]!="" and destination=="inventory" and s.inventory.size()-(1 if source=="inventory" else 0)>=15:return "旧装備を戻すバックパックに空きがありません。"
	if destination=="warehouse" and int(args.get("cell",-1))>=0:
		var occupied: String=Storage.uid_at(s,int(args.cell))
		if occupied!="" and (removing or occupied!=uid):return "その倉庫マスは使用中です。空きマスを選んでください。"
	return ""
static func apply(s: Dictionary, args: Dictionary, cfg: Dictionary, removing: bool=false) -> String:
	var error: String=reason(s,args,cfg,removing)
	if error!="":return error
	Storage.ensure_positions(s)
	var actor: String=args.get("actor","hero");var source: String=args.get("source","inventory");var destination: String=args.get("destination",source);var equipment: Dictionary=Party.gear(s,actor)
	var uid: String=args.get("uid","");var slot: String=args.get("slot","") if removing else str(cfg.items[s.items[uid]].slot)
	var old: String=equipment[slot];var target_cell: int=int(args.get("cell",-1))
	if not removing:
		if source=="warehouse" and destination=="warehouse" and target_cell<0:target_cell=Storage.position(s,uid)
		s[source].erase(uid);s.warehouse_positions.erase(uid)
	equipment[slot]="" if removing else uid
	if old!="":
		s[destination].append(old)
		if destination=="warehouse" and target_cell>=0:s.warehouse_positions[old]=target_cell
	Storage.ensure_positions(s);Party.clamp_member(s,cfg,actor);return ""
