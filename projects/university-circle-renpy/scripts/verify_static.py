"""Read files only. Does NOT import Ren'Py, game Python, or execute .rpy files."""
from pathlib import Path
import hashlib
import json
import re
import struct
import sys
import wave
import xml.etree.ElementTree as ET

root = Path(sys.argv[1]).resolve()
issues = []
labels = {}
sources = {}
for path in sorted((root / 'game').rglob('*.rpy')):
    text = path.read_text(encoding='utf-8-sig')
    sources[path] = text
    if '\ufffd' in text:
        issues.append(f'Unexpected replacement character: {path.relative_to(root)}')
    for label in re.findall(r'^label\s+([\w.]+)\s*(?:\([^\n]*\))?\s*:', text, re.M):
        if label in labels:
            issues.append(f'Duplicate label: {label}')
        labels[label] = str(path.relative_to(root))
for name in ['start', 'circle_map_loop', 'campus_event', 'clubroom_event', 'beach_event']:
    if name not in labels:
        issues.append(f'Missing label: {name}')
assets = sources[root / 'game/assets.rpy']
references = re.findall(r'=\s*"((?:images|audio)/[^"\n]+)"', assets)
for name in references:
    if not (root / 'game' / name).is_file():
        issues.append(f'Missing asset: {name}')
for path in sorted((root / 'game/images').rglob('*.svg')):
    try:
        ET.parse(path)
    except ET.ParseError as error:
        issues.append(f'Invalid SVG: {path.name}: {error}')
sounds = []
for path in sorted((root / 'game/audio').rglob('*.wav')):
    with wave.open(str(path), 'rb') as audio:
        sounds.append({'file':str(path.relative_to(root)), 'seconds':audio.getnframes()/audio.getframerate(), 'channels':audio.getnchannels()})
options = sources[root / 'game/options.rpy']
versions = re.findall(r'^define config.version = "(.*?)"', options, re.M)
if len(versions) != 1:
    issues.append('Version must be defined once')
about_count = len(re.findall(r'^define gui.about\s*=', options, re.M))
if about_count != 1:
    issues.append(f'gui.about definitions: {about_count}')
gui = sources[root / 'game/gui.rpy']
if 'gui.init(1280, 720)' not in gui:
    issues.append('Expected official 1280x720 GUI')
gui_images = ['button/idle_background.png', 'slider/horizontal_idle_bar.png', 'slot.png']
# Only assert files that this exact template actually names, not alternate GUI variants.
for file in ['gui/main_menu.png','gui/textbox.png','gui/button/idle_background.png','gui/slider/horizontal_idle_bar.png']:
    if not (root/'game'/file).is_file():
        issues.append(f'Missing official GUI image: {file}')
for title, label in re.findall(r'\("([^"]+)",\s*"([^"]+_event)"', sources[root / 'game/circle_map.rpy']):
    if label not in labels:
        issues.append(f'Map target missing: {title}: {label}')

font = (root/'game/SourceHanSansLite.ttf').read_bytes()
table_count = struct.unpack_from('>H',font,4)[0]
tables = [struct.unpack_from('>4sIII',font,12+i*16) for i in range(table_count)]
offset = next(t[2] for t in tables if t[0] == b'name')
_, count, string_start = struct.unpack_from('>HHH', font, offset)
font_metadata = {}
for i in range(count):
    platform, encoding, language, name, size, start = struct.unpack_from('>HHHHHH', font, offset+6+i*12)
    if name in [0,1,5,13,14]:
        value = font[offset+string_start+start:offset+string_start+start+size].decode('utf-16-be' if platform in (0,3) else 'latin1',errors='replace')
        font_metadata.setdefault(str(name), [])
        if value not in font_metadata[str(name)]: font_metadata[str(name)].append(value)
manifest = [{'file':str(p.relative_to(root)), 'bytes':p.stat().st_size, 'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted((root/'game').rglob('*')) if p.is_file() and p.suffix in ['.rpy','.rpym','.svg','.wav','.ttf','.png']]
report = {'checked_at':'2026-10-20', 'method':'Pure stdlib file reading; no RenPy imports, SDK process, or game execution', 'isolation':'not used: file-only static checks', 'not_runtime_validation':True, 'version':versions, 'labels':labels, 'asset_references_checked':references, 'audio_headers':sounds, 'font_metadata':font_metadata, 'issues':issues, 'files':manifest}
output = Path(sys.argv[2])
output.parent.mkdir(parents=True, exist_ok=True)
output.write_text(json.dumps(report, ensure_ascii=False, indent=2)+'\n',encoding='utf-8')
print(json.dumps({'report':str(output),'issues':issues,'font_metadata':font_metadata},ensure_ascii=True,indent=2))
raise SystemExit(bool(issues))
