import {randomUUID} from 'node:crypto';import {tenantNamespace,assertTenantNamespace} from '../tenancy/namespaces.mjs';
export function createEvidenceKey(tenantId,evidenceId=randomUUID()){return tenantNamespace('evidence',tenantId,evidenceId);}
export function validateEvidenceKey(key,tenantId){return assertTenantNamespace(key,'evidence',tenantId);}
