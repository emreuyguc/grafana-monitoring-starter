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
require_file compose.local.yaml
require_file .env.example
require_file config/loki/loki-config.yaml
require_file config/alloy/config.alloy
require_file config/grafana/provisioning/datasources/loki.yaml
require_file config/grafana/provisioning/dashboards/dashboards.yaml
require_file config/grafana/dashboards/loki-overview.json
require_file README.md

reject_grep ':latest([[:space:]]|$)' compose.yaml
reject_grep '^[[:space:]]+ports:' compose.yaml

require_grep 'grafana/grafana:\$\{GRAFANA_VERSION:-13\.0\.1\}' compose.yaml
require_grep 'grafana/loki:\$\{LOKI_VERSION:-3\.7\.0\}' compose.yaml
require_grep 'grafana/alloy:\$\{ALLOY_VERSION:-v1\.16\.0\}' compose.yaml
require_grep 'profiles:[[:space:]]*\["alloy"\]' compose.yaml
require_grep 'GF_SECURITY_ADMIN_PASSWORD=\$\{GRAFANA_ADMIN_PASSWORD:\?' compose.yaml
require_grep 'GF_SERVER_ROOT_URL=\$\{GRAFANA_ROOT_URL:\?' compose.yaml

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
require_grep 'COMPOSE_PROFILES=alloy' README.md
require_grep 'http://loki:3100/loki/api/v1/push' README.md
require_grep 'Grafana domain.*:3000' README.md

export GRAFANA_ADMIN_USER=admin
export GRAFANA_ADMIN_PASSWORD=admin-password-change-me
export GRAFANA_ROOT_URL=http://localhost:3000
export LOKI_S3_BUCKET=loki-logs
export LOKI_S3_ENDPOINT=s3.example.com
export LOKI_S3_REGION=us-east-1
export LOKI_S3_ACCESS_KEY_ID=access-key
export LOKI_S3_SECRET_ACCESS_KEY=secret-key

docker compose config >/dev/null
COMPOSE_PROFILES=alloy docker compose config >/dev/null

printf 'Boilerplate validation passed.\n'
