@tool
extends Node2D
## Saved editor positions are authoritative. Runtime motion is an offset, never a rewrite.

@export_enum(
	"algae",
	"orb",
	"relic",
	"air",
	"current",
	"jelly",
	"rock",
	"octopus",
	"goal",
	"bubble",
	"wreck",
	"shrine",
	"chest"
)
var kind := "algae"
@export var extent := Vector2(48, 48)
@export var flow := Vector2.ZERO
@export var travel := Vector2(38, 0)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var color := Color(0.3, 1, 0.7, 0.5)
	if kind in ["rock", "octopus"]:
		color = Color(0.6, 0.4, 0.7, 0.5)
	draw_rect(Rect2(-extent, extent * 2), color, false, 2)
	draw_circle(Vector2.ZERO, 7, color)
	if kind == "current":
		draw_line(Vector2.ZERO, flow, Color.CYAN, 3)
	draw_string(ThemeDB.fallback_font, Vector2(12, -12), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 20)
