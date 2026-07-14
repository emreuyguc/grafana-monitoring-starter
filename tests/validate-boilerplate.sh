#!/usr/bin/env bash
set -euo pipefail

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

require_file() {
  [ -f "$1" ] || fail "missing $1"
}

require_grep() {
  local pattern="$1"
  local file="$2"
  grep -Eq "$pattern" "$file" || fail "expected pattern '$pattern' in $file"
}

reject_grep() {
  local pattern="$1"
  local file="$2"
  if grep -Eq "$pattern" "$file"; then
    fail "unexpected pattern '$pattern' in $file"
  fi
}

require_file compose.yaml
require_file compose.self-hosted-s3.yaml
require_file compose.features.alloy.yaml
require_file compose.local.yaml
require_file .env.example
require_file .env.self-hosted-s3.example
require_file config/loki/loki-config.yaml
require_file config/alloy/config.alloy
require_file config/grafana/provisioning/datasources/loki.yaml
require_file config/grafana/provisioning/dashboards/dashboards.yaml
require_file config/grafana/dashboards/loki-overview.json
require_file README.md
require_file manifest.yaml
require_file docs/USER_GUIDE.md
require_file docs/MAINTENANCE.md
require_file .github/workflows/validate.yml
require_file dokploy/config.self-hosted-s3.toml
require_file dokploy/config.external-s3.toml
require_file dokploy/templates/dokploy-self-hosted-s3.json
require_file dokploy/templates/dokploy-external-s3.json

old_default_dokploy_import='dokploy/''template'".json"
old_default_dokploy_config='dokploy/''config'".toml"
old_self_hosted_dokploy_import='dokploy/templates/''self-hosted-s3'".json"
old_external_dokploy_import='dokploy/templates/''external-s3'".json"
[ ! -e "$old_default_dokploy_import" ] || fail "remove ambiguous default Dokploy import file"
[ ! -e "$old_default_dokploy_config" ] || fail "remove ambiguous default Dokploy config file"
[ ! -e "$old_self_hosted_dokploy_import" ] || fail "remove old self-hosted Dokploy import file"
[ ! -e "$old_external_dokploy_import" ] || fail "remove old external Dokploy import file"

reject_grep ':latest([[:space:]]|$)' compose.yaml
reject_grep '^[[:space:]]+ports:' compose.yaml
reject_grep 'wget -q --spider' compose.yaml
reject_grep 'wget -q --spider' compose.features.alloy.yaml
legacy_compose_profile_env='COMPOSE''_PROFILES'
legacy_alloy_toggle_env='ENABLE''_ALLOY'
legacy_feature_env_pattern="${legacy_compose_profile_env}|${legacy_alloy_toggle_env}"
legacy_compose_profile_pattern="${legacy_feature_env_pattern}|profiles:"
reject_grep "$legacy_feature_env_pattern" .env.example
reject_grep "$legacy_feature_env_pattern" .env.self-hosted-s3.example
reject_grep "$legacy_compose_profile_pattern" compose.yaml
reject_grep "$legacy_compose_profile_pattern" compose.features.alloy.yaml
reject_grep "$legacy_feature_env_pattern" manifest.yaml
reject_grep "$legacy_feature_env_pattern" docs/USER_GUIDE.md
reject_grep "$legacy_feature_env_pattern" dokploy/config.self-hosted-s3.toml
reject_grep "$legacy_feature_env_pattern" dokploy/config.external-s3.toml
reject_grep 'dokploy/template\.json|templates/self-hosted-s3\.json|templates/external-s3\.json|config\.toml' README.md
reject_grep 'dokploy/template\.json|templates/self-hosted-s3\.json|templates/external-s3\.json|config\.toml' docs/USER_GUIDE.md
reject_grep 'dokploy/template\.json|templates/self-hosted-s3\.json|templates/external-s3\.json|config\.toml' docs/MAINTENANCE.md
reject_grep 'dokploy/template\.json|templates/self-hosted-s3\.json|templates/external-s3\.json|config\.toml' dokploy/README.md
reject_grep 'dokploy/template\.json|templates/self-hosted-s3\.json|templates/external-s3\.json|config\.toml' manifest.yaml

