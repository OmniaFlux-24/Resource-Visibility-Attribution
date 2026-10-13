# Phase 13A Implementation Tickets

## Checkpoint A0: Contract freeze

### T13A-001 Canonical resource contract
**Scope:** Define tenant/resource identity, canonical URN, resource type, display identity, creation and retirement semantics.  
**Acceptance criteria:** composite `(tenant_id, resource_id)` key; tenant-unique canonical ID; no lifecycle/condition/availability enum on the resource row; OpenAPI/schema naming agreed; ADR approved.  
**Tests/evidence:** schema validator, invalid URN/type fixtures, traceability record.  
**Rollback checkpoint:** documentation and schema changes only; revert contract commit before any migration applies.

### T13A-002 Temporal semantics ADR
**Scope:** Define effective period, recorded-at, generated recorded period, corrections, supersession and as-known-at queries.  
**Acceptance criteria:** closed-open UTC timestamp ranges; correction is append-only; no destructive historical update; query examples for believed-at T about effective-at U.  
**Tests/evidence:** temporal test matrix and architecture approval.  
**Rollback checkpoint:** revert ADR and migration draft before A1.

## Checkpoint A1: Database foundation

### T13A-003 Resources migration
**Scope:** Create `rva.resources` with composite keys, canonical ID and provenance actor.  
**Acceptance criteria:** applies after Step 12; invalid cross-tenant actor fails; duplicate canonical ID in one tenant fails; same canonical ID across tenants is allowed; forced RLS present.  
**Tests/evidence:** migration up/down/reapply and RLS report.  
**Rollback checkpoint:** stop writes; run `0010_resource_ontology.down.sql` only if no dependent production data; otherwise restore pre-migration backup.

### T13A-004 Source mappings
**Scope:** Map external connector/source identities to canonical resources.  
**Acceptance criteria:** tenant-scoped uniqueness; SHA-256 source hash; first/last observed validation; cross-tenant resource mapping rejected.  
**Tests/evidence:** duplicate, cross-tenant and invalid-time tests.  
**Rollback checkpoint:** export mapping ledger; rollback migration or restore backup.

### T13A-005 Independent resource facets
**Scope:** Implement lifecycle, condition, availability, custody, classification and domain-attribute facets independently.  
**Acceptance criteria:** multiple facet kinds coexist for a resource; schema name/version required; JSON object and size validation; effective and recorded ranges retained; update/delete blocked.  
**Tests/evidence:** coexistence, payload, temporal and immutability tests.  
**Rollback checkpoint:** disable facet write route, retain inserted facts, deploy last compatible reader; destructive rollback requires approved export/restore.

### T13A-006 Resource events and corrections
**Scope:** Append-only resource events with correction/supersession links, source hash, correlation and causation.  
**Acceptance criteria:** updates/deletes blocked; self-correction prohibited; tenant-scoped correction links; provenance fields required; replay order deterministic by recorded time/event ID.  
**Tests/evidence:** immutability, correction chain and replay fixtures.  
**Rollback checkpoint:** stop event ingestion; do not delete accepted events; deploy last compatible reader and add compensating event where needed.

## Checkpoint A2: Security and access

### T13A-007 Tenant isolation policies
**Scope:** Enable and force RLS on all Phase 13A tables.  
**Acceptance criteria:** no context returns zero rows; Tenant A cannot read/write Tenant B; application role remains non-owner and `NOBYPASSRLS`; `USING` and `WITH CHECK` applied.  
**Tests/evidence:** adversarial SQL as `rva_app`.  
**Rollback checkpoint:** never disable RLS; withdraw feature traffic and restore prior attested schema/application.

### T13A-008 Least-privilege grants
**Scope:** Grant resource/mapping update and facet/event append privileges only.  
**Acceptance criteria:** no truncate/reference/trigger privilege; no facet/event update/delete; migration role separated from request role.  
**Tests/evidence:** privilege matrix query.  
**Rollback checkpoint:** revoke new grants immediately; restore previous grants from version-controlled SQL.

## Checkpoint A3: Query and API layer

### T13A-009 Bitemporal query repository
**Scope:** Implement current, effective-at, recorded-at and combined bitemporal queries.  
**Acceptance criteria:** parameterized SQL; tenant context transaction; correction history returned without mutation; bounded pagination.  
**Tests/evidence:** golden scenarios for late-arriving fact and correction.  
**Rollback checkpoint:** feature flag new query paths; retain schema; revert repository/API independently.

### T13A-010 Resource API contracts
**Scope:** Create resource, history, source-mapping and facet endpoints.  
**Acceptance criteria:** OpenAPI version; stable pagination; idempotent create; safe errors; RBAC/ABAC; audit/evidence linkage.  
**Tests/evidence:** contract, auth, tenant and compatibility tests.  
**Rollback checkpoint:** disable endpoints via feature flag and return to prior contract version.

## Checkpoint A4: Certification

### T13A-011 Migration and restore certification
**Acceptance criteria:** up/down/reapply in disposable PostgreSQL 17; backup/restore; RLS and temporal tests after restore.  
**Rollback checkpoint:** restore named pre-change backup and verify tenant gates before reopening.

### T13A-012 Performance and observability
**Acceptance criteria:** explain plans captured for canonical/source/as-of lookups; agreed latency/load targets met; metrics avoid tenant high-cardinality labels; alerts/runbooks active.  
**Rollback checkpoint:** revert indexes/query code, retain evidence, and restore previous release artifact.

### T13A-013 Independent acceptance
**Acceptance criteria:** Architecture, Security, Data, Platform and Product sign-off; no open P0 blocker; traceability complete.  
**Rollback checkpoint:** NO-GO and retain Step 13A behind disabled feature flag.
