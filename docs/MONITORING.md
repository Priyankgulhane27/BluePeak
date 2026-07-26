# Monitoring, Alerting & Recommended Metrics

## What's already wired up (Terraform `monitoring` module)

An SNS topic (`bluepeak-<env>-alerts`) fans out to email (configurable) and
can be extended to Slack/PagerDuty via a subscription. Alarms currently cover:

| Alarm | Threshold | Why it matters |
|---|---|---|
| ALB 5xx count | >10 in a 3-minute window | Customer-facing errors from the app tier |
| ALB p95 target response time | >1s | Latency degradation impacting SLA/UX before it becomes an outage |
| ALB unhealthy target count | >0 | Early warning that a task is failing health checks, before capacity runs out |
| ECS service CPU | >85% sustained | Autoscaling is not keeping up with demand |
| Aurora CPU | >80% sustained | DB tier under load, may need higher max ACU |
| Aurora connection count | configurable (default 200) | Approaching connection exhaustion, a common silent failure mode |

A CloudWatch dashboard (`bluepeak-<env>-overview`) plots ALB requests/errors,
p95 latency, ECS CPU/memory, and Aurora CPU/connections on one screen.

## Recommended additional metrics (operational)

- **ECS task restart/failure count** — frequent restarts indicate a bad
  deploy or memory leak before customers report anything.
- **ECS deployment success/rollback rate** — tracks release health over time.
- **NAT Gateway bytes/packets dropped** — signals egress bottlenecks under load.
- **Aurora replica lag** (`AuroraReplicaLag`) — matters if reads are later
  routed to the reader endpoint; stale reads are a correctness risk for a
  finance app.
- **WAF blocked-request rate** — a spike often precedes or accompanies an
  attempted attack and is worth alerting on even if requests are being blocked
  successfully.
- **Secrets Manager rotation failures** (once rotation is enabled) — a
  silent failure here can lock the app out of the database at the worst time.

## Recommended business/customer-experience metrics

These are the ones that map to "improve customer satisfaction and platform
reliability" specifically, not just infrastructure health:

- **API success rate per business action** (increment/decrement succeeded vs.
  failed) — the direct proxy for "did the customer's action actually work,"
  as distinct from "did the server return 200."
- **End-to-end request latency percentiles (p50/p95/p99) from the client's
  perspective**, not just ALB-measured latency — consider Real User
  Monitoring (RUM) via CloudWatch RUM if/when the frontend grows past a
  static counter.
- **Error budget burn rate against an agreed SLA** (e.g., 99.9% availability)
  — translates raw alarm counts into "are we on track to breach this month's
  SLA," which is what actually drives customer trust and support tickets.
- **Time-to-detect / time-to-recover (MTTD/MTTR)** for incidents — tracked
  operationally, reported back as a reliability trend over quarters.
- **Cost per transaction** — for a finance company scaling with demand,
  tracking Fargate + Aurora ACU spend against transaction volume catches
  runaway scaling (e.g., a scaling policy stuck at max) before the AWS bill does.

## Logging

- ECS task logs → CloudWatch Logs (`/ecs/bluepeak-<env>-app`), 30-day retention.
- VPC Flow Logs → CloudWatch Logs, 90-day retention (network audit trail).
- ALB access logs → S3 (bucket supplied via `access_logs_bucket` variable;
  disabled by default in the assessment stack to avoid requiring a
  pre-existing bucket — recommended to enable for production).
- Aurora audit/error/slow-query logs → CloudWatch Logs via
  `enabled_cloudwatch_logs_exports`.

## Suggested SLOs to formalize with the business

| SLO | Target (starting point) |
|---|---|
| Availability (successful responses / total requests) | 99.9% monthly |
| p95 latency for counter API calls | < 300ms |
| Scale-out time from alarm to healthy new task | < 2 minutes |
| RPO for the database | < 5 minutes (Aurora automated backups + point-in-time recovery) |
| RTO for a single-AZ failure | Near-zero (Multi-AZ failover is automatic) |
