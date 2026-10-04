from pathlib import Path
from PIL import Image
import json,hashlib
R=Path(__file__).resolve().parents[2]
for name in ["wood_room_preview_v1","kidnapper_preview_v1"]:
 d=R/"art_delivery"/name;m=json.loads((d/"manifest.json").read_text(encoding="utf8"))
 for r in m["assets"]:
  p=d/r["file"];im=Image.open(p)
  assert list(im.size)==r["canvas_size_px"] and im.mode=="RGBA"
  assert hashlib.sha256(p.read_bytes()).hexdigest()==r["sha256"]
  assert set(im.getchannel("A").getdata())<={0,255}
floor=Image.open(R/"art_delivery/wood_room_preview_v1/floor/wood_00.png")
assert set(floor.getchannel("A").getdata())=={255}
doors=R/"art_delivery/wood_room_preview_v1/door"
im=Image.open(doors/"frame_horizontal.png");im.alpha_composite(Image.open(doors/"leaf_horizontal_open.png"))
assert im.crop((13,23,42,50)).getchannel("A").getbbox() is None
# Native top plane joins reach both border ports without gaps.
w=R/"art_delivery/wood_room_preview_v1/wall"
h=Image.open(w/"wood_mask_10.png");v=Image.open(w/"wood_mask_05.png")
assert all(h.getpixel((x,y))[3]==255 for x in [0,47] for y in range(16,28))
assert all(v.getpixel((x,y))[3]==255 for x in range(18,30) for y in [1,42])
static=R/"art_delivery/characters_v1"
for r in json.loads((static/"manifest.json").read_text(encoding="utf8"))["assets"]:
 assert hashlib.sha256((static/r["file"]).read_bytes()).hexdigest()==r["delivery_sha256"]
print("13 preview PNGs: dimensions, SHA256, binary alpha passed; floor no gaps; door aperture clear; H/V ports continuous; adopted4 static PNGs unchanged.")

