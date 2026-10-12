"""Encode game-rendered frames only; never generates/repaints art."""
from pathlib import Path
import sys
from PIL import Image
source,out=map(Path,sys.argv[1:3])
for kind in ("mine","clear_tree"):
    paths=sorted(source.glob("frame_"+kind+"_*.png"))
    if len(paths)!=64:raise RuntimeError("Expected exactly 64 actual frames: "+kind)
    frames=[Image.open(path).convert("RGB") for path in paths]
    # Lossless animated WebP keeps crisp pixel edges and dynamic game text.
    frames[0].save(out/(kind+".webp"),save_all=True,append_images=frames[1:],duration=125,loop=0,lossless=True,method=2)
    for frame in frames:frame.close()
print("Encoded two lossless eight-second sequences from 128 game frames")
