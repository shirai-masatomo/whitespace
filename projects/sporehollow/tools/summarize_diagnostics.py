"""Reduce a bounded real-play capture to review evidence. No game/save writes."""
import json, sys, hashlib, math
from pathlib import Path
source, destination, tag = Path(sys.argv[1]), Path(sys.argv[2]), sys.argv[3]
data=json.loads(source.read_text(encoding='utf-8-sig'))
frames=[r for r in data['frames'] if r['ready_ms']>=0]
def stats(a):
    if not a:return {}
    a=sorted(a)
    return dict(mean=sum(a)/len(a),p95=a[math.ceil(len(a)*.95)-1],p99=a[math.ceil(len(a)*.99)-1],max=a[-1],count=len(a))
record={k:v for k,v in data.items() if k!='frames'}
record['name']=tag
record['cpu_scopes']={key:stats([r['cpu'].get(key,0) for r in frames]) for key in sorted(set(k for r in frames for k in r['cpu'] if not k.endswith('_count')))}
record['monitors']={key:stats([r.get(key,0) for r in frames]) for key in ['gpu_render_ms','render_cpu_ms','frame_setup_cpu_ms','memory_bytes','draw_calls','objects','engine_process_ms']}
record['focused_frames']=sum(bool(r.get('focused')) for r in frames)
record['slowest']=sorted(frames,key=lambda r:r['frame_ms'],reverse=True)[:16]
record['capture_sha256']=hashlib.sha256(source.read_bytes()).hexdigest()
record['source_sha256']={q.name:hashlib.sha256(q.read_bytes()).hexdigest() for q in (Path(__file__).resolve().parent.parent/'game').glob('*.gd')}
destination.write_text(json.dumps(record,ensure_ascii=False,indent=2),encoding='utf-8')
print(tag,'first30',record['summary'].get('first_30'),'moving',record['summary'].get('moving'))
