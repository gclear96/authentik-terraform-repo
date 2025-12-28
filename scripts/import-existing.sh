#!/usr/bin/env bash
set -euo pipefail

: "${AUTHENTIK_URL:?Set AUTHENTIK_URL (e.g. http://127.0.0.1:9000 or https://authentik.k8s.magomago.moe)}"
: "${AUTHENTIK_TOKEN:?Set AUTHENTIK_TOKEN (do not commit tokens)}"

if ! command -v jq >/dev/null 2>&1; then
  echo "Missing jq" >&2
  exit 1
fi

api_get() {
  local path="$1"
  local curl_args=("-fsS")
  if [[ "${AUTHENTIK_INSECURE:-}" == "true" ]]; then
    curl_args+=("-k")
  fi
  curl "${curl_args[@]}" -H "Authorization: Bearer ${AUTHENTIK_TOKEN}" "${AUTHENTIK_URL}${path}"
}

import_if_missing() {
  local addr="$1"
  local id="$2"

  if terraform state show -no-color "${addr}" >/dev/null 2>&1; then
    echo "Already in state: ${addr}"
    return 0
  fi

  echo "Importing: ${addr} <- ${id}"
  terraform import "${addr}" "${id}"
}

# Grafana OIDC (if present)
GRAFANA_PROVIDER_ID="$(
  api_get "/api/v3/providers/oauth2/?page_size=200" \
    | jq -r '.results[] | select((.client_id // "") == "grafana" or (.name // "") == "grafana") | .pk' \
    | head -n1
)"

GRAFANA_APPLICATION_ID="$(
  api_get "/api/v3/core/applications/?page_size=200" \
    | jq -r '.results[] | select((.slug // "") == "grafana") | .pk' \
    | head -n1
)"

if [[ -n "${GRAFANA_PROVIDER_ID}" ]]; then
  import_if_missing authentik_provider_oauth2.grafana "${GRAFANA_PROVIDER_ID}"
else
  echo "Skipping Grafana provider import (not found in Authentik API)."
fi

if [[ -n "${GRAFANA_APPLICATION_ID}" ]]; then
  import_if_missing authentik_application.grafana "${GRAFANA_APPLICATION_ID}"
else
  echo "Skipping Grafana application import (not found in Authentik API)."
fi
