# Step 12 Test Plan

- Static: migration pairs, composite keys/FKs, FORCE RLS and policy coverage.
- Unit: tenant UUID/context/envelope validation, key namespace and safe errors.
- PostgreSQL integration: up/down/reapply, no context, malformed context, cross-tenant CRUD, FK mismatch, owner/app role behavior and pool reuse.
- API: invalid token, issuer/audience mismatch, selector without membership, permission/domain/sensitivity denial.
- Worker/storage: signed-envelope mismatch, queue/cache/object/export tenant collision.
- Operational: backup/restore, RLS after restore, metrics/log privacy and rollback rehearsal.
