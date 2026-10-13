\set ON_ERROR_STOP 1
-- Execute as an administrative test role after migrations; SET ROLE rva_app validates request-path behavior.
INSERT INTO rva.tenants(tenant_id,display_name,residency_code,retention_policy_code) VALUES
('11111111-1111-4111-8111-111111111111','Tenant A','GB','default'),
('22222222-2222-4222-8222-222222222222','Tenant B','GB','default');
INSERT INTO rva.principals(tenant_id,principal_id,subject,principal_type) VALUES
('11111111-1111-4111-8111-111111111111','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','user-a','USER'),
('22222222-2222-4222-8222-222222222222','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','user-b','USER');
SET ROLE rva_app;
BEGIN;
SELECT set_config('rva.tenant_id','11111111-1111-4111-8111-111111111111',true),set_config('rva.principal_id','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',true);
DO $$ BEGIN IF (SELECT count(*) FROM rva.principals)<>1 THEN RAISE EXCEPTION 'tenant A isolation failed'; END IF; END $$;
INSERT INTO rva.audit_events(tenant_id,principal_id,action_code,object_type,request_id,correlation_id,outcome) VALUES('11111111-1111-4111-8111-111111111111','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','TEST','TEST','r1','c1','SUCCEEDED');
DO $$ BEGIN
 BEGIN INSERT INTO rva.audit_events(tenant_id,principal_id,action_code,object_type,request_id,correlation_id,outcome) VALUES('22222222-2222-4222-8222-222222222222','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','BAD','TEST','r2','c2','SUCCEEDED'); RAISE EXCEPTION 'cross tenant insert unexpectedly succeeded'; EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END $$;
COMMIT;
BEGIN;
DO $$ BEGIN IF (SELECT count(*) FROM rva.principals)<>0 THEN RAISE EXCEPTION 'context leaked across transaction'; END IF; END $$;
ROLLBACK;
RESET ROLE;
