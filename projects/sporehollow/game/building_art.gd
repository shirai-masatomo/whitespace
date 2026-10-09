extends RefCounted
const TEXTURES = {
	"soil/floor/base.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/floor/base.png"),
	"soil/wall/normal/mask_00.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/wall/normal/mask_00.png"),
	"soil/wall/damaged/mask_00.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/wall/damaged/mask_00.png"),
	"soil/floor/perimeter/mask_00.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/floor/perimeter/mask_00.png"),
	"soil/wall/normal/mask_01.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/wall/normal/mask_01.png"),
	"soil/wall/damaged/mask_01.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/wall/damaged/mask_01.png"),
	"soil/floor/perimeter/mask_01.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/floor/perimeter/mask_01.png"),
	"soil/wall/normal/mask_02.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/wall/normal/mask_02.png"),
	"soil/wall/damaged/mask_02.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/wall/damaged/mask_02.png"),
	"soil/floor/perimeter/mask_02.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/floor/perimeter/mask_02.png"),
	"soil/wall/normal/mask_03.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/wall/normal/mask_03.png"),
	"soil/wall/damaged/mask_03.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/wall/damaged/mask_03.png"),
	"soil/floor/perimeter/mask_03.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/floor/perimeter/mask_03.png"),
	"soil/wall/normal/mask_04.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/wall/normal/mask_04.png"),
	"soil/wall/damaged/mask_04.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/wall/damaged/mask_04.png"),
	"soil/floor/perimeter/mask_04.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/floor/perimeter/mask_04.png"),
	"soil/wall/normal/mask_05.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/wall/normal/mask_05.png"),
	"soil/wall/damaged/mask_05.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/wall/damaged/mask_05.png"),
	"soil/floor/perimeter/mask_05.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/floor/perimeter/mask_05.png"),
	"soil/wall/normal/mask_06.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/wall/normal/mask_06.png"),
	"soil/wall/damaged/mask_06.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/wall/damaged/mask_06.png"),
	"soil/floor/perimeter/mask_06.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/floor/perimeter/mask_06.png"),
	"soil/wall/normal/mask_07.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/wall/normal/mask_07.png"),
	"soil/wall/damaged/mask_07.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/wall/damaged/mask_07.png"),
	"soil/floor/perimeter/mask_07.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/floor/perimeter/mask_07.png"),
	"soil/wall/normal/mask_08.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/wall/normal/mask_08.png"),
	"soil/wall/damaged/mask_08.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/wall/damaged/mask_08.png"),
	"soil/floor/perimeter/mask_08.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/floor/perimeter/mask_08.png"),
	"soil/wall/normal/mask_09.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/wall/normal/mask_09.png"),
	"soil/wall/damaged/mask_09.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/wall/damaged/mask_09.png"),
	"soil/floor/perimeter/mask_09.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/floor/perimeter/mask_09.png"),
	"soil/wall/normal/mask_10.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/wall/normal/mask_10.png"),
	"soil/wall/damaged/mask_10.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/wall/damaged/mask_10.png"),
	"soil/floor/perimeter/mask_10.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/floor/perimeter/mask_10.png"),
	"soil/wall/normal/mask_11.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/wall/normal/mask_11.png"),
	"soil/wall/damaged/mask_11.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/wall/damaged/mask_11.png"),
	"soil/floor/perimeter/mask_11.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/floor/perimeter/mask_11.png"),
	"soil/wall/normal/mask_12.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/wall/normal/mask_12.png"),
	"soil/wall/damaged/mask_12.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/wall/damaged/mask_12.png"),
	"soil/floor/perimeter/mask_12.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/floor/perimeter/mask_12.png"),
	"soil/wall/normal/mask_13.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/wall/normal/mask_13.png"),
	"soil/wall/damaged/mask_13.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/wall/damaged/mask_13.png"),
	"soil/floor/perimeter/mask_13.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/floor/perimeter/mask_13.png"),
	"soil/wall/normal/mask_14.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/wall/normal/mask_14.png"),
	"soil/wall/damaged/mask_14.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/wall/damaged/mask_14.png"),
	"soil/floor/perimeter/mask_14.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/floor/perimeter/mask_14.png"),
	"soil/wall/normal/mask_15.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/wall/normal/mask_15.png"),
	"soil/wall/damaged/mask_15.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/wall/damaged/mask_15.png"),
	"soil/floor/perimeter/mask_15.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/floor/perimeter/mask_15.png"),
	"soil/floor/boundary/n.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/floor/boundary/n.png"),
	"soil/floor/boundary/e.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/floor/boundary/e.png"),
	"soil/floor/boundary/s.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/floor/boundary/s.png"),
	"soil/floor/boundary/w.png": preload("res://art_delivery/earth_stone_buildings_v1/soil/floor/boundary/w.png"),
	"stone/floor/base.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/floor/base.png"),
	"stone/wall/normal/mask_00.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/wall/normal/mask_00.png"),
	"stone/wall/damaged/mask_00.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/wall/damaged/mask_00.png"),
	"stone/floor/perimeter/mask_00.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/floor/perimeter/mask_00.png"),
	"stone/wall/normal/mask_01.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/wall/normal/mask_01.png"),
	"stone/wall/damaged/mask_01.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/wall/damaged/mask_01.png"),
	"stone/floor/perimeter/mask_01.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/floor/perimeter/mask_01.png"),
	"stone/wall/normal/mask_02.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/wall/normal/mask_02.png"),
	"stone/wall/damaged/mask_02.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/wall/damaged/mask_02.png"),
	"stone/floor/perimeter/mask_02.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/floor/perimeter/mask_02.png"),
	"stone/wall/normal/mask_03.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/wall/normal/mask_03.png"),
	"stone/wall/damaged/mask_03.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/wall/damaged/mask_03.png"),
	"stone/floor/perimeter/mask_03.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/floor/perimeter/mask_03.png"),
	"stone/wall/normal/mask_04.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/wall/normal/mask_04.png"),
	"stone/wall/damaged/mask_04.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/wall/damaged/mask_04.png"),
	"stone/floor/perimeter/mask_04.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/floor/perimeter/mask_04.png"),
	"stone/wall/normal/mask_05.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/wall/normal/mask_05.png"),
	"stone/wall/damaged/mask_05.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/wall/damaged/mask_05.png"),
	"stone/floor/perimeter/mask_05.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/floor/perimeter/mask_05.png"),
	"stone/wall/normal/mask_06.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/wall/normal/mask_06.png"),
	"stone/wall/damaged/mask_06.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/wall/damaged/mask_06.png"),
	"stone/floor/perimeter/mask_06.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/floor/perimeter/mask_06.png"),
	"stone/wall/normal/mask_07.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/wall/normal/mask_07.png"),
	"stone/wall/damaged/mask_07.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/wall/damaged/mask_07.png"),
	"stone/floor/perimeter/mask_07.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/floor/perimeter/mask_07.png"),
	"stone/wall/normal/mask_08.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/wall/normal/mask_08.png"),
	"stone/wall/damaged/mask_08.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/wall/damaged/mask_08.png"),
	"stone/floor/perimeter/mask_08.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/floor/perimeter/mask_08.png"),
	"stone/wall/normal/mask_09.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/wall/normal/mask_09.png"),
	"stone/wall/damaged/mask_09.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/wall/damaged/mask_09.png"),
	"stone/floor/perimeter/mask_09.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/floor/perimeter/mask_09.png"),
	"stone/wall/normal/mask_10.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/wall/normal/mask_10.png"),
	"stone/wall/damaged/mask_10.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/wall/damaged/mask_10.png"),
	"stone/floor/perimeter/mask_10.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/floor/perimeter/mask_10.png"),
	"stone/wall/normal/mask_11.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/wall/normal/mask_11.png"),
	"stone/wall/damaged/mask_11.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/wall/damaged/mask_11.png"),
	"stone/floor/perimeter/mask_11.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/floor/perimeter/mask_11.png"),
	"stone/wall/normal/mask_12.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/wall/normal/mask_12.png"),
	"stone/wall/damaged/mask_12.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/wall/damaged/mask_12.png"),
	"stone/floor/perimeter/mask_12.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/floor/perimeter/mask_12.png"),
	"stone/wall/normal/mask_13.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/wall/normal/mask_13.png"),
	"stone/wall/damaged/mask_13.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/wall/damaged/mask_13.png"),
	"stone/floor/perimeter/mask_13.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/floor/perimeter/mask_13.png"),
	"stone/wall/normal/mask_14.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/wall/normal/mask_14.png"),
	"stone/wall/damaged/mask_14.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/wall/damaged/mask_14.png"),
	"stone/floor/perimeter/mask_14.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/floor/perimeter/mask_14.png"),
	"stone/wall/normal/mask_15.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/wall/normal/mask_15.png"),
	"stone/wall/damaged/mask_15.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/wall/damaged/mask_15.png"),
	"stone/floor/perimeter/mask_15.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/floor/perimeter/mask_15.png"),
	"stone/floor/boundary/n.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/floor/boundary/n.png"),
	"stone/floor/boundary/e.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/floor/boundary/e.png"),
	"stone/floor/boundary/s.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/floor/boundary/s.png"),
	"stone/floor/boundary/w.png": preload("res://art_delivery/earth_stone_buildings_v1/stone/floor/boundary/w.png"),
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

