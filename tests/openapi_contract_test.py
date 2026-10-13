#!/usr/bin/env python3
import re,sys,yaml
from pathlib import Path
p=Path(sys.argv[1] if len(sys.argv)>1 else 'contracts/openapi.yaml');d=yaml.safe_load(p.read_text());errors=[]
def need(c,m):
 if not c:errors.append(m)
need(d.get('openapi')=='3.1.1','OpenAPI version');need(d.get('security')==[{'bearerAuth':[]}],'global bearer security')
scheme=d.get('components',{}).get('securitySchemes',{}).get('bearerAuth',{});need(scheme.get('type')=='http' and scheme.get('scheme')=='bearer','bearer scheme')
http={'get','post','put','patch','delete'};ops=[]
for path,item in d.get('paths',{}).items():
 for method,op in item.items():
  if method not in http:continue
  name=f'{method.upper()} {path}';ops.append(op.get('operationId'))
  need(bool(op.get('operationId')),name+' operationId');need(bool(op.get('tags')),name+' tags');need('responses' in op,name+' responses')
  responses=op.get('responses',{});need('default' in responses,name+' default problem response')
  if method in {'post','put','patch'}:need('requestBody' in op,name+' requestBody')
  if method=='post':
   headers={x.get('$ref','') for x in op.get('parameters',[]) if isinstance(x,dict)}
   if path in {'/v1/resources','/v1/resources/{resourceId}/events'}:need('#/components/parameters/IdempotencyKey' in headers,name+' idempotency')
need(len(ops)==10 and len(set(ops))==10,'ten unique operations')
# Path parameters must be declared and required.
for path,item in d['paths'].items():
 for token in re.findall(r'{([^}]+)}',path):
  params=item.get('parameters',[])
  need(any((x.get('$ref')=='#/components/parameters/ResourceId') or (x.get('name')==token and x.get('required')) for x in params),path+' path parameter '+token)
# Every local reference resolves.
def walk(x):
 if isinstance(x,dict):
  for k,v in x.items():
   if k=='$ref' and isinstance(v,str) and v.startswith('#/'):
    cur=d
    try:
     for part in v[2:].split('/'):cur=cur[part.replace('~1','/').replace('~0','~')]
    except Exception:errors.append('unresolved '+v)
   else:walk(v)
 elif isinstance(x,list):
  for v in x:walk(v)
walk(d)
need(d['components']['parameters']['Limit']['schema']['maximum']==100,'page max 100')
need(d['components']['responses']['Problem']['content'].get('application/problem+json') is not None,'problem+json')
for schema in ('Resource','ResourceCreate','ResourcePatch','ResourceFacet','FacetAppend','ResourceEvent','EventAppend','SourceMapping','SourceMappingCreate','ResourcePage','FacetPage','EventPage','Problem'):need(schema in d['components']['schemas'],'schema '+schema)
if errors:print('\n'.join('ERROR: '+x for x in errors));sys.exit(1)
print(f'PASS: OpenAPI contract; {len(d["paths"])} paths; {len(ops)} endpoint operations; all local refs resolved')
