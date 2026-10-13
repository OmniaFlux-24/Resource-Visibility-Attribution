# Bitemporal Query Repository Tickets

## T13A-QRY-001 Repository interface and query vocabulary
**Scope:** Define current, effective-at, recorded-at, combined as-known-at, full history and correction-chain methods for resources, facets and events.  
**Acceptance:** exact UTC instant semantics; tenant context required; stable method names; no query allows tenant override; result schemas reference OpenAPI models.  
**Tests:** interface contract and invalid/missing time tests.  
**Rollback:** revert interface before implementation; no data change.

## T13A-QRY-002 Current resource lookup
**Scope:** Lookup by resource ID and canonical ID with retirement policy.  
**Acceptance:** parameterized SQL; returns zero/one tenant-visible resource; optionally includes current independent facets; no hidden cross-tenant existence signal.  
**Tests:** found, missing, retired and wrong-tenant fixtures.  
**Rollback:** feature-flag repository method and use preceding lookup.

## T13A-QRY-003 Effective-at facet query
**Scope:** Return facets where `effective_period @> effectiveAt`.  
**Acceptance:** filter by facet kind/schema; deterministic order by kind/schema/recorded time; bounded result count.  
**Tests:** inclusive lower, exclusive upper, unbounded upper and empty/invalid input.  
**Rollback:** disable temporal filter endpoint; retain stored facts.

## T13A-QRY-004 Recorded-at query
**Scope:** Reconstruct facts visible as recorded at a given time.  
**Acceptance:** `recorded_period @> recordedAt`; no future recorded fact returned; correction lineage retained.  
**Tests:** late arrival and before/after correction scenarios.  
**Rollback:** revert query code; no schema rollback.

## T13A-QRY-005 Combined bitemporal reconstruction
**Scope:** Answer what RVA believed at recorded time T about effective time U.  
**Acceptance:** both ranges contain their supplied instants; latest applicable recorded version selected per facet identity; deterministic tie-break by `recorded_at, facet_id`; complete provenance returned.  
**Tests:** backdated fact, correction, supersession and simultaneous recordings.  
**Rollback:** disable combined endpoint and retain history endpoint.

## T13A-QRY-006 Event history and correction chain
**Scope:** Paginate resource events and traverse correction/supersession references.  
**Acceptance:** keyset cursor uses recorded time and event ID; maximum page size 100; cycle/depth guard; source hash and actor preserved.  
**Tests:** first/next pages, invalid cursor, chain depth and tenant mismatch.  
**Rollback:** disable chain expansion while retaining flat event history.

## T13A-QRY-007 Source mapping lookup
**Scope:** Resolve canonical resource from connector/source identity.  
**Acceptance:** all five source identity fields parameterized; zero/one result; never accepts raw SQL fragments; tenant transaction required.  
**Tests:** found, duplicate prevention, wrong tenant and malicious source strings.  
**Rollback:** return connector ingestion to quarantine/manual matching.

## T13A-QRY-008 Performance and plan governance
**Scope:** Capture `EXPLAIN (ANALYZE, BUFFERS)` for canonical, source and bitemporal paths.  
**Acceptance:** agreed staging dataset and targets documented; intended indexes used; no unbounded sequential scan accepted without review.  
**Tests/evidence:** versioned plans and load report.  
**Rollback:** revert index/query change separately and rerun correctness gates.

## T13A-QRY-009 Repository security review
**Acceptance:** no string interpolation of record values; all methods enter Step 12 tenant transaction; safe errors; query timeouts; row limits; audit for sensitive history export.  
**Rollback:** block repository promotion on any P0 finding.

## T13A-QRY-010 Independent acceptance
**Acceptance:** Data, Security, Platform and API reviewers approve; OpenAPI compatibility test passes; PostgreSQL 17 native suite passes.  
**Rollback:** NO-GO and keep feature flag disabled.
