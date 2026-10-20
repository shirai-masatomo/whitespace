extends RefCounted
## One physical currency, never a second wallet. Mutate transaction copies only.
const Items=preload("res://core/item_instances.gd")
const STACK_MAX=999
const SOURCES=["inventory","cloth","warehouse"]
static func amount(s: Dictionary, source: String="inventory") -> int:
	var total: int=0
	for uid in s.get(source,[]):
		if s.items.get(uid)=="C01": total+=int(s.quantities[uid])
	return total
static func limit(source: String) -> int:
	return 15 if source=="inventory" else (3 if source=="cloth" else 2147483647)
static func room(s: Dictionary, source: String) -> int:
	if source=="warehouse": return 2147483647
	var space: int=maxi(0,limit(source)-s[source].size())*STACK_MAX
	for uid in s[source]:
		if s.items[uid]=="C01": space+=STACK_MAX-int(s.quantities[uid])
	return space
static func credit(s: Dictionary, value: int, source: String="inventory") -> bool:
	if not source in SOURCES or value<0 or room(s,source)<value: return false
	var remaining: int=value
	for uid in s[source]:
		if s.items[uid]!="C01": continue
		var n: int=mini(STACK_MAX-int(s.quantities[uid]),remaining); s.quantities[uid]+=n; remaining-=n
	while remaining>0:
		var n: int=mini(STACK_MAX,remaining); Items.install(s,"C01",Items.roll(s,"C01","currency"),source,n); remaining-=n
	return true
static func pay(s: Dictionary, value: int, source: String="inventory") -> bool:
	if not source in SOURCES or (source=="warehouse" and s.phase!="town") or value<0 or amount(s,source)<value: return false
	var remaining: int=value
	for uid in s[source].duplicate():
		if s.items[uid]!="C01": continue
		var n: int=mini(int(s.quantities[uid]),remaining); s.quantities[uid]-=n; remaining-=n
		if s.quantities[uid]==0: Items.erase(s,uid)
		if remaining==0: break
	return true
static func move(s: Dictionary, uid: String, source: String, destination: String, count: int=-1) -> bool:
	if s.phase!="town" or not source in SOURCES or not destination in SOURCES or source==destination or uid not in s[source] or s.items[uid]!="C01": return false
	var n: int=int(s.quantities[uid]) if count<0 else count
	if n<1 or n>int(s.quantities[uid]) or room(s,destination)<n: return false
	s.quantities[uid]-=n
	if s.quantities[uid]==0: Items.erase(s,uid)
	return credit(s,n,destination)
static func split(s: Dictionary, uid: String, source: String, count: int) -> bool:
	if s.phase!="town" or not source in SOURCES or uid not in s[source] or s.items[uid]!="C01" or s[source].size()>=limit(source): return false
	if count<1 or count>=int(s.quantities[uid]): return false
	s.quantities[uid]-=count; Items.install(s,"C01",Items.roll(s,"C01","split"),source,count); return true
static func combine(s: Dictionary, source: String) -> bool:
	if s.phase!="town" or not source in SOURCES: return false
	var coins: Array=s[source].filter(func(uid):return s.items[uid]=="C01")
	if coins.size()<2: return false
	var changed: bool=false
	for target in coins:
		if not s.items.has(target): continue
		for uid in coins:
			if uid==target or not s.items.has(uid) or int(s.quantities[target])>=STACK_MAX: continue
			# Fill earlier stacks only, never redistribute into a later empty stack.
			if coins.find(uid)<=coins.find(target): continue
			var n: int=mini(STACK_MAX-int(s.quantities[target]),int(s.quantities[uid])); s.quantities[target]+=n; s.quantities[uid]-=n; changed=changed or n>0
			if s.quantities[uid]==0: Items.erase(s,uid)
	return changed
