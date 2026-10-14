extends RefCounted
## Opt-in capture instrumentation; inert during normal play.
static var enabled=false
static var frame={}
static func start() -> int:return Time.get_ticks_usec() if enabled else 0
static func finish(label: String,started: int):
	if not enabled:return
	frame[label]=frame.get(label,0.0)+(Time.get_ticks_usec()-started)/1000.0
	frame[label+"_count"]=frame.get(label+"_count",0)+1
static func take() -> Dictionary:
	var result=frame;frame={};return result

static func count(label: String,amount: int=1):
	if enabled:frame[label]=frame.get(label,0)+amount
