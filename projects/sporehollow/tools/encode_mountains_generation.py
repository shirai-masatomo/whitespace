from pathlib import Path
import sys,json
from PIL import Image
source,out=map(Path,sys.argv[1:3])
info=json.loads((source/'mountains-observations.json').read_text(encoding='utf-8-sig'))
paths=sorted(source.glob('frame_mountains_*.png'))
assert len(paths)==info['frames'] and len(paths)>1
frames=[Image.open(p).convert('RGB') for p in paths]
frames[0].save(out/'mining.webp',save_all=True,append_images=frames[1:],duration=500,loop=0,lossless=True,method=2)
for frame in frames:frame.close()
print('Saved actual-game sequence; each frame represents 0.5 game seconds.')
