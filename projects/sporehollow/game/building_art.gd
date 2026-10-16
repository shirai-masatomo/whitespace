extends RefCounted
const BED=preload("res://art_delivery/bed_assets_v1/bed.png")
const FURNITURE_WORLD = {
	"cooking_bench":preload("res://art_delivery/crafting_assets_v1/benches/cooking_bench.png"),
	"carpentry_bench":preload("res://art_delivery/crafting_assets_v1/benches/carpentry_bench.png"),
	"sewing_bench":preload("res://art_delivery/crafting_assets_v1/benches/sewing_bench.png"),
	"wood_crate":preload("res://art_delivery/crafting_assets_v1/placeables/wood_crate.png"),
	"wood_shelf":preload("res://art_delivery/crafting_assets_v1/placeables/wood_shelf.png"),
}
const FURNITURE_UI = {
	"bed":preload("res://art_delivery/bed_assets_v1/bed_ui.png"),
	"cooking_bench":preload("res://art_delivery/crafting_assets_v1/ui_icons/cooking_bench.png"),
	"carpentry_bench":preload("res://art_delivery/crafting_assets_v1/ui_icons/carpentry_bench.png"),
	"sewing_bench":preload("res://art_delivery/crafting_assets_v1/ui_icons/sewing_bench.png"),
	"wood_crate":preload("res://art_delivery/crafting_assets_v1/ui_icons/wood_crate.png"),
	"wood_shelf":preload("res://art_delivery/crafting_assets_v1/ui_icons/wood_shelf.png"),
}
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
	var mask=b.preview_mask if b.has("preview_mask") else wall_mask(game,Vector2i(p/game.TILE))
	var state="damaged" if b.hp<=b.max_hp*0.5 else "normal"
	var mat=material(b.kind)
	var path="wall/%s/wood_mask_%02d.png"%[state,mask] if mat=="wood" else "%s/wall/%s/mask_%02d.png"%[mat,state,mask]
	draw_outer_wall(game,TEXTURES[path],(p-Vector2(24,34)).round(),b.get("tint",Color(1,1,1,0.45 if preview else 1.0)))

static func floor_tile(game,cell: Vector2i):
	var mask=0
	for pair in [[Vector2i.UP,1],[Vector2i.RIGHT,2],[Vector2i.DOWN,4],[Vector2i.LEFT,8]]:
		var p=cell+pair[0]
		if game.world.floors.get(p,{}).get("status")!="ready" and not game.world.Buildings.enclosure(game.world.structures.get(p,{})):mask+=pair[1]
	floor_at(game,cell,game.world.floors[cell].kind,mask)
	var kind=game.world.floors[cell].kind;var path=floor_path(kind)
	var tex=TEXTURES[path+("wood_00.png" if material(kind)=="wood" else "base.png")]
	# The wall mesh's side contact is eight pixels inside its cell. Continue
	# only that strip, not half a floor tile. No north/south overshoot.
	for d in [Vector2i.LEFT,Vector2i.RIGHT]:
		var b=game.world.structures.get(cell+d,{})
		if game.world.floors.get(cell+d,{}).get("status")=="ready":continue
		if not game.world.Buildings.enclosure(b) or b.kind not in game.world.Buildings.WALLS:continue
		var left=d==Vector2i.LEFT
		game.draw_texture_rect_region(tex,Rect2(Vector2(cell)*game.TILE+Vector2(-8 if left else 48,0),Vector2(8,42)),Rect2(Vector2(40 if left else 0,0),Vector2(8,42)))
	# A doorway has its own single-cell threshold. Choose one neighbouring
	# floor deterministically so mixed floors never overpaint each other.
	for d in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
		var door=cell+d;var b=game.world.structures.get(door,{})
		if not game.world.Buildings.enclosure(b) or b.kind not in game.world.Buildings.DOORS or game.world.floors.get(door,{}).get("status")=="ready":continue
		var source=Vector2i(-1,-1)
		for side in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
			if game.world.floors.get(door+side,{}).get("status")=="ready":source=door+side;break
		if source==cell:game.draw_texture_rect_region(tex,Rect2(Vector2(door)*game.TILE,game.TILE),Rect2(Vector2.ZERO,game.TILE))

static func floor_at(game,cell:Vector2i,kind:String,mask:int,tint:Color=Color.WHITE):
	var p=Vector2(cell)*game.TILE;var path=floor_path(kind)
	game.draw_texture(TEXTURES[path+("wood_00.png" if material(kind)=="wood" else "base.png")],p,tint)
	game.draw_texture(TEXTURES[path+"perimeter/mask_%02d.png"%mask],p,tint)

static func boundaries(game):
	for cell in game.world.floors:
		var a=game.world.floors[cell]
		if a.status!="ready":continue
		for pair in [[Vector2i.RIGHT,"e"],[Vector2i.DOWN,"s"]]:
			var b=game.world.floors.get(cell+pair[0],{})
			if b.get("status")=="ready" and b.kind!=a.kind:
				game.draw_texture(TEXTURES[floor_path(a.kind)+"boundary/%s.png"%pair[1]],Vector2(cell)*game.TILE)

static func door_layer(game,p: Vector2,b: Dictionary,layer: String):
	var mask=b.preview_mask if b.has("preview_mask") else wall_mask(game,Vector2i(p/game.TILE))
	var tint=b.get("tint",Color.WHITE)
	var direction="vertical" if int(bool(mask&1))+int(bool(mask&4))>int(bool(mask&2))+int(bool(mask&8)) else "horizontal"
	var root="door/"+direction+"_"
	var at=(p-Vector2(24,34)).round()
	if layer!="leaf":game.draw_texture(TEXTURES[root+layer+".png"],at,tint);return
	var state="open" if b.open else "closed"
	game.draw_texture(TEXTURES[root+"leaf_"+state+("_damaged.png" if b.hp<=b.max_hp*0.5 else "_normal.png")],at,tint)
	if b.kind=="locked_door":game.draw_texture(TEXTURES[root+"lock_"+state+("_broken.png" if b.get("lock_hp",0)<=0 else "_normal.png")],at,tint)
	if b.hp<b.max_hp:game.draw_rect(Rect2(p+Vector2(-18,19),Vector2(36.0*b.hp/b.max_hp,3)),Color("ebc171"))



static func bench(game,p:Vector2,kind:String,tint:Color=Color.WHITE):
	# 48x48 original, anchor(24,44), foot at cell center+(0,21).
	if kind in ["cooking_bench","carpentry_bench","sewing_bench"]:
		game.draw_texture_rect(FURNITURE_WORLD[kind],Rect2((p+Vector2(-24,-25)).round(),Vector2(96,88)),false,tint)
	else:game.draw_texture(FURNITURE_WORLD[kind],(p+Vector2(-24,-23)).round(),tint)

static func placeable(game,p:Vector2,kind:String,tint:Color=Color.WHITE):
	var assets=preload("res://game/direction_art.gd").ASSETS
	if kind in ["kokeshi","fossil"]:
		var row=assets["kokeshi.idle" if kind=="kokeshi" else "new.fossil"]
		game.draw_texture(row.texture,(p+Vector2(0,14)-row.anchor).round(),tint)
	else:bench(game,p,kind,tint)

static func bed(game,p:Vector2,tint:Color=Color.WHITE):
	# Foot at cell top-left+(24,42), texture anchor(24,56); same image for ghosts.
	game.draw_texture(BED,(p+Vector2(-24,-35)).round(),tint)
