extends RefCounted
const BANDS=[[76,100,1.0],[51,90,1.0],[26,80,0.75],[1,60,0.5],[0,40,0.25]]
const RATES={"idle":2.0,"wander":0.6,"rest":6.0,"move":-1.0,"work":-1.8,"haul":-1.4,"combat":0.0}
const REST_AT=15.0
const RESUME_AT=60.0
const STARVE_GRACE=60.0
const STARVE_DAMAGE_INTERVAL=20.0
const ANIMAL_HUNGER=0.12
const FOOD={
	"mushroom":{"satiety":45},"egg":{"satiety":45},"meat":{"satiety":45},"milk":{"satiety":45},
	"dog_food":{"satiety":45},"hen_food":{"satiety":45},"cat_food":{"satiety":45},
	"roast_mushroom":{"satiety":20},
	"egg_meal":{"satiety":35,"effect":"満ちる活力","regen":1.2,"duration":60.0},
	"roast_meat":{"satiety":40,"effect":"腹持ち","cost":0.9,"duration":60.0},
	"stew":{"satiety":50,"effect":"温かな食事","work":1.1,"duration":90.0}}
# Herbivores browse existing weeds; omnivores can use the original raw supply.
const DIETS={
	"shiba":["dog_food","meat","egg","milk","mushroom","roast_meat","stew"],
	"doberman":["dog_food","meat","egg","milk","mushroom","roast_meat","stew"],
	"cat":["cat_food","meat","egg","milk","roast_meat"],
	"hen":["hen_food","mushroom","weed"],"cow":["hen_food","mushroom","weed"],"bull":["hen_food","mushroom","weed"],
	"bullfrog":["meat","egg","dog_food"],"hedgehog":["mushroom","egg","meat","hen_food"]}
