# authentik-terraform-repo

Manage the **in-cluster Authentik instance configuration** declaratively using the
Terraform Authentik provider (`goauthentik/authentik`).

## Safety + secrets model

- **No secrets in Git**. This repo expects credentials via env vars and/or `out/*.env` (gitignored).
- **Terraform state is sensitive**: Authentik configuration can contain secrets (e.g. OAuth client secrets),
  and Terraform state will often contain them. Treat the remote state (Garage `tf-state`) as a secret.

## Cluster context (as of 2025-12-28)

- Namespace: `authentik`
- Service: `platform-authentik-server` (ports `80`/`443`; targets `9000`/`9443`)
- External URL (ingress): `https://authentik.k8s.magomago.moe`

Discovered with:

```bash
KUBECONFIG=../talos-proxmox-bootstrap-repo/out/talos-admin-1.kubeconfig \
kubectl -n authentik get svc,pods,ingress -o wide
```

## Prereqs

- `terraform` (or OpenTofu if you prefer; CI uses Terraform)
- `curl`, `jq`
- For local port-forward: `kubectl` and `KUBECONFIG=../talos-proxmox-bootstrap-repo/out/talos-admin-1.kubeconfig`

## Auth strategy (no secrets in repo)

The provider supports:

- `AUTHENTIK_URL` (base URL like `http://127.0.0.1:9000` or `https://authentik.k8s.magomago.moe`)
- `AUTHENTIK_TOKEN` (API token)
- `AUTHENTIK_INSECURE` (optional; `true` to skip TLS verification)

API calls are under `AUTHENTIK_URL/api/v3/...` (see `scripts/inspect-authentik.sh`).

## Local workflow

1) Port-forward Authentik (HTTP by default):

```bash
./scripts/port-forward-authentik.sh
```

Then in another shell:

```bash
export AUTHENTIK_URL="http://127.0.0.1:9000"
export AUTHENTIK_TOKEN="...redacted..."
```

2) Initialize remote state in Garage:

Create `out/garage-tfstate.env` with Garage S3 credentials + endpoint (gitignored), then:

```bash
./scripts/tf-init-garage.sh
```

3) Inventory what exists (read-only; secrets redacted):

```bash
./scripts/inspect-authentik.sh
```

4) Import existing objects before the first apply:

```bash
./scripts/import-existing.sh
```

5) Plan/apply:

```bash
terraform plan
terraform apply
```

## Remote state (Garage S3)

This repo uses an S3 backend targeting Garage:

- bucket: `tf-state`
- key: `authentik/terraform.tfstate`

The backend is intentionally partial in `backend.tf`; supply the Garage endpoint and S3-compat flags at init time
(see `scripts/tf-init-garage.sh`).

## CI notes (Forgejo Actions)

- `AUTHENTIK_URL` should typically use the **in-cluster** Service, e.g. `http://platform-authentik-server.authentik.svc:80`.
- Use a scoped Authentik token for `AUTHENTIK_TOKEN` (avoid long-lived admin/root).

## Initial scope

Start small and avoid user/password management. The initial config in `main.tf` focuses on the Grafana OIDC
application/provider pair (if present) and ignores some fields we’re not ready to enforce yet (notably secrets).
