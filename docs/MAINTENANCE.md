# Maintenance

This repository is a single-stack Grafana observability starter. Keep the structure small and operationally useful.

## Source of Truth

- [compose.yaml](../compose.yaml) is the canonical base stack definition.
- [compose.self-hosted-s3.yaml](../compose.self-hosted-s3.yaml) is the MinIO-backed storage topology overlay.
- [compose.features.alloy.yaml](../compose.features.alloy.yaml) is the optional Alloy collector overlay.
- [compose.local.yaml](../compose.local.yaml) is only for loopback-bound local ports.
- [.env.example](../.env.example) is the complete non-secret environment inventory.
- [.env.self-hosted-s3.example](../.env.self-hosted-s3.example) is the self-hosted MinIO variant env inventory.
- [manifest.yaml](../manifest.yaml) records service metadata, features and validation commands.
- [dokploy/templates/dokploy-self-hosted-s3.json](../dokploy/templates/dokploy-self-hosted-s3.json) is the Dokploy import artifact for the self-hosted S3 variant.
- [dokploy/templates/dokploy-external-s3.json](../dokploy/templates/dokploy-external-s3.json) is the Dokploy import artifact for the external S3 variant.
- [tests/validate-boilerplate.sh](../tests/validate-boilerplate.sh) is the static validator used locally and in CI.

## Repository Rules

- Do not add platform folders unless there is a real generated or maintained artifact for that platform.
- Keep Dokploy limited to `grafana` as the only public domain target.
- Env files provide values. Compose overlays select topology. Do not use env values to hide or remove services.
- Keep self-hosted object storage internal; do not publish MinIO by default.
- Do not add `scripts/` or `Makefile` until there are multiple repeatable commands worth grouping.
- Do not split production behavior into `compose.prod.yaml` while [compose.yaml](../compose.yaml) already carries the required restart and logging policies.
- Keep Grafana as the only public service. Loki and Alloy must stay internal by default.
- Keep optional collectors behind explicit Compose feature overlays instead of environment-driven Compose profile switches.
- Keep image tags explicit; do not use `latest`.
- Keep root Compose free of public `ports:` mappings. Use [compose.local.yaml](../compose.local.yaml) for local-only ports.
- Avoid making Grafana deployment depend on Loki health status; keep service healthchecks for observability without blocking stack startup.
- Keep production Grafana cookies secure by default, and document local HTTP exceptions.
- Keep generated Dokploy templates synchronized with `compose.yaml`, `compose.self-hosted-s3.yaml`, `dokploy/config.*.toml` and `config/`.

## Documentation Rules

- Keep [README.md](../README.md) short: overview, quick commands and file map.
- Put operational details in [docs/USER_GUIDE.md](USER_GUIDE.md).
- Update this file when the maintenance shape or source-of-truth rules change.
- Avoid adding new docs for narrow topics unless existing docs become hard to use.

## Validation Checklist

Before changing Compose, env or provisioning files:

1. Update synchronized docs and [manifest.yaml](../manifest.yaml) if service metadata changed.
2. Run:

```bash
bash tests/validate-boilerplate.sh
```

3. For runtime-sensitive changes, start the stack and check Loki readiness plus a manual log push.
