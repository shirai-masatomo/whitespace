extends RefCounted
## Small player-facing feed, independent of AI/diagnostic logs.
static func name_of(w,a: Dictionary) -> String:
 if a.is_empty() or a==w.keeper:return "牧場主"
 return a.get("name","") if a.get("name","")!="" else w.SPECIES.get(a.get("species",""),{}).get("title",a.get("archetype","仲間"))
static func add(w,text: String,key: String=""):
 if key!="" and w.player_events.any(func(row):return row.key==key and w.tick-row.tick<ceili(3.0/w.DT)):return
 w.player_events.append({"tick":w.tick,"text":text,"key":key})
 while w.player_events.size()>6:w.player_events.pop_front()
static func damage(w,source: Dictionary,target: Dictionary,value: float,action: String):
 if action=="poison":
  var key="poison:"+str(target.get("faction","keeper"))+str(target.get("id",-1))
  for row in w.player_events:
   if row.key==key and w.tick-row.tick<ceili(5.0/w.DT):
    row.total+=value;row.text=name_of(w,target)+"：毒 %dダメージ"%row.total;return
  add(w,name_of(w,target)+"：毒 %dダメージ"%value,key);w.player_events.back().total=value
 else:add(w,name_of(w,source)+" → "+name_of(w,target)+"　%dダメージ"%value)
