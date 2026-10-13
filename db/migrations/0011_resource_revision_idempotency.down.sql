BEGIN;
DROP TABLE IF EXISTS rva.idempotency_records;
ALTER TABLE rva.resources DROP COLUMN IF EXISTS revision;
COMMIT;
