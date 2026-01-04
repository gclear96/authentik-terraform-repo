variable "cluster_domain" {
  description = "Base cluster domain used for external app URLs (non-secret)."
  type        = string
  default     = "k8s.magomago.moe"
}

variable "grafana_authorization_flow_slug" {
  description = "Authentik Flow slug for OAuth2 authorization (used by the Grafana provider)."
  type        = string
  default     = "default-provider-authorization-implicit-consent"
}

variable "grafana_invalidation_flow_slug" {
  description = "Authentik Flow slug for OAuth2 token/session invalidation (used by the Grafana provider)."
  type        = string
  default     = "default-provider-invalidation-flow"
}

variable "forgejo_auth_source_name" {
  description = "Forgejo auth source name used in the OAuth callback path (e.g. https://forgejo.../user/oauth2/<name>/callback)."
  type        = string
  default     = "authentik"
}

variable "longhorn_oidc_redirect_uri" {
  description = "Redirect URI registered in Authentik for Longhorn UI (oauth2-proxy callback)."
  type        = string
  default     = "https://auth.k8s.magomago.moe/oauth2/callback"
}

variable "proxmox_allowed_redirect_uris" {
  description = "Allowed redirect URIs for Proxmox OIDC (set to match your Proxmox WebUI callback URL)."
  type        = list(string)
  default     = ["https://pve1.magomago.moe"]
}

variable "authentik_signing_key_id" {
  description = "Certificate keypair UUID used to sign OIDC tokens (RS256)."
  type        = string
  default     = "d7c308b4-41f5-40f2-af52-42220e3de45e"
}

variable "authentik_groups" {
  description = "Authentik groups managed by Terraform."
  type        = list(string)
  default = [
    "platform-admins",
    "grafana-admins",
    "grafana-editors",
    "argocd-admins",
  ]
}

variable "authentik_users" {
  description = "Authentik users managed by Terraform (passwords not managed here)."
  type = map(object({
    username  = string
    name      = optional(string)
    email     = optional(string)
    is_active = optional(bool)
    type      = optional(string)
    path      = optional(string)
    groups    = optional(list(string))
  }))
  default = {
    akadmin = {
      username  = "akadmin"
      is_active = true
      groups    = ["platform-admins"]
    }
  }
}
