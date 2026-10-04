"""Read-only PNG receipt/reference audit; no artwork generation or modification."""
from pathlib import Path
import hashlib, json, re
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
DELIVERIES = {
    'earth_stone_buildings_v1': 'ebe446e5329aa7780b6ef5f13268ceb9433c9796',
    'wood_buildings_v1': 'e648cf75a288219887733c5fa2d9536a113dae83',
    'characters_v1': 'f3e4ae82b68c342b928dfb5dfcebb451353f9b8d',
    'characters_motion_v1': 'ae950a3df8de7a3dbbd14f40dc3ef9df05e22fd4',
    'ranch_assets_v1': '57aab97c3efc495d7553ee412c68696945d8e846',
    'merchant_cart_v2': '0bbbc1c104acd13e7a9458c141a4a52921c05587',
    'merchant_board_v1': '7e408375f19b86759fc614508fc3e5f413f67ff9',
}

def audit():
    code = '\n'.join(p.read_text(encoding='utf-8-sig') for p in (ROOT/'game').glob('*.gd'))
    referenced = set(re.findall(r'res://(art_delivery/[^"\s]+\.png)', code))
    book = json.loads((ROOT/'art_delivery/ranch_assets_v1/manifest.json').read_text())['book']
    for animation in book['animations'].values():
        referenced.update('art_delivery/ranch_assets_v1/'+p for p in animation['files'])
    rows=[]
    for folder, commit in DELIVERIES.items():
        manifest_text=(ROOT/'art_delivery'/folder/'manifest.json').read_text(encoding='utf-8-sig')
        for png in sorted((ROOT/'art_delivery'/folder).rglob('*.png')):
            relative=png.relative_to(ROOT).as_posix()
            digest=hashlib.sha256(png.read_bytes()).hexdigest()
            im=Image.open(png)
            rows.append({'path':relative,'delivery_commit':commit,'sha256':digest,
                         'size':list(im.size),'mode':im.mode,'bbox':im.getbbox(),
                         'runtime_reference':relative in referenced,
                         'hash_in_manifest':digest in manifest_text})
    missing=referenced-{row['path'] for row in rows}
    assert not missing, missing
    assert all(row['hash_in_manifest'] for row in rows if row['runtime_reference']), 'Adopted PNG differs from delivery manifest'
    return {'deliveries':DELIVERIES,'runtime_count':len(referenced),'files':rows}

if __name__=='__main__':
    import argparse
    parser=argparse.ArgumentParser();parser.add_argument('--output',required=True)
    args=parser.parse_args()
    report=audit();Path(args.output).write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
    print(f"Adopted runtime PNGs: {report['runtime_count']}; delivery hashes matched")
