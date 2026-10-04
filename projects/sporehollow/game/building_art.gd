extends RefCounted
const TEXTURES = {
	"wall/normal/wood_mask_00.png": preload("res://art_delivery/wood_buildings_v1/wall/normal/wood_mask_00.png"),
	"wall/damaged/wood_mask_00.png": preload("res://art_delivery/wood_buildings_v1/wall/damaged/wood_mask_00.png"),
	"wall/normal/wood_mask_01.png": preload("res://art_delivery/wood_buildings_v1/wall/normal/wood_mask_01.png"),
	"wall/damaged/wood_mask_01.png": preload("res://art_delivery/wood_buildings_v1/wall/damaged/wood_mask_01.png"),
	"wall/normal/wood_mask_02.png": preload("res://art_delivery/wood_buildings_v1/wall/normal/wood_mask_02.png"),
	"wall/damaged/wood_mask_02.png": preload("res://art_delivery/wood_buildings_v1/wall/damaged/wood_mask_02.png"),
	"wall/normal/wood_mask_03.png": preload("res://art_delivery/wood_buildings_v1/wall/normal/wood_mask_03.png"),
	"wall/damaged/wood_mask_03.png": preload("res://art_delivery/wood_buildings_v1/wall/damaged/wood_mask_03.png"),
	"wall/normal/wood_mask_04.png": preload("res://art_delivery/wood_buildings_v1/wall/normal/wood_mask_04.png"),
	"wall/damaged/wood_mask_04.png": preload("res://art_delivery/wood_buildings_v1/wall/damaged/wood_mask_04.png"),
	"wall/normal/wood_mask_05.png": preload("res://art_delivery/wood_buildings_v1/wall/normal/wood_mask_05.png"),
	"wall/damaged/wood_mask_05.png": preload("res://art_delivery/wood_buildings_v1/wall/damaged/wood_mask_05.png"),
	"wall/normal/wood_mask_06.png": preload("res://art_delivery/wood_buildings_v1/wall/normal/wood_mask_06.png"),
	"wall/damaged/wood_mask_06.png": preload("res://art_delivery/wood_buildings_v1/wall/damaged/wood_mask_06.png"),
	"wall/normal/wood_mask_07.png": preload("res://art_delivery/wood_buildings_v1/wall/normal/wood_mask_07.png"),
	"wall/damaged/wood_mask_07.png": preload("res://art_delivery/wood_buildings_v1/wall/damaged/wood_mask_07.png"),
	"wall/normal/wood_mask_08.png": preload("res://art_delivery/wood_buildings_v1/wall/normal/wood_mask_08.png"),
	"wall/damaged/wood_mask_08.png": preload("res://art_delivery/wood_buildings_v1/wall/damaged/wood_mask_08.png"),
	"wall/normal/wood_mask_09.png": preload("res://art_delivery/wood_buildings_v1/wall/normal/wood_mask_09.png"),
	"wall/damaged/wood_mask_09.png": preload("res://art_delivery/wood_buildings_v1/wall/damaged/wood_mask_09.png"),
	"wall/normal/wood_mask_10.png": preload("res://art_delivery/wood_buildings_v1/wall/normal/wood_mask_10.png"),
	"wall/damaged/wood_mask_10.png": preload("res://art_delivery/wood_buildings_v1/wall/damaged/wood_mask_10.png"),
	"wall/normal/wood_mask_11.png": preload("res://art_delivery/wood_buildings_v1/wall/normal/wood_mask_11.png"),
	"wall/damaged/wood_mask_11.png": preload("res://art_delivery/wood_buildings_v1/wall/damaged/wood_mask_11.png"),
	"wall/normal/wood_mask_12.png": preload("res://art_delivery/wood_buildings_v1/wall/normal/wood_mask_12.png"),
	"wall/damaged/wood_mask_12.png": preload("res://art_delivery/wood_buildings_v1/wall/damaged/wood_mask_12.png"),
	"wall/normal/wood_mask_13.png": preload("res://art_delivery/wood_buildings_v1/wall/normal/wood_mask_13.png"),
	"wall/damaged/wood_mask_13.png": preload("res://art_delivery/wood_buildings_v1/wall/damaged/wood_mask_13.png"),
	"wall/normal/wood_mask_14.png": preload("res://art_delivery/wood_buildings_v1/wall/normal/wood_mask_14.png"),
	"wall/damaged/wood_mask_14.png": preload("res://art_delivery/wood_buildings_v1/wall/damaged/wood_mask_14.png"),
	"wall/normal/wood_mask_15.png": preload("res://art_delivery/wood_buildings_v1/wall/normal/wood_mask_15.png"),
	"wall/damaged/wood_mask_15.png": preload("res://art_delivery/wood_buildings_v1/wall/damaged/wood_mask_15.png"),
	"floor/wood_00.png": preload("res://art_delivery/wood_buildings_v1/floor/wood_00.png"),
	"floor/perimeter/mask_00.png": preload("res://art_delivery/wood_buildings_v1/floor/perimeter/mask_00.png"),
	"floor/perimeter/mask_01.png": preload("res://art_delivery/wood_buildings_v1/floor/perimeter/mask_01.png"),
	"floor/perimeter/mask_02.png": preload("res://art_delivery/wood_buildings_v1/floor/perimeter/mask_02.png"),
	"floor/perimeter/mask_03.png": preload("res://art_delivery/wood_buildings_v1/floor/perimeter/mask_03.png"),
	"floor/perimeter/mask_04.png": preload("res://art_delivery/wood_buildings_v1/floor/perimeter/mask_04.png"),
	"floor/perimeter/mask_05.png": preload("res://art_delivery/wood_buildings_v1/floor/perimeter/mask_05.png"),
	"floor/perimeter/mask_06.png": preload("res://art_delivery/wood_buildings_v1/floor/perimeter/mask_06.png"),
	"floor/perimeter/mask_07.png": preload("res://art_delivery/wood_buildings_v1/floor/perimeter/mask_07.png"),
	"floor/perimeter/mask_08.png": preload("res://art_delivery/wood_buildings_v1/floor/perimeter/mask_08.png"),
	"floor/perimeter/mask_09.png": preload("res://art_delivery/wood_buildings_v1/floor/perimeter/mask_09.png"),
	"floor/perimeter/mask_10.png": preload("res://art_delivery/wood_buildings_v1/floor/perimeter/mask_10.png"),
	"floor/perimeter/mask_11.png": preload("res://art_delivery/wood_buildings_v1/floor/perimeter/mask_11.png"),
	"floor/perimeter/mask_12.png": preload("res://art_delivery/wood_buildings_v1/floor/perimeter/mask_12.png"),
	"floor/perimeter/mask_13.png": preload("res://art_delivery/wood_buildings_v1/floor/perimeter/mask_13.png"),
	"floor/perimeter/mask_14.png": preload("res://art_delivery/wood_buildings_v1/floor/perimeter/mask_14.png"),
	"floor/perimeter/mask_15.png": preload("res://art_delivery/wood_buildings_v1/floor/perimeter/mask_15.png"),
	"floor/boundary/n.png": preload("res://art_delivery/wood_buildings_v1/floor/boundary/n.png"),
	"floor/boundary/e.png": preload("res://art_delivery/wood_buildings_v1/floor/boundary/e.png"),
	"floor/boundary/s.png": preload("res://art_delivery/wood_buildings_v1/floor/boundary/s.png"),
	"floor/boundary/w.png": preload("res://art_delivery/wood_buildings_v1/floor/boundary/w.png"),
	"door/horizontal_frame_rear.png": preload("res://art_delivery/wood_buildings_v1/door/horizontal_frame_rear.png"),
	"door/horizontal_frame_front.png": preload("res://art_delivery/wood_buildings_v1/door/horizontal_frame_front.png"),
	"door/horizontal_leaf_closed_normal.png": preload("res://art_delivery/wood_buildings_v1/door/horizontal_leaf_closed_normal.png"),
	"door/horizontal_leaf_closed_damaged.png": preload("res://art_delivery/wood_buildings_v1/door/horizontal_leaf_closed_damaged.png"),
	"door/horizontal_lock_closed_normal.png": preload("res://art_delivery/wood_buildings_v1/door/horizontal_lock_closed_normal.png"),
	"door/horizontal_lock_closed_broken.png": preload("res://art_delivery/wood_buildings_v1/door/horizontal_lock_closed_broken.png"),
	"door/horizontal_leaf_open_normal.png": preload("res://art_delivery/wood_buildings_v1/door/horizontal_leaf_open_normal.png"),
	"door/horizontal_leaf_open_damaged.png": preload("res://art_delivery/wood_buildings_v1/door/horizontal_leaf_open_damaged.png"),
	"door/horizontal_lock_open_normal.png": preload("res://art_delivery/wood_buildings_v1/door/horizontal_lock_open_normal.png"),
	"door/horizontal_lock_open_broken.png": preload("res://art_delivery/wood_buildings_v1/door/horizontal_lock_open_broken.png"),
	"door/vertical_frame_rear.png": preload("res://art_delivery/wood_buildings_v1/door/vertical_frame_rear.png"),
	"door/vertical_frame_front.png": preload("res://art_delivery/wood_buildings_v1/door/vertical_frame_front.png"),
	"door/vertical_leaf_closed_normal.png": preload("res://art_delivery/wood_buildings_v1/door/vertical_leaf_closed_normal.png"),
	"door/vertical_leaf_closed_damaged.png": preload("res://art_delivery/wood_buildings_v1/door/vertical_leaf_closed_damaged.png"),
	"door/vertical_lock_closed_normal.png": preload("res://art_delivery/wood_buildings_v1/door/vertical_lock_closed_normal.png"),
	"door/vertical_lock_closed_broken.png": preload("res://art_delivery/wood_buildings_v1/door/vertical_lock_closed_broken.png"),
	"door/vertical_leaf_open_normal.png": preload("res://art_delivery/wood_buildings_v1/door/vertical_leaf_open_normal.png"),
	"door/vertical_leaf_open_damaged.png": preload("res://art_delivery/wood_buildings_v1/door/vertical_leaf_open_damaged.png"),
	"door/vertical_lock_open_normal.png": preload("res://art_delivery/wood_buildings_v1/door/vertical_lock_open_normal.png"),
	"door/vertical_lock_open_broken.png": preload("res://art_delivery/wood_buildings_v1/door/vertical_lock_open_broken.png"),
}

