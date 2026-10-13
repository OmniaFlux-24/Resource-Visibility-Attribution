#!/usr/bin/env python3
import hashlib,json,sys
from pathlib import Path
r=Path(sys.argv[1]).resolve();o=Path(sys.argv[2]).resolve();a=[]
for p in sorted(x for x in r.rglob('*') if x.is_file() and x.resolve()!=o):
 b=p.read_bytes();a.append({'path':p.relative_to(r).as_posix(),'sha256':hashlib.sha256(b).hexdigest(),'bytes':len(b)})
o.parent.mkdir(parents=True,exist_ok=True);o.write_text(json.dumps({'schemaVersion':1,'artifacts':a},indent=2)+'\n');print(f'Wrote {len(a)} hashes')
