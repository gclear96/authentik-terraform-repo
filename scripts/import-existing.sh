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

# Groups mapping scope (if present)
GROUPS_MAPPING_ID="$(
  api_get "/api/v3/propertymappings/provider/scope/?page_size=200" \
    | jq -r '.results[] | select((.scope_name // "") == "groups" and (.name // "") == "authentik groups") | .pk' \
    | head -n1
)"

if [[ -n "${GROUPS_MAPPING_ID}" ]]; then
  import_if_missing authentik_property_mapping_provider_scope.groups "${GROUPS_MAPPING_ID}"
else
  echo "Skipping groups scope mapping import (not found in Authentik API)."
fi

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

# Argo CD OIDC (if present)
ARGOCD_PROVIDER_ID="$(
  api_get "/api/v3/providers/oauth2/?page_size=200" \
    | jq -r '.results[] | select((.client_id // "") == "argocd" or (.name // "") == "argocd") | .pk' \
    | head -n1
)"

ARGOCD_APPLICATION_ID="$(
  api_get "/api/v3/core/applications/?page_size=200" \
    | jq -r '.results[] | select((.slug // "") == "argocd") | .pk' \
    | head -n1
)"

if [[ -n "${ARGOCD_PROVIDER_ID}" ]]; then
  import_if_missing authentik_provider_oauth2.argocd "${ARGOCD_PROVIDER_ID}"
else
  echo "Skipping Argo CD provider import (not found in Authentik API)."
fi

if [[ -n "${ARGOCD_APPLICATION_ID}" ]]; then
  import_if_missing authentik_application.argocd "${ARGOCD_APPLICATION_ID}"
else
  echo "Skipping Argo CD application import (not found in Authentik API)."
fi

# Forgejo OIDC (if present)
FORGEJO_PROVIDER_ID="$(
  api_get "/api/v3/providers/oauth2/?page_size=200" \
    | jq -r '.results[] | select((.client_id // "") == "forgejo" or (.name // "") == "forgejo") | .pk' \
    | head -n1
)"

FORGEJO_APPLICATION_ID="$(
  api_get "/api/v3/core/applications/?page_size=200" \
    | jq -r '.results[] | select((.slug // "") == "forgejo") | .pk' \
    | head -n1
)"

if [[ -n "${FORGEJO_PROVIDER_ID}" ]]; then
  import_if_missing authentik_provider_oauth2.forgejo "${FORGEJO_PROVIDER_ID}"
else
  echo "Skipping Forgejo provider import (not found in Authentik API)."
fi

if [[ -n "${FORGEJO_APPLICATION_ID}" ]]; then
  import_if_missing authentik_application.forgejo "${FORGEJO_APPLICATION_ID}"
else
  echo "Skipping Forgejo application import (not found in Authentik API)."
fi

# Longhorn OIDC (if present)
LONGHORN_PROVIDER_ID="$(
  api_get "/api/v3/providers/oauth2/?page_size=200" \
    | jq -r '.results[] | select((.client_id // "") == "longhorn" or (.name // "") == "longhorn") | .pk' \
    | head -n1
)"

LONGHORN_APPLICATION_ID="$(
  api_get "/api/v3/core/applications/?page_size=200" \
    | jq -r '.results[] | select((.slug // "") == "longhorn") | .pk' \
    | head -n1
)"

if [[ -n "${LONGHORN_PROVIDER_ID}" ]]; then
  import_if_missing authentik_provider_oauth2.longhorn "${LONGHORN_PROVIDER_ID}"
else
  echo "Skipping Longhorn provider import (not found in Authentik API)."
fi

if [[ -n "${LONGHORN_APPLICATION_ID}" ]]; then
  import_if_missing authentik_application.longhorn "${LONGHORN_APPLICATION_ID}"
else
  echo "Skipping Longhorn application import (not found in Authentik API)."
fi

# Vault OIDC (if present)
VAULT_PROVIDER_ID="$(
  api_get "/api/v3/providers/oauth2/?page_size=200" \
    | jq -r '.results[] | select((.client_id // "") == "vault" or (.name // "") == "vault") | .pk' \
    | head -n1
)"