require_grep 'grafana/grafana:\$\{GRAFANA_VERSION:-13\.0\.1\}' compose.yaml
require_grep 'grafana/loki:\$\{LOKI_VERSION:-3\.7\.0\}' compose.yaml
require_grep 'grafana/alloy:\$\{ALLOY_VERSION:-v1\.16\.0\}' compose.features.alloy.yaml
require_grep 'GF_SECURITY_ADMIN_PASSWORD=\$\{GRAFANA_ADMIN_PASSWORD:\?' compose.yaml
require_grep 'GF_SERVER_ROOT_URL=\$\{GRAFANA_ROOT_URL:\?' compose.yaml
require_grep 'condition:[[:space:]]*service_started' compose.yaml
require_grep 'condition:[[:space:]]*service_started' compose.features.alloy.yaml
require_grep 'GF_SECURITY_COOKIE_SECURE=\$\{GRAFANA_COOKIE_SECURE:-true\}' compose.yaml
require_grep 'GF_SECURITY_COOKIE_SAMESITE=\$\{GRAFANA_COOKIE_SAMESITE:-lax\}' compose.yaml
require_grep 'GF_SECURITY_CONTENT_SECURITY_POLICY=\$\{GRAFANA_CONTENT_SECURITY_POLICY:-true\}' compose.yaml
require_grep 'GF_AUTH_ANONYMOUS_HIDE_VERSION=true' compose.yaml
require_grep 'GF_USERS_ALLOW_ORG_CREATE=false' compose.yaml
require_grep 'GF_SNAPSHOTS_EXTERNAL_ENABLED=false' compose.yaml
require_grep 'GF_METRICS_ENABLED=false' compose.yaml
require_grep 'http://127\.0\.0\.1:3100/ready' compose.yaml
require_grep 'LOKI_HEALTH_INTERVAL' compose.yaml
require_grep 'LOKI_STOP_GRACE_PERIOD' compose.yaml

require_grep 'auth_enabled:[[:space:]]*false' config/loki/loki-config.yaml
require_grep 'store:[[:space:]]*tsdb' config/loki/loki-config.yaml
require_grep 'schema:[[:space:]]*v13' config/loki/loki-config.yaml
require_grep 'object_store:[[:space:]]*s3' config/loki/loki-config.yaml
require_grep 'retention_enabled:[[:space:]]*true' config/loki/loki-config.yaml
require_grep 'delete_request_store:[[:space:]]*s3' config/loki/loki-config.yaml
require_grep 'allow_structured_metadata:[[:space:]]*true' config/loki/loki-config.yaml

require_grep 'uid:[[:space:]]*loki' config/grafana/provisioning/datasources/loki.yaml
require_grep 'url:[[:space:]]*http://loki:3100' config/grafana/provisioning/datasources/loki.yaml
require_grep 'Log volume by service' config/grafana/dashboards/loki-overview.json
require_grep 'Recent logs' config/grafana/dashboards/loki-overview.json
require_grep 'Error and fatal logs' config/grafana/dashboards/loki-overview.json
require_grep 'Unknown service coverage' config/grafana/dashboards/loki-overview.json

require_grep 'discovery\.docker "linux"' config/alloy/config.alloy
require_grep 'loki\.source\.docker "containers"' config/alloy/config.alloy
require_grep 'otelcol\.receiver\.otlp "default"' config/alloy/config.alloy
require_grep 'endpoint = "http://loki:3100/otlp"' config/alloy/config.alloy
require_grep 'url = "http://loki:3100/loki/api/v1/push"' config/alloy/config.alloy

