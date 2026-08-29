# JMeter Performance Testing with Dynatrace

A containerized Apache JMeter performance testing setup for the [dtpay](https://github.com/domuharahap/sampleusecase) application, with built-in Dynatrace observability integration.

## Overview

This repo provides ready-to-run JMeter load tests packaged as Docker images. Each version adds deeper Dynatrace integration — from basic monitoring up to live stats streaming via Business Events.

**Application under test:** dtpay — a payment demo app deployed on Kubernetes and monitored by Dynatrace.

**Test scenarios (all versions):**
- `GET /` — Home Page
- `POST /api/payment` — Payment request with randomized amount, method, name, and user ID

---

## Versions

| Version | Docker Image | What's new |
|---------|-------------|------------|
| v1.0 | `domuharahap/jmeter-testing:1.0` | Basic load test — homepage and payment endpoint |
| v1.2 | `domuharahap/jmeter-testing:1.2` | Adds `x-dynatrace-test` header + request attributes for Dynatrace test marking |
| v1.3 | `domuharahap/jmeter-testing:1.3` | Sends BizEvents to Dynatrace at test start and end with full summary stats |
| v1.4 | `domuharahap/jmeter-testing:1.4` | Same as v1.3 + live stats BizEvent sent every 30s (configurable) |

### v1.0 — Basic Performance Test

Runs load against the home page and payment API. Results visible in Dynatrace APM traces since the app is instrumented with a Dynatrace agent.

### v1.2 — Dynatrace Test Marking

Adds the standard `x-dynatrace-test` header to every request:

```
x-dynatrace-test: LTN=<test-name>;LSN=<scenario>;TSN=<sampler>;VU=<thread>;RUN=<time>;RID=<run-id>
```

This lets Dynatrace correlate HTTP traces back to specific JMeter test runs. Also includes custom headers (`X-JMeter-Test-Case`, `X-JMeter-Active-Threads`, etc.) for request-level attribution.

### v1.3 — BizEvents: Start & End Summary

Sends two Business Events to Dynatrace:

1. **`com.jmeter.test.start`** — fired before the test begins (setUp thread group)
2. **`com.jmeter.test.summary`** — fired after the test ends (tearDown thread group) with full stats:
   - Samples, avg/min/max response time, std dev, error %, throughput, KB/s per sampler
   - A `TOTAL` row aggregating all samplers
   - Thread count, ramp-up, and duration metadata

This enables Dynatrace Notebooks/Dashboards to compare stats across multiple test runs using `fetch bizevents`.

### v1.4 — BizEvents: Live Stats (every 30s)

Extends v1.3 with a background thread group that sends incremental stats to Dynatrace every 30 seconds during the test. Useful for real-time visibility into performance trends while the test is running.

Live stats interval is configurable via `STATS_INTERVAL_SEC` (default: `30`).

---

## Configuration

All parameters are passed as environment variables.

| Variable | Default | Description |
|----------|---------|-------------|
| `JVM_THREADS` | `10` | Number of concurrent virtual users |
| `JVM_LOOPS` | `1` | Iterations per thread (`-1` = run for full duration) |
| `JVM_DURATION` | `60` | Test duration in seconds |
| `JVM_APP_URL` | `dtpay.34.67.92.11.nip.io` | Target app domain (no protocol/port) |
| `JVM_DT_URL` | _(required)_ | Dynatrace environment URL (e.g. `https://xxx.live.dynatrace.com`) |
| `JVM_DT_TOKEN` | _(required)_ | Dynatrace API token with `bizevents.ingest` scope |

---

## Running on Kubernetes

### 1. Create Dynatrace credentials secret

```bash
kubectl create secret generic dynatrace-creds \
  --from-literal=DT_URL=https://<your-tenant>.live.dynatrace.com \
  --from-literal=DT_TOKEN=<your-api-token> \
  -n jmeter
```

### 2. Run the job

```bash
kubectl apply -f jmeter-job.yaml
```

The job runs once, auto-deletes after 60 seconds (`ttlSecondsAfterFinished: 60`), and does not retry on failure.

### 3. Check logs

```bash
kubectl logs -n jmeter job/jmeter-load-test
```

---

## Running with Docker

```bash
docker run --rm \
  -e JVM_THREADS=20 \
  -e JVM_DURATION=120 \
  -e JVM_APP_URL=dtpay.yourdomain.com \
  -e JVM_DT_URL=https://<your-tenant>.live.dynatrace.com \
  -e JVM_DT_TOKEN=<your-api-token> \
  domuharahap/jmeter-testing:1.4
```

---

## Building the Docker Image

The Dockerfile copies the latest JMX plan and the entrypoint script:

```bash
docker build -t domuharahap/jmeter-testing:<version> .
docker push domuharahap/jmeter-testing:<version>
```

---

## Dynatrace Setup

### Required API Token Scopes
- `bizevents.ingest` — for sending Business Events (v1.3 and v1.4)

### Querying BizEvents in Dynatrace

Use DQL in a Dynatrace Notebook to compare test runs:

```
fetch bizevents
| filter event.type == "com.jmeter.test.summary"
| sort timestamp desc
```

Filter by run ID, compare throughput and response times across sprints.

---

## Tech Stack

- **JMeter** 5.6.3 (headless, non-GUI mode)
- **Java** 17 (OpenJDK, Alpine-based image)
- **Groovy** scripts for random data generation and BizEvent publishing
- **Kubernetes** Job for one-shot execution
- **Dynatrace** Business Events API v2 for test telemetry
