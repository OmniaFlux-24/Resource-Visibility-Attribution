#!/usr/bin/env python3
import hashlib,json,sys
from pathlib import Path
root=Path(sys.argv[1]).resolve();out=Path(sys.argv[2]).resolve();items=[]
for p in sorted(x for x in root.rglob('*') if x.is_file() and x.resolve()!=out):
 b=p.read_bytes();items.append({'path':p.relative_to(root).as_posix(),'sha256':hashlib.sha256(b).hexdigest(),'bytes':len(b)})
out.parent.mkdir(parents=True,exist_ok=True);out.write_text(json.dumps({'schemaVersion':1,'artifacts':items},indent=2)+'\n');print(f'Wrote {len(items)} hashes')
