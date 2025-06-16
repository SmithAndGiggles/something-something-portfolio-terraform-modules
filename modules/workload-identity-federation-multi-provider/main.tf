variable "project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "pool_id" {
  description = "The Workload Identity Pool ID."
  type        = string
}

variable "wif_providers" {
  description = "List of provider configurations for the workload identity pool."
  type = list(object({
    provider_id         = string
    select_provider     = string # "oidc", "aws", or "saml"
    provider_config     = map(any)
    disabled            = optional(bool)
    attribute_condition = optional(string)
    attribute_mapping   = map(string)
  }))
}

variable "service_accounts" {
  description = "List of service accounts to create and bind roles to."
  type = list(object({
    name           = string
    attribute      = string
    all_identities = bool
    roles          = list(string)
  }))
}

# Create the Workload Identity Pool
resource "google_iam_workload_identity_pool" "this" {
  provider                  = google-beta
  project                   = var.project_id
  workload_identity_pool_id = var.pool_id
  display_name              = var.pool_id
}

# Create multiple providers
resource "google_iam_workload_identity_pool_provider" "this" {
  for_each                         = { for p in var.wif_providers : p.provider_id => p }
  provider                        = google-beta
  project                         = var.project_id
  workload_identity_pool_id        = google_iam_workload_identity_pool.this.workload_identity_pool_id
  workload_identity_pool_provider_id = each.value.provider_id
  display_name                    = each.value.provider_id
  description                     = each.value.provider_id
  disabled                        = lookup(each.value, "disabled", false)
  attribute_condition             = lookup(each.value, "attribute_condition", null)
  attribute_mapping               = each.value.attribute_mapping

  dynamic "oidc" {
    for_each = each.value.select_provider == "oidc" ? [1] : []
    content {
      issuer_uri = each.value.provider_config["issuer_uri"]
      allowed_audiences = split(",", lookup(each.value.provider_config, "allowed_audiences", ""))
    }
  }

  dynamic "aws" {
    for_each = each.value.select_provider == "aws" ? [1] : []
    content {
      account_id = each.value.provider_config["account_id"]
    }
  }

  dynamic "saml" {
    for_each = each.value.select_provider == "saml" ? [1] : []
    content {
      idp_metadata_xml = each.value.provider_config["idp_metadata_xml"]
    }
  }
}

# Create service accounts and IAM bindings
resource "google_service_account" "this" {
  for_each = { for sa in var.service_accounts : sa.name => sa }
  account_id   = each.value.name
  display_name = each.value.name
  project      = var.project_id
}

resource "google_service_account_iam_binding" "this" {
  for_each = {
    for sa in var.service_accounts : sa.name => sa
  }
  service_account_id = google_service_account.this[each.key].name
  role               = each.value.roles[0] # Only the first role for simplicity; can be expanded for multiple roles
  members = [
    "principalSet://iam.googleapis.com/projects/${var.project_id}/locations/global/workloadIdentityPools/${var.pool_id}/attribute.${replace(each.value.attribute, "/", ".")}" # attribute mapping
  ]
  condition {
    title       = "Allow federation"
    description = "Allow federated identity to impersonate this service account."
    expression  = each.value.all_identities ? "true" : "false"
  }
}
