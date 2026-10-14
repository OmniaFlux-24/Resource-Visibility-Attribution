\# Observability Architecture



\## 1. The Three Pillars

The RVA platform implements the three pillars of observability:



\### 1.1 Logs (Structured JSON)

\- All application logs are emitted as structured JSON.

\- Fields: `timestamp`, `level`, `service`, `tenant\_id`, `message`, `trace\_id`.

\- Routed to: \*\*AWS CloudWatch Logs\*\* (Production) / \*\*Console\*\* (Development).



\### 1.2 Metrics (OpenTelemetry)

\- Key metrics: Request latency (p50, p95, p99), Error rates, Database connection pool usage, Active tenant count.

\- Exported via: \*\*OpenTelemetry Protocol (OTLP)\*\*.

\- Backend: \*\*AWS CloudWatch Metrics\*\* or \*\*Datadog\*\*.



\### 1.3 Traces (Distributed Tracing)

\- Every incoming HTTP request generates a `trace\_id`.

\- Traces propagate through: HTTP Handler → Repository → PostgreSQL.

\- Backend: \*\*AWS X-Ray\*\* or \*\*Jaeger\*\*.



\## 2. Alerting Thresholds

| Metric | Warning | Critical |

|--------|---------|----------|

| p95 Latency | > 500ms | > 2000ms |

| Error Rate | > 1% | > 5% |

| DB Pool Usage | > 80% | > 95% |



\## 3. Implementation Status

\- \[x] Structured logging framework defined

\- \[x] OpenTelemetry configuration documented

\- \[ ] CI check for log format validation (TODO)

\- \[ ] Production alerting rules deployed (TODO)

