extends RefCounted
## User-adopted direction art; v2 actors currently use supplied key poses.
const ASSETS={
	"new.bull":{"texture":preload("res://art_delivery/bull_motion_v1/idle/right_00.png"),"anchor":Vector2(48, 58)},
	"new.cow":{"texture":preload("res://art_delivery/cow_motion_v1/idle/right_00.png"),"anchor":Vector2(40, 58)},
	"new.fossil":{"texture":preload("res://art_delivery/ui_world_direction_v1/candidates/new/fossil.png"),"anchor":Vector2(24, 36)},
	"new.poison_cloud":{"texture":preload("res://art_delivery/ui_world_direction_v1/candidates/new/poison_cloud.png"),"anchor":Vector2(32, 36)},
	"new.poison_projectile":{"texture":preload("res://art_delivery/ui_world_direction_v1/candidates/new/poison_projectile.png"),"anchor":Vector2(16, 12)},
	"new.poison_splash":{"texture":preload("res://art_delivery/ui_world_direction_v1/candidates/new/poison_splash.png"),"anchor":Vector2(24, 28)},
	"portraits.cat":{"texture":preload("res://art_delivery/ui_world_direction_v1/candidates/portraits/cat.png"),"anchor":Vector2(96, 96)},
	"portraits.destroyer":{"texture":preload("res://art_delivery/ui_world_direction_v1/candidates/portraits/destroyer.png"),"anchor":Vector2(96, 96)},
	"portraits.doberman":{"texture":preload("res://art_delivery/ui_world_direction_v1/candidates/portraits/doberman.png"),"anchor":Vector2(96, 96)},
	"portraits.hen":{"texture":preload("res://art_delivery/ui_world_direction_v1/candidates/portraits/hen.png"),"anchor":Vector2(96, 96)},
	"portraits.salaryman":{"texture":preload("res://art_delivery/ui_world_direction_v1/candidates/portraits/salaryman.png"),"anchor":Vector2(96, 96)},
	"portraits.shiba":{"texture":preload("res://art_delivery/ui_world_direction_v1/candidates/portraits/shiba.png"),"anchor":Vector2(96, 96)},
	"ui.rarity_common":{"texture":preload("res://art_delivery/ui_world_direction_v1/candidates/ui/rarity_common.png"),"anchor":Vector2(32, 32)},
	"ui.rarity_epic":{"texture":preload("res://art_delivery/ui_world_direction_v1/candidates/ui/rarity_epic.png"),"anchor":Vector2(32, 32)},
	"ui.rarity_legendary":{"texture":preload("res://art_delivery/ui_world_direction_v1/candidates/ui/rarity_legendary.png"),"anchor":Vector2(32, 32)},
	"ui.rarity_rare":{"texture":preload("res://art_delivery/ui_world_direction_v1/candidates/ui/rarity_rare.png"),"anchor":Vector2(32, 32)},
	"ui.rarity_uncommon":{"texture":preload("res://art_delivery/ui_world_direction_v1/candidates/ui/rarity_uncommon.png"),"anchor":Vector2(32, 32)},
	"ui.ready_aura":{"texture":preload("res://art_delivery/ui_world_direction_v1/candidates/ui/ready_aura.png"),"anchor":Vector2(24, 12)},
	"ui.ready_corners":{"texture":preload("res://art_delivery/ui_world_direction_v1/candidates/ui/ready_corners.png"),"anchor":Vector2(96, 96)},
	"ui.ready_stars":{"texture":preload("res://art_delivery/ui_world_direction_v1/candidates/ui/ready_stars.png"),"anchor":Vector2(12, 12)},
	"ui.skill_bark":{"texture":preload("res://art_delivery/ui_world_direction_v1/candidates/ui/skill_bark.png"),"anchor":Vector2(32, 32)},
	"ui.skill_destruction":{"texture":preload("res://art_delivery/ui_world_direction_v1/candidates/ui/skill_destruction.png"),"anchor":Vector2(32, 32)},
	"ui.skill_reinforcement":{"texture":preload("res://art_delivery/ui_world_direction_v1/candidates/ui/skill_reinforcement.png"),"anchor":Vector2(32, 32)},
	"ui.stamina_lightning":{"texture":preload("res://art_delivery/ui_world_direction_v1/candidates/ui/stamina_lightning.png"),"anchor":Vector2(12, 12)},
	"ui.stamina_shoe":{"texture":preload("res://art_delivery/ui_world_direction_v1/candidates/ui/stamina_shoe.png"),"anchor":Vector2(12, 12)},
	"ui.ultimate_frame":{"texture":preload("res://art_delivery/ui_world_direction_v1/candidates/ui/ultimate_frame.png"),"anchor":Vector2(32, 32)},
	"ui.ultimate_rage":{"texture":preload("res://art_delivery/ui_world_direction_v1/candidates/ui/ultimate_rage.png"),"anchor":Vector2(32, 32)},
	"ui.ultimate_resurrection":{"texture":preload("res://art_delivery/ui_world_direction_v1/candidates/ui/ultimate_resurrection.png"),"anchor":Vector2(32, 32)},
	"world.goldA":{"texture":preload("res://art_delivery/ui_world_direction_v1/candidates/world/goldA.png"),"anchor":Vector2(72, 152)},
	"world.goldB":{"texture":preload("res://art_delivery/ui_world_direction_v1/candidates/world/goldB.png"),"anchor":Vector2(72, 152)},
	"world.tree_a":{"texture":preload("res://art_delivery/ui_world_direction_v1/candidates/world/tree_a.png"),"anchor":Vector2(32, 72)},
	"world.tree_a_canopy":{"texture":preload("res://art_delivery/ui_world_direction_v1/candidates/world/tree_a_canopy.png"),"anchor":Vector2(32, 72)},
	"world.tree_a_trunk":{"texture":preload("res://art_delivery/ui_world_direction_v1/candidates/world/tree_a_trunk.png"),"anchor":Vector2(32, 72)},
	"world.tree_b":{"texture":preload("res://art_delivery/ui_world_direction_v1/candidates/world/tree_b.png"),"anchor":Vector2(32, 72)},
	"world.tree_b_canopy":{"texture":preload("res://art_delivery/ui_world_direction_v1/candidates/world/tree_b_canopy.png"),"anchor":Vector2(32, 72)},
	"world.tree_b_trunk":{"texture":preload("res://art_delivery/ui_world_direction_v1/candidates/world/tree_b_trunk.png"),"anchor":Vector2(32, 72)},
	"world.tree_c":{"texture":preload("res://art_delivery/ui_world_direction_v1/candidates/world/tree_c.png"),"anchor":Vector2(32, 72)},
	"world.tree_c_canopy":{"texture":preload("res://art_delivery/ui_world_direction_v1/candidates/world/tree_c_canopy.png"),"anchor":Vector2(32, 72)},
	"world.tree_c_trunk":{"texture":preload("res://art_delivery/ui_world_direction_v1/candidates/world/tree_c_trunk.png"),"anchor":Vector2(32, 72)},
	"maid.idle":{"texture":preload("res://art_delivery/maid_motion_v1/idle/right_00.png"),"anchor":Vector2(32, 58)},
	"maid.rage":{"texture":preload("res://art_delivery/ui_world_direction_v2/candidates/maid/rage.png"),"anchor":Vector2(32, 58)},
	"maid.chase":{"texture":preload("res://art_delivery/ui_world_direction_v2/candidates/maid/chase.png"),"anchor":Vector2(32, 58)},
	"thief.idle":{"texture":preload("res://art_delivery/thief_motion_v1/idle/right_00.png"),"anchor":Vector2(32, 58)},
	"thief.steal":{"texture":preload("res://art_delivery/ui_world_direction_v2/candidates/thief/steal.png"),"anchor":Vector2(32, 58)},
	"thief.poison_windup":{"texture":preload("res://art_delivery/ui_world_direction_v2/candidates/thief/poison_windup.png"),"anchor":Vector2(32, 58)},
	"dancer.idle":{"texture":preload("res://art_delivery/dancer_motion_v1/idle/right_00.png"),"anchor":Vector2(32, 58)},
	"dancer.fan_raise":{"texture":preload("res://art_delivery/ui_world_direction_v2/candidates/dancer/fan_raise.png"),"anchor":Vector2(32, 58)},
	"dancer.fan_spread":{"texture":preload("res://art_delivery/ui_world_direction_v2/candidates/dancer/fan_spread.png"),"anchor":Vector2(32, 58)},
	"maid.rage_aura":{"texture":preload("res://art_delivery/ui_world_direction_v2/candidates/maid/rage_aura.png"),"anchor":Vector2(32, 58)},
	"kokeshi.idle":{"texture":preload("res://art_delivery/ui_world_direction_v2/candidates/kokeshi/idle.png"),"anchor":Vector2(16, 36)},
}
const ACTORS=["maid","dancer","thief","cow","bull"]

static func actor_key(a: Dictionary) -> String:
	var who=a.get("archetype",a.get("species",""))
	if who in ["cow","bull"]: return "new."+who
	var pose=a.get("action_id","idle")
	var key=who+"."+pose
	return key if ASSETS.has(key) else who+".idle"

static func draw(c: CanvasItem,id: String,foot: Vector2,alpha: float=1.0):
	if not ASSETS.has(id): return
	var row=ASSETS[id]
	c.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	c.draw_texture(row.texture,(foot-row.anchor).round(),Color(1,1,1,alpha))

static func actor(g,c,a: Dictionary,foot: Vector2):
	preload("res://game/six_motion.gd").draw(g,c,a,foot)

static func bounds(g,a: Dictionary,enemy: bool=false) -> Rect2:
	return preload("res://game/six_motion.gd").bounds(g,a,enemy)
