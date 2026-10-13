\set ON_ERROR_STOP 1
SET ROLE rva_app;
BEGIN;
SELECT set_config('rva.tenant_id','11111111-1111-4111-8111-111111111111',true),set_config('rva.principal_id','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',true);
INSERT INTO rva.resources(tenant_id,resource_id,canonical_id,resource_type,display_name,created_by_principal_id) VALUES('11111111-1111-4111-8111-111111111111','dddddddd-dddd-4ddd-8ddd-dddddddddddd','urn:rva:test:revision:one','DIGITAL_ASSET','Revision One','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');
DO $$ BEGIN IF (SELECT revision FROM rva.resources WHERE resource_id='dddddddd-dddd-4ddd-8ddd-dddddddddddd')<>1 THEN RAISE EXCEPTION 'initial revision failed'; END IF; END $$;
UPDATE rva.resources SET display_name='Revision Two',revision=revision+1 WHERE resource_id='dddddddd-dddd-4ddd-8ddd-dddddddddddd' AND revision=1;
DO $$ BEGIN IF (SELECT revision FROM rva.resources WHERE resource_id='dddddddd-dddd-4ddd-8ddd-dddddddddddd')<>2 THEN RAISE EXCEPTION 'revision increment failed'; END IF; END $$;
DO $$ DECLARE changed integer; BEGIN UPDATE rva.resources SET display_name='Stale',revision=revision+1 WHERE resource_id='dddddddd-dddd-4ddd-8ddd-dddddddddddd' AND revision=1; GET DIAGNOSTICS changed=ROW_COUNT; IF changed<>0 THEN RAISE EXCEPTION 'stale revision updated resource'; END IF; END $$;
INSERT INTO rva.idempotency_records(tenant_id,principal_id,idempotency_key,operation_code,request_hash,state,response_status,response_headers,response_body,resource_id,completed_at,expires_at) VALUES('11111111-1111-4111-8111-111111111111','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','1234567890123456','RESOURCE.CREATE',repeat('a',64),'COMPLETED',201,'{"location":"/x"}','{"ok":true}','dddddddd-dddd-4ddd-8ddd-dddddddddddd',clock_timestamp(),clock_timestamp()+interval '1 day');
DO $$ DECLARE blocked boolean:=false; BEGIN BEGIN INSERT INTO rva.idempotency_records(tenant_id,principal_id,idempotency_key,operation_code,request_hash,state,expires_at) VALUES('11111111-1111-4111-8111-111111111111','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','1234567890123456','OTHER',repeat('b',64),'IN_PROGRESS',clock_timestamp()+interval '1 day'); EXCEPTION WHEN unique_violation THEN blocked:=true; END; IF NOT blocked THEN RAISE EXCEPTION 'duplicate idempotency key allowed'; END IF; END $$;
ROLLBACK;
RESET ROLE;
