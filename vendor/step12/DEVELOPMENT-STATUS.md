# Step 12 Development Status

## Implemented and locally verified

- Prioritized Step 12 backlog with P0/P1 acceptance and evidence.
- ADR-001 tenant isolation.
- Immutable validated request context.
- Active membership tenant selection.
- Transaction-local PostgreSQL context helper.
- Tenant namespaces for cache, queue, objects and exports.
- HMAC-signed, expiring worker envelopes with tenant binding.
- Tenant-safe evidence object keys.
- Safe API error contract.
- PostgreSQL migrations for tenants, principals, audit and evidence.
- Composite tenant keys and foreign keys.
- Forced RLS on all tenant-owned tables.
- Append-only audit and immutable evidence triggers.
- Application role definition with `NOSUPERUSER NOBYPASSRLS`.
- PostgreSQL adversarial isolation SQL and migration rollback/reapply runner.
- CI workflow for unit/static and native PostgreSQL 17 integration.

## Passed here

- Static migration/RLS/role/backlog/ADR audit.
- Six Node unit tests covering context, tenant selection, namespaces, evidence keys, signed envelopes and transaction handling.

## Not executed here

The sandbox does not provide a PostgreSQL server/client, so native migration, RLS, rollback and reapply execution is configured in CI but not claimed as passed locally.

## Deferred backlog

OIDC/JWKS runtime integration, SAML, MFA/step-up, ABAC policy store, migration checksum ledger, object-store implementation, backup/restore evidence, queues/caches/export adapters and real observability deployment remain open Step 12 work. Domain ontology and engines remain outside Step 12.

## Release decision

NO-GO. This is a working shared-foundation slice, not a complete SaaS or production certification.
