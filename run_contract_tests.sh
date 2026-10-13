#!/usr/bin/env bash
set -euo pipefail
base="$(cd "$(dirname "$0")" && pwd)"
python3 "$base/tests/openapi_contract_test.py" "$base/contracts/openapi.yaml"
node --test "$base/tests/repository.test.mjs" "$base/tests/handlers.integration.test.mjs" "$base/tests/idempotency.test.mjs"
