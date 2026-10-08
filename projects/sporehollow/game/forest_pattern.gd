extends RefCounted
static var cache={}
static func noise(seed_value: int) -> FastNoiseLite:
 if not cache.has(seed_value):
  var n=FastNoiseLite.new();n.seed=seed_value;n.frequency=0.16;n.fractal_octaves=2;cache[seed_value]=n
 return cache[seed_value]
static func rank(p: Vector2i,seed_value: int) -> int:
 return posmod(hash(str(seed_value)+":"+str(p.x)+":"+str(p.y)),100000)
static func candidate(p: Vector2i,seed_value: int,deep: bool) -> bool:
 var n=noise(seed_value).get_noise_2d(p.x,p.y)
 return n>(-0.32 if deep else -0.08) and rank(p,seed_value)%100<(72 if deep else 58)
static func tree(p: Vector2i,seed_value: int,deep: bool=false) -> bool:
 if not candidate(p,seed_value,deep):return false
 for d in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
  var neighbor=p+d;var other=rank(neighbor,seed_value);var own=rank(p,seed_value)
  if candidate(neighbor,seed_value,deep) and (other<own or (other==own and (neighbor.y<p.y or neighbor.y==p.y and neighbor.x<p.x))):return false
 return true

static func outer_tree(p: Vector2i,seed_value: int,width: int,height: int) -> bool:
 if p.x>=1 and p.x<width-1 and p.y>=1 and p.y<height-1:return false
 # Visual forest only; retain every physical entry lane and the existing inner forest.
 if p.x in [5,12,19] or p.y in [5,8,11]:return false
 return tree(p,seed_value,true) or (rank(p,seed_value+7919)%100<50 and tree(p+Vector2i.LEFT,seed_value,true))
