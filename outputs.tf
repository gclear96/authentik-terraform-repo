output "grafana_application_id" {
  value       = authentik_application.grafana.id
  description = "Grafana Authentik Application id."
}

output "grafana_oauth2_provider_id" {
  value       = authentik_provider_oauth2.grafana.id
  description = "Grafana Authentik OAuth2 Provider id."
}

