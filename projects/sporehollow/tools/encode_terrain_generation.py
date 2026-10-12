from pathlib import Path
import json, sys
from PIL import Image
source, out = map(Path, sys.argv[1:3])
observations = json.loads((source / 'terrain-observations.json').read_text(encoding='utf-8-sig'))
for name, count in observations['clip_frames'].items():
    paths = sorted(source.glob('frame_' + name + '_*.png'))
    assert len(paths) == count and count > 1, (name, count, len(paths))
    frames = [Image.open(path).convert('RGB') for path in paths]
    frames[0].save(out / (name + '.webp'), save_all=True, append_images=frames[1:], duration=250, loop=0, lossless=True, method=2)
    for frame in frames:
        frame.close()
print('Encoded actual-world review sequences; variable simulation sampling, not real-time video.')
