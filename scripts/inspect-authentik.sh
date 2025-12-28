#!/usr/bin/env bash
set -euo pipefail

: "${AUTHENTIK_URL:?Set AUTHENTIK_URL (e.g. http://127.0.0.1:9000 or https://authentik.k8s.magomago.moe)}"
: "${AUTHENTIK_TOKEN:?Set AUTHENTIK_TOKEN (do not commit tokens)}"

if ! command -v jq >/dev/null 2>&1; then
  echo "Missing jq" >&2
  exit 1
fi

redact() {
  jq '
    def scrub:
      walk(
        if type == "object" then
          del(.client_secret?, .token?, .secret?, .password?, .key?, .private_key?)
        else .
        end
      );
    scrub
  '
}

api_get() {
  local path="$1"
  local curl_args=("-fsS")
  if [[ "${AUTHENTIK_INSECURE:-}" == "true" ]]; then
    curl_args+=("-k")
  fi
  curl "${curl_args[@]}" -H "Authorization: Bearer ${AUTHENTIK_TOKEN}" "${AUTHENTIK_URL}${path}"
}

echo "== Authentik version =="
api_get "/api/v3/admin/version/" | jq .

echo
echo "== Applications (core/applications) =="
api_get "/api/v3/core/applications/?page_size=200" | redact | jq -r '
  .results
  | sort_by(.slug)
  | .[]
  | "- slug=\(.slug) name=\(.name) pk=\(.pk) uuid=\(.uuid) protocol_provider=\(.provider // .protocol_provider // "n/a")"
'

echo
echo "== OAuth2 providers (providers/oauth2) =="
api_get "/api/v3/providers/oauth2/?page_size=200" | redact | jq -r '
  .results
  | sort_by(.client_id)
  | .[]
  | "- name=\(.name) client_id=\(.client_id) pk=\(.pk) redirect_uris=" + ((.redirect_uris // []) | map(.url) | join(","))
'

echo
echo "== Flows (flows/instances) =="
api_get "/api/v3/flows/instances/?page_size=200" | jq -r '
  .results
  | sort_by(.slug)
  | .[]
  | "- slug=\(.slug) name=\(.name) pk=\(.pk)"
'
