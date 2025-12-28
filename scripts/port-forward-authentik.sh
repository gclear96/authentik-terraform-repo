#!/usr/bin/env bash
set -euo pipefail

: "${KUBECONFIG:?Set KUBECONFIG (e.g. ../talos-proxmox-bootstrap-repo/out/talos-admin-1.kubeconfig)}"

KUBECTL="${KUBECTL:-kubectl}"
NAMESPACE="${NAMESPACE:-authentik}"
SERVICE="${SERVICE:-}"
MODE="${MODE:-http}" # http|https

if [[ -z "${SERVICE}" ]]; then
  SERVICE="$(
    "${KUBECTL}" -n "${NAMESPACE}" get svc -l app.kubernetes.io/name=authentik,app.kubernetes.io/component=server \
      -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true
  )"
fi

if [[ -z "${SERVICE}" ]]; then
  echo "Could not auto-detect Authentik Service in namespace ${NAMESPACE}." >&2
  echo "Available services:" >&2
  "${KUBECTL}" -n "${NAMESPACE}" get svc -o wide >&2
  echo >&2
  echo "Re-run with SERVICE=... (for this cluster it is usually: platform-authentik-server)" >&2
  exit 1
fi

case "${MODE}" in
  http)
    LOCAL_PORT="${LOCAL_PORT:-9000}"
    REMOTE_PORT="${REMOTE_PORT:-80}"
    echo "Port-forwarding ${NAMESPACE}/svc/${SERVICE} ${LOCAL_PORT}:${REMOTE_PORT} (http)"
    echo "Suggested env:"
    echo "  export AUTHENTIK_URL=http://127.0.0.1:${LOCAL_PORT}"
    ;;
  https)
    LOCAL_PORT="${LOCAL_PORT:-9443}"
    REMOTE_PORT="${REMOTE_PORT:-443}"
    echo "Port-forwarding ${NAMESPACE}/svc/${SERVICE} ${LOCAL_PORT}:${REMOTE_PORT} (https)"
    echo "Suggested env:"
    echo "  export AUTHENTIK_URL=https://127.0.0.1:${LOCAL_PORT}"
    echo "  export AUTHENTIK_INSECURE=true   # if Authentik serves an internal/self-signed cert"
    ;;
  *)
    echo "MODE must be 'http' or 'https' (got: ${MODE})" >&2
    exit 2
    ;;
esac

echo
echo "Service ports:"
"${KUBECTL}" -n "${NAMESPACE}" get svc "${SERVICE}" -o jsonpath='{range .spec.ports[*]}- {.name}: {.port} -> {.targetPort}{"\n"}{end}' || true
echo

exec "${KUBECTL}" -n "${NAMESPACE}" port-forward "svc/${SERVICE}" "${LOCAL_PORT}:${REMOTE_PORT}"
