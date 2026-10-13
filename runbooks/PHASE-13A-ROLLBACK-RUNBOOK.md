# Phase 13A Rollback Runbook

## A0 Contract freeze
Trigger: unresolved ontology ambiguity or incompatible API naming. Rollback: revert contract/ADR commit; no runtime action. Verification: baseline Step 12 tests unchanged.

## A1 Database foundation
Trigger: migration, RLS, integrity or restore failure. Contain: disable Phase 13A feature flag and stop ontology writes. If no accepted data/dependency exists, execute the down migration in a disposable/rehearsed path. If data exists, preserve evidence, deploy the previous compatible application and restore the named pre-change PostgreSQL backup rather than deleting history. Verification: Step 12 tenant/identity gates pass, schema version restored, no Phase 13A routes active.

## A2 Security and access
Trigger: cross-tenant visibility, overbroad grant or role bypass. Treat as SEV1. Do not disable RLS. Withdraw service traffic, revoke the new privileges, restore the previous role grant file and prior artifact, then run all tenant-isolation gates.

## A3 Query and API
Trigger: incorrect bitemporal result, compatibility break or unacceptable latency. Disable Phase 13A endpoints behind the feature flag. Retain the append-only schema and data. Revert repository/API code and published contract to the preceding compatible version. Do not rewrite events or facets.

## A4 Certification
Any failed mandatory gate means NO-GO. Keep the feature disabled, retain evidence and create corrective tickets. Production promotion resumes only after rerunning the full migration, restore, isolation, temporal, security and performance gates.
