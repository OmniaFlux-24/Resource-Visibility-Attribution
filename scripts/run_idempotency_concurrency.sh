#!/usr/bin/env bash
set -euo pipefail
: "${RVA_ADMIN_DATABASE_URL:?RVA_ADMIN_DATABASE_URL required}"
base="$(cd "$(dirname "$0")/.." && pwd)"; psql_bin="${PSQL_BIN:-psql}"; out="$base/evidence/idempotency-concurrency"
mkdir -p "$out"
cleanup(){ "$psql_bin" -X -v ON_ERROR_STOP=1 "$RVA_ADMIN_DATABASE_URL" -c "DELETE FROM rva.idempotency_records WHERE idempotency_key='concurrent-key-0001'" >/dev/null 2>&1 || true; }; trap cleanup EXIT
cleanup
"$psql_bin" -X -v ON_ERROR_STOP=1 "$RVA_ADMIN_DATABASE_URL" -f "$base/db/tests/concurrency/session_a.sql" >"$out/session-a.log" 2>&1 & a=$!
sleep 0.3
"$psql_bin" -X -v ON_ERROR_STOP=1 "$RVA_ADMIN_DATABASE_URL" -f "$base/db/tests/concurrency/session_b_same.sql" >"$out/session-b-same.log" 2>&1 & b=$!
wait "$a"; wait "$b"
"$psql_bin" -X -v ON_ERROR_STOP=1 "$RVA_ADMIN_DATABASE_URL" -f "$base/db/tests/concurrency/session_b_conflict.sql" >"$out/session-b-conflict.log" 2>&1
count=$("$psql_bin" -X -At -v ON_ERROR_STOP=1 "$RVA_ADMIN_DATABASE_URL" -c "SELECT count(*) FROM rva.idempotency_records WHERE tenant_id='11111111-1111-4111-8111-111111111111' AND idempotency_key='concurrent-key-0001'")
[[ "$count" == 1 ]] || { echo "expected one committed idempotency row, got $count" >&2; exit 1; }
echo 'PASS: two-session idempotency serialization, replay and payload-conflict detection'
