# Step 12 Traceability

| Requirement | Module | Tests | Evidence | Gate |
|---|---|---|---|---|
| Tenant isolation | DB/tenancy | RLS adversarial | PG report | P0 |
| Verified context | tenancy/API | context unit/API | test report | P0 |
| Append-only audit | audit/DB | immutability/RLS | DB report | P0 |
| Evidence metadata | evidence/DB | hash/key tests | test report | P0 |
| OIDC boundary | security | token negative suite | identity report | P0 |