VAULT_APPLICATION_ID="$(
  api_get "/api/v3/core/applications/?page_size=200" \
    | jq -r '.results[] | select((.slug // "") == "vault") | .pk' \
    | head -n1
)"

if [[ -n "${VAULT_PROVIDER_ID}" ]]; then
  import_if_missing authentik_provider_oauth2.vault "${VAULT_PROVIDER_ID}"
else
  echo "Skipping Vault provider import (not found in Authentik API)."
fi

if [[ -n "${VAULT_APPLICATION_ID}" ]]; then
  import_if_missing authentik_application.vault "${VAULT_APPLICATION_ID}"
else
  echo "Skipping Vault application import (not found in Authentik API)."
fi

# Proxmox OIDC (if present)
PROXMOX_PROVIDER_ID="$(
  api_get "/api/v3/providers/oauth2/?page_size=200" \
    | jq -r '.results[] | select((.client_id // "") == "proxmox" or (.name // "") == "proxmox") | .pk' \
    | head -n1
)"

PROXMOX_APPLICATION_ID="$(
  api_get "/api/v3/core/applications/?page_size=200" \
    | jq -r '.results[] | select((.slug // "") == "proxmox") | .pk' \
    | head -n1
)"

if [[ -n "${PROXMOX_PROVIDER_ID}" ]]; then
  import_if_missing authentik_provider_oauth2.proxmox "${PROXMOX_PROVIDER_ID}"
else
  echo "Skipping Proxmox provider import (not found in Authentik API)."
fi

if [[ -n "${PROXMOX_APPLICATION_ID}" ]]; then
  import_if_missing authentik_application.proxmox "${PROXMOX_APPLICATION_ID}"
else
  echo "Skipping Proxmox application import (not found in Authentik API)."
fi

# Authentik users (if present)
USER_IDS="$(
  api_get "/api/v3/core/users/?page_size=200" \
    | jq -r '.results[] | "\(.username)|\(.pk)"'
)"

import_user_if_missing() {
  local username="$1"
  local user_id
  user_id="$(printf '%s\n' "${USER_IDS}" | awk -F'|' -v name="${username}" '$1 == name { print $2; exit }')"
  if [[ -n "${user_id}" ]]; then
    import_if_missing "authentik_user.managed[\"${username}\"]" "${user_id}"
  else
    echo "Skipping user import (${username} not found in Authentik API)."
  fi
}

# Import users declared in Terraform config.
managed_users="$(
  terraform console -json <<'EOF' | jq -r '.[]' || true
keys(var.authentik_users)
EOF
)"

if [[ -z "${managed_users}" ]]; then
  echo "WARN: could not resolve managed users via terraform console; falling back to defaults." >&2
  managed_users="akadmin"
fi

echo "Managed users (import candidates): ${managed_users}"
while IFS= read -r username; do
  [[ -z "${username}" ]] && continue
  import_user_if_missing "${username}"
done <<< "${managed_users}"

# Authentik groups (if present)
GROUP_IDS="$(
  api_get "/api/v3/core/groups/?page_size=200" \
    | jq -r '.results[] | "\(.name)|\(.pk)"'
)"

import_group_if_missing() {
  local group_name="$1"
  local group_id
  group_id="$(printf '%s\n' "${GROUP_IDS}" | awk -F'|' -v name="${group_name}" '$1 == name { print $2; exit }')"
  if [[ -n "${group_id}" ]]; then
    import_if_missing "authentik_group.managed[\"${group_name}\"]" "${group_id}"
  else
    echo "Skipping group import (${group_name} not found in Authentik API)."
  fi
}

managed_groups="$(
  terraform console -json <<'EOF' | jq -r '.[]' || true
distinct(concat(var.authentik_groups, flatten([for _, user in var.authentik_users : try(user.groups, [])])))
EOF
)"

if [[ -z "${managed_groups}" ]]; then
  echo "WARN: could not resolve managed groups via terraform console; falling back to defaults." >&2
  managed_groups=$(cat <<'EOF'
platform-admins
grafana-admins
grafana-editors
argocd-admins
EOF
)
fi

echo "Managed groups (import candidates): ${managed_groups}"
while IFS= read -r group_name; do
  [[ -z "${group_name}" ]] && continue
  import_group_if_missing "${group_name}"
done <<< "${managed_groups}"
