"""Create working inputs only; no model download, generation, or network request."""
import argparse
import hashlib
import io
from pathlib import Path
from PIL import Image, ImageOps


def put(path, content):
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists() and path.read_bytes() != content:
        raise SystemExit(f'Refusing to replace a different existing baseline: {path}')
    path.write_bytes(content)
    return hashlib.sha256(content).hexdigest()


def prepare(foundation, include_benchmark=False):
    workshop = Path(__file__).resolve().parents[1]
    inputs = foundation.resolve() / 'data/inputs'
    with Image.open(workshop / 'assets/image_a.png') as original:
        working = ImageOps.pad(original.convert('RGB'), (832, 1216),
                               method=Image.Resampling.LANCZOS, color='white')
        data = io.BytesIO()
        working.save(data, format='PNG')
    checksums = {'workshop_image_a_work.png': put(inputs / 'workshop_image_a_work.png', data.getvalue())}
    checksums['workshop_pose_guide.png'] = put(inputs / 'workshop_pose_guide.png', (workshop / 'assets/pose_guide.png').read_bytes())
    if include_benchmark:
        for image in sorted((workshop / 'assets/benchmark').glob('workshop_bench_*.png')):
            checksums[image.name] = put(inputs / image.name, image.read_bytes())
    print('Prepared inputs:', inputs)
    for name, checksum in checksums.items():
        print(name, checksum)
    print('No model downloaded and no image generation submitted.')
    return checksums


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    repo = Path(__file__).resolve().parents[4]
    parser.add_argument('--foundation', type=Path, default=repo / 'tools/local-ai-foundation')
    parser.add_argument('--include-benchmark', action='store_true', help='Also copy the fixed experimental masks and pose guide.')
    args = parser.parse_args()
    prepare(args.foundation, args.include_benchmark)
