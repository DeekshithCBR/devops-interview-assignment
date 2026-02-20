# Monitoring and Observability Setup

## Metrics

* **Application:** request latency (p50/p95/p99), error rate, throughput
  (chunks/sec), upload success rate, queue depth, disk usage.
* **Infrastructure:** CPU/memory of EKS nodes, pod restarts, GPU
  utilization, pod network bytes.
* **Business:** number of video chunks processed per hour/day,
  SLA compliance, number of edge devices online.
* **Edge Device:** VPN tunnel status, interface throughput, MTU errors,
  GPU temperature, local disk usage, container health.

Metrics are exported via Prometheus on the cluster and pushed to
CloudWatch for centralized alerting.  Edge devices run a small
Prometheus/Pushgateway agent.

## SLOs (Service Level Objectives)

* **Availability:** 99.9% uptime for API ingestion and processing
  (drop of 43.2 min/month).
* **Latency:** 95% of upload requests complete within 30 s (end‑to‑end).
* **Data Freshness:** 99% of video chunks must be uploaded within 10
  minutes of capture.
* **Edge Uptime:** 99.5% per device per month.

SLOs are measured by comparing CloudWatch metrics against thresholds
and generating burn rate alerts when the error budget is exhausted.

## Alerting

* **Page:** high-severity outages such as upload failure rate > 5% for
  10 min, VPN tunnel down > 5 min, disk > 90% on any edge device.
* **Ticket:** degraded performance (latency > 30 s), CPU > 80% for 15 min,
  S3 upload errors > 1%.
* **Info:** low‑priority logs (failed login attempts, minor container
  restarts) reported to logging system but not paged.

Use burn‑rate alerts to throttle pages (e.g. if 3 critical alerts fire in
1 hour escalate to L2).  Integrate with PagerDuty/Slack for notifications.

## Escalation

1. **L1 (automated):** run remediation scripts (e.g., reset MTU, restart
   containers) via self‑healing runbooks.
2. **L2 (on-call engineer):** investigate alerts, analyze dashboards and
   logs, deploy fixes or rollbacks.
3. **L3 (senior architect):** for prolonged outages, security incidents,
   or customer impact.  Notify customers if SLA is breached > 30 min.

Edge devices report back to central system; on-call engineer can
trigger remote commands or dispatch field technician if automated
remediation fails.

## Dashboards

* **Service Overview:** health of video processor pods, error rate,
  request latency lines, PVC/disk usage.
* **Cluster Health:** node CPU/memory, pod restarts, GPU metrics.
* **Edge Fleet:** list of devices, tunnel status, disk usage, MTU errors,
  scaled down/up events.
* **Business Metrics:** chunks processed per site, upload success rate,
  cost vs. budget graphs.

Each dashboard has links to relevant runbooks and Grafana panels for
quick navigation.
