# Step 12 Threat Model

Assets: tenant data, identity/member relationships, audit evidence, object keys and database context. Threats include selector injection, IDOR/BOLA, missing filters, request-role bypass, pool leakage, worker-envelope substitution, key collisions, signed-URL reuse and log/export leakage. Controls are server-verified membership, immutable contexts, forced RLS, composite FKs, non-bypass roles, transaction-local settings, tenant namespaces, exact envelope checks, short-lived signed URLs, redaction and adversarial tests.
