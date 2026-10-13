#!/usr/bin/env python3
import json,re,sys
from pathlib import Path
root=Path(sys.argv[1] if len(sys.argv)>1 else '.').resolve();errors=[]
def err(x):errors.append(x)
# migration pairs
ups=sorted((root/'db/migrations').glob('*.up.sql'));downs=sorted((root/'db/migrations').glob('*.down.sql'))
if not ups:err('no migrations')
if {p.name.replace('.up.sql','') for p in ups}!={p.name.replace('.down.sql','') for p in downs}:err('migration pair mismatch')
up='\n'.join(p.read_text() for p in ups)
code='\n'.join(p.read_text() for p in (root/'src').rglob('*.mjs'))
for table in ('principals','audit_events','evidence_objects'):
 if not re.search(rf'ALTER TABLE rva\.{table} ENABLE ROW LEVEL SECURITY',up):err(f'{table} missing ENABLE RLS')
 if not re.search(rf'ALTER TABLE rva\.{table} FORCE ROW LEVEL SECURITY',up):err(f'{table} missing FORCE RLS')
 if not re.search(rf'CREATE POLICY \w+ ON rva\.{table}',up):err(f'{table} missing policy')
for marker in ('NOSUPERUSER','NOBYPASSRLS',"current_setting('rva.tenant_id',true)",'PRIMARY KEY(tenant_id','FOREIGN KEY(tenant_id,principal_id)'):
 if marker not in up:err('missing schema control: '+marker)
if "set_config('rva.tenant_id'" not in code:err('transaction-local tenant context missing')
if 'GRANT ALL' in up.upper():err('overbroad GRANT ALL')
# backlog, ADR, code, tests and runbook
for f in ('STEP-12-IMPLEMENTATION-BACKLOG.md','docs/adrs/ADR-001-tenant-isolation.md','docs/security/threat-model.md','docs/testing/test-plan.md','docs/runbooks/tenant-isolation-incident.md','tests/tenancy.test.mjs'):
 p=root/f
 if not p.exists() or p.stat().st_size<300:err('missing/incomplete '+f)
# package parse
try:json.loads((root/'package.json').read_text())
except Exception as e:err('invalid package.json '+str(e))
if errors:
 print('\n'.join('ERROR: '+x for x in errors));sys.exit(1)
print(f'PASS: Step 12 static validation; {len(ups)} migration pairs; 3 forced-RLS tenant tables')
