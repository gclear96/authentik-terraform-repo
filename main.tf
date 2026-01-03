locals {
  authentik_external_url = "https://authentik.${var.cluster_domain}"
  grafana_external_url   = "https://grafana.${var.cluster_domain}"
  argocd_external_url    = "https://argocd.${var.cluster_domain}"
  forgejo_external_url   = "https://forgejo.${var.cluster_domain}"
  longhorn_external_url  = "https://longhorn.${var.cluster_domain}"
  vault_external_url     = "https://vault.${var.cluster_domain}"
  forgejo_auth_source    = var.forgejo_auth_source_name
}

# Required flows for OAuth2 providers.
data "authentik_flow" "grafana_authorization" {
  slug = var.grafana_authorization_flow_slug
}

data "authentik_flow" "grafana_invalidation" {
  slug = var.grafana_invalidation_flow_slug
}

# Default OIDC scopes for userinfo/id token claims.
data "authentik_property_mapping_provider_scope" "openid" {
  scope_name = "openid"
}

data "authentik_property_mapping_provider_scope" "email" {
  scope_name = "email"
}

data "authentik_property_mapping_provider_scope" "profile" {
  scope_name = "profile"
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

  property_mappings = [
    data.authentik_property_mapping_provider_scope.openid.id,
    data.authentik_property_mapping_provider_scope.email.id,
    data.authentik_property_mapping_provider_scope.profile.id,
  ]

  lifecycle {
    ignore_changes = [
      client_secret,
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

resource "authentik_provider_oauth2" "argocd" {
  name      = "argocd"
  client_id = "argocd"

  authorization_flow = data.authentik_flow.grafana_authorization.id
  invalidation_flow  = data.authentik_flow.grafana_invalidation.id

  allowed_redirect_uris = [
    {
      matching_mode = "strict"
      url           = "${local.argocd_external_url}/auth/callback"
    },
  ]

  property_mappings = [
    data.authentik_property_mapping_provider_scope.openid.id,
    data.authentik_property_mapping_provider_scope.email.id,
    data.authentik_property_mapping_provider_scope.profile.id,
  ]

  lifecycle {
    ignore_changes = [
      client_secret,
      signing_key,
      encryption_key,
    ]
  }
}

resource "authentik_application" "argocd" {
  name              = "Argo CD"
  slug              = "argocd"
  protocol_provider = authentik_provider_oauth2.argocd.id

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

resource "authentik_provider_oauth2" "forgejo" {
  name      = "forgejo"
  client_id = "forgejo"

  authorization_flow = data.authentik_flow.grafana_authorization.id
  invalidation_flow  = data.authentik_flow.grafana_invalidation.id

  allowed_redirect_uris = [
    {
      matching_mode = "strict"
      url           = "${local.forgejo_external_url}/user/oauth2/${local.forgejo_auth_source}/callback"
    },
  ]

  property_mappings = [
    data.authentik_property_mapping_provider_scope.openid.id,
    data.authentik_property_mapping_provider_scope.email.id,
    data.authentik_property_mapping_provider_scope.profile.id,
  ]

  lifecycle {
    ignore_changes = [
      client_secret,
      signing_key,
      encryption_key,
    ]
  }
}

resource "authentik_application" "forgejo" {
  name              = "Forgejo"
  slug              = "forgejo"
  protocol_provider = authentik_provider_oauth2.forgejo.id

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

resource "authentik_provider_oauth2" "longhorn" {
  name      = "longhorn"
  client_id = "longhorn"

  authorization_flow = data.authentik_flow.grafana_authorization.id
  invalidation_flow  = data.authentik_flow.grafana_invalidation.id

  allowed_redirect_uris = [
    {
      matching_mode = "strict"
      url           = var.longhorn_oidc_redirect_uri
    },
  ]

  property_mappings = [
    data.authentik_property_mapping_provider_scope.openid.id,
    data.authentik_property_mapping_provider_scope.email.id,
    data.authentik_property_mapping_provider_scope.profile.id,
  ]

  lifecycle {
    ignore_changes = [
      client_secret,
      signing_key,
      encryption_key,
    ]
  }
}

resource "authentik_application" "longhorn" {
  name              = "Longhorn"
  slug              = "longhorn"
  protocol_provider = authentik_provider_oauth2.longhorn.id

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

resource "authentik_provider_oauth2" "vault" {
  name      = "vault"
  client_id = "vault"

  authorization_flow = data.authentik_flow.grafana_authorization.id
  invalidation_flow  = data.authentik_flow.grafana_invalidation.id

  allowed_redirect_uris = [
    {
      matching_mode = "strict"
      url           = "${local.vault_external_url}/ui/vault/auth/oidc/oidc/callback"
    },
  ]

  property_mappings = [
    data.authentik_property_mapping_provider_scope.openid.id,
    data.authentik_property_mapping_provider_scope.email.id,
    data.authentik_property_mapping_provider_scope.profile.id,
  ]

  lifecycle {
    ignore_changes = [
      client_secret,
      signing_key,
      encryption_key,
    ]
  }
}

resource "authentik_application" "vault" {
  name              = "Vault"
  slug              = "vault"
  protocol_provider = authentik_provider_oauth2.vault.id

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

resource "authentik_provider_oauth2" "proxmox" {
  name      = "proxmox"
  client_id = "proxmox"

  authorization_flow = data.authentik_flow.grafana_authorization.id
  invalidation_flow  = data.authentik_flow.grafana_invalidation.id

  allowed_redirect_uris = [
    for uri in var.proxmox_allowed_redirect_uris : {
      matching_mode = "strict"
      url           = uri
    }
  ]

  property_mappings = [
    data.authentik_property_mapping_provider_scope.openid.id,
    data.authentik_property_mapping_provider_scope.email.id,
    data.authentik_property_mapping_provider_scope.profile.id,
  ]

  lifecycle {
    ignore_changes = [
      client_secret,
      signing_key,
      encryption_key,
    ]
  }
}

resource "authentik_application" "proxmox" {
  name              = "Proxmox"
  slug              = "proxmox"
  protocol_provider = authentik_provider_oauth2.proxmox.id

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
