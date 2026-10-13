#!/usr/bin/env bash
set -euo pipefail
: "${RVA_DATABASE_URL:?RVA_DATABASE_URL required}"
base="$(cd "$(dirname "$0")/.." && pwd)"
for f in "$base"/db/migrations/*.up.sql; do psql "$RVA_DATABASE_URL" -v ON_ERROR_STOP=1 -f "$f"; done
psql "$RVA_DATABASE_URL" -v ON_ERROR_STOP=1 -f "$base/db/tests/tenant_isolation.sql"
for f in $(find "$base/db/migrations" -name '*.down.sql' | sort -r); do psql "$RVA_DATABASE_URL" -v ON_ERROR_STOP=1 -f "$f"; done
for f in "$base"/db/migrations/*.up.sql; do psql "$RVA_DATABASE_URL" -v ON_ERROR_STOP=1 -f "$f"; done
echo 'PostgreSQL migration, tenant isolation, rollback and reapply passed'
