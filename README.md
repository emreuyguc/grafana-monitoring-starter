# Grafana Observability Starter Kit

Personal Grafana-based observability starter kit for fast setup and practical configuration.

This repository is a single-stack boilerplate for Grafana, Loki and optional Alloy. Grafana and Loki are the core services. Loki can use either external S3-compatible storage or the self-hosted MinIO variant. Alloy is configured as an optional Compose overlay.

## Personal Use Notice

This project is created for personal use and experimentation.

- No license is currently provided.
- Use at your own risk.
- I do not accept responsibility for issues, data loss, outages or any damage caused by using this repository.

## System Summary

| Field | Value |
| --- | --- |
| App | `grafana-observability` |
| Starter version | `0.1.0` |
| Last updated | `2026-07-12` |
| Repository type | `single-stack-template` |
| Canonical Compose | `compose.yaml` |
| Local override | `compose.local.yaml` |
| Env example | `.env.example` |
| Static validation | `tests/validate-boilerplate.sh` |
| Dokploy variants | `dokploy/templates/dokploy-self-hosted-s3.json`, `dokploy/templates/dokploy-external-s3.json` |

## Service Inventory

Service metadata is mirrored from [manifest.yaml](manifest.yaml).

| Service | Role | Image | Default state | Public access |
| --- | --- | --- | --- | --- |
| `grafana` | Dashboard | `grafana/grafana:13.0.1` | Always on | Expose only this service in Coolify |
| `loki` | Log storage | `grafana/loki:3.7.0` | Always on | Internal only |
| `minio` | Self-hosted S3 storage | `ghcr.io/coollabsio/minio:RELEASE.2025-10-15T17-29-55Z` | `self-hosted-s3` overlay | Internal only |
| `minio-createbucket` | Self-hosted S3 bucket bootstrap | `ghcr.io/coollabsio/minio:RELEASE.2025-10-15T17-29-55Z` | `self-hosted-s3` overlay | Internal only |
| `alloy` | Optional collector | `grafana/alloy:v1.16.0` | `compose.features.alloy.yaml` overlay | Internal only |

## Quick Start

Run with external S3-compatible storage:

```bash
cp .env.example .env
docker compose --env-file .env -f compose.yaml up -d grafana loki
```

Run with self-hosted MinIO storage:

```bash
cp .env.self-hosted-s3.example .env
docker compose --env-file .env -f compose.yaml -f compose.self-hosted-s3.yaml up -d
```

Run locally with loopback-only Grafana and Loki ports:

```bash
docker compose --env-file .env -f compose.yaml -f compose.self-hosted-s3.yaml -f compose.local.yaml up -d
```

Open Grafana at `http://localhost:3000`.

## Deployment Notes

Coolify should use [compose.yaml](compose.yaml) as the canonical base Compose file. Assign a public domain to `grafana` only, and route the Grafana domain to container port `3000`.

Do not assign public domains to `loki` or `alloy`.

Dokploy import files are explicit per variant: use [dokploy/templates/dokploy-self-hosted-s3.json](dokploy/templates/dokploy-self-hosted-s3.json) for bundled MinIO storage, or [dokploy/templates/dokploy-external-s3.json](dokploy/templates/dokploy-external-s3.json) for external S3-compatible storage.

Default direct Fluent Bit ingestion target:

```text
http://loki:3100/loki/api/v1/push
```

Enable Alloy only when you need Docker log collection or OTLP ingestion:

```bash
docker compose --env-file .env -f compose.yaml -f compose.self-hosted-s3.yaml -f compose.features.alloy.yaml up -d
```

## Primary Files

| Path | Purpose |
| --- | --- |
| [compose.yaml](compose.yaml) | Canonical base Docker Compose stack |
| [compose.self-hosted-s3.yaml](compose.self-hosted-s3.yaml) | MinIO-backed self-hosted S3 variant overlay |
| [compose.features.alloy.yaml](compose.features.alloy.yaml) | Optional Alloy collector overlay |
| [compose.local.yaml](compose.local.yaml) | Local loopback-only port bindings |
| [.env.example](.env.example) | Non-secret complete environment inventory |
| [.env.self-hosted-s3.example](.env.self-hosted-s3.example) | Self-hosted MinIO variant environment inventory |
| [config/](config) | Grafana, Loki and Alloy runtime configuration |
| [manifest.yaml](manifest.yaml) | Machine-readable service and validation inventory |
| [dokploy/](dokploy) | Dokploy import template and platform notes |
| [tests/validate-boilerplate.sh](tests/validate-boilerplate.sh) | Static project validator |
| [docs/USER_GUIDE.md](docs/USER_GUIDE.md) | Full usage, deployment, ingestion and verification guide |
| [docs/MAINTENANCE.md](docs/MAINTENANCE.md) | Maintenance rules and source-of-truth notes |

## Optional Future Features

- [ ] Tempo for distributed tracing
- [ ] Prometheus for metrics scraping and storage
- [ ] Grafana Alerting rules, contact points and notification policies
- [ ] Prebuilt dashboards for common infrastructure and application workloads
