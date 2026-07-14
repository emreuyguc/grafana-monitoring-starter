# Dokploy

This folder contains Dokploy import artifacts for the Grafana Observability Starter Kit.

## Files

| Path | Purpose |
| --- | --- |
| `config.self-hosted-s3.toml` | Self-hosted S3 Dokploy variables, domain mapping and environment defaults |
| `config.external-s3.toml` | External S3 Dokploy variables, domain mapping and environment defaults |
| `templates/dokploy-self-hosted-s3.json` | Self-hosted MinIO variant import template |
| `templates/dokploy-external-s3.json` | External S3 variant import template |

## Variant Map

| Variant | Compose files | Env example | Dokploy config | Dokploy import |
| --- | --- | --- | --- | --- |
| Self-hosted S3 | `compose.yaml` + `compose.self-hosted-s3.yaml` | `.env.self-hosted-s3.example` | `dokploy/config.self-hosted-s3.toml` | `dokploy/templates/dokploy-self-hosted-s3.json` |
| External S3 base | `compose.yaml` | `.env.example` | `dokploy/config.external-s3.toml` | `dokploy/templates/dokploy-external-s3.json` |
| Alloy feature | `compose.features.alloy.yaml` | same selected storage env | no default Dokploy template | manually add overlay service if needed |

## Usage

Import the self-hosted MinIO-backed S3 template in Dokploy:

```text
dokploy/templates/dokploy-self-hosted-s3.json
```

For external S3, import:

```text
dokploy/templates/dokploy-external-s3.json
```

The external S3 template does not start MinIO or another S3 service. After import, set real external S3-compatible Loki storage values before deploying:

```dotenv
LOKI_S3_BUCKET=loki-logs
LOKI_S3_ENDPOINT=http://s3.example.com
LOKI_S3_REGION=us-east-1
LOKI_S3_ACCESS_KEY_ID=replace_with_s3_access_key_id
LOKI_S3_SECRET_ACCESS_KEY=replace_with_s3_secret_access_key
LOKI_S3_INSECURE=true
```

If your S3 endpoint uses HTTPS, switch `LOKI_S3_ENDPOINT` to the HTTPS endpoint and set `LOKI_S3_INSECURE=false`.

Only the `grafana` service should receive a public domain. Loki, MinIO and Alloy stay internal.

## Alloy

Alloy is disabled in the committed Dokploy templates. To use Alloy in Dokploy, add the Alloy service from [compose.features.alloy.yaml](../compose.features.alloy.yaml) to the imported Compose before deployment.

Alloy mounts the Docker socket read-only, but that still exposes host container metadata.

## Maintenance

Templates are currently generated manually from the canonical Compose files when this repository changes. There is no committed render script because this starter is still small.

When changing root Compose, the self-hosted S3 overlay, Dokploy configs or files under `config/`, update `dokploy/templates/dokploy-*.json` in the same change.
