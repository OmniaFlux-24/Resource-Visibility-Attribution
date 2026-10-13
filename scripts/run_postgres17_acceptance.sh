#!/usr/bin/env bash
set -euo pipefail
: "${RVA_ADMIN_DATABASE_URL:?RVA_ADMIN_DATABASE_URL is required}"
: "${STEP12_ROOT:?STEP12_ROOT must point to the unzipped complete Step 12 package}"
base="$(cd "$(dirname "$0")/.." && pwd)"
psql_bin="${PSQL_BIN:-psql}"
"$psql_bin" --version | grep -Eq 'psql \(PostgreSQL\) 17\.' || { echo 'PostgreSQL psql 17.x required' >&2; exit 2; }
run(){ "$psql_bin" -X -v ON_ERROR_STOP=1 "$RVA_ADMIN_DATABASE_URL" -f "$1"; }
# Apply complete Step 12, then Phase 13A.
for f in "$STEP12_ROOT"/db/migrations/*.up.sql; do run "$f"; done
for f in "$base"/db/migrations/*.up.sql; do run "$f"; done
# Seed two tenants and principals as migration owner for adversarial application-role tests.
"$psql_bin" -X -v ON_ERROR_STOP=1 "$RVA_ADMIN_DATABASE_URL" <<'SQL'
INSERT INTO rva.tenants(tenant_id,display_name,residency_code,retention_policy_code) VALUES
('11111111-1111-4111-8111-111111111111','Tenant A','GB','default'),('22222222-2222-4222-8222-222222222222','Tenant B','GB','default') ON CONFLICT DO NOTHING;
INSERT INTO rva.principals(tenant_id,principal_id,subject,principal_type) VALUES
('11111111-1111-4111-8111-111111111111','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','user-a','USER'),('22222222-2222-4222-8222-222222222222','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','user-b','USER') ON CONFLICT DO NOTHING;
DO $$ DECLARE s boolean;b boolean; BEGIN SELECT rolsuper,rolbypassrls INTO s,b FROM pg_roles WHERE rolname='rva_app'; IF s OR b THEN RAISE EXCEPTION 'unsafe rva_app role'; END IF; END $$;
SQL
run "$base/db/tests/phase13a_acceptance.sql"
run "$base/db/tests/phase13a_bitemporal.sql"
run "$base/db/tests/phase13a_revision_idempotency.sql"
RVA_ADMIN_DATABASE_URL="$RVA_ADMIN_DATABASE_URL" "$base/scripts/run_idempotency_concurrency.sh"
RVA_ADMIN_DATABASE_URL="$RVA_ADMIN_DATABASE_URL" "$base/scripts/run_pgbench_idempotency_stress.sh"
# Roll back Phase 13A and verify removal, then reapply and rerun static catalog assertions.
while IFS= read -r f; do run "$f"; done < <(find "$base/db/migrations" -name '*.down.sql' -print | sort -r)
"$psql_bin" -X -At -v ON_ERROR_STOP=1 "$RVA_ADMIN_DATABASE_URL" -c "SELECT to_regclass('rva.resources') IS NULL" | grep -qx t
for f in "$base"/db/migrations/*.up.sql; do run "$f"; done
"$psql_bin" -X -v ON_ERROR_STOP=1 "$RVA_ADMIN_DATABASE_URL" <<'SQL'
DO $$ DECLARE n integer; BEGIN SELECT count(*) INTO n FROM pg_class c JOIN pg_namespace nsp ON nsp.oid=c.relnamespace WHERE nsp.nspname='rva' AND c.relname IN('resources','resource_source_mappings','resource_facets','resource_events','idempotency_records') AND c.relrowsecurity AND c.relforcerowsecurity; IF n<>5 THEN RAISE EXCEPTION 'RLS catalog assertion failed: %',n; END IF; END $$;
SQL
echo 'PASS: native PostgreSQL 17 Phase 13A migration, isolation, bitemporal, rollback and reapply gates'
