locals {
  authentik_external_url = "https://authentik.${var.cluster_domain}"
  grafana_external_url   = "https://grafana.${var.cluster_domain}"
}

# Required flows for OAuth2 providers.
data "authentik_flow" "grafana_authorization" {
  slug = var.grafana_authorization_flow_slug
}

data "authentik_flow" "grafana_invalidation" {
  slug = var.grafana_invalidation_flow_slug
}

# Minimal, safe initial scope:
# - Manage the Grafana OIDC provider/application pair.
# - Avoid enforcing secrets and “everything Authentik can do” on day 1.
#
# Important: even when we "ignore" changes to secrets, Terraform state can still contain sensitive values.

resource "authentik_provider_oauth2" "grafana" {
  name      = "grafana"
  client_id = "grafana"

  authorization_flow = data.authentik_flow.grafana_authorization.id
  invalidation_flow  = data.authentik_flow.grafana_invalidation.id

  allowed_redirect_uris = [
    {
      matching_mode = "strict"
      url           = "${local.grafana_external_url}/login/generic_oauth"
    },
  ]

  lifecycle {
    ignore_changes = [
      client_secret,
      property_mappings,
      signing_key,
      encryption_key,
    ]
  }
}

resource "authentik_application" "grafana" {
  name              = "Grafana"
  slug              = "grafana"
  protocol_provider = authentik_provider_oauth2.grafana.id

  lifecycle {
    ignore_changes = [
      group,
      meta_description,
      meta_icon,
      meta_launch_url,
      meta_publisher,
      open_in_new_tab,
      policy_engine_mode,
      backchannel_providers,
    ]
  }
}
