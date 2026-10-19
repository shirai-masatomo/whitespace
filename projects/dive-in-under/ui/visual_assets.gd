extends RefCounted
## Display-only assets adopted as the current baseline on 2026-10-17.
## Never read by Combat, Expedition or SaveStore. Original filenames are retained.
const ROOT := "res://assets/visual-candidates/v1/"
const FILES := {"cavern":"dive-ordinary-cave-candidate-v2.png", "boss":"dive-boss-gate-cave-candidate-v2.png",
	"hero":"dive-hero-static-candidate-v1.png", "E04":"dive-e04-goblin-static-candidate-v1.png", "B10":"dive-b10-gatekeeper-static-candidate-v1.png",
	"E01":"dive-e01-underground-rat-static-candidate-v2.png","E02":"dive-e02-slime-mold-static-candidate-v1.png",
	"E03":"dive-e03-ironwing-bat-static-candidate-v1.png","E05":"dive-e05-rock-beetle-static-candidate-v1.png",
	"E06":"dive-e06-wet-rock-crab-static-candidate-v1.png","E07":"dive-e07-cave-frog-static-candidate-v1.png",
	"E08":"dive-e08-aquatic-lizard-static-candidate-v1.png"}
static var cache: Dictionary = {}
static var actor_cache: Dictionary = {}
const FEET := {"hero":Vector2(640,1135),"E04":Vector2(565,1156),"B10":Vector2(646,1221),
	"E01":Vector2(800,1013),"E02":Vector2(627,949),"E03":Vector2(520,1030),"E05":Vector2(645,1093),
	"E06":Vector2(460,1078),"E07":Vector2(865,1168),"E08":Vector2(839,1096)}
# Measured alpha>=16 body bounds plus 4px fringe. Atlas crops leave PNG bytes intact.
# Faint, distant alpha specks must not determine the visible body's fit.
const BODY_REGIONS := {"E01":Rect2(16,382,1230,637),"E02":Rect2(24,323,1206,632),
	"E03":Rect2(32,236,1197,799),"E05":Rect2(47,308,1197,791),
	"E06":Rect2(27,269,1212,821),"E07":Rect2(47,390,1192,783),"E08":Rect2(15,223,1215,878)}
const UNAPPROVED := []

static func texture(key: String) -> Texture2D:
	if not FILES.has(key): return null
	if not cache.has(key):
		var path: String = ROOT + FILES[key]
		cache[key] = load(path) if ResourceLoader.exists(path) else null
	return cache[key]

static func actor_texture(key: String) -> Texture2D:
	if actor_cache.has(key): return actor_cache[key]
	var source := texture(key)
	if source == null: return null
	var image := source.get_image()
	if image.is_compressed(): image.decompress()
	var used := image.get_used_rect()
	if used.size == Vector2i.ZERO: return null
	var atlas := AtlasTexture.new()
	atlas.atlas = source
	atlas.region = BODY_REGIONS.get(key,Rect2(used))
	actor_cache[key] = atlas
	return atlas

static func actor_foot(key: String) -> Vector2:
	var atlas := actor_texture(key) as AtlasTexture
	if atlas == null: return Vector2.ZERO
	return FEET.get(key,Vector2.ZERO) - atlas.region.position

static func depth_name(floor_number: int) -> String:
	if floor_number >= 10: return "10F · 門番の広間"
	if floor_number >= 7: return "深層 · 水底の回廊"
	if floor_number >= 4: return "中層 · 青い鉱脈"
	return "浅層 · 灯りの坑道"

static func depth_tint(floor_number: int) -> Color:
	if floor_number >= 10: return Color.WHITE
	if floor_number >= 7: return Color(0.60,0.72,0.83)
	if floor_number >= 4: return Color(0.79,0.93,1.0)
	return Color(1.0,0.96,0.86)

static func background_key(floor_number: int) -> String:
	return "boss" if floor_number >= 10 else "cavern"

static func preview_note(enemy_id: String) -> String:
	var note := "静止素材12点：採用済み"
	if enemy_id == "E01": note += " / ネズミ視点修正版v2"
	if enemy_id in UNAPPROVED: note += " / %s：未採用候補" % enemy_id
	if enemy_id != "" and texture(enemy_id) == null: note += " · この敵は仮表示"
	return note

static func background_texture(value: String) -> Texture2D:
	if FILES.has(value): return texture(value)
	if not cache.has(value): cache[value]=load(value) if ResourceLoader.exists(value) else null
	return cache[value] as Texture2D
