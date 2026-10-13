BEGIN;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE SCHEMA IF NOT EXISTS rva;

CREATE TYPE rva.tenant_status AS ENUM ('ACTIVE','SUSPENDED','CLOSED');
CREATE TABLE rva.tenants(
 tenant_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 display_name text NOT NULL CHECK(length(display_name) BETWEEN 1 AND 200),
 status rva.tenant_status NOT NULL DEFAULT 'ACTIVE',
 residency_code text NOT NULL CHECK(residency_code ~ '^[A-Z]{2}(-[A-Z0-9]{1,8})?$'),
 retention_policy_code text NOT NULL,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
CREATE TABLE rva.principals(
 tenant_id uuid NOT NULL,
 principal_id uuid NOT NULL DEFAULT gen_random_uuid(),
 subject text NOT NULL CHECK(length(subject) BETWEEN 1 AND 512),
 principal_type text NOT NULL CHECK(principal_type IN('USER','SERVICE')),
 active boolean NOT NULL DEFAULT true,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(tenant_id,principal_id),
 UNIQUE(tenant_id,subject),
 FOREIGN KEY(tenant_id) REFERENCES rva.tenants(tenant_id)
);
CREATE TABLE rva.audit_events(
 tenant_id uuid NOT NULL,
 audit_event_id uuid NOT NULL DEFAULT gen_random_uuid(),
 principal_id uuid NOT NULL,
 action_code text NOT NULL,
 object_type text NOT NULL,
 object_id uuid,
 request_id text NOT NULL,
 correlation_id text NOT NULL,
 policy_version text,
 input_hash char(64),
 result_hash char(64),
 outcome text NOT NULL CHECK(outcome IN('SUCCEEDED','DENIED','FAILED')),
 recorded_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(tenant_id,audit_event_id),
 FOREIGN KEY(tenant_id,principal_id) REFERENCES rva.principals(tenant_id,principal_id),
 CHECK(input_hash IS NULL OR input_hash ~ '^[0-9a-f]{64}$'),
 CHECK(result_hash IS NULL OR result_hash ~ '^[0-9a-f]{64}$')
);
CREATE TABLE rva.evidence_objects(
 tenant_id uuid NOT NULL,
 evidence_id uuid NOT NULL DEFAULT gen_random_uuid(),
 captured_by_principal_id uuid NOT NULL,
 storage_key text NOT NULL,
 media_type text NOT NULL,
 byte_length bigint NOT NULL CHECK(byte_length>=0),
 sha256 char(64) NOT NULL CHECK(sha256 ~ '^[0-9a-f]{64}$'),
 source_reference text NOT NULL,
 captured_at timestamptz NOT NULL,
 recorded_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(tenant_id,evidence_id),
 UNIQUE(tenant_id,storage_key),
 FOREIGN KEY(tenant_id,captured_by_principal_id) REFERENCES rva.principals(tenant_id,principal_id),
 CHECK(storage_key LIKE 'rva/evidence/'||tenant_id::text||'/%')
);

CREATE FUNCTION rva.current_tenant_id() RETURNS uuid LANGUAGE plpgsql STABLE AS $$
DECLARE value text;
BEGIN
 value:=current_setting('rva.tenant_id',true);
 IF value IS NULL OR value='' THEN RETURN NULL; END IF;
 BEGIN RETURN value::uuid; EXCEPTION WHEN invalid_text_representation THEN RETURN NULL; END;
END $$;
CREATE FUNCTION rva.current_principal_id() RETURNS uuid LANGUAGE plpgsql STABLE AS $$
DECLARE value text;
BEGIN
 value:=current_setting('rva.principal_id',true);
 IF value IS NULL OR value='' THEN RETURN NULL; END IF;
 BEGIN RETURN value::uuid; EXCEPTION WHEN invalid_text_representation THEN RETURN NULL; END;
END $$;
CREATE FUNCTION rva.block_mutation() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN RAISE EXCEPTION 'append-only record'; END $$;
CREATE TRIGGER audit_append_only BEFORE UPDATE OR DELETE ON rva.audit_events FOR EACH ROW EXECUTE FUNCTION rva.block_mutation();
CREATE TRIGGER evidence_immutable BEFORE UPDATE OR DELETE ON rva.evidence_objects FOR EACH ROW EXECUTE FUNCTION rva.block_mutation();

ALTER TABLE rva.principals ENABLE ROW LEVEL SECURITY; ALTER TABLE rva.principals FORCE ROW LEVEL SECURITY;
ALTER TABLE rva.audit_events ENABLE ROW LEVEL SECURITY; ALTER TABLE rva.audit_events FORCE ROW LEVEL SECURITY;
ALTER TABLE rva.evidence_objects ENABLE ROW LEVEL SECURITY; ALTER TABLE rva.evidence_objects FORCE ROW LEVEL SECURITY;
CREATE POLICY principals_tenant ON rva.principals USING(tenant_id=rva.current_tenant_id()) WITH CHECK(tenant_id=rva.current_tenant_id());
CREATE POLICY audit_tenant ON rva.audit_events USING(tenant_id=rva.current_tenant_id()) WITH CHECK(tenant_id=rva.current_tenant_id() AND principal_id=rva.current_principal_id());
CREATE POLICY evidence_tenant ON rva.evidence_objects USING(tenant_id=rva.current_tenant_id()) WITH CHECK(tenant_id=rva.current_tenant_id() AND captured_by_principal_id=rva.current_principal_id());

CREATE INDEX audit_tenant_recorded_idx ON rva.audit_events(tenant_id,recorded_at DESC);
CREATE INDEX evidence_tenant_recorded_idx ON rva.evidence_objects(tenant_id,recorded_at DESC);
COMMIT;