static func wall_mask(game, cell: Vector2i) -> int:
	var links=game.wall_links(cell)
	return int(links[Vector2i.UP])+2*int(links[Vector2i.RIGHT])+4*int(links[Vector2i.DOWN])+8*int(links[Vector2i.LEFT])

static func wall(game,p: Vector2,b: Dictionary,preview: bool):
	var mask=0 if preview else wall_mask(game,Vector2i(p/game.TILE))
	var state="damaged" if b.hp<=b.max_hp*0.5 else "normal"
	game.draw_texture(TEXTURES["wall/%s/wood_mask_%02d.png"%[state,mask]],(p-Vector2(24,34)).round(),Color(1,1,1,0.45 if preview else 1.0))

static func floor_tile(game,cell: Vector2i):
	var p=Vector2(cell)*game.TILE
	game.draw_texture(TEXTURES["floor/wood_00.png"],p)
	var mask=0
	for pair in [[Vector2i.UP,1],[Vector2i.RIGHT,2],[Vector2i.DOWN,4],[Vector2i.LEFT,8]]:
		if game.world.floors.get(cell+pair[0],{}).get("status")!="ready":mask+=pair[1]
	game.draw_texture(TEXTURES["floor/perimeter/mask_%02d.png"%mask],p)

static func boundaries(game):
	for cell in game.world.floors:
		var a=game.world.floors[cell]
		if a.status!="ready":continue
		for pair in [[Vector2i.RIGHT,"e"],[Vector2i.DOWN,"s"]]:
			var b=game.world.floors.get(cell+pair[0],{})
			if b.get("status")=="ready" and b.kind!=a.kind and "wood_tile" in [a.kind,b.kind]:
				game.draw_texture(TEXTURES["floor/boundary/%s.png"%pair[1]],Vector2(cell)*game.TILE)

static func door_layer(game,p: Vector2,b: Dictionary,layer: String):
	var mask=wall_mask(game,Vector2i(p/game.TILE))
	var direction="vertical" if int(bool(mask&1))+int(bool(mask&4))>int(bool(mask&2))+int(bool(mask&8)) else "horizontal"
	var root="door/"+direction+"_"
	var at=(p-Vector2(24,34)).round()
	if layer!="leaf":game.draw_texture(TEXTURES[root+layer+".png"],at);return
	var state="open" if b.open else "closed"
	game.draw_texture(TEXTURES[root+"leaf_"+state+("_damaged.png" if b.hp<=b.max_hp*0.5 else "_normal.png")],at)
	if b.kind=="locked_door":game.draw_texture(TEXTURES[root+"lock_"+state+("_broken.png" if b.get("lock_hp",0)<=0 else "_normal.png")],at)
	if b.hp<b.max_hp:game.draw_rect(Rect2(p+Vector2(-18,19),Vector2(36.0*b.hp/b.max_hp,3)),Color("ebc171"))
