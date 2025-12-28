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
