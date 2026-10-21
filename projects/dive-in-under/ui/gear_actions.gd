extends RefCounted
## All inventory/equipment gestures resolve to the same revision-checked core actions.
const E=preload("res://core/expedition.gd")
static func reason(game: Control, payload: Variant, destination: String, target_slot: String="") -> String:
	if not payload is Dictionary or payload.get("kind")!="equipment-item": return "移動できるアイテムを選んでください。"
	var s: Dictionary=game.campaign
	if int(payload.get("revision",-1))!=int(s.revision): return "表示が更新されました。もう一度選んでください。"
	if s.phase not in ["town","explore","reward","event","event_result","treasure","portal","portal_done"]: return "戦闘中は装備を変更できません。"
	var source: String=payload.source; var uid: String=payload.uid
	if destination in ["inventory","warehouse"] and source=="equipment":
		if preload("res://core/party_ui.gd").gear(s,payload.get("actor","hero")).get(payload.slot,"")!=uid:return "装備が変更されました。"
		return preload("res://core/gear_transfer.gd").reason(s,{"actor":payload.get("actor","hero"),"slot":payload.slot,"source":"inventory","destination":destination},game.cfg,true)
	if source in ["inventory","warehouse"] and destination=="equipment":
		return preload("res://core/gear_transfer.gd").reason(s,{"actor":payload.get("actor","hero"),"uid":uid,"source":source,"destination":source,"slot":target_slot},game.cfg)
	if destination!="equipment": return "装備枠またはバックパックへ移してください。"
	var template: String=""
	if source=="inventory" and uid in s.inventory: template=s.items[uid]
	elif source=="pending" and s.phase=="reward":
		var i: int=E.Journey.reward_index(s,uid)
		if i>=0: template=s.pending_rewards[i].id
	if template=="": return "この場所からは移動できません。"
	var slot: String=game.cfg.items[template].slot
	if slot=="" or (target_slot!="" and target_slot!=slot): return "この部位には装備できません。"
	if source=="pending" and s.equipment[slot]!="" and s.inventory.size()>=15: return "外す装備のため、バックパックに1枠必要です。"
	return ""
static func apply(game: Control, payload: Dictionary, destination: String, slot: String="") -> void:
	var error: String=reason(game,payload,destination,slot)
	if error!="": game.notice=error; game.show_campaign(); return
	var args: Dictionary={"actor":payload.get("actor","hero"),"source":payload.source,"uid":payload.uid,"slot":slot}
	if payload.source=="equipment":args.slot=payload.slot;args.source="inventory";args.destination=destination;game.perform("unequip",args,int(payload.revision))
	elif payload.source=="pending":game.perform("equip_reward",{"token":payload.uid,"slot":slot} if slot!="" else {"token":payload.uid},int(payload.revision))
	else:game.perform("equip",args,int(payload.revision))
static func payload(game: Control, source: String, uid: String, slot: String="", actor: String="hero") -> Dictionary:
	return {"actor":actor,"kind":"equipment-item","source":source,"uid":uid,"slot":slot,"revision":int(game.campaign.revision)}

static func compared_hero(game: Control, source: String, uid: String) -> Dictionary:
	var preview: Dictionary=game.campaign.duplicate(true)
	if source=="pending":
		var index: int=E.Journey.reward_index(preview,uid)
		if index>=0:
			var template: String=preview.pending_rewards[index].id; var slot: String=game.cfg.items[template].slot
			if slot!="":
				if preview.has("item_details"): preview.item_details["comparison-only"]=preview.pending_rewards[index].profile.duplicate(true)
				preview.items["comparison-only"]=template; preview.item_condition["comparison-only"]=E.Condition.fresh(); preview.equipment[slot]="comparison-only"
	elif uid in preview.inventory:
		var slot: String=game.cfg.items[preview.items[uid]].slot
		if slot!="": preview.equipment[slot]=uid
	return E.hero(preview,game.cfg)
