# User Guide

This guide covers local use, Coolify deployment, ingestion paths, storage and verification for the Grafana Observability Starter Kit.

## Stack

Grafana and Loki are the core services and start together. Loki can use external S3-compatible storage or the self-hosted MinIO variant. Alloy is configured as an optional Compose overlay.

| Service | Default state | Network surface |
| --- | --- | --- |
| Grafana | Always on | Internal `grafana:3000`; expose this in Coolify |
| Loki | Always on | Internal `loki:3100`; do not assign a public domain |
| MinIO | Self-hosted S3 overlay | Internal `minio:9000`, `minio:9001`; do not assign a public domain |
| Alloy | Optional `compose.features.alloy.yaml` overlay | Internal `alloy:12345`, `alloy:4317`, `alloy:4318`; do not assign a public domain |

## Coolify Deployment

Coolify should treat [compose.yaml](../compose.yaml) as the canonical base Compose file.

1. Create a Docker Compose resource from this repository.
2. Set the required S3 and Grafana variables from [.env.example](../.env.example).
3. Assign a Grafana domain to the `grafana` service only.
4. Grafana domain routing must target container port `3000`, for example `https://grafana.example.com:3000`.
5. Do not assign domains to `loki` or `alloy`.

Required production variables for the external S3 base stack:

```dotenv
GRAFANA_ROOT_URL=https://grafana.example.com
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=change-me-use-a-long-random-password
GRAFANA_COOKIE_SECURE=true
LOKI_S3_BUCKET=loki-logs
LOKI_S3_ENDPOINT=s3.example.com
LOKI_S3_REGION=us-east-1
LOKI_S3_ACCESS_KEY_ID=change-me
LOKI_S3_SECRET_ACCESS_KEY=change-me
```

To use self-hosted MinIO instead, copy [.env.self-hosted-s3.example](../.env.self-hosted-s3.example) and run with [compose.self-hosted-s3.yaml](../compose.self-hosted-s3.yaml):

```bash
cp .env.self-hosted-s3.example .env
docker compose --env-file .env -f compose.yaml -f compose.self-hosted-s3.yaml up -d
```

## Dokploy Deployment

Dokploy has explicit import files per storage variant.

For self-hosted MinIO-backed S3, import:

```text
dokploy/templates/dokploy-self-hosted-s3.json
```

The Dokploy self-hosted S3 template exposes only the `grafana` service on port `3000`. Loki, MinIO and Alloy stay internal. It uses `http://${main_domain}` for `GRAFANA_ROOT_URL`; switch it to HTTPS only if your Dokploy ingress is configured for HTTPS.

For external S3-compatible storage, import:

```text
dokploy/templates/dokploy-external-s3.json
```

The templates embed the runtime config files from `config/` as Dokploy mounts, so update Dokploy templates whenever those files change.

## Local Usage

Copy the example environment for external S3 and fill in real S3-compatible storage values:

```bash
cp .env.example .env
```

If you use plain HTTP locally at `http://localhost:3000`, set this value in `.env`:

```dotenv
GRAFANA_COOKIE_SECURE=false
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

For self-hosted MinIO storage:

```bash
cp .env.self-hosted-s3.example .env
docker compose --env-file .env -f compose.yaml -f compose.self-hosted-s3.yaml -f compose.local.yaml up -d
```

## Optional Alloy

Alloy collects Docker container logs from the local Docker daemon and accepts OpenTelemetry logs over OTLP.

Run Alloy locally by adding [compose.features.alloy.yaml](../compose.features.alloy.yaml) to the selected storage variant.

External S3 plus Alloy:

```bash
docker compose --env-file .env -f compose.yaml -f compose.features.alloy.yaml up -d
```

Self-hosted MinIO plus Alloy:

```bash
docker compose --env-file .env -f compose.yaml -f compose.self-hosted-s3.yaml -f compose.features.alloy.yaml up -d
```

Internal Alloy endpoints when enabled:

```text
OTLP gRPC: alloy:4317
OTLP HTTP: alloy:4318
Alloy UI:   alloy:12345
```

The Docker socket mount is read-only, but it still grants host container metadata access. Keep Alloy disabled unless you actually need this collector path.

## Fluent Bit

Default ingestion is direct Fluent Bit to Loki over the private Compose network:

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

Avoid high-cardinality labels such as request IDs, user IDs, trace IDs, IP addresses, full container IDs and dynamic paths. Keep those in the log body or structured metadata instead.

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

The self-hosted S3 variant creates the Loki bucket in MinIO through the `minio-createbucket` one-shot service before Loki starts.

## Verification

Run the project validator:

```bash
bash tests/validate-boilerplate.sh
```

Validate the rendered Compose model with optional Alloy enabled:

```bash
docker compose --env-file .env.example -f compose.yaml -f compose.features.alloy.yaml config
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
