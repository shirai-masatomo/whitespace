from pathlib import Path
from PIL import Image,ImageOps
import json,hashlib
R=Path(r"C:\Users\masat\.codex\worktrees\sporehollow-art\codex_test\projects\sporehollow")
D=R/"art_delivery/characters_motion_v1"
f=Image.open(R/"art_delivery/characters_v1/keeper_idle_right_00.png").convert("RGBA")
left=Image.new("RGBA",f.size);left.alpha_composite(ImageOps.mirror(f),(1,0))
p=D/"keeper/idle_left_00.png";left.save(p)
m=json.loads((D/"manifest.json").read_text(encoding="utf8"))
m["assets"]=[r for r in m["assets"] if not (r["character"]=="keeper" and r["action"]=="idle")]
m["assets"].append({"character":"keeper","action":"idle","direction":"left","canvas":[32,48],"foot_anchor":[16,44],"frame_order":[0],"frame_duration_ms":[None],"duration_mode":"hold_until_state_change","loop":False,"files":["keeper/idle_left_00.png"],"status":"art_complete_game_integration_unverified","derivation":"Exact adopted v1 pixel reflection about foot x16; no face redraw","sha256":{"keeper/idle_left_00.png":hashlib.sha256(p.read_bytes()).hexdigest()}})
(D/"manifest.json").write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding="utf8")
p=D/"HANDOFF.md";s=p.read_text(encoding="utf8").replace("計44コマと横シート","計45コマ（追加動作44＋左向き停止1）と横シート").replace("静止は先行納品を使う。","右向き静止・柴犬静止は先行納品を使う。主人公の左向き停止は本納品 keeper/idle_left_00.png を使用する。採用v1を足元x16で反転したもので顔の描き直しはない。")
p.write_text(s,encoding="utf8")
assert left.getbbox()[3]==44
print("Added keeper left stop",left.getbbox())