static func material(kind: String) -> String:
	return "wood" if kind.begins_with("wood") else "stone" if kind.begins_with("stone") else "soil"

static func floor_path(kind: String) -> String:
	var mat=material(kind)
	return "floor/" if mat=="wood" else mat+"/floor/"

static var floor_signature=0
static var floor_regions: Array[Rect2]=[]
static var wall_offsets: Dictionary={}
static var door_points: Array[Vector2]=[]

static func refresh_wall_regions(game):
	var signature=hash([game.world.get_instance_id(),game.world.floors,game.world.structures])
	if signature==floor_signature:return
	floor_signature=signature;floor_regions.clear();wall_offsets.clear();door_points.clear()
	for cell in game.world.structures:
		var b=game.world.structures[cell]
		if b.get("status")=="ready" and b.kind in ["door","locked_door"]:door_points.append(game.center(cell))
	var pending={}
	for cell in game.world.floors:
		if game.world.floors[cell].get("status")=="ready":pending[cell]=true
	while not pending.is_empty():
		var seed=pending.keys()[0];var queue=[seed];pending.erase(seed)
		var region=Rect2(Vector2(seed)*game.TILE,game.TILE)
		while not queue.is_empty():
			var cell=queue.pop_back()
			region=region.merge(Rect2(Vector2(cell)*game.TILE,game.TILE))
			for d in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
				if pending.has(cell+d):pending.erase(cell+d);queue.append(cell+d)
		floor_regions.append(region)

