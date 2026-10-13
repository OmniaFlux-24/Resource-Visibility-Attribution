#!/usr/bin/env bash
set -euo pipefail
for c in initdb pg_ctl createdb psql; do command -v "$c" >/dev/null || { echo "PostgreSQL 17 command missing: $c" >&2; exit 127; }; done
psql --version | grep -Eq '17\.' || { echo 'PostgreSQL 17 required' >&2; exit 2; }
work="$(mktemp -d)"; trap 'pg_ctl -D "$work/data" -m immediate stop >/dev/null 2>&1 || true; rm -rf "$work"' EXIT
initdb -D "$work/data" -A trust -U postgres >/dev/null
pg_ctl -D "$work/data" -o "-F -k $work -p 55432" -w start >/dev/null
createdb -h "$work" -p 55432 -U postgres rva_acceptance
export RVA_ADMIN_DATABASE_URL="postgresql://postgres@localhost:55432/rva_acceptance?host=$work"
exec "$(cd "$(dirname "$0")" && pwd)/run_postgres17_acceptance.sh"
