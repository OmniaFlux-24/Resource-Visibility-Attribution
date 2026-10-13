import {assertUuid} from './context.mjs';
const PART=/^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$/;
function clean(v,n){if(typeof v!=='string'||!PART.test(v))throw new Error(`Invalid ${n}`);return v;}
export function tenantNamespace(kind,tenantId,...parts){return ['rva',clean(kind,'kind'),assertUuid(tenantId,'tenantId'),...parts.map((x,i)=>clean(x,`part${i}`))].join('/');}
export function assertTenantNamespace(key,kind,tenantId){const prefix=tenantNamespace(kind,tenantId);if(typeof key!=='string'||!(key===prefix||key.startsWith(prefix+'/')))throw new Error('Tenant namespace mismatch');return key;}
