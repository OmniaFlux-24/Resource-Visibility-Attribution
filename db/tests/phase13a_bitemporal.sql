\set ON_ERROR_STOP 1
-- Run after phase13a_acceptance fixture setup is committed by the native runner.
SET ROLE rva_app;
BEGIN;
SELECT set_config('rva.tenant_id','11111111-1111-4111-8111-111111111111',true),set_config('rva.principal_id','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',true);
INSERT INTO rva.resources(tenant_id,resource_id,canonical_id,resource_type,display_name,created_by_principal_id)
VALUES('11111111-1111-4111-8111-111111111111','dddddddd-dddd-4ddd-8ddd-dddddddddddd','urn:rva:test:bitemporal:one','DIGITAL_ASSET','Bitemporal Resource','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');
INSERT INTO rva.resource_facets(tenant_id,facet_id,resource_id,facet_kind,facet_schema,facet_schema_version,payload,effective_period,recorded_at,provenance_source,source_hash,recorded_by_principal_id) VALUES
('11111111-1111-4111-8111-111111111111','10000000-0000-4000-8000-000000000001','dddddddd-dddd-4ddd-8ddd-dddddddddddd','CONDITION','rva.condition',1,'{"condition":"GOOD"}','[2026-01-01,2026-07-01)','2026-01-10T00:00:00Z','fixture','aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'),
('11111111-1111-4111-8111-111111111111','10000000-0000-4000-8000-000000000002','dddddddd-dddd-4ddd-8ddd-dddddddddddd','CONDITION','rva.condition',1,'{"condition":"DEGRADED"}','[2026-07-01,infinity)','2026-07-02T00:00:00Z','fixture','bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');
DO $$ BEGIN
 IF (SELECT count(*) FROM rva.resource_facets WHERE effective_period @> '2026-06-30T23:59:59Z'::timestamptz)<>1 THEN RAISE EXCEPTION 'effective lower-period query failed'; END IF;
 IF (SELECT count(*) FROM rva.resource_facets WHERE effective_period @> '2026-07-01T00:00:00Z'::timestamptz)<>1 THEN RAISE EXCEPTION 'closed-open boundary query failed'; END IF;
 IF (SELECT count(*) FROM rva.resource_facets WHERE effective_period @> '2026-07-01T00:00:00Z'::timestamptz AND recorded_period @> '2026-07-01T12:00:00Z'::timestamptz)<>0 THEN RAISE EXCEPTION 'future recorded fact leaked'; END IF;
 IF (SELECT count(*) FROM rva.resource_facets WHERE effective_period @> '2026-07-01T00:00:00Z'::timestamptz AND recorded_period @> '2026-07-03T00:00:00Z'::timestamptz)<>1 THEN RAISE EXCEPTION 'combined bitemporal query failed'; END IF;
END $$;
ROLLBACK;
RESET ROLE;
