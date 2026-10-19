extends RefCounted
## All inventory/equipment gestures resolve to the same revision-checked core actions.
const E=preload("res://core/expedition.gd")
static func reason(game: Control, payload: Variant, destination: String, target_slot: String="") -> String:
	if not payload is Dictionary or payload.get("kind")!="equipment-item": return "移動できるアイテムを選んでください。"
	var s: Dictionary=game.campaign
	if int(payload.get("revision",-1))!=int(s.revision): return "表示が更新されました。もう一度選んでください。"
	if s.phase not in ["town","explore","reward","event","event_result","treasure"]: return "戦闘中は装備を変更できません。"
	var source: String=payload.source; var uid: String=payload.uid
	if destination=="inventory":
		if source!="equipment" or s.equipment.get(payload.slot,"")!=uid: return "装備枠からバックパックへ移してください。"
		return "バックパックに空きがありません" if s.inventory.size()>=15 else ""
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
	if destination=="inventory": game.perform("unequip",{"slot":payload.slot},int(payload.revision))
	elif payload.source=="pending": game.perform("equip_reward",{"token":payload.uid,"slot":slot} if slot!="" else {"token":payload.uid},int(payload.revision))
	else: game.perform("equip",{"uid":payload.uid,"slot":slot} if slot!="" else {"uid":payload.uid},int(payload.revision))
static func payload(game: Control, source: String, uid: String, slot: String="") -> Dictionary:
	return {"kind":"equipment-item","source":source,"uid":uid,"slot":slot,"revision":int(game.campaign.revision)}
