extends RefCounted
## The existing full-day Shiba convalescence now shows gradual healing; eligibility is unchanged.
static func protected(w,a) -> bool:
	return a.get("species","")=="shiba" and w.campaign.day<=a.get("unavailable_through_day",0)

static func step(w,a) -> bool:
	if a.species!="shiba" or a.get("dead",false) or a.get("lost",false):return false
	if w.campaign.day>a.unavailable_through_day:
		a.convalescent_ticks=0;return false
	a.rescuing=false
	a.state="気絶" if a.hp<=0 else "療養中"
	if w.paused or a.get("convalescent_at",-1)==w.tick:return true
	a.convalescent_at=w.tick
	var limit=maxi(1,w.AnimalData.stats(a.species,a.lv).hp/2)
	if a.hp>=limit:a.convalescent_ticks=0;return true
	a.convalescent_ticks=a.get("convalescent_ticks",0)+1
	if a.convalescent_ticks>=ceili(w.Rules.REST.seconds/w.DT):
		a.hp=mini(limit,a.hp+1);a.convalescent_ticks=0
	return true
