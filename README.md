# observability-grafana-starter

Personal Grafana-based observability starter kit for fast setup and practical configuration.

This repository is my own boilerplate for personal projects and applications, built as a quick-start observability stack with up-to-date Grafana, Loki, and optional Alloy configuration patterns.

Grafana and Loki are the core stack and always start together. Alloy is fully configured but disabled by default through a Docker Compose profile, so a normal Coolify deployment stays focused on Grafana + Loki while Fluent Bit can push logs directly to Loki.

## Personal Use Notice

This project is created for personal use and experimentation.

- No license is currently provided.
- Use at your own risk.
- I do not accept responsibility for issues, data loss, outages, or any damage caused by using this repository.

## Services

| Service | Default state | Network surface |
| --- | --- | --- |
| Grafana | Always on | Internal `grafana:3000`; expose this in Coolify |
| Loki | Always on | Internal `loki:3100`; do not assign a public domain |
| Alloy | Optional profile | Internal `alloy:12345`, `alloy:4317`, `alloy:4318`; do not assign a public domain |

## Coolify Deployment

Coolify treats the Compose file as the source of truth, so configure the required variables in this resource's environment settings.

1. Create a Docker Compose resource from this repository.
2. Set the required S3 and Grafana variables from `.env.example`.
3. Assign a Grafana domain to the `grafana` service only.
4. Grafana domain routing must target container port `3000`, for example `https://grafana.example.com:3000`.
5. Do not assign domains to `loki` or `alloy`.

Required production variables:

```dotenv
GRAFANA_ROOT_URL=https://grafana.example.com
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=change-me-use-a-long-random-password
LOKI_S3_BUCKET=loki-logs
LOKI_S3_ENDPOINT=s3.example.com
LOKI_S3_REGION=us-east-1
LOKI_S3_ACCESS_KEY_ID=change-me
LOKI_S3_SECRET_ACCESS_KEY=change-me
```

## Local Usage

Copy the example environment and fill in real S3-compatible storage values:

```bash
cp .env.example .env
```

Validate Compose rendering:

```bash
docker compose config
```

Run the core stack with loopback-only local ports:

```bash
docker compose -f compose.yaml -f compose.local.yaml up -d grafana loki
```

Open Grafana at `http://localhost:3000`.

## Optional Alloy

Alloy is behind the `alloy` profile. It collects Docker container logs from the local Docker daemon and also accepts OpenTelemetry logs over OTLP.

Run Alloy locally:

```bash
COMPOSE_PROFILES=alloy docker compose -f compose.yaml -f compose.local.yaml up -d
```

Run Alloy in Coolify by setting:

```dotenv
COMPOSE_PROFILES=alloy
```

Internal Alloy endpoints when enabled:

```text
OTLP gRPC: alloy:4317
OTLP HTTP: alloy:4318
Alloy UI:   alloy:12345
```

The Docker socket mount is read-only, but it still grants host container metadata access. Keep Alloy disabled unless you actually need this collector path.

## Fluent Bit

Default ingestion is direct Fluent Bit -> Loki over the private Compose network:

```text
http://loki:3100/loki/api/v1/push
```

Example Fluent Bit output:

```ini
[OUTPUT]
    Name        loki
    Match       *
    Host        loki
    Port        3100
    URI         /loki/api/v1/push
    Labels      service_name=$service_name,environment=production,host=$HOSTNAME,container_name=$container_name
    Line_Format json
```

Recommended indexed labels:

- `service_name`
- `environment`
- `host`
- `container_name`

Avoid high-cardinality labels such as request IDs, user IDs, trace IDs, IP addresses, full container IDs, and dynamic paths. Keep those in log body or structured metadata instead.

## Loki Storage

This boilerplate uses Loki TSDB schema `v13` with S3-compatible object storage. Retention is enabled through the Loki compactor and defaults to 30 days:

```dotenv
LOKI_RETENTION_PERIOD=720h
```

If your bucket has a lifecycle policy, keep it longer than the Loki retention period so Loki can compact and delete chunks intentionally.

Minimum bucket permissions:

- `s3:ListBucket`
- `s3:PutObject`
- `s3:GetObject`
- `s3:DeleteObject`

## Verification

Run the project validator:

```bash
bash tests/validate-boilerplate.sh
```

After starting the stack, check Loki readiness:

```bash
docker compose exec loki wget -qO- http://localhost:3100/ready
```

Push a test log directly to Loki:

```bash
curl -sS -X POST http://localhost:3100/loki/api/v1/push \
  -H 'Content-Type: application/json' \
  --data-raw '{"streams":[{"stream":{"service_name":"manual-test","environment":"local"},"values":[["'$(date +%s%N)'","manual loki test log"]]}]}'
```

Then open the provisioned `Loki Overview` dashboard in Grafana.

## Optional Future Features

- [ ] Tempo for distributed tracing
- [ ] Prometheus for metrics scraping and storage
- [ ] Grafana Alerting (rules, contact points, and notification policies)
- [ ] Prebuilt dashboards for common infrastructure and application workloads
