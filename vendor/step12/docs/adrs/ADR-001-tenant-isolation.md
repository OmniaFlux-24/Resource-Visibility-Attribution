# ADR-001: Tenant Isolation Strategy

**Status:** Accepted for Step 12 implementation baseline  
**Date:** 13 October 2026  
**Decision owners:** CTO, Security Engineering, Data Engineering

## Context
RVA is a pooled SaaS platform containing assurance evidence and findings. A cross-tenant disclosure is a critical failure. Isolation must cover API, workers, PostgreSQL, caches, queues, object storage, exports, search, logs and signed URLs.

## Decision
1. Use opaque UUID tenant identity.
2. Authenticate with a trusted OIDC provider. A tenant selector is only a selector; current membership or service authorisation grants access.
3. Carry immutable, server-verified tenant context through the request/worker envelope.
4. For PostgreSQL tenant-owned tables use `tenant_id` first in primary/unique keys and all inter-table foreign keys.
5. Set `rva.tenant_id`, principal and request values transaction-locally after `BEGIN` and before tenant queries.
6. Enable and force RLS. Policies use fail-closed tenant functions in both `USING` and `WITH CHECK`.
7. Application roles are not table owners, superusers or `BYPASSRLS`; they cannot change policies, roles or tenant context through arbitrary SQL.
8. Administrative migrations use a separate controlled role and are never used on request paths.
9. Queue/cache/object/export/search identifiers are server-generated tenant-prefixed namespaces. Workers compare authenticated envelope tenant with payload and referenced records.
10. Logs and metrics carry bounded environment/service attributes. Tenant and user identity, when operationally necessary, are protected structured fields, not metric labels.
11. Every boundary receives adversarial tenant-isolation tests.

## RLS function design
`rva.current_tenant_id()` reads a missing-tolerant custom setting, converts empty/malformed values to null and is stable. Null never matches a non-null tenant key. Context is established with `set_config(..., true)` inside an explicit transaction.

## Alternatives rejected
- Application WHERE clauses only: vulnerable to omitted filters.
- Database per tenant initially: creates disproportionate operational/migration cost for the baseline; retain as a future tier/regulated isolation option.
- Schema per tenant: migration and connection/search complexity with incomplete isolation outside PostgreSQL.
- Session-scoped tenant setting: unsafe with pools due to context retention.
- Superuser request role: RLS bypasses by definition.

## Consequences
Benefits: defence in depth, consistent FK/RLS boundary, pooled efficiency and testable isolation. Costs: composite keys, transaction discipline, RLS planning overhead, explicit worker/storage contracts and careful administration.

## Failure and rollback
Missing or malformed context denies access. If an RLS rollout causes an outage, disable affected feature traffic and redeploy the last attested application/migration set; never turn off RLS as an availability workaround. Database rollback requires proven schema/data compatibility and a restore point.

## Verification
Static schema audit; app-role assertions; no-context and malformed-context tests; cross-tenant SELECT/INSERT/UPDATE/DELETE; tenant FK mismatch; pool reuse; workers; cache; object keys; exports; backup restore and penetration testing.
