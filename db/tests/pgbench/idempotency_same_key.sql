BEGIN;
SELECT set_config('rva.tenant_id','11111111-1111-4111-8111-111111111111',true),set_config('rva.principal_id','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',true);
INSERT INTO rva.idempotency_records(tenant_id,principal_id,idempotency_key,operation_code,request_hash,state,expires_at)
VALUES(rva.current_tenant_id(),rva.current_principal_id(),'pgbench-same-key-01','RESOURCE.CREATE',repeat('a',64),'IN_PROGRESS',clock_timestamp()+interval '1 day')
ON CONFLICT(tenant_id,idempotency_key) DO NOTHING;
COMMIT;
