BEGIN;
CREATE EXTENSION IF NOT EXISTS btree_gist;
CREATE TYPE rva.resource_facet_kind AS ENUM('LIFECYCLE','CONDITION','AVAILABILITY','CUSTODY','CLASSIFICATION','DOMAIN_ATTRIBUTES');
CREATE TABLE rva.resources(
 tenant_id uuid NOT NULL,
 resource_id uuid NOT NULL DEFAULT gen_random_uuid(),
 canonical_id text NOT NULL CHECK(canonical_id ~ '^urn:rva:[a-z0-9][a-z0-9._:-]{1,510}$'),
 resource_type text NOT NULL CHECK(resource_type ~ '^[A-Z][A-Z0-9_]{1,127}$'),
 display_name text NOT NULL CHECK(length(display_name) BETWEEN 1 AND 300),
 created_by_principal_id uuid NOT NULL,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 retired_at timestamptz,
 PRIMARY KEY(tenant_id,resource_id),
 UNIQUE(tenant_id,canonical_id),
 FOREIGN KEY(tenant_id) REFERENCES rva.tenants(tenant_id),
 FOREIGN KEY(tenant_id,created_by_principal_id) REFERENCES rva.principals(tenant_id,principal_id),
 CHECK(retired_at IS NULL OR retired_at>=created_at)
);
CREATE TABLE rva.resource_source_mappings(
 tenant_id uuid NOT NULL,mapping_id uuid NOT NULL DEFAULT gen_random_uuid(),resource_id uuid NOT NULL,
 connector_code text NOT NULL CHECK(connector_code ~ '^[A-Z][A-Z0-9_.-]{1,127}$'),
 source_system text NOT NULL CHECK(length(source_system) BETWEEN 1 AND 200),source_object_type text NOT NULL,
 source_object_id text NOT NULL CHECK(length(source_object_id) BETWEEN 1 AND 512),source_version text,
 first_observed_at timestamptz NOT NULL,last_observed_at timestamptz NOT NULL,source_hash char(64) NOT NULL CHECK(source_hash ~ '^[0-9a-f]{64}$'),
 PRIMARY KEY(tenant_id,mapping_id),UNIQUE(tenant_id,connector_code,source_system,source_object_type,source_object_id),
 FOREIGN KEY(tenant_id,resource_id) REFERENCES rva.resources(tenant_id,resource_id),CHECK(last_observed_at>=first_observed_at)
);
CREATE TABLE rva.resource_facets(
 tenant_id uuid NOT NULL,facet_id uuid NOT NULL DEFAULT gen_random_uuid(),resource_id uuid NOT NULL,
 facet_kind rva.resource_facet_kind NOT NULL,facet_schema text NOT NULL,facet_schema_version integer NOT NULL CHECK(facet_schema_version>0),
 payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object' AND pg_column_size(payload)<=1048576),
 effective_period tstzrange NOT NULL,recorded_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 recorded_period tstzrange GENERATED ALWAYS AS (tstzrange(recorded_at,NULL,'[)')) STORED,
 provenance_source text NOT NULL,source_hash char(64) NOT NULL CHECK(source_hash ~ '^[0-9a-f]{64}$'),
 recorded_by_principal_id uuid NOT NULL,
 PRIMARY KEY(tenant_id,facet_id),
 FOREIGN KEY(tenant_id,resource_id) REFERENCES rva.resources(tenant_id,resource_id),
 FOREIGN KEY(tenant_id,recorded_by_principal_id) REFERENCES rva.principals(tenant_id,principal_id),
 CHECK(NOT isempty(effective_period) AND lower_inc(effective_period) AND NOT upper_inc(effective_period)),
 CHECK(NOT isempty(recorded_period) AND lower_inc(recorded_period) AND NOT upper_inc(recorded_period))
);
CREATE TABLE rva.resource_events(
 tenant_id uuid NOT NULL,event_id uuid NOT NULL DEFAULT gen_random_uuid(),resource_id uuid NOT NULL,
 event_type text NOT NULL CHECK(event_type ~ '^[A-Z][A-Z0-9_.-]{1,127}$'),event_schema_version integer NOT NULL CHECK(event_schema_version>0),
 effective_period tstzrange NOT NULL,recorded_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 recorded_period tstzrange GENERATED ALWAYS AS (tstzrange(recorded_at,NULL,'[)')) STORED,
 actor_principal_id uuid NOT NULL,source_reference text NOT NULL,source_hash char(64) NOT NULL CHECK(source_hash ~ '^[0-9a-f]{64}$'),
 correction_of_event_id uuid,supersedes_event_id uuid,correlation_id uuid NOT NULL,causation_id uuid,
 payload jsonb NOT NULL DEFAULT '{}'::jsonb CHECK(jsonb_typeof(payload)='object' AND pg_column_size(payload)<=1048576),
 PRIMARY KEY(tenant_id,event_id),
 FOREIGN KEY(tenant_id,resource_id) REFERENCES rva.resources(tenant_id,resource_id),
 FOREIGN KEY(tenant_id,actor_principal_id) REFERENCES rva.principals(tenant_id,principal_id),
 FOREIGN KEY(tenant_id,correction_of_event_id) REFERENCES rva.resource_events(tenant_id,event_id) DEFERRABLE,
 FOREIGN KEY(tenant_id,supersedes_event_id) REFERENCES rva.resource_events(tenant_id,event_id) DEFERRABLE,
 CHECK(correction_of_event_id IS NULL OR correction_of_event_id<>event_id),
 CHECK(supersedes_event_id IS NULL OR supersedes_event_id<>event_id),
 CHECK(NOT isempty(effective_period) AND lower_inc(effective_period) AND NOT upper_inc(effective_period)),
 CHECK(NOT isempty(recorded_period) AND lower_inc(recorded_period) AND NOT upper_inc(recorded_period))
);
CREATE INDEX resource_facets_asof_idx ON rva.resource_facets USING gist(tenant_id,resource_id,effective_period,recorded_period);
CREATE INDEX resource_events_asof_idx ON rva.resource_events USING gist(tenant_id,resource_id,effective_period,recorded_period);
CREATE INDEX resource_mapping_lookup_idx ON rva.resource_source_mappings(tenant_id,connector_code,source_system,source_object_type,source_object_id);
CREATE TRIGGER resource_events_append_only BEFORE UPDATE OR DELETE ON rva.resource_events FOR EACH ROW EXECUTE FUNCTION rva.block_mutation();
CREATE TRIGGER resource_facets_append_only BEFORE UPDATE OR DELETE ON rva.resource_facets FOR EACH ROW EXECUTE FUNCTION rva.block_mutation();
CREATE TRIGGER resource_mappings_immutable BEFORE DELETE ON rva.resource_source_mappings FOR EACH ROW EXECUTE FUNCTION rva.block_mutation();
ALTER TABLE rva.resources ENABLE ROW LEVEL SECURITY; ALTER TABLE rva.resources FORCE ROW LEVEL SECURITY;
ALTER TABLE rva.resource_source_mappings ENABLE ROW LEVEL SECURITY; ALTER TABLE rva.resource_source_mappings FORCE ROW LEVEL SECURITY;
ALTER TABLE rva.resource_facets ENABLE ROW LEVEL SECURITY; ALTER TABLE rva.resource_facets FORCE ROW LEVEL SECURITY;
ALTER TABLE rva.resource_events ENABLE ROW LEVEL SECURITY; ALTER TABLE rva.resource_events FORCE ROW LEVEL SECURITY;
CREATE POLICY resources_tenant ON rva.resources USING(tenant_id=rva.current_tenant_id()) WITH CHECK(tenant_id=rva.current_tenant_id() AND created_by_principal_id=rva.current_principal_id());
CREATE POLICY mappings_tenant ON rva.resource_source_mappings USING(tenant_id=rva.current_tenant_id()) WITH CHECK(tenant_id=rva.current_tenant_id());
CREATE POLICY facets_tenant ON rva.resource_facets USING(tenant_id=rva.current_tenant_id()) WITH CHECK(tenant_id=rva.current_tenant_id() AND recorded_by_principal_id=rva.current_principal_id());
CREATE POLICY events_tenant ON rva.resource_events USING(tenant_id=rva.current_tenant_id()) WITH CHECK(tenant_id=rva.current_tenant_id() AND actor_principal_id=rva.current_principal_id());
GRANT SELECT,INSERT,UPDATE ON rva.resources,rva.resource_source_mappings TO rva_app;
GRANT SELECT,INSERT ON rva.resource_facets,rva.resource_events TO rva_app;
REVOKE TRUNCATE,REFERENCES,TRIGGER ON rva.resources,rva.resource_source_mappings,rva.resource_facets,rva.resource_events FROM rva_app;
COMMIT;
