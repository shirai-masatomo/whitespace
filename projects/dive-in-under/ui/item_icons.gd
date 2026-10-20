extends RefCounted
## Small original pixel icons, separate from scenery, frames and live text.
static var cache: Dictionary={}
static func texture(kind: String) -> Texture2D:
	if cache.has(kind): return cache[kind]
	var im:=Image.create(32,32,false,Image.FORMAT_RGBA8)
	var palette: Dictionary={"o":Color("151511"),"s":Color("5c3d29"),"m":Color("94673d"),"l":Color("c8a171"),"h":Color("ead3a0"),"g":Color("dbab47"),"b":Color("4f9ca7"),"t":Color("293943"),"v":Color("8c65ac")}
	var pixels: Array=[]
	match kind:
		"shield": pixels=["       ggggg       ","    gggbbbbbggg    ","  ggbbbbbbbbbbbgg  ","  gbttttgttttttbg  ","  gbttttgttttttbg  ","  gbttttgttttttbg  ","  gbgggggggggggbg  ","  gbttttgttttttbg  ","   gbtttgtttttbg   ","    gbttgttttbg    ","     gbtttttbg     ","      gbtttbg      ","       gbbbg       ","        ggg        "]
		"coin": pixels=["       ooooooo       ","     oogggggggoo     ","    ogghhhhhggggo    ","   ogghgggggggmgo   ","   ogghggghgggmgo   ","   ogghgghhgggmgo   ","   ogghggghgggmgo   ","   ogghggghgggmgo   ","   oggggghhhggmgo   ","   oggggggggggmgo   ","    oggmmmmmmggo    ","     oogggggggoo     ","       ooooooo       "]
		"head": pixels=["       oooooooo       ","     oossmmmmssoo     ","    osmmlllllmmso     ","   osmmllhhlllmmso    ","   osmmlllllllmmso    ","  oosssssssssssssoo   "," oommllllllllllmmoo   ","  oooooooooooooooo    "]
		"body": pixels=["     ooo     ooo     ","   oosmsooooosmsoo   ","  osmmlmssssmlmmso   "," osmmmlmmllmmlmmmso  "," osmmmlmmllmmlmmmso  ","  ooomlmmllmmlmooo   ","    omlmmllmmlmo     ","    omlmmllmmlmo     ","    osssssssssso     ","     oooooooooo      "]
		"legs": pixels=["    oooooooooooo    ","    osmllllllmso    ","    osmmllllmmso    ","    osmmmssmmmso    ","    osmmooommmso    ","    osmmsoosmmso    ","    osmmsoosmmso    ","    ollmsoosmlho    ","    oooo  oooooo    "]
		"feet": pixels=["     ooooo   ooooo   ","     osmmo   osmmo   ","     osllo   osllo   ","    ossmmo  ossmmo   ","   osmmmmo osmmmmo   ","  oslllllo oslllllo  ","  osssssso osssssso  ","   oooooo   oooooo   "]
		"finger": pixels=["       ooooooo       ","     oogghhgggoo     ","    oggooooooogggo   ","   oggo       oggo   ","   oglo       oglo   ","   oglo       oglo   ","    oglo     oggo    ","     oogggggggoo     ","       ooooooo       "]
		"wrist": pixels=["       oooooooo      ","     oollhhhhlloo    ","    ollooosssoollo   ","   ollo       osllo  ","   ollo       osllo  ","   ollo       osllo  ","    ollossssosllo    ","     oollllllloo     ","       oooooooo      "]
		"neck": pixels=["   oo           oo  ","   ogo         ogo  ","    ogo       ogo   ","     ogo     ogo    ","      ogooooogo     ","       oggggo       ","        oggo        ","       ogbbgo       ","      ogbhbbgo      ","       ogbbgo       ","        oooo        "]
		"ears": pixels=["     oooo    oooo    ","    oghgo   oghgo    ","     ogo     ogo     ","     ogo     ogo     ","    ogbgo   ogbgo    ","   ogbhbgo ogbhbgo   ","    ogbgo   ogbgo    ","     ooo     ooo     "]
		"eyes": pixels=["       ooooooo       ","     oollhhhhlloo    ","    ollbbbbbbbllo    ","   ollbbhhbbbbbslo   ","   olbbhhbbbbbbblo   ","   olbbbbbbbbbbblo   ","    olbbbbbbbbllo    ","     oollbbllloo     ","       ooollo       ","         ollo       ","          ollo      "]
		"cloth": pixels=["        oo  oo       ","       ovvoovvo      ","        ovvvvo       ","      oovvvvvvoo     ","    oovvvhlvvvvvoo   ","   ovvvvhlvvvvvvvvo  ","  ovvvvhlvvvvvvvvvo  ","  ovvvvhlvvvvvvvvvo  ","   ovvvllllllllvvo   ","    oovvvvvvvvvoo    ","      ooooooooo      "]
		"warehouse": pixels=["    ooooooooooooo    ","   osmmmmmmmmmmmsso  ","  osmllllllmmmmmmso  ","  osssssssssssssso  ","  oggggggggggggggo  ","  osmmmgggggmmmmso  ","  osmmmghhggmmmmso  ","  osmmmggoggmmmmso  ","  osmmmmgggmmmmmso  ","  osssssssssssssso  ","   oooooooooooooo   "]
		"lantern": pixels=["       ooooooo       ","       ogggggo       ","      ogooooogo      ","       ogggggo       ","      ogghhggo       ","     ogghhhhggo      ","     oghhhhhggo      ","     ogghhhhggo      ","     oggggggggo      ","      oggggggo       ","       oooooo        "]
		_: pixels=["        oooo         ","      oolhhloo       ","     olhhhhlllo      ","    olhhllmmmllo     ","   olhhllmmmmslo     ","   olllmmmmssmso     ","    ommmmssmsso      ","     ossssmsoo       ","       oooooo        "]
	for y in pixels.size():
		var row: String=pixels[y]
		for x in row.length():
			if palette.has(row[x]):
				# Doubled vertical pixel pitch makes the compact patterns substantial.
				im.fill_rect(Rect2i(4+x,5+y*2,1,2),palette[row[x]])
	var result:=ImageTexture.create_from_image(im); cache[kind]=result
	return result
