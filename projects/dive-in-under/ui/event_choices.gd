extends RefCounted
## Only known, cost-free benefit/leave choices use a direct E/X presentation.
static func simple(event: Dictionary) -> bool:
	if event.choices.size()!=2: return false
	if event.choices[0].has("ops"):
		return event.choices.all(func(c):return c.cost.is_empty()) and event.choices.filter(func(c):return c.ops.is_empty()).size()==1 and event.choices.filter(func(c):return c.ops.size()==1 and c.ops[0].kind in ["hp","exp","item","coin"]).size()==1
	var benefits:=0; var skips:=0
	for choice in event.choices:
		for key in choice:
			if key not in ["id","label","effect","amount","item","result"]: return false
		if choice.effect=="none": skips+=1
		elif choice.effect=="item" or (choice.effect in ["hp","exp"] and int(choice.get("amount",-1))>=0): benefits+=1
		else: return false
	return benefits==1 and skips==1
static func summary(choice: Dictionary, cfg: Dictionary) -> String:
	if choice.has("ops"):
		var lines: Array[String]=[]
		for op in choice.ops:
			if op.kind in ["hp","sp","exp"]:lines.append(op.kind.to_upper()+" %+d"%int(op.amount))
			elif op.kind=="coin":lines.append("コイン %dG"%op.amount)
			elif op.kind=="item":lines.append("獲得："+cfg.items[op.id].name)
			elif op.kind=="chance_item":lines.append("%d%%：%s / 外れは品なし"%[op.chance,cfg.items[op.id].name])
			elif op.kind=="repair":lines.append("選んだ装備を耐久%d回復（上限100）"%op.amount)
		var costs: Array[String]=[]
		for key in choice.cost:
			if key=="hp":costs.append("HP -%d"%choice.cost[key])
			elif key=="sp":costs.append("SP -%d"%choice.cost[key])
			elif key=="coin":costs.append("選択した収納から%dG"%choice.cost[key])
			elif key=="durability":costs.append("非支給装備の耐久-%d"%choice.cost[key])
			elif key=="item":costs.append(cfg.items[choice.cost[key]].name+" ×%d"%choice.cost.amount)
		return (" / ".join(lines) if not lines.is_empty() else "費用も獲得もなし")+(" / 対価："+"・".join(costs) if not costs.is_empty() else "")
	var effect: String=choice.effect
	if effect=="hp": return "HP %+d（上限まで）"%int(choice.amount)
	if effect=="exp": return "EXP +%d"%int(choice.amount)
	if effect=="item": return "獲得："+cfg.items[choice.item].name
	return "何も受け取らず、その場を離れます。" if effect=="none" else str(choice.get("cost_text","この選択の効果は未対応です。"))
