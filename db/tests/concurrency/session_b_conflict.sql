\set ON_ERROR_STOP 1
SET ROLE rva_app;
BEGIN;
SELECT set_config('rva.tenant_id','11111111-1111-4111-8111-111111111111',true),set_config('rva.principal_id','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',true);
DO $$ BEGIN IF EXISTS(SELECT 1 FROM rva.idempotency_records WHERE idempotency_key='concurrent-key-0001' AND request_hash<>repeat('b',64)) THEN RAISE NOTICE 'PASS: conflicting hash detected'; ELSE RAISE EXCEPTION 'conflicting hash was not detected'; END IF; END $$;
ROLLBACK;
RESET ROLE;
