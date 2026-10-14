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

# Rebalance adopted roof/side proportions while preserving cell-edge ports and
# the lower foot anchor. One shared 24-vertex mesh, one draw call per layer.
# The wider roof has the same cell-relative thickness on both axes (32x28).
const WALL_SOURCE_X = [0.0,18.0,30.0,48.0]
const WALL_DEST_X = [0.0,8.0,40.0,48.0]
const WALL_SOURCE_Y = [0.0,2.0,16.0,28.0,44.0,68.0]
const WALL_DEST_Y = [0.0,2.0,8.0,36.0,44.0,68.0]
static var wall_mesh: ArrayMesh

static func surface_mesh() -> ArrayMesh:
	if wall_mesh!=null:return wall_mesh
	var vertices=PackedVector2Array();var uv=PackedVector2Array();var indices=PackedInt32Array()
	for y in range(WALL_SOURCE_Y.size()):
		for x in range(WALL_SOURCE_X.size()):
			vertices.append(Vector2(WALL_DEST_X[x],WALL_DEST_Y[y]))
			uv.append(Vector2(WALL_SOURCE_X[x]/48.0,WALL_SOURCE_Y[y]/68.0))
	for y in range(WALL_SOURCE_Y.size()-1):
		for x in range(WALL_SOURCE_X.size()-1):
			var i=y*4+x
			indices.append_array(PackedInt32Array([i,i+1,i+4,i+1,i+5,i+4]))
	var arrays=[];arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_TEX_UV]=uv;arrays[Mesh.ARRAY_INDEX]=indices
	wall_mesh=ArrayMesh.new();wall_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return wall_mesh

static func draw_outer_wall(game,texture: Texture2D,at: Vector2,color: Color):
	game.draw_mesh(surface_mesh(),texture,Transform2D(0,at),color)

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
	if layer!="leaf":draw_outer_wall(game,TEXTURES[root+layer+".png"],at,Color.WHITE);return
	var state="open" if b.open else "closed"
	draw_outer_wall(game,TEXTURES[root+"leaf_"+state+("_damaged.png" if b.hp<=b.max_hp*0.5 else "_normal.png")],at,Color.WHITE)
	if b.kind=="locked_door":draw_outer_wall(game,TEXTURES[root+"lock_"+state+("_broken.png" if b.get("lock_hp",0)<=0 else "_normal.png")],at,Color.WHITE)
	if b.hp<b.max_hp:game.draw_rect(Rect2(p+Vector2(-18,19),Vector2(36.0*b.hp/b.max_hp,3)),Color("ebc171"))