static func wall_outer_offset(game,point: Vector2) -> Vector2:
	# Draw-only: retain straight edges along each connected floor region.
	if wall_offsets.has(point):return wall_offsets[point]
	var nearest=72.0;var offset=Vector2.ZERO
	for region in floor_regions:
		var delta=point-point.clamp(region.position,region.end)
		var distance=delta.length()
		if distance>0 and distance<nearest:
			nearest=distance;offset=delta.normalized()*minf(9.0,distance*0.5)*clampf((72.0-distance)/24.0,0,1)
	for door in door_points:offset*=clampf((point.distance_to(door)-36.0)/48.0,0,1)
	wall_offsets[point]=offset
	return offset

static func draw_outer_wall(game,texture: Texture2D,at: Vector2,color: Color):
	# Shared pixel coordinates on tile edges; fixed 48x42 board proportions.
	refresh_wall_regions(game)
	var size=texture.get_size()
	for y in range(0,int(size.y),7):
		for x in range(0,int(size.x),8):
			var a=Vector2(x,y);var b=Vector2(minf(x+8,size.x),minf(y+7,size.y))
			var uv=PackedVector2Array([a,Vector2(b.x,a.y),b,Vector2(a.x,b.y)])
			var points=PackedVector2Array()
			for i in range(4):
				var point=at+uv[i]
				points.append((point+wall_outer_offset(game,point)).round())
				uv[i]/=size
			game.draw_polygon(points,PackedColorArray([color]),uv,texture)

static func wall(game,p: Vector2,b: Dictionary,preview: bool):
	var mask=0 if preview else wall_mask(game,Vector2i(p/game.TILE))
	var state="damaged" if b.hp<=b.max_hp*0.5 else "normal"
	var mat=material(b.kind)
	var path="wall/%s/wood_mask_%02d.png"%[state,mask] if mat=="wood" else "%s/wall/%s/mask_%02d.png"%[mat,state,mask]
	draw_outer_wall(game,TEXTURES[path],(p-Vector2(24,34)).round(),Color(1,1,1,0.45 if preview else 1.0))

static func floor_tile(game,cell: Vector2i):
	var p=Vector2(cell)*game.TILE
	var kind=game.world.floors[cell].kind
	var path=floor_path(kind)
	game.draw_texture(TEXTURES[path+("wood_00.png" if material(kind)=="wood" else "base.png")],p)
	var mask=0
	for pair in [[Vector2i.UP,1],[Vector2i.RIGHT,2],[Vector2i.DOWN,4],[Vector2i.LEFT,8]]:
		if game.world.floors.get(cell+pair[0],{}).get("status")!="ready":mask+=pair[1]
	game.draw_texture(TEXTURES[path+"perimeter/mask_%02d.png"%mask],p)

static func boundaries(game):
	for cell in game.world.floors:
		var a=game.world.floors[cell]
		if a.status!="ready":continue
		for pair in [[Vector2i.RIGHT,"e"],[Vector2i.DOWN,"s"]]:
			var b=game.world.floors.get(cell+pair[0],{})
			if b.get("status")=="ready" and b.kind!=a.kind:
				game.draw_texture(TEXTURES[floor_path(a.kind)+"boundary/%s.png"%pair[1]],Vector2(cell)*game.TILE)

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


