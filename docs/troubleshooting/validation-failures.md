\# Validation Failures



\## Workflow Missing

\*\*Symptoms:\*\*

\- `.github/workflows` not found



\*\*Resolution:\*\*

\- Verify workflow files exist and are committed.



\## PostgreSQL Missing

\*\*Symptoms:\*\*

\- `initdb: command not found`



\*\*Resolution:\*\*

\- Install PostgreSQL 17 and ensure `initdb`, `pg\_ctl`, `psql`, and `pgbench` exist in PATH.



\## Step12 Dependency Missing

\*\*Symptoms:\*\*

\- `STEP12\_ROOT` invalid



\*\*Resolution:\*\*

\- Verify `vendor/step12` contains extracted Step12 content.



\## OpenAPI Validation Failure

\*\*Symptoms:\*\*

\- Contract validation failed



\*\*Resolution:\*\*

\- Verify `contracts/openapi.yaml` exists and matches tests.



\## Concurrency Failure

\*\*Symptoms:\*\*

\- Expected one row got zero



\*\*Resolution:\*\*

\- Verify:

&#x20; - `0011` migration applied

&#x20; - RLS context set

&#x20; - Tenant fixtures loaded



\## pgbench Failure

\*\*Symptoms:\*\*

\- Relation `rva.idempotency\_records` does not exist



\*\*Resolution:\*\*

\- Verify migration 0011 completed successfully.

