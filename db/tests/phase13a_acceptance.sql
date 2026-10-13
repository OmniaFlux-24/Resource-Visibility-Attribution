\set ON_ERROR_STOP 1
-- Requires Step 12 synthetic tenants/principals and Phase 13A migration.
SET ROLE rva_app;
BEGIN;
SELECT set_config('rva.tenant_id','11111111-1111-4111-8111-111111111111',true),set_config('rva.principal_id','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',true);
INSERT INTO rva.resources(tenant_id,resource_id,canonical_id,resource_type,display_name,created_by_principal_id) VALUES('11111111-1111-4111-8111-111111111111','dddddddd-dddd-4ddd-8ddd-dddddddddddd','urn:rva:test:resource:one','DIGITAL_ASSET','Resource One','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');
INSERT INTO rva.resource_facets(tenant_id,resource_id,facet_kind,facet_schema,facet_schema_version,payload,effective_period,provenance_source,source_hash,recorded_by_principal_id) VALUES
('11111111-1111-4111-8111-111111111111','dddddddd-dddd-4ddd-8ddd-dddddddddddd','LIFECYCLE','rva.lifecycle',1,'{"state":"ACTIVE"}','[2026-01-01,infinity)','test','aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'),
('11111111-1111-4111-8111-111111111111','dddddddd-dddd-4ddd-8ddd-dddddddddddd','CONDITION','rva.condition',1,'{"condition":"GOOD"}','[2026-01-01,infinity)','test','bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');
DO $$ BEGIN IF (SELECT count(*) FROM rva.resource_facets WHERE resource_id='dddddddd-dddd-4ddd-8ddd-dddddddddddd')<>2 THEN RAISE EXCEPTION 'independent facets failed'; END IF; END $$;
DO $$ DECLARE blocked boolean:=false; BEGIN
 BEGIN INSERT INTO rva.resources(tenant_id,canonical_id,resource_type,display_name,created_by_principal_id) VALUES('22222222-2222-4222-8222-222222222222','urn:rva:test:bad','DIGITAL_ASSET','Bad','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'); EXCEPTION WHEN insufficient_privilege THEN blocked:=true; END;
 IF NOT blocked THEN RAISE EXCEPTION 'cross tenant insert succeeded'; END IF;
END $$;
INSERT INTO rva.resource_events(tenant_id,event_id,resource_id,event_type,event_schema_version,effective_period,actor_principal_id,source_reference,source_hash,correlation_id,payload) VALUES('11111111-1111-4111-8111-111111111111','eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee','dddddddd-dddd-4ddd-8ddd-dddddddddddd','RESOURCE.OBSERVED',1,'[2026-01-01,infinity)','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','source:1','cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc','ffffffff-ffff-4fff-8fff-ffffffffffff','{}');
DO $$ DECLARE blocked boolean:=false; BEGIN BEGIN UPDATE rva.resource_events SET payload='{"changed":true}' WHERE event_id='eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee'; EXCEPTION WHEN raise_exception THEN blocked:=true; END; IF NOT blocked THEN RAISE EXCEPTION 'event mutation succeeded'; END IF; END $$;
ROLLBACK;
RESET ROLE;
