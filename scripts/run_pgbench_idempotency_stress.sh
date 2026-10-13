#!/usr/bin/env bash
set -euo pipefail
: "${RVA_ADMIN_DATABASE_URL:?RVA_ADMIN_DATABASE_URL required}"
base="$(cd "$(dirname "$0")/.." && pwd)"; pgbench_bin="${PGBENCH_BIN:-pgbench}"; psql_bin="${PSQL_BIN:-psql}"; out="$base/evidence/pgbench"
clients="${PGBENCH_CLIENTS:-16}"; threads="${PGBENCH_THREADS:-4}"; transactions="${PGBENCH_TRANSACTIONS:-50}"
for n in "$clients" "$threads" "$transactions"; do [[ "$n" =~ ^[1-9][0-9]*$ ]] || { echo 'positive integer stress settings required' >&2; exit 2; }; done
mkdir -p "$out"
cleanup(){ "$psql_bin" -X -v ON_ERROR_STOP=1 "$RVA_ADMIN_DATABASE_URL" -c "DELETE FROM rva.idempotency_records WHERE idempotency_key LIKE 'pgbench-%'" >/dev/null; }
cleanup
"$pgbench_bin" -n -M prepared -c "$clients" -j "$threads" -t "$transactions" -f "$base/db/tests/pgbench/idempotency_same_key.sql" "$RVA_ADMIN_DATABASE_URL" | tee "$out/same-key.txt"
same_count=$("$psql_bin" -X -At -v ON_ERROR_STOP=1 "$RVA_ADMIN_DATABASE_URL" -c "SELECT count(*) FROM rva.idempotency_records WHERE tenant_id='11111111-1111-4111-8111-111111111111' AND idempotency_key='pgbench-same-key-01'")
[[ "$same_count" == 1 ]] || { echo "same-key stress expected one row, got $same_count" >&2; exit 1; }
cleanup
"$pgbench_bin" -n -M prepared -c "$clients" -j "$threads" -t "$transactions" -f "$base/db/tests/pgbench/idempotency_unique_keys.sql" "$RVA_ADMIN_DATABASE_URL" | tee "$out/unique-keys.txt"
unique_count=$("$psql_bin" -X -At -v ON_ERROR_STOP=1 "$RVA_ADMIN_DATABASE_URL" -c "SELECT count(*) FROM rva.idempotency_records WHERE tenant_id='11111111-1111-4111-8111-111111111111' AND idempotency_key LIKE 'pgbench-key-%'")
[[ "$unique_count" -gt 0 ]] || { echo 'unique-key stress inserted no rows' >&2; exit 1; }
printf 'clients=%s\nthreads=%s\ntransactions_per_client=%s\nsame_key_rows=%s\nunique_key_rows=%s\n' "$clients" "$threads" "$transactions" "$same_count" "$unique_count" | tee "$out/assertions.txt"
cleanup
echo 'PASS: pgbench idempotency contention and distributed-key stress'
