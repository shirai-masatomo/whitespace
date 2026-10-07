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
  if candidate(p+d,seed_value,deep) and rank(p+d,seed_value)<rank(p,seed_value):return false
 return true
