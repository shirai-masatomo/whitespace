from pathlib import Path
import sys
from PIL import Image
source,out=map(Path,sys.argv[1:3])
for which in ("center","edge","corner"):
    paths=sorted(source.glob("frame_"+which+"_*.png"))
    assert len(paths)==104,(which,len(paths))
    frames=[Image.open(path).convert("RGB") for path in paths]
    frames[0].save(out/(which+".webp"),save_all=True,append_images=frames[1:],duration=125,loop=0,lossless=True,method=2)
    for frame in frames:frame.close()
print("Encoded three 13-second actual-world sequences")
