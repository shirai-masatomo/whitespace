extends Control
## Original pixel placeholders; not approved final character assets.
var enemy_id := "E04"
var hero_alive := true
var enemy_alive := true
const PALETTE := {"o":"17242b","h":"324553","b":"766047","g":"b4a17b","s":"dfb282","e":"f6d578",
	"t":"486878","m":"6d917a","l":"9ab494","r":"c27a53","a":"c6d0c5","w":"ece9c8"}
const HERO := [
	"       ooooo      ","     oohhhhhoo    ","    ohhhtthhho   ","   ohhhoosssoho  ",
	"   ohhoossesooho ","    ooossssooho  ","    ohhoooohhho  ","   ohhhggbhhho   ",
	"  ohhtggbgbhhho  "," ohtthbggbhhhho  ","ohtthbbgbbhsso   "," ohtobbgbbbbho   ",
	"  oobbbbgbbbho   ","  oobggggggbho   ","   obbbobbbbho   ","  oabbooobbbho   ",
	" oawobbo obbo    ","oaw obbo obbo    ","ow  obgo obgo    ","    obbo obbo    ",
	"    oggo oggo    ","    obbo obbo    ","   obbbo obbbo   ","   ooooo ooooo   "]
const GOBLIN := [
	"    oo     oo    ","   ommooooommo   ","  ommmmmmmmmmo   "," ommllmmmmllmmo  ",
	"  ommemmmmemmo   ","   ommmommmmo    ","    omwwwwmo     ","   ooboooboo     ",
	"  ommbbbbmmmo    "," ommmbbbbmmmmo   ","ommoobbbboommo   "," oo obbbbo oo    ",
	"    oggggo       ","   obboobbo      ","   ommoommo      ","  ommmoommmo     ","  ooooo ooooo    "]
const SLIME := [
	"       oooo       ","     ootttttoo    ","    ottttttttto   ","   ottttttttttto  ",
	"  ottwtttttwtttto "," ottttottttottttto","otttttttttttttttto","ottttttooottttttto"," oooooooooooooooo "]
const RAT := [
	"  ooo      ooo     "," ommmo    ommmo    "," ommmooooommmmo    ","  ommmmmmmmmmo     ",
	" ommmemmmmmemmo    "," ommmmmmmmmmmmo    ","  ommmrrrmmmmo     ","   ommwwmmmmo      ",
	"  ommmmmmmmmmo     "," ommmmmmmmmmmmo    ","ommmmmmmmmmmmmmo   ","ommmmooooommmmmoooo",
	" ommo     ommo     "," oooo     oooo     "]
const BAT := [
	"o                 o","oo      o o      oo","oto    oomoo    oto","otto  ommmmmo  otto",
	"otttoommeemmoottto","otttttmmmmmmttttto"," ottttommmmotttto ","  oto owwwo oto   ","   o   ooo   o    "]
const BEETLE := [
	"  oo          oo   ","  omoo      oommo  ","   omooooooooomo   ","   oohhgggghhoo    ",
	"  ohhgggggggghho   "," ohhgggggggggghho  ","ohhhgggoggogghhho  ","ohhhgggoggogghhho  ",
	" ohhhggoggoghhho   ","  ohhgggggghho     "," oommoeeeoommoo    ","ommo oooo  ommmo   ","oo          ooo    "]
const STATUE := [
	"     oooooooo     ","    oaggggggao    ","    oggoooggao    ","    oggeogeggo    ",
	"    ogggoogggo    ","     ogwwggo      ","   ooaggggaoo     "," ooaaggggggaaoo   ",
	"oaaggggggggggaao  ","oggaaggggggaaggo  ","oggoaggggggaoggo  ","oggoaggggggaoggo  ",
	"ooooaggggggaoooo  ","   oaggggggao     ","   oaggooaggo     ","   oaggooaggo     ",
	"   ogggoogggo     ","  oagggoogggao    ","  ooooo oooooo    "]

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	custom_minimum_size.y = 220
	resized.connect(queue_redraw)

func sprite(pattern: Array, origin: Vector2, pixel: int, _alive: bool) -> void:
	for y in range(pattern.size()):
		for x in range(pattern[y].length()):
			var key: String = pattern[y][x]
			if PALETTE.has(key):
				var color := Color(PALETTE[key])
				draw_rect(Rect2(origin+Vector2(x,y)*pixel,Vector2.ONE*pixel),color)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("0c222b"))
	for x in range(0,int(size.x),24):
		var height := 20 + (x * 7 % 47)
		draw_rect(Rect2(x,0,24,height),Color("153b45"))
		draw_rect(Rect2(x+6,height,12,12),Color("153b45"))
	for x in range(int(size.x*0.42),int(size.x*0.56),8):
		draw_rect(Rect2(x,0,6,size.y-32),Color("255563"))
		for y in range(15,int(size.y-32),29):
			draw_rect(Rect2(x+2,y+x%17,2,12),Color("4c8890"))
	for x in range(0,int(size.x),32):
		draw_rect(Rect2(x,size.y-35,30,5),Color("687260"))
		draw_rect(Rect2(x+2,size.y-30,28,30),Color("243f44"))
		draw_rect(Rect2(x+5,size.y-25,18,3),Color("34555b"))
	for x in [16.0,size.x-30]:
		draw_rect(Rect2(x+5,42,3,47),Color("80663b"))
		draw_rect(Rect2(x,86,16,25),Color("b67b3d"))
		draw_rect(Rect2(x+4,90,8,17),Color("ffdb7b"))
	var patterns := {"E01":RAT,"E02":SLIME,"E03":BAT,"E04":GOBLIN,"E05":BEETLE,"B10":STATUE}
	var pattern: Array = patterns.get(enemy_id,GOBLIN)
	if enemy_id!="": sprite(pattern,Vector2(size.x*0.17,size.y-35-pattern.size()*5),5,enemy_alive)
	sprite(HERO,Vector2(size.x*0.72,size.y-35-HERO.size()*5),5,hero_alive)
