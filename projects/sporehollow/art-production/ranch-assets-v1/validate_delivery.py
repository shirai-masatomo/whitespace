from pathlib import Path
from PIL import Image,ImageOps
import json,hashlib
R=Path(__file__).resolve().parents[2];D=R/"art_delivery/ranch_assets_v1"
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
S=R/"art_delivery/characters_v1"
sm=json.loads((S/"manifest.json").read_text(encoding="utf8"))
for r in sm["assets"]:
 p=S/r["file"];im=Image.open(p)
 assert sha(p)==r["source_sha256"]==r["delivery_sha256"]
 assert im.mode=="RGBA" and list(im.size)==r["canvas_size_px"]
 assert list(im.getbbox())==r["visible_bounds_exclusive_px"]
 assert set(im.getchannel("A").getdata())=={0,255}
 assert p.read_bytes()==(R/r["source_processed_file"]).read_bytes()
M=R/"art_delivery/characters_motion_v1"
mm=json.loads((M/"manifest.json").read_text(encoding="utf8"));motion_count=0
for r in mm["assets"]:
 for f in r["files"]:
  p=M/f;im=Image.open(p);motion_count+=1
  assert im.mode=="RGBA" and list(im.size)==r["canvas"]
  assert im.getbbox()[3]==r["foot_anchor"][1]==44
  assert set(im.getchannel("A").getdata())=={0,255}
  assert sha(p)==r["sha256"][f]
m=json.loads((D/"manifest.json").read_text(encoding="utf8"))
for r in m["files"]:
 p=D/r["file"];im=Image.open(p)
 assert im.mode=="RGBA" and list(im.size)==r["size"]
 assert sha(p)==r["sha256"]
 assert set(im.getchannel("A").getdata())<={0,255}
for r in m["animations"]:
 for f in r["files"]:
  im=Image.open(D/f)
  assert list(im.size)==r["frame_size"] and im.getbbox()[3]==r["foot_anchor"][1]
 assert len(r["files"])==len(r["frame_order"])==len(r["duration_ms"])
for key in ["hen","cat"]:
 files=[D/key/f"walk_right_{i:02}.png" for i in range(4)]
 assert len({Image.open(p).tobytes() for p in files})==4
 tops={Image.open(p).getbbox()[1] for p in files};assert len(tops)==1
for name,r in m["book"]["animations"].items():
 assert len(r["files"])==6 and r["loop"]==False
 for f in r["files"]:assert Image.open(D/f).size==(1024,640)
assert (D/"book/opening_05.png").read_bytes()==(D/"book/open_00.png").read_bytes()
# Overlaid source-derived layers must reconstruct every visible pixel.
recon=Image.new("RGBA",(1024,640))
for name in ["cover","paper","binding_shadow"]:recon.alpha_composite(Image.open(D/f"book/{name}_layer.png"))
orig=Image.open(D/"book/open_00.png")
assert list(recon.convert("RGB").getdata())==list(orig.convert("RGB").getdata()) or all(a==b for a,b in zip(recon.getdata(),orig.getdata()) if b[3])
report={"static_adopted_files_unchanged":4,"motion_frame_files":motion_count,"ranch_production_pngs":len(m["files"]),"canvas_alpha_anchor_hash_checks":"passed","book_hinge_frames_and_layer_reconstruction":"passed","reviewed":["overview.png","animal-actions.png","animals-walk-frames.png","book-opening.png"],"runtime_integration":"not_checked_by_art_task"}
(D/"QA.json").write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding="utf8")
print(json.dumps(report))

