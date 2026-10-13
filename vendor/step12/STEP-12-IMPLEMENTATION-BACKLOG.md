# Step 12 Implementation Backlog

## Delivery objective
Build the common security and persistence foundation required before canonical resources and the eight specialist assurance engines.

## P0 Epic 12.1: Tenant identity and isolation

### RVA12-TEN-001 Tenant registry
- Implement tenant identity, status, residency and retention settings.
- Acceptance: UUID identity; immutable creation; suspended tenants cannot establish request context.
- Evidence: migration tests and API context tests.

### RVA12-TEN-002 Composite tenant keys
- Every tenant-owned table uses `(tenant_id, entity_id)` keys and tenant-scoped foreign keys.
- Acceptance: cross-tenant references fail at the database boundary.

### RVA12-TEN-003 Transaction-local context
- Set verified tenant/principal/request context with transaction-local PostgreSQL settings.
- Acceptance: context disappears at commit/rollback and pooled connections cannot retain another tenant.

### RVA12-TEN-004 Forced RLS
- Enable and force RLS on every tenant-owned table; use explicit `USING` and `WITH CHECK` policies.
- Acceptance: no context means no rows; cross-tenant CRUD fails; owner-bypass is prevented for application paths.

### RVA12-TEN-005 Application role
- Provision a login role with `NOSUPERUSER NOBYPASSRLS`, no schema ownership and least privilege.
- Acceptance: automated role assertion passes.

### RVA12-TEN-006 Non-database boundaries
- Define tenant-prefixed cache, queue, object and export keys; workers use signed tenant envelopes.
- Acceptance: adversarial tests prove tenant mismatch rejection.

## P0 Epic 12.2: Identity and access boundary

### RVA12-IDN-001 OIDC access-token verification
- Trusted HTTPS issuer discovery, JWKS rotation, fixed algorithm allowlist, signature, issuer, audience, lifetime and tenant-membership validation.
- Acceptance: invalid/mismatched claims fail closed.

### RVA12-IDN-002 Server-owned tenant selection
- Client tenant selector never grants access; membership lookup authorises the selected tenant.
- Acceptance: selector mismatch returns 403 without confirming target existence.

### RVA12-IDN-003 RBAC plus ABAC contract
- Define permissions and domain/sensitivity constraints for future modules.
- Acceptance: deny-by-default policy unit tests.

## P0 Epic 12.3: Audit and evidence foundation

### RVA12-AUD-001 Append-only audit
- Add tenant-scoped audit events with actor, action, object, policy, request/correlation IDs and hashes.
- Acceptance: update/delete blocked; tenant RLS enforced.

### RVA12-EVD-001 Evidence metadata
- Add source/evidence identity, media type, size, SHA-256, storage key, captured/recorded times and provenance.
- Acceptance: storage keys are tenant-prefixed; content hash format enforced; metadata immutable.

### RVA12-EVD-002 Object-store adapter contract
- Define put/get/stat using server-generated tenant keys and signed-URL TTL policy.
- Acceptance: adapter rejects foreign tenant keys and caller-provided absolute keys.

## P1 Epic 12.4: Core service infrastructure

### RVA12-API-001 Request envelope
- Immutable server context containing tenant, principal, permissions, assurance attributes, request and correlation IDs.

### RVA12-API-002 Error contract
- Stable machine codes, safe messages and request ID; no stack/SQL/tenant-existence leakage.

### RVA12-DB-001 Migration runner
- Up/down/checksum ledger, single migration lock, transactional migrations and production backup precondition.

### RVA12-OPS-001 Observability integration
- Metrics and structured logs without tenant/user/request identifiers as high-cardinality labels.

## P1 Epic 12.5: Engineering assurance
- PostgreSQL 17 migration up/down/reapply.
- Adversarial RLS across all tenant tables and CRUD operations.
- Connection-pool context leakage test.
- Static composite-FK and FORCE-RLS audit.
- Backup/restore proof.
- SAST, dependency review, SBOM and provenance.

## Definition of done
Working code, tests, threat review, migration rollback, traceability, operational runbooks and retained evidence. No placeholder production paths or invented compliance claim.
