extends RefCounted
# Balance values are provisional; engine, UI and bills all read these rows.
const BENCHES={"cooking_bench":"調理台","carpentry_bench":"木工作業台","sewing_bench":"裁縫台"}
const RECIPES={
	"roast_mushroom":{"bench":"cooking_bench","ingredients":{"mushroom":2},"output":"roast_mushroom","count":1,"seconds":5.0},
	"egg_meal":{"bench":"cooking_bench","ingredients":{"egg":2,"milk":1},"output":"egg_meal","count":1,"seconds":7.0},
	"roast_meat":{"bench":"cooking_bench","ingredients":{"meat":2},"output":"roast_meat","count":1,"seconds":6.0},
	"stew":{"bench":"cooking_bench","ingredients":{"meat":1,"mushroom":2},"output":"stew","count":1,"seconds":9.0},
	"wood_crate":{"bench":"carpentry_bench","ingredients":{"wood":5},"output":"wood_crate","count":1,"seconds":6.0},
	"wood_shelf":{"bench":"carpentry_bench","ingredients":{"wood":6},"output":"wood_shelf","count":1,"seconds":8.0},
	"fiber_clothes":{"bench":"sewing_bench","ingredients":{"fiber":6},"output":"fiber_clothes","count":1,"seconds":8.0}}
