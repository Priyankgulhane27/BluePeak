# Architecture Diagram (quick view)

> The authoritative editable diagram is [`diagram.drawio`](./diagram.drawio) — open it at https://app.diagrams.net.
> This Mermaid version renders directly on GitHub for a fast preview.

```mermaid
flowchart TB
    Internet((Internet Users)) --> R53[Route 53 DNS]
    R53 --> WAF[AWS WAF<br/>managed rules + rate limiting]
    WAF --> ALB[Application Load Balancer<br/>public subnets, 2 AZs]

    subgraph VPC["VPC 10.20.0.0/16"]
        subgraph Public["Public Subnets"]
            ALB
            NAT1[NAT Gateway AZ-a]
            NAT2[NAT Gateway AZ-b]
        end

        subgraph AppTier["Private App Subnets - ECS Fargate"]
            ECS1[Fargate Task AZ-a]
            ECS2[Fargate Task AZ-b]
            AAS[Application Auto Scaling<br/>CPU + ALB RequestCountPerTarget]
        end

        subgraph DataTier["Private DB Subnets - RDS PostgreSQL"]
            RDS[(RDS PostgreSQL Instance<br/>Single-AZ on Free Plan)]
        end
    end

    ALB --> ECS1
    ALB --> ECS2
    ECS1 --> NAT1
    ECS2 --> NAT2
    ECS1 --> RDS
    ECS2 --> RDS
    AAS -.scales.-> ECS1
    AAS -.scales.-> ECS2

    ECS1 -. reads creds .-> SM[Secrets Manager]
    ECS2 -. reads creds .-> SM
    ECS1 -. logs .-> CW[CloudWatch Logs/Metrics]
    ECS2 -. logs .-> CW
    ALB -. logs .-> CW
    RDS -. metrics .-> CW
    CW --> SNS[SNS Alerts -> Email/Slack]
```

## Tier summary

| Tier | Components | Subnet placement | Internet reachability |
|---|---|---|---|
| Presentation | Static assets served by app container, browser | N/A (client-side) | Direct via ALB |
| Application | ECS Fargate service (Node.js/Express), Application Auto Scaling | Private-app subnets, 2 AZs | Only via ALB; egress via NAT for ECR/Secrets Manager/CloudWatch |
| Data | RDS PostgreSQL, Single-AZ by default (`multi_az` togglable) | Private-db subnets | None — no route to internet at all |

> **Note:** the data tier was originally designed as Aurora PostgreSQL
> Serverless v2 with a writer + reader across 2 AZs. It was changed to a
> standard RDS PostgreSQL instance because AWS Free Plan accounts can only
> create Aurora clusters via an "express configuration" path that cannot be
> placed inside a customer VPC — incompatible with this project's private-
> network requirement. See `docs/ARCHITECTURE.md` section 4a for the full
> explanation and how to restore Multi-AZ/elastic scaling off the Free Plan.