require_grep 'LOKI_RETENTION_PERIOD=720h' .env.example
require_grep 'GRAFANA_COOKIE_SECURE=true' .env.example
require_grep 'GRAFANA_CONTENT_SECURITY_POLICY=true' .env.example
require_grep 'LOKI_HEALTH_START_PERIOD=45s' .env.example
require_grep 'LOKI_STOP_GRACE_PERIOD=2m' .env.example
require_grep 'MINIO_ROOT_USER=loki' .env.self-hosted-s3.example
require_grep 'MINIO_ROOT_PASSWORD=' .env.self-hosted-s3.example
require_grep 'LOKI_S3_ENDPOINT=http://minio:9000' compose.self-hosted-s3.yaml
require_grep 'condition:[[:space:]]*service_completed_successfully' compose.self-hosted-s3.yaml
require_grep 'app:[[:space:]]*grafana-observability' manifest.yaml
require_grep 'canonical_compose:[[:space:]]*compose\.yaml' manifest.yaml
require_grep 'base_compose:[[:space:]]*compose\.yaml' manifest.yaml
require_grep 'local_override:[[:space:]]*compose\.local\.yaml' manifest.yaml
require_grep 'static_validation:[[:space:]]*tests/validate-boilerplate\.sh' manifest.yaml
require_grep 'self-hosted-s3:[[:space:]]*dokploy/templates/dokploy-self-hosted-s3\.json' manifest.yaml
require_grep 'external-s3:[[:space:]]*dokploy/templates/dokploy-external-s3\.json' manifest.yaml
require_grep 'grafana/grafana:13\.0\.1' manifest.yaml
require_grep 'grafana/loki:3\.7\.0' manifest.yaml
require_grep 'grafana/alloy:v1\.16\.0' manifest.yaml
require_grep 'alloy_feature_overlay:[[:space:]]*compose\.features\.alloy\.yaml' manifest.yaml
require_grep 'grafana_security_hardening:[[:space:]]*enabled' manifest.yaml
require_grep 'loki_readiness_healthcheck:[[:space:]]*enabled' manifest.yaml
require_grep 'public_root_compose_ports:[[:space:]]*disabled' manifest.yaml

require_grep 'docs/USER_GUIDE\.md' README.md
require_grep 'docs/MAINTENANCE\.md' README.md
require_grep 'manifest\.yaml' README.md
require_grep 'canonical base Compose' README.md
require_grep 'canonical base Compose' docs/USER_GUIDE.md
require_grep 'canonical base stack' docs/MAINTENANCE.md
require_grep 'compose\.features\.alloy\.yaml' docs/USER_GUIDE.md
require_grep 'GRAFANA_COOKIE_SECURE=false' docs/USER_GUIDE.md
require_grep 'http://loki:3100/loki/api/v1/push' docs/USER_GUIDE.md
require_grep 'Grafana domain.*:3000' docs/USER_GUIDE.md
require_grep 'Do not add `scripts/` or `Makefile`' docs/MAINTENANCE.md
require_grep 'without blocking stack startup' docs/MAINTENANCE.md
require_grep 'bash tests/validate-boilerplate\.sh' .github/workflows/validate.yml

export GRAFANA_ADMIN_USER=admin
export GRAFANA_ADMIN_PASSWORD=change_me_grafana_admin_password_32_chars
export GRAFANA_ROOT_URL=http://localhost:3000
export LOKI_S3_BUCKET=loki-logs
export LOKI_S3_ENDPOINT=s3.example.com
export LOKI_S3_REGION=us-east-1
export LOKI_S3_ACCESS_KEY_ID=replace_with_s3_access_key_id
export LOKI_S3_SECRET_ACCESS_KEY=replace_with_s3_secret_access_key

docker compose config >/dev/null
docker compose --env-file .env.example -f compose.yaml -f compose.features.alloy.yaml config >/dev/null
docker compose --env-file .env.self-hosted-s3.example -f compose.yaml -f compose.self-hosted-s3.yaml config >/dev/null
docker compose --env-file .env.self-hosted-s3.example -f compose.yaml -f compose.self-hosted-s3.yaml -f compose.features.alloy.yaml config >/dev/null
jq empty dokploy/templates/dokploy-self-hosted-s3.json dokploy/templates/dokploy-external-s3.json
jq -r .compose dokploy/templates/dokploy-self-hosted-s3.json | docker compose --env-file .env.self-hosted-s3.example -f - config >/dev/null
jq -r .compose dokploy/templates/dokploy-external-s3.json | docker compose --env-file .env.example -f - config >/dev/null

printf 'Boilerplate validation passed.\n'
