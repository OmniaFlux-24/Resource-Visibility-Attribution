BEGIN;
ALTER TABLE rva.resources ADD COLUMN revision bigint NOT NULL DEFAULT 1 CHECK(revision>0);
CREATE TABLE rva.idempotency_records(
 tenant_id uuid NOT NULL,
 principal_id uuid NOT NULL,
 idempotency_key text NOT NULL CHECK(length(idempotency_key) BETWEEN 16 AND 200),
 operation_code text NOT NULL CHECK(operation_code ~ '^[A-Z][A-Z0-9_.-]{1,127}$'),
 request_hash char(64) NOT NULL CHECK(request_hash ~ '^[0-9a-f]{64}$'),
 state text NOT NULL CHECK(state IN('IN_PROGRESS','COMPLETED')),
 response_status integer CHECK(response_status BETWEEN 200 AND 599),
 response_headers jsonb CHECK(response_headers IS NULL OR jsonb_typeof(response_headers)='object'),
 response_body jsonb,
 resource_id uuid,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 completed_at timestamptz,
 expires_at timestamptz NOT NULL,
 PRIMARY KEY(tenant_id,idempotency_key),
 FOREIGN KEY(tenant_id) REFERENCES rva.tenants(tenant_id),
 FOREIGN KEY(tenant_id,principal_id) REFERENCES rva.principals(tenant_id,principal_id),
 FOREIGN KEY(tenant_id,resource_id) REFERENCES rva.resources(tenant_id,resource_id),
 CHECK(expires_at>created_at),
 CHECK((state='IN_PROGRESS' AND completed_at IS NULL AND response_status IS NULL) OR (state='COMPLETED' AND completed_at IS NOT NULL AND response_status IS NOT NULL))
);
CREATE INDEX idempotency_expiry_idx ON rva.idempotency_records(tenant_id,expires_at);
ALTER TABLE rva.idempotency_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE rva.idempotency_records FORCE ROW LEVEL SECURITY;
CREATE POLICY idempotency_tenant ON rva.idempotency_records USING(tenant_id=rva.current_tenant_id() AND principal_id=rva.current_principal_id()) WITH CHECK(tenant_id=rva.current_tenant_id() AND principal_id=rva.current_principal_id());
GRANT SELECT,INSERT,UPDATE ON rva.idempotency_records TO rva_app;
REVOKE DELETE,TRUNCATE,REFERENCES,TRIGGER ON rva.idempotency_records FROM rva_app;
COMMIT;
