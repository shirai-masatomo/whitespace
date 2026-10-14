extends SceneTree
## Headless CanvasItem calls only: no window, GPU readback or OS input.
const Log=preload("res://game/event_log_view.gd")
class WorldStub extends RefCounted:
 var player_events=[]
class Context extends Node2D:
 const FONT=preload("res://assets/fonts/ui_font.tres")
 var world=WorldStub.new()
 var selected={}
 var event_log_rect=Rect2()
 var event_scroll=0
 var log=Log.new()
 var checks=[]
 var hud:Node2D
 func _ready():hud=self
 func label_on(target,p,text,size,color):target.draw_string(FONT,p,text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)
 func measure(note):
  for i in 10:log.draw(self)
  var initial=Performance.get_monitor(Performance.OBJECT_COUNT)
  for i in 1000:log.draw(self)
  var delta=Performance.get_monitor(Performance.OBJECT_COUNT)-initial
  checks.append({"check":note,"object_delta_after_warmup":delta,"passed":delta==0})
 func _draw():
  measure("Empty log: 1000 draws retain no additional objects")
  world.player_events=[{"tick":0,"text":"牧場主 → 盗賊　4ダメージ"}]
  measure("Populated log: paragraphs and styles are reused for 1000 draws")
  world.player_events[0].text="牧場主：毒 8ダメージ"
  log.draw(self)
  checks.append({"check":"Updated text invalidates cached paragraphs","passed":log.paragraph_key[1][0]==world.player_events[0].text})
  world.player_events.clear();log.draw(self)
  checks.append({"check":"Cleared history removes old paragraphs","passed":log.paragraphs.is_empty()})
  set_process(false)
  get_tree().call_deferred("finish",self)
func _initialize():call_deferred("run")
func run():
 if DisplayServer.get_name()!="headless" or OS.get_environment("FARM_REVIEW_OUTPUT")=="":quit(2);return
 root.add_child(Context.new())
func finish(context):
 var checks=context.checks.duplicate(true)
 context.queue_free();await process_frame
 var failures=checks.filter(func(c):return not c.passed).size()
 FileAccess.open(OS.get_environment("FARM_REVIEW_OUTPUT")+"/log-render-cache.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
 print("LOG_CACHE: ",checks.size()," checks, failures=",failures)
 quit(1 if failures else 0)
