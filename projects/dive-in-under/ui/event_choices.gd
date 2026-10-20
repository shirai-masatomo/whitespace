extends RefCounted
## Only known, cost-free benefit/leave choices use a direct E/X presentation.
static func simple(event: Dictionary) -> bool:
	if event.choices.size()!=2: return false
	var benefits:=0; var skips:=0
	for choice in event.choices:
		for key in choice:
			if key not in ["id","label","effect","amount","item","result"]: return false
		if choice.effect=="none": skips+=1
		elif choice.effect=="item" or (choice.effect in ["hp","exp"] and int(choice.get("amount",-1))>=0): benefits+=1
		else: return false
	return benefits==1 and skips==1
static func summary(choice: Dictionary, cfg: Dictionary) -> String:
	var effect: String=choice.effect
	if effect=="hp": return "HP %+d（上限まで）"%int(choice.amount)
	if effect=="exp": return "EXP +%d"%int(choice.amount)
	if effect=="item": return "獲得："+cfg.items[choice.item].name
	return "何も受け取らず、その場を離れます。" if effect=="none" else str(choice.get("cost_text","この選択の効果は未対応です。"))
